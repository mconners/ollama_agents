#!/bin/bash

# Update Docker Compose files to use shared models from NFS
# This gives nodes access to AGX0's existing models while still allowing local model downloads

NODE_TYPE=${1:-"gateway"}  # gateway, secondary, primary

case $NODE_TYPE in
    "gateway")
        echo "🔄 Updating PI51 Gateway to use shared models..."
        # PI51 can read from shared models AND store its own
        cat > docker-compose-pi51-gateway-shared.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:latest
    container_name: traefik-gateway
    restart: unless-stopped
    command:
      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:8081
      - --entrypoints.websecure.address=:8443
      - --entrypoints.ollama.address=:11434
      - --log.level=INFO
    ports:
      - "8081:8081"
      - "8443:8443"
      - "8080:8080"
      - "11434:11434"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - ollama_cluster
    healthcheck:
      test: ["CMD", "traefik", "healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 3

  ollama-primary:
    image: ollama/ollama:latest
    container_name: ollama-primary
    restart: unless-stopped
    ports:
      - "11435:11434"
    volumes:
      - ./data/ollama-primary:/root/.ollama
      - ./data/ollama-primary/models:/models
      - /mnt/shared-models:/shared-models:ro  # Read-only access to AGX0 models
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
      - OLLAMA_ORIGINS=*
      - OLLAMA_MODELS=/models
    networks:
      - ollama_cluster
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ollama-primary.rule=Host(\`192.168.1.147\`) && PathPrefix(\`/api\`)"
      - "traefik.http.routers.ollama-primary.entrypoints=ollama"
      - "traefik.http.services.ollama-primary.loadbalancer.server.port=11434"
      - "traefik.http.routers.ollama-primary.priority=100"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  gateway-dashboard:
    image: nginx:alpine
    container_name: gateway-dashboard
    restart: unless-stopped
    ports:
      - "3000:80"
    volumes:
      - ./gateway-html:/usr/share/nginx/html:ro
    networks:
      - ollama_cluster
    depends_on:
      - ollama-primary

networks:
  ollama_cluster:
    driver: bridge
EOF
        echo "✅ Created docker-compose-pi51-gateway-shared.yml"
        ;;
        
    "secondary")
        echo "🔄 Updating ORIN0 Secondary to use shared models..."
        cat > docker-compose-orin0-simple-shared.yml << 'EOF'
version: '3.8'

services:
  postgres-sonar:
    image: postgres:13
    container_name: postgres-sonar
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar_password
      POSTGRES_DB: sonarqube
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar"]
      interval: 30s
      timeout: 10s
      retries: 3

  ollama-secondary:
    image: ollama/ollama:latest
    container_name: ollama-secondary
    restart: unless-stopped
    networks:
      - ai-network
    volumes:
      - ./data/ollama-secondary:/root/.ollama
      - ./data/ollama-secondary/models:/models
      - /mnt/shared-models:/shared-models:ro  # Read-only access to AGX0 models
    ports:
      - "11435:11434"
    environment:
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_MODELS=/models
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
          memory: 2G
        limits:
          memory: 4G

  code-server:
    image: codercom/code-server:latest
    container_name: code-server-orin0
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      - PASSWORD=ollama-cluster-dev
    volumes:
      - ./data/codeserver-config:/home/coder/.config
      - ./data/codeserver-workspace:/home/coder/workspace
    ports:
      - "8080:8080"
    depends_on:
      - ollama-secondary

networks:
  ai-network:
    driver: bridge
EOF
        echo "✅ Created docker-compose-orin0-simple-shared.yml"
        ;;
        
    *)
        echo "Usage: $0 {gateway|secondary|primary}"
        echo "  gateway   - Update PI51 Gateway configuration"
        echo "  secondary - Update ORIN0 Secondary configuration"
        exit 1
        ;;
esac

echo ""
echo "📋 Next Steps:"
echo "1. Run setup-nfs-server.sh on AGX0 (192.168.1.154)"
echo "2. Run setup-nfs-client.sh on other nodes"
echo "3. Use the new *-shared.yml files for deployment"
echo ""
echo "💡 Benefits of shared models:"
echo "  ✅ All nodes can access AGX0's existing models immediately"
echo "  ✅ Nodes can still download their own models locally"
echo "  ✅ Reduces storage duplication across cluster"
echo "  ✅ Faster model access for nodes with slower storage"
