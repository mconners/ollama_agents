#!/bin/bash
# Docker Stack Manager for Distributed AI System
# Centralized management of all containerized services

set -e

# Configuration
STACK_NAME="distributed-ai"
NODES=(
    "192.168.1.147:pi51:gateway"
    "192.168.1.157:orin0:secondary" 
    "192.168.1.247:pi52:backend"
)

SSH_USER="$USER"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Execute command on node
exec_on_node() {
    local ip=$1
    local cmd=$2
    ssh "$SSH_USER@$ip" "$cmd"
}

# Get service status
get_service_status() {
    local ip=$1
    local hostname=$2
    local service_dir=$3
    
    echo "  $hostname ($ip):"
    
    # Get container status
    containers=$(exec_on_node "$ip" "cd ~/$service_dir 2>/dev/null && docker-compose ps -q 2>/dev/null | wc -l" || echo "0")
    running=$(exec_on_node "$ip" "cd ~/$service_dir 2>/dev/null && docker-compose ps | grep -c 'Up' 2>/dev/null" || echo "0")
    
    echo "    Containers: $running/$containers running"
    
    # Get resource usage
    cpu=$(exec_on_node "$ip" "docker stats --no-stream --format 'table {{.CPUPerc}}' 2>/dev/null | tail -n +2 | head -1" || echo "N/A")
    memory=$(exec_on_node "$ip" "docker stats --no-stream --format 'table {{.MemUsage}}' 2>/dev/null | tail -n +2 | head -1" || echo "N/A")
    
    echo "    CPU: $cpu, Memory: $memory"
    echo
}

# Show stack status
show_status() {
    log "📊 Distributed AI Stack Status"
    echo "======================================"
    
    get_service_status "192.168.1.147" "pi51" "api-gateway"
    get_service_status "192.168.1.157" "orin0" "ai-services" 
    get_service_status "192.168.1.247" "pi52" "backend-services"
    
    echo "🌐 Service Endpoints:"
    echo "  - Main Gateway: http://192.168.1.147"
    echo "  - Image Gen: http://192.168.1.157/comfy/"
    echo "  - Database: http://192.168.1.247:8080"
    echo "  - Monitoring: http://192.168.1.147:3000"
}

# Start all services
start_stack() {
    log "🚀 Starting distributed AI stack..."
    
    # Start backend services first
    log "📦 Starting backend services (PI52)..."
    exec_on_node "192.168.1.247" "cd ~/backend-services && docker-compose up -d"
    sleep 10
    
    # Start AI services
    log "🖼️ Starting AI services (ORIN0)..."
    exec_on_node "192.168.1.157" "cd ~/ai-services && docker-compose up -d"
    sleep 10
    
    # Start gateway last
    log "🌐 Starting API gateway (PI51)..."
    exec_on_node "192.168.1.147" "cd ~/api-gateway && docker-compose up -d"
    sleep 5
    
    success "✅ Stack startup complete!"
}

# Stop all services
stop_stack() {
    log "🛑 Stopping distributed AI stack..."
    
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        log "Stopping $hostname services..."
        
        case $hostname in
            "pi51")
                exec_on_node "$ip" "cd ~/api-gateway && docker-compose down" || true
                ;;
            "orin0") 
                exec_on_node "$ip" "cd ~/ai-services && docker-compose down" || true
                ;;
            "pi52")
                exec_on_node "$ip" "cd ~/backend-services && docker-compose down" || true
                ;;
        esac
    done
    
    success "✅ Stack stopped"
}

# Restart all services
restart_stack() {
    log "🔄 Restarting distributed AI stack..."
    stop_stack
    sleep 5
    start_stack
}

# Show logs from all services
show_logs() {
    local service=${1:-""}
    local follow=${2:-""}
    
    log "📋 Showing logs for distributed AI stack..."
    
    if [ -n "$service" ]; then
        log "Filtering for service: $service"
    fi
    
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        
        echo "=== $hostname ($role) ==="
        
        case $hostname in
            "pi51")
                exec_on_node "$ip" "cd ~/api-gateway && docker-compose logs ${follow} ${service}" | head -20
                ;;
            "orin0")
                exec_on_node "$ip" "cd ~/ai-services && docker-compose logs ${follow} ${service}" | head -20
                ;;  
            "pi52")
                exec_on_node "$ip" "cd ~/backend-services && docker-compose logs ${follow} ${service}" | head -20
                ;;
        esac
        echo
    done
}

# Run health checks
health_check() {
    log "🔍 Running health checks..."
    
    echo "API Gateway Health:"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.147/health | grep -q "200" && echo "✅ Gateway: Healthy" || echo "❌ Gateway: Down"
    
    echo "Primary Ollama:"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.154:11434/api/tags | grep -q "200" && echo "✅ AGX0: Healthy" || echo "❌ AGX0: Down"
    
    echo "Secondary Ollama:"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.157:11435/api/tags | grep -q "200" && echo "✅ ORIN0 Ollama: Healthy" || echo "❌ ORIN0 Ollama: Down"
    
    echo "ComfyUI:"
    curl -s -o /dev/null -w "%{http_code}" http://192.168.1.157:7860/ | grep -q "200" && echo "✅ ComfyUI: Healthy" || echo "❌ ComfyUI: Down"
    
    echo "Database:"
    exec_on_node "192.168.1.247" "cd ~/backend-services && docker-compose exec -T postgres pg_isready -U ai_user -d ai_gateway" > /dev/null 2>&1 && echo "✅ PostgreSQL: Healthy" || echo "❌ PostgreSQL: Down"
    
    echo "Redis Cache:"
    exec_on_node "192.168.1.247" "cd ~/backend-services && docker-compose exec -T redis redis-cli -a redis_secure_2024 ping" | grep -q "PONG" && echo "✅ Redis: Healthy" || echo "❌ Redis: Down"
}

# Update services
update_stack() {
    log "🔄 Updating distributed AI stack..."
    
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        log "Updating $hostname images..."
        
        case $hostname in
            "pi51")
                exec_on_node "$ip" "cd ~/api-gateway && docker-compose pull && docker-compose up -d"
                ;;
            "orin0")
                exec_on_node "$ip" "cd ~/ai-services && docker-compose pull && docker-compose up -d" 
                ;;
            "pi52")
                exec_on_node "$ip" "cd ~/backend-services && docker-compose pull && docker-compose up -d"
                ;;
        esac
    done
    
    success "✅ Stack updated"
}

# Backup data
backup_stack() {
    log "💾 Creating stack backup..."
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="backup_${timestamp}"
    
    mkdir -p "$backup_dir"
    
    # Database backup
    log "Backing up database..."
    exec_on_node "192.168.1.247" "cd ~/backend-services && docker-compose exec -T postgres pg_dump -U ai_user ai_gateway" > "$backup_dir/database.sql"
    
    # MinIO data backup (metadata only)
    log "Backing up MinIO metadata..."
    exec_on_node "192.168.1.247" "cd ~/backend-services && tar -czf - minio/config" > "$backup_dir/minio_config.tar.gz"
    
    # Configuration backups
    for node in "${NODES[@]}"; do
        IFS=':' read -r ip hostname role <<< "$node"
        log "Backing up $hostname configuration..."
        
        case $hostname in
            "pi51")
                exec_on_node "$ip" "cd ~/api-gateway && tar -czf - config monitoring" > "$backup_dir/${hostname}_config.tar.gz"
                ;;
            "orin0")
                exec_on_node "$ip" "cd ~/ai-services && tar -czf - config nginx.conf" > "$backup_dir/${hostname}_config.tar.gz"
                ;;
            "pi52") 
                exec_on_node "$ip" "cd ~/backend-services && tar -czf - postgres/init" > "$backup_dir/${hostname}_config.tar.gz"
                ;;
        esac
    done
    
    success "✅ Backup created in $backup_dir/"
}

# Show usage
show_usage() {
    echo "Docker Stack Manager for Distributed AI System"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  status              - Show stack status and resource usage"
    echo "  start               - Start all services in correct order"
    echo "  stop                - Stop all services"
    echo "  restart             - Restart all services"  
    echo "  health              - Run health checks on all services"
    echo "  update              - Pull latest images and update services"
    echo "  backup              - Create backup of data and configurations"
    echo "  logs [service]      - Show logs (optionally for specific service)"
    echo "  logs-f [service]    - Follow logs (optionally for specific service)"
    echo
    echo "Examples:"
    echo "  $0 status           # Show current status"
    echo "  $0 start            # Start the entire stack"
    echo "  $0 logs nginx       # Show nginx logs from all nodes"
    echo "  $0 logs-f kong      # Follow kong logs"
    echo "  $0 health           # Check all service health"
}

# Main execution
case "${1:-status}" in
    "status"|"st")
        show_status
        ;;
    "start")
        start_stack
        ;;
    "stop") 
        stop_stack
        ;;
    "restart"|"rs")
        restart_stack
        ;;
    "health"|"check")
        health_check
        ;;
    "update"|"up")
        update_stack
        ;;
    "backup"|"bk")
        backup_stack
        ;;
    "logs")
        show_logs "$2" ""
        ;;
    "logs-f"|"follow")
        show_logs "$2" "-f"
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
