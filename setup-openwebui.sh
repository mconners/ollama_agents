#!/bin/bash

# Open WebUI Setup and Management for Ollama Cluster
# Complete web interface for coding, image generation, and chat

echo "🌐 Setting up Open WebUI for Ollama Cluster"
echo "============================================="

# Check if on AGX0 (main node) or ORIN0 (secondary)
CURRENT_HOST=$(hostname)
CURRENT_IP=$(hostname -I | awk '{print $1}')

echo "Current host: $CURRENT_HOST ($CURRENT_IP)"
echo ""

# Determine deployment location
if [[ "$CURRENT_HOST" == *"agx0"* ]] || [[ "$CURRENT_IP" == "192.168.1.154" ]]; then
    DEPLOY_NODE="AGX0"
    DEPLOY_IP="192.168.1.154"
elif [[ "$CURRENT_HOST" == *"orin0"* ]] || [[ "$CURRENT_IP" == "192.168.1.157" ]]; then
    DEPLOY_NODE="ORIN0" 
    DEPLOY_IP="192.168.1.157"
else
    echo "⚠️  Not on AGX0 or ORIN0. Deploying to ORIN0 via SSH..."
    DEPLOY_NODE="ORIN0"
    DEPLOY_IP="192.168.1.157"
    USE_SSH=true
fi

deploy_openwebui() {
    echo "🚀 Deploying Open WebUI to $DEPLOY_NODE ($DEPLOY_IP)"
    
    if [[ "$USE_SSH" == "true" ]]; then
        echo "📡 Copying deployment files to $DEPLOY_IP..."
        scp -i ~/.ssh/ollama_cluster_key deployment/docker-compose-openwebui.yml mconners@$DEPLOY_IP:~/
        
        echo "🔧 Setting up Open WebUI remotely..."
        ssh -i ~/.ssh/ollama_cluster_key mconners@$DEPLOY_IP << 'EOF'
            cd ~/
            
            # Pull embedding model for RAG
            echo "📚 Setting up embedding model for document search..."
            docker run --rm -v embedding-models:/root/.ollama ollama/ollama pull nomic-embed-text:latest
            
            # Start Open WebUI
            echo "🌐 Starting Open WebUI cluster interface..."
            docker-compose -f docker-compose-openwebui.yml up -d
            
            echo "⏳ Waiting for services to start..."
            sleep 15
            
            # Check status
            echo "📊 Service Status:"
            docker-compose -f docker-compose-openwebui.yml ps
EOF
    else
        echo "🔧 Setting up Open WebUI locally..."
        
        # Pull embedding model for RAG
        echo "📚 Setting up embedding model for document search..."
        docker run --rm -v embedding-models:/root/.ollama ollama/ollama pull nomic-embed-text:latest
        
        # Start Open WebUI
        echo "🌐 Starting Open WebUI cluster interface..."
        docker-compose -f deployment/docker-compose-openwebui.yml up -d
        
        echo "⏳ Waiting for services to start..."
        sleep 15
        
        # Check status
        echo "📊 Service Status:"
        docker-compose -f deployment/docker-compose-openwebui.yml ps
    fi
}

show_access_info() {
    echo ""
    echo "🎯 Access Your AI Cluster Web Interface"
    echo "========================================"
    echo ""
    echo "🌐 Open WebUI (Main Interface):"
    echo "   URL: http://$DEPLOY_IP:8080"
    echo "   Features: Chat, Coding, RAG, Model Management"
    echo "   Default Models: codellama:34b, qwen2.5-coder:32b, llama3:8b"
    echo ""
    echo "🎨 Image Generation (Stable Diffusion):"
    echo "   URL: http://$DEPLOY_IP:7860"
    echo "   Features: Text-to-image, Image editing"
    echo "   Note: Initial setup may take 10-15 minutes"
    echo ""
    echo "🔍 Embedding Service (RAG):"
    echo "   URL: http://$DEPLOY_IP:11436"
    echo "   Features: Document search, Semantic similarity"
    echo ""
    echo "📚 Connected Ollama Endpoints:"
    echo "   AGX0 (Primary): http://192.168.1.154:11434 (134GB models)"
    echo "   ORIN0 (Secondary): http://192.168.1.157:11435 (shared models)"
    echo ""
    echo "🎯 Quick Start Guide:"
    echo "   1. Open http://$DEPLOY_IP:8080 in your browser"
    echo "   2. Create an account (first user becomes admin)"
    echo "   3. Select a model from the dropdown"
    echo "   4. Start chatting, coding, or generating images!"
    echo ""
    echo "💡 Usage Examples:"
    echo "   • Coding: 'Review this Python code and suggest improvements'"
    echo "   • Image: 'Generate an image of a futuristic data center'"
    echo "   • Chat: 'Explain quantum computing in simple terms'"
    echo "   • RAG: Upload documents and ask questions about them"
}

check_status() {
    echo "📊 Open WebUI Cluster Status"
    echo "============================"
    
    # Check Open WebUI
    if curl -s "http://$DEPLOY_IP:8080" > /dev/null; then
        echo "✅ Open WebUI: http://$DEPLOY_IP:8080"
    else
        echo "❌ Open WebUI: Not responding"
    fi
    
    # Check Stable Diffusion
    if curl -s "http://$DEPLOY_IP:7860" > /dev/null; then
        echo "✅ Stable Diffusion: http://$DEPLOY_IP:7860"
    else
        echo "⏳ Stable Diffusion: Starting up or not ready"
    fi
    
    # Check embedding service
    if curl -s "http://$DEPLOY_IP:11436/api/tags" > /dev/null; then
        echo "✅ Embedding Service: http://$DEPLOY_IP:11436"
    else
        echo "❌ Embedding Service: Not responding"
    fi
    
    # Check connected Ollama services
    if curl -s "http://192.168.1.154:11434/api/tags" > /dev/null; then
        echo "✅ AGX0 Ollama: http://192.168.1.154:11434"
    else
        echo "❌ AGX0 Ollama: Not responding"
    fi
    
    if curl -s "http://192.168.1.157:11435/api/tags" > /dev/null; then
        echo "✅ ORIN0 Ollama: http://192.168.1.157:11435"
    else
        echo "❌ ORIN0 Ollama: Not responding"
    fi
}

stop_services() {
    echo "🛑 Stopping Open WebUI services..."
    
    if [[ "$USE_SSH" == "true" ]]; then
        ssh -i ~/.ssh/ollama_cluster_key mconners@$DEPLOY_IP \
            "docker-compose -f docker-compose-openwebui.yml down"
    else
        docker-compose -f deployment/docker-compose-openwebui.yml down
    fi
}

# Main script logic
case "${1:-deploy}" in
    "deploy"|"start")
        deploy_openwebui
        show_access_info
        ;;
    "status")
        check_status
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        sleep 5
        deploy_openwebui
        show_access_info
        ;;
    "logs")
        if [[ "$USE_SSH" == "true" ]]; then
            ssh -i ~/.ssh/ollama_cluster_key mconners@$DEPLOY_IP \
                "docker-compose -f docker-compose-openwebui.yml logs -f"
        else
            docker-compose -f deployment/docker-compose-openwebui.yml logs -f
        fi
        ;;
    *)
        echo "Usage: $0 {deploy|start|status|stop|restart|logs}"
        echo ""
        echo "Commands:"
        echo "  deploy/start  - Deploy Open WebUI with image generation"
        echo "  status        - Check service status"
        echo "  stop          - Stop all services"
        echo "  restart       - Restart all services"
        echo "  logs          - Show service logs"
        ;;
esac
