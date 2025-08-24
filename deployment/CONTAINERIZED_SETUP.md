# Containerized Distributed AI System - Quick Reference

## 🚀 Fully Containerized Architecture

All services are now containerized using Docker and Docker Compose for easy deployment and cleanup:

### Node Distribution
- **PI51** (192.168.1.147) - API Gateway + Load Balancer + Monitoring  
- **AGX0** (192.168.1.154) - Primary AI Hub (Ollama) ✅ Already Running
- **ORIN0** (192.168.1.157) - Image Generation + Code Analysis + Secondary AI
- **PI52** (192.168.1.247) - Backend Services (Database + Cache + Storage)

## 📦 Container Services Per Node

### PI51 (API Gateway)
```yaml
services:
  - nginx (reverse proxy)
  - kong (API gateway) 
  - redis (rate limiting)
  - prometheus (metrics)
  - grafana (visualization)
```

### ORIN0 (AI Services)  
```yaml
services:
  - nginx (local proxy)
  - comfyui (image generation)
  - ollama-secondary (backup AI)
  - sonarqube (code analysis)
  - jupyterhub (development)
```

### PI52 (Backend)
```yaml  
services:
  - postgres (main database)
  - redis (session cache)
  - minio (file storage)
  - pgadmin (DB management)
  - redis-commander (cache management)
  - backup-service (automated backups)
```

## 🔧 Deployment Commands

### Quick Deploy Everything
```bash
cd /home/mconners/ollama_agents/deployment
./deploy_system.sh
```

### Individual Node Setup
```bash
# API Gateway (PI51)
./setup_pi51.sh

# AI Services (ORIN0) 
./setup_orin0.sh

# Backend Services (PI52)
./setup_pi52.sh
```

### Stack Management
```bash
# Centralized management
./stack_manager.sh status     # Check all services
./stack_manager.sh start      # Start everything
./stack_manager.sh stop       # Stop everything
./stack_manager.sh health     # Health checks
./stack_manager.sh logs       # View logs
```

## 🧹 Easy Cleanup Options

### Per-Node Cleanup
```bash
# On each node, cleanup scripts are created automatically:
ssh pi51 '~/api-gateway/cleanup.sh'      # Remove PI51 services
ssh orin0 '~/ai-services/cleanup.sh'     # Remove ORIN0 services  
ssh pi52 '~/backend-services/cleanup.sh' # Remove PI52 services (with data!)
```

### Complete System Cleanup
```bash
# Nuclear option - removes EVERYTHING
./cleanup_system.sh

# Check what's currently running first
./cleanup_system.sh status
```

### Docker Commands on Each Node
```bash
# Stop all containers
docker-compose down

# Stop and remove volumes (DATA LOSS!)
docker-compose down -v

# Remove images too
docker-compose down --rmi all

# Complete Docker cleanup
docker system prune -af --volumes
```

## 🌐 Access Points (After Deployment)

### Main Interfaces
- **AI Gateway**: http://192.168.1.147
- **Chat API**: http://192.168.1.147/api/v1/chat  
- **Code API**: http://192.168.1.147/api/v1/code
- **Image API**: http://192.168.1.147/api/v1/image

### Management Dashboards
- **Grafana Monitoring**: http://192.168.1.147:3000 (admin/admin123)
- **Kong Admin**: http://192.168.1.147:8001
- **Database Admin**: http://192.168.1.247:8080
- **MinIO Console**: http://192.168.1.247:9001
- **ComfyUI Direct**: http://192.168.1.157:7860

## 🐳 Container Benefits

### Easy Management
- **Start/Stop**: Single command across all nodes
- **Updates**: `docker-compose pull && docker-compose up -d`
- **Logs**: Centralized via `docker-compose logs`
- **Scaling**: Easy to add replicas or new nodes

### Clean Isolation  
- **No System Dependencies**: Everything runs in containers
- **Port Conflicts**: Containers handle networking
- **Clean Removal**: No leftover files or services

### Consistent Environment
- **Same Everywhere**: Identical containers across nodes
- **Version Control**: Specific image versions
- **Reproducible**: Easy to recreate exact same setup

## 📊 Resource Requirements

### Minimum Requirements
- **Docker**: 20.10+ with Compose V2
- **RAM**: 2GB per node minimum  
- **Storage**: 20GB per node for images/data
- **Network**: All nodes on same network

### GPU Support
- **NVIDIA Devices**: Requires nvidia-container-toolkit
- **Auto-Detection**: Containers automatically use GPU when available

## 🔄 Typical Workflow

1. **Deploy**: `./deploy_system.sh`
2. **Check Status**: `./stack_manager.sh status`
3. **Use Services**: Access via gateway at http://192.168.1.147
4. **Monitor**: Check Grafana dashboard
5. **Cleanup When Done**: `./cleanup_system.sh`

## 🚨 Emergency Commands

### Stop Everything Immediately
```bash
./stack_manager.sh stop
```

### Complete Nuclear Cleanup
```bash
./cleanup_system.sh  # Will ask for confirmation
```

### Check What's Running
```bash
./cleanup_system.sh status
./stack_manager.sh status  
```

The entire system is now containerized for maximum portability, easy management, and clean removal!
