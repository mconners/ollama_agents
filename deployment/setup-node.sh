#!/bin/bash

# Ollama Cluster Node Setup Script with Persistent Storage
# Creates directory structure and deploys Docker services with host-mounted volumes

NODE_NAME=${1:-"unknown"}
COMPOSE_FILE=${2:-"docker-compose.yml"}

echo "🚀 Setting up Ollama Cluster Node: $NODE_NAME"
echo "📁 Creating persistent data directories..."

# Create directory structure for persistent storage
mkdir -p data/{ollama,ollama-primary,ollama-secondary}
mkdir -p data/{ollama/models,ollama-primary/models,ollama-secondary/models}
mkdir -p data/{postgres,redis,prometheus}
mkdir -p data/{jupyter,codeserver-config,codeserver-workspace}
mkdir -p data/logs
mkdir -p config

# Check if ~/ollama exists, if not create it
if [ ! -d "$HOME/ollama" ]; then
    echo "📦 Creating Ollama models directory at ~/ollama"
    mkdir -p ~/ollama
else
    echo "✅ Found existing Ollama models at ~/ollama"
fi

echo "✅ Directory structure created:"
echo "📂 data/"
echo "├── ollama/                 # Ollama config and cache"
echo "├── ollama-primary/         # Gateway node Ollama config"
echo "├── ollama-secondary/       # Secondary node Ollama config"
echo "├── postgres/               # PostgreSQL database"
echo "├── redis/                  # Redis cache"
echo "├── prometheus/             # Monitoring data"
echo "├── jupyter/                # Jupyter notebooks"
echo "├── codeserver-config/      # VS Code server config"
echo "├── codeserver-workspace/   # VS Code workspace"
echo "└── logs/                   # Application logs"
echo "📂 ~/ollama/                # Shared Ollama models (existing)"
echo "📂 config/                  # Configuration files"

# Set proper permissions
echo "🔐 Setting permissions..."
chmod -R 755 data/
chmod -R 755 config/
# Ensure ~/ollama is accessible
chmod -R 755 ~/ollama/ 2>/dev/null || true

# Create initial config files if they don't exist
if [ ! -f "config/ollama.env" ]; then
    echo "📝 Creating Ollama environment config..."
    cat > config/ollama.env << EOF
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*
OLLAMA_DEBUG=false
OLLAMA_MODELS=/models
EOF
fi

# Create a health check script
echo "📊 Creating health check script..."
cat > health-check-$NODE_NAME.sh << 'EOF'
#!/bin/bash

NODE_NAME="$1"
echo "🏥 Health Check for $NODE_NAME Node"
echo "=================================="

# Check Docker services
echo ""
echo "📋 Docker Services Status:"
docker compose ps

echo ""
echo "💾 Storage Usage:"
df -h ./data 2>/dev/null || echo "Data directory not found"

echo ""
echo "🔍 Service Endpoints:"
if docker compose ps | grep -q "ollama"; then
    OLLAMA_PORT=$(docker compose ps | grep ollama | grep -o '0.0.0.0:[0-9]*' | head -1 | cut -d: -f2)
    if [ ! -z "$OLLAMA_PORT" ]; then
        echo "🤖 Ollama API: http://localhost:$OLLAMA_PORT/api/tags"
        curl -s http://localhost:$OLLAMA_PORT/api/tags > /dev/null && echo "  ✅ Ollama API responding" || echo "  ❌ Ollama API not responding"
    fi
fi

if docker compose ps | grep -q "traefik"; then
    echo "🌐 Traefik Dashboard: http://localhost:8080"
    curl -s http://localhost:8080 > /dev/null && echo "  ✅ Traefik responding" || echo "  ❌ Traefik not responding"
fi

if docker compose ps | grep -q "code-server"; then
    echo "💻 Code Server: http://localhost:8080"
    curl -s http://localhost:8080 > /dev/null && echo "  ✅ Code Server responding" || echo "  ❌ Code Server not responding"
fi

echo ""
echo "📈 Resource Usage:"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"

if command -v nvidia-smi >/dev/null 2>&1; then
    echo ""
    echo "🎮 GPU Status:"
    nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | while read line; do
        echo "  $line"
    done
fi
EOF

chmod +x health-check-$NODE_NAME.sh

# Create management script
echo "🛠️ Creating management script..."
cat > manage-services-$NODE_NAME.sh << 'EOF'
#!/bin/bash

COMPOSE_FILE=${COMPOSE_FILE:-"docker-compose.yml"}
NODE_NAME="$1"

case "$2" in
    "start")
        echo "🚀 Starting $NODE_NAME services..."
        docker compose -f $COMPOSE_FILE up -d
        echo "✅ Services started"
        ;;
    "stop")
        echo "🛑 Stopping $NODE_NAME services..."
        docker compose -f $COMPOSE_FILE down
        echo "✅ Services stopped"
        ;;
    "restart")
        echo "🔄 Restarting $NODE_NAME services..."
        docker compose -f $COMPOSE_FILE down
        docker compose -f $COMPOSE_FILE up -d
        echo "✅ Services restarted"
        ;;
    "status")
        echo "📊 $NODE_NAME Service Status:"
        docker compose -f $COMPOSE_FILE ps
        ;;
    "logs")
        SERVICE=$3
        if [ -z "$SERVICE" ]; then
            docker compose -f $COMPOSE_FILE logs -f
        else
            docker compose -f $COMPOSE_FILE logs -f $SERVICE
        fi
        ;;
    "clean")
        echo "🧹 Cleaning up $NODE_NAME (keeping data)..."
        docker compose -f $COMPOSE_FILE down
        docker system prune -f
        echo "✅ Cleanup complete"
        ;;
    "backup")
        BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
        echo "💾 Creating backup in $BACKUP_DIR..."
        mkdir -p $BACKUP_DIR
        cp -r data/ $BACKUP_DIR/
        cp -r models/ $BACKUP_DIR/ 2>/dev/null || true
        cp *.yml $BACKUP_DIR/ 2>/dev/null || true
        tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR/
        rm -rf $BACKUP_DIR/
        echo "✅ Backup created: $BACKUP_DIR.tar.gz"
        ;;
    *)
        echo "Usage: $0 $NODE_NAME {start|stop|restart|status|logs [service]|clean|backup}"
        echo ""
        echo "Commands:"
        echo "  start     - Start all services"
        echo "  stop      - Stop all services"
        echo "  restart   - Restart all services"
        echo "  status    - Show service status"
        echo "  logs      - Show logs (optionally for specific service)"
        echo "  clean     - Stop services and clean Docker (keeps data)"
        echo "  backup    - Create backup of all data and configs"
        exit 1
        ;;
esac
EOF

chmod +x manage-services-$NODE_NAME.sh

# Deploy services if compose file exists
if [ -f "$COMPOSE_FILE" ]; then
    echo ""
    echo "🐳 Deploying services with Docker Compose..."
    docker compose -f $COMPOSE_FILE up -d
    
    echo ""
    echo "⏳ Waiting for services to start..."
    sleep 10
    
    echo ""
    echo "📋 Service Status:"
    docker compose -f $COMPOSE_FILE ps
    
    echo ""
    echo "✅ $NODE_NAME deployment complete!"
    echo ""
    echo "📁 Persistent Data Locations:"
    echo "  - Ollama Models: $HOME/ollama/"
    echo "  - Ollama Config: $(pwd)/data/ollama/"
    echo "  - Config: $(pwd)/config/"
    echo "  - Logs: $(pwd)/data/logs/"
    echo ""
    echo "🛠️ Management Commands:"
    echo "  - Health Check: ./health-check-$NODE_NAME.sh $NODE_NAME"
    echo "  - Manage Services: ./manage-services-$NODE_NAME.sh $NODE_NAME {start|stop|status|logs}"
    echo "  - Backup Data: ./manage-services-$NODE_NAME.sh $NODE_NAME backup"
else
    echo ""
    echo "⚠️  Docker Compose file '$COMPOSE_FILE' not found"
    echo "📁 Directory structure created - copy your compose file and run:"
    echo "   docker compose up -d"
fi

echo ""
echo "🎉 Setup complete for $NODE_NAME!"
