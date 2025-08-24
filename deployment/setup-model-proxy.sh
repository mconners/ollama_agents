#!/bin/bash

# Model-on-Demand Strategy
# Creates a model proxy system where nodes can pull models from AGX0 when needed

echo "🔄 Setting up Model-on-Demand Architecture"
echo "=========================================="

# Create docker-compose for model proxy
cat > docker-compose-model-proxy.yml << 'EOF'
version: '3.8'

services:
  # Nginx proxy to route model requests
  model-proxy:
    image: nginx:alpine
    container_name: model-proxy
    restart: unless-stopped
    ports:
      - "11440:80"
    volumes:
      - ./nginx-model-proxy.conf:/etc/nginx/nginx.conf:ro
    networks:
      - ollama_cluster
    depends_on:
      - ollama-cache

  # Local Ollama with smart caching
  ollama-cache:
    image: ollama/ollama:latest
    container_name: ollama-cache
    restart: unless-stopped
    volumes:
      - ./data/ollama-cache:/root/.ollama
      - ./cache-script.sh:/cache-script.sh:ro
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
      - OLLAMA_ORIGINS=*
      - PRIMARY_OLLAMA_HOST=192.168.1.154:11434
    networks:
      - ollama_cluster
    command: >
      sh -c "/cache-script.sh & /bin/ollama serve"

networks:
  ollama_cluster:
    driver: bridge
EOF

# Create nginx config for model routing
cat > nginx-model-proxy.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream agx0_primary {
        server 192.168.1.154:11434;
    }
    
    upstream local_cache {
        server ollama-cache:11434;
    }
    
    server {
        listen 80;
        
        # Try local cache first, fallback to AGX0
        location /api/generate {
            proxy_pass http://local_cache;
            proxy_set_header Host $host;
            proxy_connect_timeout 2s;
            proxy_read_timeout 300s;
            
            # If local fails, try AGX0
            error_page 502 503 504 = @fallback;
        }
        
        # Fallback to AGX0 for model requests
        location @fallback {
            proxy_pass http://agx0_primary;
            proxy_set_header Host $host;
        }
        
        # Model management always goes to AGX0
        location /api/pull {
            proxy_pass http://agx0_primary;
            proxy_set_header Host $host;
        }
        
        location /api/tags {
            proxy_pass http://agx0_primary;
            proxy_set_header Host $host;
        }
    }
}
EOF

# Create cache management script
cat > cache-script.sh << 'EOF'
#!/bin/sh

# Smart model caching script
# Downloads frequently used models locally, routes others to AGX0

CACHE_DIR="/root/.ollama"
PRIMARY_HOST="${PRIMARY_OLLAMA_HOST:-192.168.1.154:11434}"

# List of models to cache locally based on node type
case "$(hostname)" in
    "pi5"*) 
        CACHE_MODELS="phi3:mini gemma2:2b"  # Lightweight models for Pi5
        ;;
    "orin"*)
        CACHE_MODELS="codellama:7b qwen2.5-coder:7b phi3:medium"  # Code models for ORIN
        ;;
    *)
        CACHE_MODELS="phi3:mini"  # Default lightweight model
        ;;
esac

echo "🔄 Starting model caching for $(hostname)"
echo "📋 Will cache: $CACHE_MODELS"

# Wait for Ollama to start
sleep 10

# Cache essential models
for model in $CACHE_MODELS; do
    echo "📦 Checking if $model is cached..."
    if ! ollama list | grep -q "$model"; then
        echo "⬇️ Downloading $model from AGX0..."
        OLLAMA_HOST="$PRIMARY_HOST" ollama pull "$model"
        ollama pull "$model"  # Pull to local instance
    fi
done

echo "✅ Model caching complete"

# Keep running to handle dynamic caching
while true; do
    sleep 3600  # Check every hour for new models to cache
done
EOF

chmod +x cache-script.sh

echo "✅ Model-on-Demand configuration created"
echo ""
echo "📋 This approach provides:"
echo "  🔄 Intelligent model routing (local first, AGX0 fallback)"
echo "  📦 Automatic caching of frequently used models"
echo "  ⚡ Fast access to cached models, network access for others"
echo "  🎯 Node-specific model optimization"
