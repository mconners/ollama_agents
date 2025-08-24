#!/bin/bash
# Deployment script for ORIN0 - Image Generation & Code Analysis Node
# Target: 192.168.1.157 (orin0)

set -e

echo "🚀 Setting up ORIN0 as Image Generation & Code Analysis Node..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directories
mkdir -p ~/ai-services/{comfyui,models,output,config}
mkdir -p ~/code-analysis/{sonarqube,data}

# Setup ComfyUI for Image Generation with containerized Nginx
cat > ~/ai-services/docker-compose.yml << 'EOF'
version: '3.8'

networks:
  ai-network:
    driver: bridge

services:
  # Nginx reverse proxy for ORIN0 services
  nginx:
    image: nginx:alpine
    container_name: orin0-nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - comfyui
      - ollama-secondary
      - sonarqube
      - jupyterhub
    networks:
      - ai-network
    restart: unless-stopped

  # ComfyUI for Image Generation
  comfyui:
    image: yanwk/comfyui-boot:cu121
    container_name: comfyui
    ports:
      - "7860:8188"
    volumes:
      - ./models:/opt/ComfyUI/models
      - ./output:/opt/ComfyUI/output
      - ./config:/opt/ComfyUI/config
    environment:
      - CLI_ARGS=--listen 0.0.0.0 --port 8188
    networks:
      - ai-network
    restart: unless-stopped
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  # Ollama as secondary inference engine  
  ollama-secondary:
    image: ollama/ollama:latest
    container_name: ollama-secondary
    ports:
      - "11435:11434"
    volumes:
      - ./ollama-data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    networks:
      - ai-network
    restart: unless-stopped
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1  
              capabilities: [gpu]

  # Code analysis with SonarQube
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:h2:mem:sonarqube
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube-data:/opt/sonarqube/data
      - sonarqube-logs:/opt/sonarqube/logs
      - sonarqube-extensions:/opt/sonarqube/extensions
    networks:
      - ai-network
    restart: unless-stopped

  # Jupyter Hub for development
  jupyterhub:
    image: jupyterhub/jupyterhub:latest
    container_name: jupyterhub
    ports:
      - "8000:8000"
    volumes:
      - ./jupyter-config:/srv/jupyterhub
      - ./jupyter-notebooks:/home
    networks:
      - ai-network
    restart: unless-stopped

volumes:
  sonarqube-data:
  sonarqube-logs:
  sonarqube-extensions:
EOF

# Download essential Stable Diffusion models
echo "📥 Downloading Stable Diffusion models..."
cd ~/ai-services/models

# Create model directories
mkdir -p checkpoints vae controlnet loras embeddings

# Download SDXL base model (if not exists)
if [ ! -f "checkpoints/sd_xl_base_1.0.safetensors" ]; then
    echo "Downloading SDXL Base model..."
    wget -O checkpoints/sd_xl_base_1.0.safetensors \
        "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
fi

# Create system cleanup script
cat > ~/ai-services/cleanup.sh << 'EOF'
#!/bin/bash
# Complete cleanup of ORIN0 containerized services

echo "🧹 Cleaning up ORIN0 containerized services..."

cd ~/ai-services

# Stop and remove all containers with data
docker-compose down -v

# Remove all images used by services
docker-compose down --rmi all

# Remove any dangling images and containers  
docker system prune -af

# Remove service directories (keep models)
rm -rf config logs jupyter-config

# Remove systemd service if exists
sudo systemctl disable orin0-ai-services.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/orin0-ai-services.service
sudo systemctl daemon-reload

echo "✅ Cleanup complete! Models preserved, everything else removed."
echo "💡 To completely remove models too: rm -rf ~/ai-services/models"
EOF

chmod +x ~/ai-services/cleanup.sh

# Install secondary Ollama models (smaller ones for this node)
echo "🤖 Setting up secondary Ollama instance..."
cd ~/ai-services
docker-compose up -d ollama-secondary

# Wait for Ollama to start
sleep 30

# Pull smaller models for secondary inference
docker exec ollama-secondary ollama pull phi3:mini
docker exec ollama-secondary ollama pull llama3.2:1b
docker exec ollama-secondary ollama pull codellama:7b

# Remove native Nginx installation and use containerized reverse proxy
cat > ~/ai-services/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream comfyui {
        server comfyui:8188;
    }
    
    upstream ollama-secondary {
        server ollama-secondary:11434;
    }
    
    upstream sonarqube {
        server sonarqube:9000;
    }
    
    upstream jupyterhub {
        server jupyterhub:8000;
    }

    server {
        listen 80;
        server_name orin0.local 192.168.1.157;

        # ComfyUI Image Generation
        location /comfy/ {
            proxy_pass http://comfyui/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Secondary Ollama API
        location /ollama/ {
            proxy_pass http://ollama-secondary/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # SonarQube Code Analysis
        location /sonar/ {
            proxy_pass http://sonarqube/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # JupyterHub
        location /jupyter/ {
            proxy_pass http://jupyterhub/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

        # Health check
        location /health {
            return 200 "ORIN0 services healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Create health check script
cat > ~/ai-services/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for ORIN0 services

echo "🔍 ORIN0 Health Check - $(date)"
echo "=================================="

# Check Docker services
echo "Docker Services Status:"
docker-compose ps

echo -e "\n🖼️ ComfyUI Status:"
curl -s http://localhost:7860/ > /dev/null && echo "✅ ComfyUI: Running" || echo "❌ ComfyUI: Down"

echo -e "\n🤖 Secondary Ollama Status:" 
curl -s http://localhost:11435/api/tags > /dev/null && echo "✅ Ollama: Running" || echo "❌ Ollama: Down"

echo -e "\n📊 SonarQube Status:"
curl -s http://localhost:9000/ > /dev/null && echo "✅ SonarQube: Running" || echo "❌ SonarQube: Down"

echo -e "\n🐍 JupyterHub Status:"
curl -s http://localhost:8000/ > /dev/null && echo "✅ JupyterHub: Running" || echo "❌ JupyterHub: Down"

echo -e "\n🌐 Nginx Status:"
docker-compose exec nginx nginx -t > /dev/null 2>&1 && echo "✅ Nginx: Running" || echo "❌ Nginx: Down"

echo -e "\n💾 GPU Memory Usage:"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits

echo -e "\n🔥 System Load:"
uptime
EOF

chmod +x ~/ai-services/health-check.sh

# Start all services
cd ~/ai-services
docker-compose up -d

echo ""
echo "🎉 ORIN0 containerized setup complete!"
echo ""
echo "🌐 Access Points:"
echo "  - ComfyUI: http://192.168.1.157/comfy/"
echo "  - Secondary Ollama: http://192.168.1.157:11435"
echo "  - SonarQube: http://192.168.1.157/sonar/"
echo "  - JupyterHub: http://192.168.1.157/jupyter/"
echo ""
echo "🔍 Management:"
echo "  - Health Check: ~/ai-services/health-check.sh"
echo "  - Container Logs: docker-compose logs -f [service]"
echo "  - Cleanup All: ~/ai-services/cleanup.sh"
echo ""
echo "🐳 Container Management:"
echo "  - Start: docker-compose up -d"
echo "  - Stop: docker-compose down"
echo "  - Restart: docker-compose restart [service]"
echo ""
echo "⚠️  Note: All services are now containerized"
echo "    GPU access requires nvidia-container-toolkit to be installed"
