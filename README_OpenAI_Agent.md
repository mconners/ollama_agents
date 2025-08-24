# OpenAI Network Resolution Agent

A fully OpenAI-compliant agent that provides hostname-to-IP and IP-to-hostname resolution capabilities using OpenAI's function calling interface. This agent combines DNS resolution, reverse DNS lookups, and local network data from your OpenWRT router for comprehensive network resolution.

## 🚀 Features

- **OpenAI Function Calling Compatible**: Fully compliant with OpenAI's function calling schema
- **Dual Resolution**: Hostname ↔ IP address resolution in both directions
- **Local Network Integration**: Leverages OpenWRT router data for faster local network resolution
- **Bulk Operations**: Resolve multiple targets in a single request
- **Comprehensive Network Info**: Get detailed network information about any target
- **Smart Caching**: Efficient caching of router data to minimize network calls
- **Error Handling**: Robust error handling with detailed error messages

## 📋 Available Functions

### 1. `resolve_hostname_to_ip`
Resolve a hostname to its IP address using DNS lookup and local network data.

**Parameters:**
- `hostname` (required): The hostname to resolve (e.g., 'google.com', 'my-laptop')
- `include_router_data` (optional): Check local router data first (default: true)

### 2. `resolve_ip_to_hostname`
Resolve an IP address to its hostname using reverse DNS and local network data.

**Parameters:**
- `ip_address` (required): The IP address to resolve (e.g., '192.168.1.100', '8.8.8.8')
- `include_router_data` (optional): Check local router data first (default: true)

### 3. `bulk_resolve`
Resolve multiple hostnames or IP addresses in a single request.

**Parameters:**
- `queries` (required): Array of hostnames or IP addresses to resolve
- `auto_detect_type` (optional): Auto-detect whether each query is hostname or IP (default: true)

### 4. `get_network_info`
Get comprehensive network information about a hostname or IP address.

**Parameters:**
- `target` (required): The hostname or IP address to analyze

## 🛠 Installation & Setup

### Prerequisites
```bash
# Install required Python packages
pip install paramiko requests

# Optional: Install OpenAI client for integration
pip install openai
```

### Quick Start

1. **Basic Agent Usage:**
```python
from openai_network_agent import create_openai_agent_instance

# Create agent instance
agent = create_openai_agent_instance(use_router_data=True)

# Resolve hostname to IP
result = agent.resolve_hostname_to_ip("google.com")
print(f"google.com -> {result.result}")

# Resolve IP to hostname
result = agent.resolve_ip_to_hostname("8.8.8.8")
print(f"8.8.8.8 -> {result.result}")
```

2. **OpenAI Integration:**
```python
from openai_integration_example import OpenAINetworkAgentWrapper
import openai

# Initialize the wrapper
wrapper = OpenAINetworkAgentWrapper(use_router_data=True)

# Get function schemas for OpenAI
functions = wrapper.get_functions_for_openai()

# Use with OpenAI client
client = openai.OpenAI(api_key="your-api-key")

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {
            "role": "user",
            "content": "What's the IP address of github.com?"
        }
    ],
    functions=functions,
    function_call="auto"
)

# Handle function call
if response.choices[0].message.function_call:
    function_call = response.choices[0].message.function_call
    result = wrapper.execute_function_call({
        "name": function_call.name,
        "arguments": function_call.arguments
    })
    print(result)
```

## 📊 Example Usage & Results

### Function Call Examples

```json
{
  "resolve_hostname": {
    "name": "resolve_hostname_to_ip",
    "arguments": {
      "hostname": "google.com"
    }
  },
  "resolve_ip": {
    "name": "resolve_ip_to_hostname",
    "arguments": {
      "ip_address": "8.8.8.8"
    }
  },
  "bulk_resolve": {
    "name": "bulk_resolve",
    "arguments": {
      "queries": ["google.com", "8.8.8.8", "github.com"],
      "auto_detect_type": true
    }
  },
  "network_info": {
    "name": "get_network_info",
    "arguments": {
      "target": "google.com"
    }
  }
}
```

### Response Format

```json
{
  "success": true,
  "function": "resolve_hostname_to_ip",
  "query": "google.com",
  "result": "108.177.122.139",
  "source": "dns",
  "additional_info": {
    "method": "dns_lookup",
    "address_family": 2
  },
  "error": null,
  "timestamp": 1692123456.789
}
```

## 🏠 Router Integration

The agent automatically integrates with your OpenWRT router to provide faster resolution for local network devices:

### Router Setup
1. Configure your router credentials in `config/router_config.json`
2. Ensure SSH access is enabled on your router
3. The agent will automatically cache device information from your router

### Benefits of Router Integration
- **Faster Local Resolution**: Skip DNS for local devices
- **Device Discovery**: Find devices that don't have DNS entries
- **Network Mapping**: Get comprehensive local network information
- **Smart Caching**: Efficient 5-minute cache TTL

## 🔧 Configuration

### Router Configuration (`config/router_config.json`)
```json
{
  "router_ip": "192.168.1.1",
  "router_user": "root",
  "router_password": "your_password",
  "ssh_port": 22,
  "method": "ssh",
  "timeout": 30
}
```

### Agent Configuration
```python
# Create agent with router data
agent = create_openai_agent_instance(use_router_data=True)

# Create agent without router data (DNS only)
agent = create_openai_agent_instance(use_router_data=False)
```

## 📈 Performance Features

### Intelligent Resolution Strategy
1. **Local Network First**: Check router data for private IP ranges
2. **DNS Fallback**: Use standard DNS resolution for external hosts
3. **Alternative Methods**: Try ping-based resolution for difficult cases
4. **Smart Caching**: Cache router data for 5 minutes to reduce load

### Error Handling
- **Validation**: Input validation with detailed error messages
- **Graceful Degradation**: Falls back to DNS if router data unavailable
- **Timeout Management**: Configurable timeouts for all operations
- **Detailed Logging**: Comprehensive logging for debugging

## 🧪 Testing & Validation

### Run Built-in Tests
```bash
# Test the agent functionality
python3 openai_network_agent.py

# Test OpenAI integration
python3 openai_integration_example.py

# Test router connectivity
python3 tests/test_router_connectivity.py
```

### Expected Test Results
```
✓ Router manager initialized for local network queries
✓ Hostname to IP: google.com -> 108.177.122.139
✓ IP to Hostname: 8.8.8.8 -> dns.google
✓ Local network resolution working
✓ Network info gathering successful
✓ Bulk resolution handling multiple targets
```

## 🔍 Use Cases

### For OpenAI Applications
- **Network Diagnostics**: "Check if my server is reachable and get its IP"
- **Domain Resolution**: "What's the IP address of my website?"
- **Local Network Discovery**: "List all devices on my network"
- **Bulk Operations**: "Resolve these 10 hostnames for me"

### For Network Administration
- **Device Identification**: Quickly identify unknown IP addresses
- **Network Mapping**: Map hostnames to IPs across your network
- **Connectivity Testing**: Check if devices are reachable
- **Documentation**: Generate network documentation automatically

### For Development & DevOps
- **Service Discovery**: Resolve service endpoints dynamically
- **Health Checks**: Verify service availability and resolution
- **Infrastructure Automation**: Automate network configuration tasks
- **Monitoring Integration**: Enhance monitoring with hostname resolution

## 🛡 Security Considerations

- **Router Credentials**: Store router passwords securely in config files
- **SSH Keys**: Consider using SSH key authentication instead of passwords
- **Network Access**: Agent only requires network access to router and DNS servers
- **Data Privacy**: All resolution data stays local, no external services called
- **Logging**: Sensitive information is not logged by default

## 🐛 Troubleshooting

### Common Issues

**"Router manager initialization failed"**
- Check router IP address and credentials in config
- Verify SSH access is enabled on router
- Test manual SSH connection: `ssh root@192.168.1.1`

**"DNS resolution failed"**
- Check internet connectivity
- Verify DNS servers are accessible
- Try with different hostnames

**"Function execution failed"**
- Check function parameters match schema exactly
- Verify all required parameters are provided
- Enable debug logging for detailed error info

### Debug Mode
```python
import logging
logging.basicConfig(level=logging.DEBUG)

# Now run your agent operations
```

## 📝 Function Schema Export

Generate OpenAI-compatible function schemas:

```bash
python3 openai_integration_example.py
# Creates: output/openai_function_schemas.json
```

This file contains the complete OpenAI function calling schemas that you can directly use in your OpenAI applications.

## 🤝 Contributing

Feel free to extend the agent with additional functionality:

- **New Resolution Methods**: Add support for other network discovery protocols
- **Enhanced Router Support**: Support for additional router firmware
- **Performance Optimizations**: Improve caching and resolution speed
- **Additional Network Info**: Gather more detailed network information

## 📄 License

This OpenAI Network Resolution Agent is provided as-is for educational and practical use with OpenAI applications and OpenWRT routers.

---

## Quick Reference

### Core Commands
```bash
# Test agent functionality
python3 openai_network_agent.py

# Test OpenAI integration  
python3 openai_integration_example.py

# Generate function schemas
# (automatically creates output/openai_function_schemas.json)
```

### Key Files
- `openai_network_agent.py` - Main agent implementation
- `openai_integration_example.py` - OpenAI integration wrapper
- `output/openai_function_schemas.json` - Generated function schemas
- `config/router_config.json` - Router configuration
