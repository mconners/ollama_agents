# Ollama Network Agent - Complete Usage Guide

Your OpenAI-compliant network resolution agent is now successfully integrated with your Ollama server running on **agx0**! 🚀

## 🎯 Quick Start

### 1. Basic Network Queries
```python
from ollama_network_agent import OllamaNetworkAgent

# Connect to your Ollama server
agent = OllamaNetworkAgent(
    ollama_host="agx0",
    ollama_port=11434,
    model="llama3.2",  # Or any of your 18 available models
    use_router_data=True
)

# Direct function calls
result = agent.resolve_hostname_to_ip("github.com")
print(f"github.com -> {result['ip_address']}")  # 140.82.114.4

result = agent.resolve_ip_to_hostname("8.8.8.8") 
print(f"8.8.8.8 -> {result['hostname']}")  # dns.google
```

### 2. Found Your nano Device! 
Your `nano` device is at **192.168.1.159** on your local network.

### 3. Interactive Chat
```bash
python3 test_ollama_simple.py
# Then choose 'y' to start interactive chat
```

## 🤖 Available Ollama Models

Your server has **18 models** available:

**Recommended Models:**
- `gpt-oss:latest` (12.8GB) - GPT-style model
- `llama3.2:latest` (1.9GB) - Latest Llama, fast and efficient 
- `llama3:8b` (4.3GB) - Larger Llama model
- `phi3:mini` (2.0GB) - Microsoft's compact model

**Specialized Models:**
- `codellama:34b` (17.7GB) - Best for coding tasks
- `qwen2.5-coder:32b` (18.5GB) - Advanced coding model
- `mistral-small3.2:latest` (14.1GB) - Good balance of size/performance

## 📡 Network Resolution Capabilities

### Automatic Function Detection
The agent automatically detects network queries and executes the appropriate functions:

**Ask Ollama:**
- *"What's the IP address of github.com?"*
- *"Find the hostname for 8.8.8.8"*
- *"Look up nano on my network"*
- *"Resolve these domains: google.com, github.com, stackoverflow.com"*

### Available Functions
1. **resolve_hostname_to_ip** - Convert hostnames to IP addresses
2. **resolve_ip_to_hostname** - Convert IP addresses to hostnames  
3. **bulk_resolve** - Handle multiple queries at once
4. **get_network_info** - Comprehensive network analysis

### Data Sources
- **Router Data**: 26 devices cached from your OpenWRT router
- **DNS Resolution**: Standard DNS lookups for external hosts
- **Reverse DNS**: Hostname resolution from IP addresses
- **Smart Caching**: 5-minute cache to reduce network load

## 🏠 Local Network Integration

Your router integration is working perfectly:
- **26 devices** detected and cached
- **nano found** at 192.168.1.159
- **Router**: 192.168.1.1 (SSH enabled)
- **agx0**: 192.168.1.154 (your Ollama server)

## 💻 Usage Examples

### Direct API Usage
```python
# Initialize agent
agent = OllamaNetworkAgent("agx0", 11434, "llama3.2")

# Chat with network functions
response = agent.chat_with_functions(
    "What's the IP address of nano on my network?"
)
print(response['response'])
```

### Interactive Chat Session
```python
agent.interactive_chat()
# Start asking questions like:
# - "Find nano's IP address"
# - "What's the hostname for 192.168.1.154?"
# - "Resolve github.com to IP"
```

### Bulk Network Operations
```python
# Resolve multiple targets at once
queries = ["google.com", "github.com", "nano", "192.168.1.1"]
results = agent.bulk_resolve(queries, auto_detect_type=True)

for result in results['results']:
    print(f"{result['query']} -> {result['result']}")
```

## 🔧 Configuration Options

### Model Selection
```python
# Use different models for different purposes
agent_fast = OllamaNetworkAgent("agx0", 11434, "phi3:mini")      # 2GB, fast
agent_smart = OllamaNetworkAgent("agx0", 11434, "llama3:8b")     # 4.3GB, balanced
agent_code = OllamaNetworkAgent("agx0", 11434, "codellama:34b")  # 17.7GB, coding
```

### Router Data Toggle
```python
# With router data (recommended for local network)
agent = OllamaNetworkAgent("agx0", 11434, "llama3.2", use_router_data=True)

# DNS only (for external queries only)
agent = OllamaNetworkAgent("agx0", 11434, "llama3.2", use_router_data=False)
```

## 🚀 Ready-to-Run Commands

### Quick Testing
```bash
# Test everything is working
python3 setup_ollama_agent.py

# Interactive network assistant
python3 test_ollama_simple.py

# Full feature demo
python3 ollama_network_agent.py
```

### Programmatic Usage
```python
from ollama_network_agent import OllamaNetworkAgent

agent = OllamaNetworkAgent("agx0")

# Your nano device
nano_info = agent.get_network_info("nano")
print(f"nano: {nano_info}")

# Your agx0 server  
agx0_info = agent.get_network_info("192.168.1.154")
print(f"agx0: {agx0_info}")
```

## 🎯 Specific Use Cases

### 1. Device Discovery
```python
# Find devices on your network
response = agent.chat_with_functions(
    "Show me all devices with 'nano' in their name on my network"
)
```

### 2. Network Diagnostics
```python
# Check connectivity and get detailed info
response = agent.chat_with_functions(
    "Check if nano at 192.168.1.159 is reachable and give me network details"
)
```

### 3. Bulk Lookups
```python
# Resolve multiple hostnames/IPs
response = agent.chat_with_functions(
    "Resolve these to IP addresses: github.com, google.com, stackoverflow.com"
)
```

## 📊 Performance Notes

- **Router Cache**: Refreshed every 5 minutes
- **Response Time**: ~1-3 seconds for local queries
- **Model Speed**: llama3.2 is fastest, codellama:34b is most capable
- **Network Load**: Minimal impact due to smart caching

## 🔍 Troubleshooting

### Connection Issues
```bash
# Test Ollama connectivity
curl http://agx0:11434/api/tags

# Test network agent
python3 -c "from ollama_network_agent import OllamaNetworkAgent; print('✅ Import OK')"
```

### Function Not Working
- Check that your query contains network-related keywords
- Use specific hostnames or IP addresses
- Try direct function calls for debugging

## 🎉 Success Summary

✅ **Ollama Server**: Connected to agx0:11434  
✅ **Network Agent**: 26 devices cached from router  
✅ **Models**: 18 models available  
✅ **nano Device**: Found at 192.168.1.159  
✅ **Integration**: Full function calling support  
✅ **Performance**: Fast local network resolution  

Your AI-powered network assistant is ready! Ask it anything about IP addresses, hostnames, or network resolution. 🚀
