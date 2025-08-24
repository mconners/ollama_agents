# Network Topology Diagram - Distributed AI System

## 🌐 Physical Network Layout

```
                               INTERNET
                                  │
                                  ▼
                      ┌─────────────────────────┐
                      │    OpenWRT Router       │
                      │    192.168.1.1          │
                      │    Gateway/DHCP/DNS     │
                      └─────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │  192.168.1.0/24 Network  │
                    └─────────────┼─────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
    AI CLUSTER                OTHER DEVICES             MANAGEMENT
  (7 machines)               (20 devices)              & CLIENTS

═══════════════════════════════════════════════════════════════════

                      🤖 AI CLUSTER TOPOLOGY
                      
┌─────────────────────────────────────────────────────────────────┐
│                    TIER 1: API GATEWAY                         │
│                                                                 │
│    ┌─────────────────────┐          ┌─────────────────────┐     │
│    │      PI51           │◄────────►│    External Users   │     │
│    │  192.168.1.147      │          │   (Internet/LAN)    │     │
│    │  Raspberry Pi 5     │          └─────────────────────┘     │
│    │  8GB RAM, 1TB SSD   │                                      │
│    │                     │                                      │
│    │  🌐 Nginx (80/443)  │                                      │
│    │  🚪 Kong Gateway    │                                      │
│    │  📊 Prometheus      │                                      │
│    │  📈 Grafana         │                                      │
│    │  💾 Redis Cache     │                                      │
│    └─────────────────────┘                                      │
│              │                                                  │
│              │ Load Balanced Traffic                            │
│              ▼                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   TIER 2: AI PROCESSING                        │
│                                                                 │
│  ┌─────────────────────┐              ┌─────────────────────┐   │
│  │       AGX0          │◄────────────►│       ORIN0         │   │
│  │   192.168.1.154     │   Failover   │   192.168.1.157     │   │
│  │ Jetson Orin AGX     │   & Load     │ Jetson Orin Nano    │   │
│  │ 64GB RAM, 2TB NVMe  │   Balance    │ 8GB RAM, 1TB NVMe   │   │
│  │                     │              │                     │   │
│  │ 🧠 PRIMARY AI HUB   │              │ 🎨 SECONDARY AI     │   │
│  │                     │              │                     │   │
│  │ ┌─────────────────┐ │              │ ┌─────────────────┐ │   │
│  │ │ Ollama Server   │ │              │ │ ComfyUI Image   │ │   │
│  │ │ 18 Models       │ │              │ │ Generation      │ │   │
│  │ │ 2048 CUDA Cores │ │              │ │ 1024 CUDA Cores │ │   │
│  │ └─────────────────┘ │              │ └─────────────────┘ │   │
│  │                     │              │                     │   │
│  │ • llama3.2 (chat)  │              │ • Stable Diffusion │   │
│  │ • codellama (code)  │              │ • Ollama Backup    │   │
│  │ • gpt-oss          │              │ • SonarQube        │   │
│  │ • mistral-small    │              │ • JupyterHub       │   │
│  └─────────────────────┘              └─────────────────────┘   │
│              │                                   │              │
│              └───────────────┬───────────────────┘              │
│                              │                                  │
│                              ▼                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    TIER 3: DATA LAYER                          │
│                                                                 │
│          ┌─────────────────────┐                                │
│          │        PI52         │                                │
│          │   192.168.1.247     │                                │
│          │  Raspberry Pi 5     │                                │
│          │  8GB RAM, 1TB SSD   │                                │
│          │                     │                                │
│          │ 💾 BACKEND SERVICES │                                │
│          │                     │                                │
│          │ ┌─────────────────┐ │                                │
│          │ │ PostgreSQL DB   │ │   Stores:                      │
│          │ │ • Users         │ │   • User accounts              │
│          │ │ • Conversations │ │   • Chat history               │
│          │ │ • Messages      │ │   • Generated images           │
│          │ │ • Code snippets │ │   • Code snippets              │
│          │ │ • API usage     │ │   • System metrics             │
│          │ └─────────────────┘ │                                │
│          │                     │                                │
│          │ ┌─────────────────┐ │                                │
│          │ │ Redis Cache     │ │   Caches:                      │
│          │ │ • Sessions      │ │   • User sessions              │
│          │ │ • API responses │ │   • Rate limits                │
│          │ │ • Rate limits   │ │   • Temporary data             │
│          │ └─────────────────┘ │                                │
│          │                     │                                │
│          │ ┌─────────────────┐ │                                │
│          │ │ MinIO Storage   │ │   Files:                       │
│          │ │ • Images        │ │   • Generated images           │
│          │ │ • Models        │ │   • Model files                │
│          │ │ • Backups       │ │   • System backups             │
│          │ └─────────────────┘ │                                │
│          └─────────────────────┘                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  TIER 4: MONITORING                            │
│                                                                 │
│          ┌─────────────────────┐                                │
│          │        PI41         │                                │
│          │   192.168.1.204     │                                │
│          │  Raspberry Pi 4     │                                │
│          │  2GB RAM, 1TB SSD   │                                │
│          │                     │                                │
│          │ 📊 MONITORING HUB   │                                │
│          │                     │                                │
│          │ ┌─────────────────┐ │   Monitors:                    │
│          │ │ Grafana         │ │   • System resources           │
│          │ │ Dashboards      │ │   • Service health             │
│          │ │ Port 3000       │ │   • API performance            │
│          │ └─────────────────┘ │   • GPU utilization            │
│          │                     │   • Container status           │
│          │ ┌─────────────────┐ │                                │
│          │ │ Log Collection  │ │   Collects:                    │
│          │ │ Alert Manager   │ │   • Application logs           │
│          │ │ Node Exporters  │ │   • System metrics             │
│          │ └─────────────────┘ │   • Error notifications        │
│          └─────────────────────┘                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    TIER 5: EDGE/UTILITY                        │
│                                                                 │
│  ┌─────────────────────┐              ┌─────────────────────┐   │
│  │       NANO          │              │        PI31         │   │
│  │   192.168.1.159     │              │   192.168.1.234     │   │
│  │   Jetson Nano       │              │  Raspberry Pi 3     │   │
│  │  2GB RAM, 116GB     │              │  1GB RAM, 32GB      │   │
│  │                     │              │                     │   │
│  │ 🔗 EDGE INFERENCE   │              │ 🛠️ UTILITY SERVICES│   │
│  │                     │              │                     │   │
│  │ ┌─────────────────┐ │              │ ┌─────────────────┐ │   │
│  │ │ Lightweight     │ │              │ │ Configuration   │ │   │
│  │ │ Models          │ │              │ │ Management      │ │   │
│  │ │ 128 CUDA Cores  │ │              │ │                 │ │   │
│  │ └─────────────────┘ │              │ │ Backup          │ │   │
│  │                     │              │ │ Coordination    │ │   │
│  │ • Local caching     │              │ │                 │ │   │
│  │ • Offline fallback  │              │ │ Network Utils   │ │   │
│  │ • Edge processing   │              │ └─────────────────┘ │   │
│  └─────────────────────┘              └─────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════

                    🔄 DATA FLOW PATTERNS

Chat Request Flow:
User → PI51 → Kong → [80%] AGX0 → PostgreSQL → Response
                   → [20%] ORIN0 → Redis Cache

Image Generation Flow:
User → PI51 → Kong → ORIN0 → ComfyUI → MinIO Storage → Response

Code Analysis Flow:
User → PI51 → Kong → AGX0 → CodeLlama → ORIN0 SonarQube → Response

Monitoring Flow:
All Nodes → PI41 → Grafana → Alerts/Dashboards

═══════════════════════════════════════════════════════════════════

                    🔌 PORT MAPPING

External Access (through PI51):
• HTTP:     Port 80  → Kong Gateway
• HTTPS:    Port 443 → Kong Gateway (SSL)
• Grafana:  Port 3000 → Monitoring Dashboard

Internal Services:
• AGX0:     Port 11434 → Primary Ollama
• ORIN0:    Port 11435 → Secondary Ollama
• ORIN0:    Port 7860  → ComfyUI
• PI52:     Port 5432  → PostgreSQL
• PI52:     Port 6379  → Redis
• PI52:     Port 9000  → MinIO
• PI41:     Port 3000  → Grafana

═══════════════════════════════════════════════════════════════════

                    🛡️ NETWORK SECURITY

Firewall Rules:
• Only PI51 exposed to external network
• Internal cluster communication on trusted network
• SSH access requires key authentication
• All services containerized with minimal host exposure

Load Balancing:
• Kong handles API routing and rate limiting
• Health checks ensure service availability
• Automatic failover between AGX0 and ORIN0
• Redis-based session persistence
```

This network topology diagram shows the complete physical and logical layout of your distributed AI system, with clear data flow patterns and service relationships!
