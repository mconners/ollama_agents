#!/usr/bin/env python3
"""
Setup script for Ollama Network Agent
Tests connectivity and provides setup instructions
"""

import requests
import socket
import subprocess
from typing import Dict, List

def test_host_connectivity(hostname: str, port: int = 11434) -> bool:
    """Test if the Ollama host is reachable"""
    print(f"🔍 Testing connectivity to {hostname}:{port}")
    
    try:
        # First test basic connectivity with socket
        sock = socket.create_connection((hostname, port), timeout=5)
        sock.close()
        print(f"   ✅ Port {port} is open on {hostname}")
        return True
    except (socket.timeout, ConnectionRefusedError, OSError) as e:
        print(f"   ❌ Cannot connect to {hostname}:{port} - {e}")
        return False

def test_ollama_api(hostname: str, port: int = 11434) -> Dict:
    """Test Ollama API endpoints"""
    base_url = f"http://{hostname}:{port}"
    
    print(f"🧪 Testing Ollama API at {base_url}")
    
    try:
        # Test /api/tags endpoint
        response = requests.get(f"{base_url}/api/tags", timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = data.get("models", [])
            print(f"   ✅ API is responding")
            print(f"   📊 Found {len(models)} models:")
            for model in models:
                name = model.get("name", "Unknown")
                size = model.get("size", 0)
                size_gb = size / (1024**3) if size > 0 else 0
                print(f"      • {name} ({size_gb:.1f}GB)")
            return {
                "success": True,
                "models": [m["name"] for m in models],
                "base_url": base_url
            }
        else:
            print(f"   ❌ API returned HTTP {response.status_code}")
            return {"success": False, "error": f"HTTP {response.status_code}"}
    except requests.exceptions.RequestException as e:
        print(f"   ❌ API request failed: {e}")
        return {"success": False, "error": str(e)}

def test_dns_resolution(hostname: str) -> bool:
    """Test if hostname resolves correctly"""
    print(f"🌐 Testing DNS resolution for '{hostname}'")
    
    try:
        ip = socket.gethostbyname(hostname)
        print(f"   ✅ {hostname} resolves to {ip}")
        return True
    except socket.gaierror as e:
        print(f"   ❌ DNS resolution failed: {e}")
        return False

def suggest_fixes(hostname: str):
    """Provide troubleshooting suggestions"""
    print(f"\n🔧 Troubleshooting suggestions for {hostname}:")
    
    print(f"\n1. Check if Ollama is running on {hostname}:")
    print(f"   ssh {hostname}")
    print(f"   systemctl status ollama")
    print(f"   # or check if process is running:")
    print(f"   ps aux | grep ollama")
    
    print(f"\n2. Check if Ollama is listening on the correct port:")
    print(f"   ssh {hostname}")
    print(f"   netstat -tlnp | grep 11434")
    print(f"   # or:")
    print(f"   ss -tlnp | grep 11434")
    
    print(f"\n3. Check Ollama configuration:")
    print(f"   # On {hostname}, check if Ollama is configured to bind to all interfaces")
    print(f"   # Set environment variable: OLLAMA_HOST=0.0.0.0:11434")
    print(f"   # Or start with: ollama serve --host 0.0.0.0")
    
    print(f"\n4. Test network connectivity:")
    print(f"   # From this machine:")
    print(f"   ping {hostname}")
    print(f"   telnet {hostname} 11434")
    print(f"   curl http://{hostname}:11434/api/tags")
    
    print(f"\n5. Check firewall settings on {hostname}:")
    print(f"   sudo ufw status")
    print(f"   # If firewall is blocking, add rule:")
    print(f"   sudo ufw allow 11434")

def test_local_network_agent():
    """Test if the network agent works locally"""
    print(f"\n🧪 Testing local network agent functionality:")
    
    try:
        from openai_network_agent import create_openai_agent_instance
        
        agent = create_openai_agent_instance(use_router_data=True)
        result = agent.resolve_hostname_to_ip("google.com")
        
        if result.success:
            print(f"   ✅ Network agent working: google.com -> {result.result}")
            return True
        else:
            print(f"   ❌ Network agent failed: {result.error}")
            return False
    except Exception as e:
        print(f"   ❌ Network agent error: {e}")
        return False

def main():
    """Main setup and testing function"""
    
    print("🚀 Ollama Network Agent Setup & Testing")
    print("=" * 50)
    
    hostname = "agx0"
    port = 11434
    
    # Test 1: DNS resolution
    dns_ok = test_dns_resolution(hostname)
    
    # Test 2: Host connectivity
    connection_ok = False
    if dns_ok:
        connection_ok = test_host_connectivity(hostname, port)
    
    # Test 3: Ollama API
    api_result = {"success": False}
    if connection_ok:
        api_result = test_ollama_api(hostname, port)
    
    # Test 4: Local network agent
    print()
    agent_ok = test_local_network_agent()
    
    # Summary
    print("\n" + "=" * 50)
    print("📋 Setup Summary:")
    print(f"   DNS Resolution: {'✅' if dns_ok else '❌'}")
    print(f"   Host Connectivity: {'✅' if connection_ok else '❌'}")
    print(f"   Ollama API: {'✅' if api_result['success'] else '❌'}")
    print(f"   Network Agent: {'✅' if agent_ok else '❌'}")
    
    if all([dns_ok, connection_ok, api_result['success'], agent_ok]):
        print(f"\n🎉 All tests passed! Your Ollama server is ready.")
        
        print(f"\n🚀 Ready to use:")
        print(f"   python3 ollama_network_agent.py")
        print(f"\n   Or in Python:")
        print(f"   from ollama_network_agent import OllamaNetworkAgent")
        print(f"   agent = OllamaNetworkAgent('agx0', 11434)")
        print(f"   agent.interactive_chat()")
        
        if api_result.get('models'):
            recommended_model = api_result['models'][0]
            print(f"\n💡 Available models: {api_result['models']}")
            print(f"   Recommended: {recommended_model}")
    else:
        print(f"\n❌ Some tests failed. Please fix the issues above.")
        if not connection_ok or not api_result['success']:
            suggest_fixes(hostname)
    
    print(f"\n📚 Next steps:")
    print(f"   1. Fix any failed tests above")
    print(f"   2. Run: python3 ollama_network_agent.py")
    print(f"   3. Start chatting with your AI assistant!")

if __name__ == "__main__":
    main()
