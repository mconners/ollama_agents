#!/usr/bin/env python3
"""
Simple test script for Ollama Network Agent integration
"""

from ollama_network_agent import OllamaNetworkAgent

def test_simple_queries():
    """Test simple network resolution queries"""
    
    # Create agent
    agent = OllamaNetworkAgent(
        ollama_host="agx0",
        ollama_port=11434,
        model="llama3.2",
        use_router_data=True
    )
    
    if not agent.test_ollama_connection():
        print("❌ Cannot connect to Ollama server")
        return
    
    print("\n🧪 Testing Direct Network Functions:")
    print("-" * 40)
    
    # Test 1: Hostname to IP
    result = agent.resolve_hostname_to_ip("github.com")
    print(f"1. github.com -> {result['ip_address'] if result['success'] else result['error']}")
    
    # Test 2: IP to hostname
    result = agent.resolve_ip_to_hostname("8.8.8.8")
    print(f"2. 8.8.8.8 -> {result['hostname'] if result['success'] else result['error']}")
    
    # Test 3: Look for 'nano' in local network (using router data)
    print(f"\n🏠 Searching for 'nano' in local network:")
    
    # Get all devices from router and search for 'nano'
    try:
        devices = agent.network_agent.router_manager.get_connected_devices()
        nano_devices = [d for d in devices if 'nano' in d.hostname.lower()]
        
        if nano_devices:
            for device in nano_devices:
                print(f"   Found: {device.hostname} -> {device.ip_address}")
        else:
            print("   No devices with 'nano' in hostname found")
            print("   Available devices:")
            for device in devices[:5]:  # Show first 5 devices
                print(f"     • {device.hostname} -> {device.ip_address}")
            if len(devices) > 5:
                print(f"     ... and {len(devices) - 5} more devices")
    except Exception as e:
        print(f"   Error searching local network: {e}")
    
    # Test 4: Bulk resolution
    queries = ["google.com", "github.com", "8.8.8.8"]
    result = agent.bulk_resolve(queries)
    
    print(f"\n📊 Bulk resolution results:")
    if result['success']:
        for res in result['results']:
            status = "✅" if res['success'] else "❌"
            print(f"   {status} {res['query']} -> {res['result'] or res['error']}")
    
    print(f"\n🎯 You can now ask Ollama questions like:")
    print(f"   'What is the IP address of github.com?'")
    print(f"   'Find the hostname for 8.8.8.8'")
    print(f"   'Look up nano on my network'")
    
    return agent

def interactive_mode():
    """Start interactive mode with the agent"""
    agent = test_simple_queries()
    
    if agent:
        print(f"\n" + "="*50)
        start_chat = input("Start interactive chat with Ollama? (y/n): ").lower().strip()
        
        if start_chat in ['y', 'yes']:
            print(f"\n💡 Tips for better results:")
            print(f"   - Ask specific questions about IP addresses or hostnames")
            print(f"   - Try: 'What is google.com's IP address?'")
            print(f"   - Try: 'Find the hostname for 192.168.1.154'")
            print(f"   - The AI will automatically use network functions when needed")
            
            agent.interactive_chat()

if __name__ == "__main__":
    interactive_mode()
