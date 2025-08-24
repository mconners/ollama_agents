# Distributed AI System Architecture - Complete System Design

## 🏗️ Network Architecture Overview

Based on system interrogation of your infrastructure, here's the complete distributed AI system design:

```
                    Internet/WAN
                         │
                         ▼
              ┌─────────────────────┐
              │   Router/Gateway    │
              │   192.168.1.1       │
              │   (OpenWRT)         │
              └─────────────────────┘
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
    [External Users] [Local Network] [Management]

═══════════════════════════════════════════════════════════════

                    🌐 DISTRIBUTED AI CLUSTER
                    192.168.1.0/24 Network

┌──────────────────────────────────────────────────────────────────┐
│                        API GATEWAY TIER                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  PI51 (192.168.1.147) - Raspberry Pi 5 - 8GB RAM - 1TB    │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ Nginx Container │  │ Kong Gateway    │                  │  │
│  │  │ (Port 80/443)   │  │ (Load Balancer) │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ Redis Cache     │  │ Prometheus      │                  │  │
│  │  │ (Rate Limiting) │  │ (Metrics)       │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │                                                            │  │
│  │  Entry Point: http://192.168.1.147                        │  │
│  │  - /api/v1/chat (Chat API)                                │  │
│  │  - /api/v1/code (Code Assistant)                          │  │
│  │  - /api/v1/image (Image Generation)                       │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

                              │
                              ▼ (Load Balanced)
                              
┌──────────────────────────────────────────────────────────────────┐
│                       PRIMARY AI TIER                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  AGX0 (192.168.1.154) - Nvidia Jetson Orin AGX - 64GB    │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ Ollama Server   │  │ 18 AI Models    │                  │  │
│  │  │ (Port 11434)    │  │ - llama3.2      │                  │  │
│  │  │                 │  │ - codellama:34b │                  │  │
│  │  │ 🔥 2048 CUDA    │  │ - gpt-oss       │                  │  │
│  │  │    Cores        │  │ - mistral-small │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │                                                            │  │
│  │  Primary Services:                                         │  │
│  │  - Chat completions (80% traffic)                         │  │
│  │  - Code generation/review                                 │  │
│  │  - Complex reasoning tasks                                │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

                              │
                              ▼ (Failover & Specialized)

┌──────────────────────────────────────────────────────────────────┐
│                     SECONDARY AI TIER                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  ORIN0 (192.168.1.157) - Nvidia Jetson Orin Nano - 8GB   │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ ComfyUI         │  │ Ollama Secondary│                  │  │
│  │  │ (Stable Diffusion│  │ (Port 11435)    │                  │  │
│  │  │  Image Gen)     │  │ - phi3:mini     │                  │  │
│  │  │                 │  │ - codellama:7b  │                  │  │
│  │  │ 🔥 1024 CUDA    │  │ - llama3.2:1b   │                  │  │
│  │  │    Cores        │  └─────────────────┘                  │  │
│  │  └─────────────────┘                                       │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ SonarQube       │  │ JupyterHub      │                  │  │
│  │  │ (Code Analysis) │  │ (Development)   │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │                                                            │  │
│  │  Services:                                                 │  │
│  │  - Image generation (SDXL, ControlNet)                    │  │
│  │  - Code analysis & quality checks                         │  │
│  │  - Backup AI inference (20% traffic)                     │  │
│  │  - Development environments                               │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

                              │
                              ▼ (Data & Storage)

┌──────────────────────────────────────────────────────────────────┐
│                       BACKEND TIER                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  PI52 (192.168.1.247) - Raspberry Pi 5 - 8GB RAM - 1TB   │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ PostgreSQL      │  │ Redis Cache     │                  │  │
│  │  │ (Main Database) │  │ (Sessions)      │                  │  │
│  │  │ - Users         │  │ - API Cache     │                  │  │
│  │  │ - Conversations │  │ - Rate Limits   │                  │  │
│  │  │ - Messages      │  └─────────────────┘                  │  │
│  │  │ - Generated     │                                       │  │
│  │  │   Images        │  ┌─────────────────┐                  │  │
│  │  │ - Code Snippets │  │ MinIO Storage   │                  │  │
│  │  └─────────────────┘  │ (File Storage)  │                  │  │
│  │                       │ - Images        │                  │  │
│  │  ┌─────────────────┐  │ - Models        │                  │  │
│  │  │ PgAdmin         │  │ - Backups       │                  │  │
│  │  │ (DB Management) │  └─────────────────┘                  │  │
│  │  └─────────────────┘                                       │  │
│  │                                                            │  │
│  │  Data Services:                                            │  │
│  │  - User authentication & sessions                         │  │
│  │  - Conversation history & context                         │  │
│  │  - Generated content storage                              │  │
│  │  - Automated daily backups                                │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

                              │
                              ▼ (Monitoring & Management)

┌──────────────────────────────────────────────────────────────────┐
│                      MONITORING TIER                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  PI41 (192.168.1.204) - Raspberry Pi 4 - 2GB RAM - 1TB   │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ Grafana         │  │ Node Exporters  │                  │  │
│  │  │ (Dashboards)    │  │ (System Metrics)│                  │  │
│  │  │ Port 3000       │  │ All Nodes       │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                  │  │
│  │  │ Log Aggregation │  │ Alert Manager   │                  │  │
│  │  │ (Centralized)   │  │ (Notifications) │                  │  │
│  │  └─────────────────┘  └─────────────────┘                  │  │
│  │                                                            │  │
│  │  Monitoring Services:                                      │  │
│  │  - System resource monitoring                             │  │
│  │  - Service health checks                                  │  │
│  │  - Performance metrics & alerts                          │  │
│  │  - Centralized logging                                    │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      EDGE/UTILITY TIER                          │
│  ┌─────────────────────────┐  ┌─────────────────────────────────┐ │
│  │ NANO (192.168.1.159)    │  │ PI31 (192.168.1.234)           │ │
│  │ Jetson Nano 2GB - 116GB │  │ Raspberry Pi 3 - 1GB - 32GB    │ │
│  │ ┌─────────────────────┐ │  │ ┌─────────────────────────────┐ │ │
│  │ │ Edge Inference      │ │  │ │ Utility Services            │ │ │
│  │ │ - Lightweight models│ │  │ │ - Backup coordination       │ │ │
│  │ │ - Local caching     │ │  │ │ - Configuration management  │ │ │
│  │ │ - Offline fallback  │ │  │ │ - Network utilities         │ │ │
│  │ └─────────────────────┘ │  │ └─────────────────────────────┘ │ │
│  │                         │  │                                 │ │
│  │ 🔥 128 CUDA Cores       │  │ Services:                       │ │
│  │ Ubuntu 18.04            │  │ - System orchestration          │ │
│  │                         │  │ - Backup management             │ │
│  └─────────────────────────┘  └─────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## 📊 System Specifications Summary

| Node | Hardware | OS | RAM | Storage | GPU | Role |
|------|----------|----|----|---------|-----|------|
| **PI51** | Raspberry Pi 5 | Debian 12 | 8GB | 1TB NVMe | - | API Gateway |
| **AGX0** | Jetson Orin AGX | Ubuntu 22.04 | 64GB | 2TB NVMe | 2048 CUDA | Primary AI |
| **ORIN0** | Jetson Orin Nano | Ubuntu 22.04 | 8GB | 1TB NVMe | 1024 CUDA | Secondary AI |
| **PI52** | Raspberry Pi 5 | Debian 12 | 8GB | 1TB NVMe | - | Backend |
| **PI41** | Raspberry Pi 4 | Debian 12 | 2GB | 1TB SSD | - | Monitoring |
| **NANO** | Jetson Nano | Ubuntu 18.04 | 2GB | 116GB eMMC | 128 CUDA | Edge |
| **PI31** | Raspberry Pi 3 | Debian 12 | 1GB | 32GB SD | - | Utility |

## 🚀 Service Distribution & Data Flow

### Request Flow (High Level)
```
User Request → PI51 (Gateway) → Kong (Load Balance) → AGX0/ORIN0 (AI) → PI52 (Data) → Response
              ↓
        Rate Limiting, Auth, Monitoring
```

### Detailed Request Patterns

#### 1. Chat Requests
```
Client → PI51:80 → Kong:8000 → AGX0:11434 (Ollama) → Response
                              ↘ ORIN0:11435 (Backup)
```

#### 2. Image Generation  
```
Client → PI51:80 → Kong:8000 → ORIN0:7860 (ComfyUI) → PI52:9000 (MinIO Storage)
```

#### 3. Code Analysis
```
Client → PI51:80 → Kong:8000 → AGX0:11434 (CodeLlama) → ORIN0:9000 (SonarQube)
```

#### 4. Data Persistence
```
All Services → PI52:5432 (PostgreSQL) ↔ PI52:6379 (Redis Cache)
```

## 🛠️ Container Architecture

### All Services Containerized with Docker Compose:

**PI51 Stack:**
- `nginx` → `kong` → `redis` → `prometheus` → `grafana`

**ORIN0 Stack:**  
- `nginx` → `comfyui` + `ollama-secondary` + `sonarqube` + `jupyterhub`

**PI52 Stack:**
- `postgres` + `redis` + `minio` + `pgadmin` + `redis-commander`

**Monitoring Stack (PI41):**
- `grafana` + `node-exporter` + log collectors

## 🌐 Network Configuration

### Discovered Network Layout:
- **Router**: 192.168.1.1 (OpenWRT)
- **Network**: 192.168.1.0/24
- **Total Devices**: 27 active devices
- **AI Cluster Nodes**: 7 dedicated machines
- **Other Devices**: Various clients, media devices, IoT

### High Availability Features:
- **Load Balancing**: Kong distributes between AGX0 (80%) and ORIN0 (20%)
- **Failover**: Automatic fallback from primary to secondary AI nodes
- **Health Checks**: Continuous monitoring of all services
- **Data Replication**: PostgreSQL with backup strategies

## 📈 Performance Characteristics

### Expected Throughput:
- **Chat**: 30-50 requests/minute
- **Code**: 15-20 requests/minute  
- **Images**: 2-4 generations/minute
- **Concurrent Users**: 10-15 active sessions

### Resource Utilization:
- **AGX0**: 60-80% GPU, 40-60% RAM (primary workload)
- **ORIN0**: 70-90% GPU, 50-70% RAM (image generation)
- **Pi Nodes**: 20-40% CPU, 30-50% RAM (services)

This architecture provides a robust, scalable, and easily manageable distributed AI system with comprehensive containerization for easy deployment and cleanup.
