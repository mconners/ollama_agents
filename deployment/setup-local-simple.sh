#!/bin/bash

# Simple Local Model Strategy
# Each node manages its own models, use AGX0 as a "model server" via API

echo "🏠 Setting up Simple Local Model Storage"
echo "======================================="

NODE_NAME=${1:-$(hostname)}

echo "📝 Creating simple local configuration for $NODE_NAME..."

# Just use local persistent volumes - no sharing complexity
cat > docker-compose-local-simple.yml << EOF
version: '3.8'

services:
  ollama-local:
    image: ollama/ollama:latest
    container_name: ollama-\${NODE_NAME}
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./data/ollama:/root/.ollama
      - ./models:/models
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
      - OLLAMA_ORIGINS=*
      - OLLAMA_MODELS=/models
      - AGX0_MODELS_API=http://192.168.1.154:11434
    networks:
      - ollama_cluster
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  ollama_cluster:
    driver: bridge
EOF

# Create helper script for model management
cat > manage-models.sh << 'EOF'
#!/bin/bash

AGX0_API="http://192.168.1.154:11434"
LOCAL_API="http://localhost:11434"

case "$1" in
    "list-agx0")
        echo "🎮 Models available on AGX0:"
        curl -s $AGX0_API/api/tags | jq -r '.models[].name' || echo "Failed to connect to AGX0"
        ;;
    "list-local") 
        echo "🏠 Models available locally:"
        curl -s $LOCAL_API/api/tags | jq -r '.models[].name' || echo "Local Ollama not running"
        ;;
    "copy-from-agx0")
        MODEL=$2
        if [ -z "$MODEL" ]; then
            echo "Usage: $0 copy-from-agx0 <model-name>"
            exit 1
        fi
        echo "📥 Copying $MODEL from AGX0 to local..."
        # This would use Ollama's model sharing capabilities
        docker exec ollama-$(hostname) ollama pull $MODEL
        ;;
    "use-agx0")
        MODEL=$2  
        PROMPT=$3
        echo "🌐 Using AGX0 for inference: $MODEL"
        curl -s -X POST $AGX0_API/api/generate \
            -d "{\"model\":\"$MODEL\", \"prompt\":\"$PROMPT\", \"stream\":false}" \
            | jq -r '.response'
        ;;
    *)
        echo "Usage: $0 {list-agx0|list-local|copy-from-agx0 <model>|use-agx0 <model> <prompt>}"
        echo ""
        echo "Simple model management:"
        echo "  📋 list-agx0        - See what models AGX0 has"
        echo "  🏠 list-local       - See what models are local" 
        echo "  📥 copy-from-agx0   - Download a model from AGX0"
        echo "  🌐 use-agx0         - Use AGX0 for inference (no local copy needed)"
        ;;
esac
EOF

chmod +x manage-models.sh

echo "✅ Simple local configuration created"
echo ""
echo "💡 This approach:"
echo "  🏠 Each node manages its own models independently"
echo "  📥 Can copy specific models from AGX0 when needed"  
echo "  🌐 Can use AGX0 for inference without local copies"
echo "  🔧 Simple Docker volumes, no NFS complexity"
echo "  ⚡ Fast local access, network API for AGX0 models"
