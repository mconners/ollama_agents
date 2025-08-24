#!/bin/bash
# Complete system cleanup for the containerized distributed AI system
# This will remove ALL containers, volumes, networks, and images across all nodes

set -e

# Configuration
NODES=(
    "192.168.1.51:pi51:gateway"
    "192.168.1.149:orin0:secondary" 
    "192.168.1.52:pi52:backend"
    "192.168.1.41:pi41:monitoring"
)

SSH_USER="mconners"
SSH_KEY="~/.ssh/ollama_cluster_key"

# Colors for output
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

# Cleanup function for each node
cleanup_node() {
    local ip=$1
    local hostname=$2
    local role=$3
    
    log "🧹 Cleaning up $hostname ($ip) - $role services..."
    
    # Run cleanup commands on remote node
    ssh "$SSH_USER@$ip" << 'EOF'
        echo "🐳 Stopping all Docker containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
        
        echo "🗑️ Removing all containers..."  
        docker rm $(docker ps -aq) 2>/dev/null || true
        
        echo "🖼️ Removing all images..."
        docker rmi $(docker images -q) 2>/dev/null || true
        
        echo "💾 Removing all volumes..."
        docker volume rm $(docker volume ls -q) 2>/dev/null || true
        
        echo "🌐 Removing all networks..."
        docker network rm $(docker network ls --format "{{.Name}}" | grep -v -E "(bridge|host|none)") 2>/dev/null || true
        
        echo "🧽 Running system prune..."
        docker system prune -af --volumes 2>/dev/null || true
        
        echo "📁 Cleaning up service directories..."
        rm -rf ~/api-gateway ~/ai-services ~/backend-services ~/monitoring 2>/dev/null || true
        
        echo "🔄 Removing any custom systemd services..."
        sudo systemctl disable pi51-gateway.service 2>/dev/null || true
        sudo systemctl disable pi52-backend.service 2>/dev/null || true
        sudo systemctl disable orin0-ai-services.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/pi*-*.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/orin0-*.service 2>/dev/null || true
        sudo systemctl daemon-reload
        
        echo "✅ Node cleanup complete!"
EOF
    
    if [ $? -eq 0 ]; then
        success "✅ Cleanup completed on $hostname"
    else
        error "❌ Cleanup failed on $hostname"
    fi
}

# Show current system status
show_status() {
    log "📊 Current system status across all nodes..."
    
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        echo "  $hostname ($ip):"
        
        # Count containers
        container_count=$(ssh "$SSH_USER@$ip" "docker ps -q | wc -l" 2>/dev/null || echo "0")
        echo "    Containers: $container_count"
        
        # Count images  
        image_count=$(ssh "$SSH_USER@$ip" "docker images -q | wc -l" 2>/dev/null || echo "0")
        echo "    Images: $image_count"
        
        # Count volumes
        volume_count=$(ssh "$SSH_USER@$ip" "docker volume ls -q | wc -l" 2>/dev/null || echo "0") 
        echo "    Volumes: $volume_count"
        echo
    done
}

# Confirm cleanup
confirm_cleanup() {
    echo
    warning "⚠️  DESTRUCTIVE OPERATION WARNING ⚠️"
    echo
    warning "This will completely remove ALL containerized services:"
    echo "  • All Docker containers (running and stopped)"
    echo "  • All Docker images" 
    echo "  • All Docker volumes (including data!)"
    echo "  • All custom Docker networks"
    echo "  • All service configuration directories"
    echo "  • All systemd service files"
    echo
    warning "Affected nodes:"
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        echo "  • $hostname ($ip) - $role"
    done
    echo
    warning "This action CANNOT be undone!"
    echo
    read -p "Type 'DESTROY' to confirm complete cleanup: " confirm
    
    if [ "$confirm" != "DESTROY" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

# Main execution
case "${1:-cleanup}" in
    "status")
        show_status
        ;;
    "cleanup")
        show_status
        confirm_cleanup
        
        log "🚀 Starting system-wide cleanup..."
        
        for node in "${NODES[@]}"; do
            IFS=':' read -r ip hostname role <<< "$node"
            cleanup_node "$ip" "$hostname" "$role"
        done
        
        success "🎉 Complete system cleanup finished!"
        echo
        log "📋 What was removed:"
        echo "  ✅ All Docker containers"
        echo "  ✅ All Docker images" 
        echo "  ✅ All Docker volumes"
        echo "  ✅ All Docker networks"
        echo "  ✅ All service directories"
        echo "  ✅ All systemd services"
        echo
        log "🔄 To redeploy the system:"
        echo "  ./deploy_system.sh"
        ;;
    "help")
        echo "System Cleanup Tool for Containerized Distributed AI"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  cleanup    - Remove all containers, images, volumes (default)"
        echo "  status     - Show current system status"
        echo "  help       - Show this help message"
        echo
        echo "Examples:"
        echo "  $0 status     # Check what's currently deployed"
        echo "  $0 cleanup    # Complete system cleanup"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
