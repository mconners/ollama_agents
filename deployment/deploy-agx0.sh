#!/bin/bash

# Deploy AGX0 Primary AI Processing Node
# Jetson AGX Orin with NVIDIA GPU support

echo "🎯 Deploying AGX0 Primary AI Processing Node"
echo "============================================="

TARGET_HOST="192.168.1.154"
SSH_KEY="~/.ssh/ollama_cluster_key"
NODE_NAME="AGX0"

echo "📡 Target: AGX0 ($TARGET_HOST)"
echo "🔑 SSH Key: $SSH_KEY"
echo ""

# Check connectivity
echo "🔍 Checking connectivity to AGX0..."
if ! ssh -i $SSH_KEY -o ConnectTimeout=5 mconners@$TARGET_HOST "echo 'Connected to AGX0'" 2>/dev/null; then
    echo "❌ Cannot connect to AGX0 at $TARGET_HOST"
    echo "Please ensure:"
    echo "  - AGX0 is powered on and connected"
    echo "  - SSH key is deployed: ssh-copy-id -i $SSH_KEY mconners@$TARGET_HOST"
    exit 1
fi

echo "✅ Connected to AGX0"

# Copy deployment files
echo ""
echo "📁 Copying deployment files to AGX0..."
scp -i $SSH_KEY deployment/docker-compose-agx0-primary.yml mconners@$TARGET_HOST:~/docker-compose.yml
scp -i $SSH_KEY deployment/setup-node.sh mconners@$TARGET_HOST:~/

echo "✅ Files copied to AGX0"

# Execute deployment
echo ""
echo "🚀 Executing deployment on AGX0..."
ssh -i $SSH_KEY mconners@$TARGET_HOST << 'ENDSSH'
    echo "🎮 Setting up AGX0 Primary AI Processing Node"
    echo "============================================="
    
    # Update system and install dependencies
    echo "📦 Updating system and installing dependencies..."
    sudo apt update -qq
    
    # Install Docker if not present
    if ! command -v docker >/dev/null 2>&1; then
        echo "🐳 Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
    fi
    
    # Install Docker Compose if not present
    if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
        echo "🐳 Installing Docker Compose..."
        sudo apt install -y docker-compose-plugin docker-buildx-plugin
    fi
    
    # Setup NVIDIA Container Toolkit if not present (for Jetson)
    if ! command -v nvidia-container-runtime >/dev/null 2>&1; then
        echo "🎮 Setting up NVIDIA Container Toolkit for Jetson..."
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt update -qq
        sudo apt install -y nvidia-container-toolkit nvidia-container-runtime
        sudo systemctl restart docker
    fi
    
    # Run setup script
    echo "🛠️ Running node setup..."
    chmod +x setup-node.sh
    ./setup-node.sh AGX0 docker-compose.yml
    
    echo ""
    echo "🎯 AGX0 Primary AI Processing Node Deployment Summary"
    echo "===================================================="
    echo "🤖 Main Ollama with GPU: http://$HOSTNAME:11434/api/tags"
    echo "🔬 Jupyter AI Lab: http://$HOSTNAME:8888 (token: ollama-cluster)"
    echo "🎛️ Model Manager: http://$HOSTNAME:3001"
    echo "📈 Prometheus: http://$HOSTNAME:9090"
    echo "🔄 Redis Cache: localhost:6379"
    echo "🌐 AI API Gateway: http://$HOSTNAME:8080"
    echo ""
    echo "📊 Final Status Check:"
    docker compose ps
    
    echo ""
    echo "💾 Persistent Storage:"
    echo "  - Ollama Models: $(pwd)/data/ollama/"
    echo "  - Jupyter Workspace: $(pwd)/data/jupyter/"
    echo "  - Redis Data: $(pwd)/data/redis/"
    echo "  - Prometheus Data: $(pwd)/data/prometheus/"
    echo ""
    echo "✅ AGX0 deployment complete!"
ENDSSH

DEPLOYMENT_STATUS=$?

echo ""
echo "🏁 AGX0 Deployment Complete!"
echo "============================="

if [ $DEPLOYMENT_STATUS -eq 0 ]; then
    echo "✅ AGX0 Primary AI Processing Node successfully deployed"
    echo ""
    echo "🔗 Service Endpoints:"
    echo "  🤖 Main Ollama API: http://$TARGET_HOST:11434/api/tags"
    echo "  🔬 Jupyter AI Lab: http://$TARGET_HOST:8888 (token: ollama-cluster)"
    echo "  🎛️ Model Manager UI: http://$TARGET_HOST:3001"
    echo "  📈 Prometheus Metrics: http://$TARGET_HOST:9090"
    echo "  🌐 AI API Gateway: http://$TARGET_HOST:8080"
    echo ""
    echo "🛠️ Management:"
    echo "  ssh -i $SSH_KEY mconners@$TARGET_HOST"
    echo "  ./health-check-AGX0.sh AGX0"
    echo "  ./manage-services-AGX0.sh AGX0 status"
    echo ""
    echo "💡 Next Steps:"
    echo "  1. Wait a few minutes for services to fully start"
    echo "  2. Test Ollama API: curl http://$TARGET_HOST:11434/api/tags"
    echo "  3. Access Jupyter Lab for AI development"
    echo "  4. Use Model Manager to download AI models"
else
    echo "❌ AGX0 deployment failed"
    echo "Please check the error messages above and try again"
fi
