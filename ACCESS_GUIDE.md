# 🌐 Ollama Cluster Access Guide

## 📋 Quick Access URLs

### **PI51 Gateway (Load Balancer & Primary Access Point)**
- **🌐 Main Dashboard**: http://192.168.1.147/ 
- **🤖 Ollama API**: http://192.168.1.147:11434/
- **💻 Code Server**: http://192.168.1.147:8080/ (password: `jetsoncopilot`)
- **📊 Traefik Dashboard**: http://192.168.1.147:8080/dashboard/

### **ORIN0 Secondary Services** 
- **🤖 Ollama API**: http://192.168.1.157:11435/
- **💻 Code Server**: http://192.168.1.157:8081/ (password: `ollama-cluster-dev`)
- **🗄️ PostgreSQL**: `192.168.1.157:5433` (user: `sonar`, pass: `sonar123`, db: `sonar`)

### **AGX0 Primary (Not yet deployed)**
- **🤖 Main Ollama API**: http://192.168.1.154:11434/ (existing models)
- **🔬 Jupyter AI Lab**: http://192.168.1.154:8888/ (when deployed)
- **📈 Model Manager**: http://192.168.1.154:7860/ (when deployed)

---

## 🚀 How to Use Your AI Cluster

### **1. Chat with AI Models**

**Via Web Interface (Easiest):**
```bash
# Open in browser:
http://192.168.1.147/
```

**Via API (Programmatic):**
```bash
# Chat with models through Gateway (load balanced)
curl -X POST http://192.168.1.147:11434/api/generate \
  -d '{"model":"phi3:mini","prompt":"Hello, how are you?","stream":false}' | jq '.response'

# Direct to ORIN0 
curl -X POST http://192.168.1.157:11435/api/generate \
  -d '{"model":"phi3:mini","prompt":"Write a Python function","stream":false}' | jq '.response'

# Direct to AGX0 (all models available)
curl -X POST http://192.168.1.154:11434/api/generate \
  -d '{"model":"llama3","prompt":"Explain quantum computing","stream":false}' | jq '.response'
```

### **2. Code Development**

**PI51 Code Server:**
- URL: http://192.168.1.147:8080/
- Password: `jetsoncopilot`
- Purpose: General development, cluster management

**ORIN0 Code Server:**  
- URL: http://192.168.1.157:8081/
- Password: `ollama-cluster-dev`
- Purpose: AI development, model testing

### **3. Model Management**

**List Available Models:**
```bash
# Via Gateway (shows all accessible models)
curl http://192.168.1.147:11434/api/tags | jq '.models[].name'

# Direct nodes
curl http://192.168.1.157:11435/api/tags | jq '.models[].name'  # ORIN0
curl http://192.168.1.154:11434/api/tags | jq '.models[].name'  # AGX0
```

**Pull New Models:**
```bash
# Pull to Gateway (will distribute via load balancer)
curl -X POST http://192.168.1.147:11434/api/pull -d '{"name":"gemma2:2b"}'

# Pull to specific node
curl -X POST http://192.168.1.157:11435/api/pull -d '{"name":"codellama:7b"}'
```

---

## 🔧 SSH Access

**Connect to any node:**
```bash
# Using cluster SSH key
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.147  # PI51
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157  # ORIN0  
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.154  # AGX0
```

**Quick Commands:**
```bash
# Check all services on a node
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker ps"

# View logs
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker logs ollama-secondary"

# Restart services
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker compose -f docker-compose-shared.yml restart"
```

---

## 📊 Monitoring & Health Checks

**Service Health:**
```bash
# Check all services across cluster
./deployment/check-cluster-health.sh

# Individual health checks
curl http://192.168.1.147:11434/api/tags      # PI51 Gateway
curl http://192.168.1.157:11435/api/tags      # ORIN0 Secondary  
curl http://192.168.1.154:11434/api/tags      # AGX0 Primary
```

**Resource Usage:**
```bash
# Check GPU usage on nodes
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "nvidia-smi"
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.154 "nvidia-smi"
```

---

## 🎯 Recommended Workflow

### **For General Chat/Questions:**
1. Use **PI51 Gateway**: http://192.168.1.147/ (load balanced across cluster)

### **For Code Development:**
1. **Code editing**: http://192.168.1.157:8081/ (ORIN0 has development tools)
2. **AI assistance**: Use API calls to appropriate models
3. **Testing**: Deploy to cluster via Docker Compose

### **For Heavy AI Tasks:**
1. **Direct to AGX0**: http://192.168.1.154:11434/ (most powerful, all models)
2. **Jupyter development**: http://192.168.1.154:8888/ (when AGX0 deployed)

### **For Data/Analytics:**
1. **PostgreSQL**: Connect to `192.168.1.157:5433` 
2. **Storage**: Use shared NFS models at `/mnt/shared-models`

---

## 🔑 Passwords & Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| PI51 Code Server | :8080 | - | `jetsoncopilot` |
| ORIN0 Code Server | :8081 | - | `ollama-cluster-dev` |
| PostgreSQL | :5433 | `sonar` | `sonar123` |
| SSH Access | - | `mconners` | SSH Key |

---

## 🚨 Troubleshooting

**If services are down:**
```bash
# Restart specific node services
ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] "docker compose -f docker-compose-shared.yml up -d"

# Check what's running
ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] "docker ps"

# View service logs  
ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] "docker logs [CONTAINER_NAME]"
```

**Network issues:**
```bash
# Test connectivity
ping 192.168.1.147  # PI51
ping 192.168.1.157  # ORIN0 
ping 192.168.1.154  # AGX0
```

---

## 🎉 What's Next?

1. **Deploy AGX0 Primary** - Full AI stack with Jupyter
2. **Configure remaining nodes** - PI41, NANO, PI31
3. **Set up static IPs** - OpenWRT configuration
4. **Add monitoring** - Prometheus/Grafana dashboard
5. **Model optimization** - Fine-tuning and custom models
