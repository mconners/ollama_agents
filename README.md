# Ollama Network Agents

This directory contains the complete Ollama integration for the OpenAI-compliant network resolution agent.

## 📁 Directory Structure

```
ollama_agents/
├── README.md                           # This file
├── USAGE_Ollama.md                     # Complete usage guide
├── README_OpenAI_Agent.md              # OpenAI integration documentation
│
├── ollama_network_agent.py             # Main Ollama integration agent
├── openai_network_agent.py             # Core OpenAI-compliant agent
├── openai_integration_example.py       # OpenAI client examples
├── openai_function_schemas.json        # Generated function schemas
│
├── setup_ollama_agent.py               # Connection testing and setup
├── test_ollama_simple.py               # Simple testing interface
│
├── openwrt_query.py                    # Router query functionality
├── config/                             # Configuration files
├── modules/                            # Additional modules
└── utils/                              # Network utilities
```

## 🚀 Quick Start

### 1. Test Connection to Ollama Server
```bash
python3 setup_ollama_agent.py
```

### 2. Simple Interactive Test
```bash
python3 test_ollama_simple.py
```

### 3. Full Feature Demo
```bash
python3 ollama_network_agent.py
```

## 🤖 Your Ollama Setup

- **Server**: agx0:11434
- **Models Available**: 18 models (gpt-oss, llama3.2, codellama, etc.)
- **Network Agent**: Integrated with 26 local devices from your router
- **nano Device**: Found at 192.168.1.159

## 💻 Basic Usage

```python
from ollama_network_agent import OllamaNetworkAgent

# Connect to your Ollama server
agent = OllamaNetworkAgent("agx0", 11434, "llama3.2")

# Ask network questions
response = agent.chat_with_functions(
    "What's the IP address of nano on my network?"
)
print(response['response'])
```

## 📚 Documentation

- `USAGE_Ollama.md` - Complete usage guide with examples
- `README_OpenAI_Agent.md` - Technical documentation for OpenAI integration

## 🧪 Available Functions

1. **resolve_hostname_to_ip** - Convert hostnames to IP addresses
2. **resolve_ip_to_hostname** - Convert IP addresses to hostnames  
3. **bulk_resolve** - Handle multiple queries at once
4. **get_network_info** - Comprehensive network analysis

## 🎯 Example Queries

Ask your AI assistant:
- *"What's the IP address of nano?"* → 192.168.1.159
- *"Find github.com's IP address"* → Automatically resolved
- *"What hostname is 8.8.8.8?"* → dns.google
- *"Look up all my local network devices"*

Your AI-powered network assistant is ready! 🚀
