#!/usr/bin/env python3

"""
Quick test script to interact with your Ollama cluster
"""

import requests
import json
import time

# Your cluster endpoints
ENDPOINTS = {
    "PI51 Gateway": "http://192.168.1.147:11434",
    "ORIN0 Secondary": "http://192.168.1.157:11435", 
    "AGX0 Primary": "http://192.168.1.154:11434"
}

def test_endpoint(name, url, prompt="Hello! Can you help me with Python?"):
    """Test an Ollama endpoint with a simple prompt"""
    print(f"\n🤖 Testing {name}")
    print(f"   URL: {url}")
    
    try:
        # Check if service is up
        response = requests.get(f"{url}/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"   ✅ Service UP - {len(models)} models available")
            
            if models:
                # Try to use the first model
                model_name = models[0]['name']
                print(f"   🎯 Testing with model: {model_name}")
                
                # Send a prompt
                data = {
                    "model": model_name,
                    "prompt": prompt,
                    "stream": False
                }
                
                start_time = time.time()
                response = requests.post(f"{url}/api/generate", json=data, timeout=30)
                end_time = time.time()
                
                if response.status_code == 200:
                    result = response.json()
                    print(f"   💬 Response ({end_time-start_time:.1f}s): {result['response'][:100]}...")
                    return True
                else:
                    print(f"   ❌ Generate failed: {response.status_code}")
            else:
                print(f"   ⚠️  No models available - try pulling a model first")
                print(f"   💡 Suggestion: curl -X POST {url}/api/pull -d '{{\"name\":\"phi3:mini\"}}'")
        else:
            print(f"   ❌ Service DOWN: {response.status_code}")
            
    except requests.exceptions.ConnectTimeout:
        print(f"   ❌ Connection timeout")
    except requests.exceptions.ConnectionError:
        print(f"   ❌ Connection failed") 
    except Exception as e:
        print(f"   ❌ Error: {e}")
        
    return False

def pull_model(endpoint_url, model_name="phi3:mini"):
    """Pull a lightweight model to test with"""
    print(f"\n📥 Pulling {model_name} to {endpoint_url}")
    
    try:
        response = requests.post(
            f"{endpoint_url}/api/pull",
            json={"name": model_name},
            stream=True,
            timeout=300
        )
        
        if response.status_code == 200:
            print("   ✅ Model pull started...")
            return True
        else:
            print(f"   ❌ Pull failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    print("🚀 Ollama Cluster Test Script")
    print("=" * 40)
    
    # Test all endpoints
    working_endpoints = []
    for name, url in ENDPOINTS.items():
        if test_endpoint(name, url):
            working_endpoints.append((name, url))
    
    print(f"\n📊 Summary:")
    print(f"   Working endpoints: {len(working_endpoints)}/{len(ENDPOINTS)}")
    
    if working_endpoints:
        print(f"\n💡 You can now use these endpoints:")
        for name, url in working_endpoints:
            print(f"   • {name}: {url}")
            
        print(f"\n🎯 Example usage:")
        first_name, first_url = working_endpoints[0]
        print(f"curl -X POST {first_url}/api/generate \\")
        print(f'  -d \'{{"model":"phi3:mini","prompt":"Write a Python function","stream":false}}\' | jq \'.response\'')
        
    else:
        print(f"\n⚠️  No endpoints responded with models.")
        print(f"   Try pulling a lightweight model first:")
        for name, url in ENDPOINTS.items():
            print(f"   curl -X POST {url}/api/pull -d '{{\"name\":\"phi3:mini\"}}'")

if __name__ == "__main__":
    main()
