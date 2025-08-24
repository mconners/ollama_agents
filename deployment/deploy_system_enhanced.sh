#!/bin/bash

# Enhanced deployment script that handles sudo password requirements
# Uses the router config to provide passwords when needed

set -e

# Load router config for password
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/router_config.json"

if [[ -f "$CONFIG_FILE" ]]; then
    # Extract password from config (assuming same password for cluster nodes)
    CLUSTER_PASSWORD=$(grep '"router_password"' "$CONFIG_FILE" | sed 's/.*"router_password":\s*"\([^"]*\)".*/\1/')
    echo "🔑 Using password from router config for sudo operations"
else
    echo "⚠️  Router config not found, will prompt for passwords"
    CLUSTER_PASSWORD=""
fi

# Configuration - Updated with current IPs
NODES=(
    "192.168.1.147:pi51:gateway"     # API Gateway & Load Balancer  
    "192.168.1.154:agx0:primary"     # Primary AI Hub (already running)
    "192.168.1.157:orin0:secondary"  # Image Gen & Code Analysis
    "192.168.1.247:pi52:backend"     # Backend Services
    "192.168.1.204:pi41:monitoring"  # Monitoring (future)
    "192.168.1.159:nano:edge"        # Edge Inference (future)
    "192.168.1.234:pi31:utility"     # Utility Services (future)
)

SSH_KEY="~/.ssh/ollama_cluster_key"
SSH_USER="mconners"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "🚀 Enhanced Distributed AI System Deployment"
echo "============================================="

# Check SSH connectivity with current IPs
check_connectivity() {
    log "🔍 Checking connectivity to all nodes with current IPs..."
    
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        echo -n "  Checking $hostname ($ip)... "
        
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY" "$SSH_USER@$ip" exit 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
        else
            echo -e "${RED}❌${NC}"
            error "Cannot connect to $hostname ($ip)"
            warning "SSH key authentication failed"
        fi
    done
    echo
}

# Enhanced deployment function with sudo password handling
deploy_node() {
    local ip=$1
    local hostname=$2
    local role=$3
    local script_name="setup_${hostname}.sh"
    
    log "🚀 Deploying $role services to $hostname ($ip)..."
    
    if [ ! -f "$script_name" ]; then
        error "Deployment script $script_name not found!"
        return 1
    fi
    
    log "📤 Copying deployment script to $hostname..."
    if ! scp -i "$SSH_KEY" "$script_name" "$SSH_USER@$ip:~/" 2>/dev/null; then
        error "Failed to copy deployment script to $hostname"
        return 1
    fi
    
    log "⚡ Running deployment on $hostname..."
    
    # Run deployment with password handling for sudo
    if [[ -n "$CLUSTER_PASSWORD" ]]; then
        # Use expect to handle sudo password prompts
        expect << EOF
spawn ssh -i "$SSH_KEY" "$SSH_USER@$ip" "echo '$CLUSTER_PASSWORD' | sudo -S chmod +x ~/$script_name && echo '$CLUSTER_PASSWORD' | sudo -S ~/$script_name"
expect {
    "password:" { send "$CLUSTER_PASSWORD\r"; exp_continue }
    eof
}
EOF
    else
        # Fallback to interactive mode
        ssh -i "$SSH_KEY" "$SSH_USER@$ip" "chmod +x ~/$script_name && ~/$script_name"
    fi
    
    if [ $? -eq 0 ]; then
        success "✅ Deployment completed on $hostname"
    else
        error "Deployment failed on $hostname"
        return 1
    fi
}

# Test connectivity first
check_connectivity

# Ask for confirmation
warning "⚠️  This will deploy the distributed AI system across multiple nodes:"
echo
for node in "${NODES[@]}"; do
    IFS=':' read -r ip hostname role <<< "$node"
    echo "  • $hostname ($ip) - $role"
done
echo
echo "Make sure all nodes are accessible via SSH."
echo
read -p "Continue with deployment? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Start phased deployment
log "🎯 Starting phased deployment..."

# Phase 1: Backend Services (PI52)
log "📦 Phase 1: Deploying Backend Services..."
deploy_node "192.168.1.247" "pi52" "backend"

# Phase 2: Image Generation & Code Analysis (ORIN0)  
log "🖼️ Phase 2: Deploying Image Generation & Code Analysis..."
deploy_node "192.168.1.157" "orin0" "image generation & code analysis"

# Phase 3: API Gateway (PI51)
log "🌐 Phase 3: Deploying API Gateway..."
deploy_node "192.168.1.147" "pi51" "gateway"

echo
success "🎉 Distributed AI System Deployment Complete!"
echo
log "🌐 System Access Points:"
echo "  • API Gateway: http://192.168.1.147:8080"
echo "  • Image Generation: http://192.168.1.157:8188"
echo "  • Backend Services: http://192.168.1.247:9000"
echo "  • Primary AI Hub: Already running on AGX0"
echo
log "🔧 Next Steps:"
echo "  1. Verify all services are running"
echo "  2. Test API endpoints"
echo "  3. Configure load balancing"
echo "  4. Set up monitoring"
