# Distributed AI Cluster System

A sophisticated multi-node AI inference cluster built on NVIDIA Jetson hardware, providing scalable access to large language models through a unified web interface.

## 🏗️ Architecture Overview

- **7-node distributed cluster** with 134GB+ of AI models
- **Primary Node (AGX0)**: Main model storage and inference
- **Secondary Node (ORIN0)**: Load balancing and web services  
- **Gateway Node (PI51)**: Network management and monitoring
- **Open WebUI**: Unified chat interface for all models
- **Automated failover** and recovery systems

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd ollama_agents

# Initialize the cluster
./cluster status
./cluster start

# Access the web interface
open http://192.168.1.157:8080
```

## 📋 System Requirements

- **Hardware**: NVIDIA Jetson AGX Orin, Jetson Orin NX, Raspberry Pi
- **Software**: Docker, Docker Compose, SSH, Python 3.8+
- **Network**: Static IP configuration, SSH key authentication
- **Storage**: 500GB+ for model storage (NFS shared)

## 🔧 Available Commands

### Cluster Management
```bash
./cluster status          # Check all nodes
./cluster start           # Start all services
./cluster stop            # Stop all services  
./cluster restart         # Restart cluster
./cluster models          # List available models
```

### Model Management
```bash
./manage-models.sh list                    # List all models
./manage-models.sh quick-start            # Load essential models
./manage-models.sh load <model-name>      # Load specific model
```

### System Recovery
```bash
./recovery.sh             # Post-reboot recovery
./test_cluster.py         # Health checks
```

## 🤖 Available AI Models

### Coding & Development
- **codellama:34b** (17.7GB) - Advanced code generation
- **qwen2.5-coder:32b** (18.5GB) - Multi-language coding
- **devstral:24b** (13.3GB) - Development-focused

### General Purpose
- **gemma2:27b** (14.6GB) - Google's latest model
- **mistral-small3.2** (14.1GB) - Efficient reasoning
- **llama3:8b** (4.3GB) - Meta's flagship model

### Specialized
- **qwen2.5vl:3b** (3.0GB) - Vision-language model
- **phi3:mini** (2.0GB) - Lightweight and fast

## 🌐 Web Interfaces

- **Open WebUI**: http://192.168.1.157:8080 - Main chat interface
- **Code Server**: http://192.168.1.157:8081 - Development environment
- **System Monitor**: http://192.168.1.157:3000 - Cluster metrics

## 📁 Project Structure

```
ollama_agents/
├── cluster                 # Main cluster management script
├── deployment/             # Docker orchestration files
│   ├── docker-compose-*.yml
│   └── deploy_system.sh
├── modules/                # Core system modules
│   └── openwrt_web.py
├── utils/                  # Utility functions
│   └── network_utils.py
├── config/                 # Configuration files
├── docs/                   # Documentation
├── tests/                  # Test scripts
└── scripts/               # Management scripts
    ├── manage-models.sh
    ├── recovery.sh
    └── setup_ssh_keys.sh
```

## 🔐 Security Features

- **SSH key-based authentication** (no passwords)
- **Network isolation** with firewall rules
- **Encrypted communications** between nodes
- **Access logging** and monitoring
- **Automated security updates**

## 🚨 Troubleshooting

### Common Issues

1. **Models not loading**:
   ```bash
   ./cluster restart
   ./manage-models.sh quick-start
   ```

2. **Network connectivity issues**:
   ```bash
   ./test_ssh_connectivity.sh
   ./recovery.sh
   ```

3. **Web UI not accessible**:
   ```bash
   docker ps | grep open-webui
   docker logs open-webui-cluster
   ```

### Recovery Procedures

- **Router restart**: `./recovery.sh` handles automatic recovery
- **Node failures**: Individual node restart via cluster script
- **Model corruption**: Re-download via manage-models script

## 📊 Performance Metrics

- **Inference Speed**: 20-50 tokens/second (model dependent)
- **Concurrent Users**: Up to 4 simultaneous sessions
- **Model Switching**: < 30 seconds load time
- **Uptime**: 99.5%+ with automated recovery

## 🛠️ Development

### Adding New Models
```bash
# On primary node (AGX0)
ollama pull <model-name>
./manage-models.sh refresh
```

### Expanding the Cluster
1. Configure new node with SSH keys
2. Update `cluster` script with new IP
3. Deploy services via docker-compose
4. Test connectivity and failover

## 📚 Documentation

- [System Architecture](docs/distributed_ai_architecture.md)
- [Network Topology](NETWORK_TOPOLOGY.md)
- [Deployment Guide](deployment/README.md)
- [SSH Security](SSH_SECURITY_GUIDE.md)
- [OpenWRT Configuration](OPENWRT_STATIC_IP_GUIDE.md)

## 🤝 Contributing

This is a private repository for a production AI cluster system. Please coordinate changes through proper testing procedures.

## 📄 License

Private - All rights reserved

## 🆘 Support

For system issues:
1. Check `./cluster status`
2. Review logs in `/var/log/`
3. Run recovery procedures
4. Contact system administrator

---

**System Status**: ✅ Operational  
**Last Updated**: August 24, 2025  
**Version**: 2.1.0
