#!/usr/bin/env python3
"""
Ollama Integration for Network Resolution Agent
Connects the OpenAI-compliant network agent to Ollama server running on agx0
"""

import json
import requests
import time
from typing import Dict, List, Any, Optional
from openai_network_agent import create_openai_agent_instance

class OllamaNetworkAgent:
    """
    Integration class for connecting Network Resolution Agent with Ollama
    """
    
    def __init__(self, 
                 ollama_host: str = "agx0", 
                 ollama_port: int = 11434,
                 model: str = "llama3.2",
                 use_router_data: bool = True):
        """
        Initialize Ollama Network Agent
        
        Args:
            ollama_host: Hostname/IP of Ollama server (default: agx0)
            ollama_port: Port of Ollama server (default: 11434)
            model: Ollama model to use
            use_router_data: Whether to use router data for local network resolution
        """
        self.ollama_host = ollama_host
        self.ollama_port = ollama_port
        self.model = model
        self.base_url = f"http://{ollama_host}:{ollama_port}"
        
        # Initialize the network resolution agent
        self.network_agent = create_openai_agent_instance(use_router_data=use_router_data)
        
        # Get function definitions
        self.functions = self._convert_openai_to_ollama_functions()
        
        print(f"🚀 Ollama Network Agent initialized")
        print(f"   Server: {self.base_url}")
        print(f"   Model: {self.model}")
        print(f"   Functions: {len(self.functions)} network resolution functions available")
    
    def _convert_openai_to_ollama_functions(self) -> List[Dict[str, Any]]:
        """
        Convert OpenAI function schemas to Ollama-compatible format
        """
        openai_functions = self.network_agent.get_openai_function_schemas()
        
        ollama_functions = []
        for func in openai_functions:
            ollama_func = {
                "name": func["name"],
                "description": func["description"],
                "parameters": func["parameters"]
            }
            ollama_functions.append(ollama_func)
        
        return ollama_functions
    
    def test_ollama_connection(self) -> bool:
        """
        Test connection to Ollama server
        """
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=10)
            if response.status_code == 200:
                models = response.json().get("models", [])
                model_names = [m["name"] for m in models]
                print(f"✅ Connected to Ollama server on {self.ollama_host}")
                print(f"   Available models: {model_names}")
                
                if any(self.model in name for name in model_names):
                    print(f"   ✅ Model '{self.model}' is available")
                    return True
                else:
                    print(f"   ⚠️  Model '{self.model}' not found. Available: {model_names}")
                    if model_names:
                        self.model = model_names[0].split(":")[0]  # Use first available model
                        print(f"   🔄 Switching to model: {self.model}")
                        return True
            else:
                print(f"❌ Failed to connect to Ollama: HTTP {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Connection error: {e}")
            print(f"   Make sure Ollama is running on {self.ollama_host}:{self.ollama_port}")
            return False
    
    def resolve_hostname_to_ip(self, hostname: str, include_router_data: bool = True) -> Dict[str, Any]:
        """Execute hostname to IP resolution"""
        result = self.network_agent.resolve_hostname_to_ip(hostname, include_router_data)
        return {
            "success": result.success,
            "hostname": hostname,
            "ip_address": result.result,
            "source": result.source,
            "error": result.error,
            "additional_info": result.additional_info
        }
    
    def resolve_ip_to_hostname(self, ip_address: str, include_router_data: bool = True) -> Dict[str, Any]:
        """Execute IP to hostname resolution"""
        result = self.network_agent.resolve_ip_to_hostname(ip_address, include_router_data)
        return {
            "success": result.success,
            "ip_address": ip_address,
            "hostname": result.result,
            "source": result.source,
            "error": result.error,
            "additional_info": result.additional_info
        }
    
    def bulk_resolve(self, queries: List[str], auto_detect_type: bool = True) -> Dict[str, Any]:
        """Execute bulk resolution"""
        results = self.network_agent.bulk_resolve(queries, auto_detect_type)
        return {
            "success": True,
            "count": len(results),
            "results": [
                {
                    "query": r.query,
                    "result": r.result,
                    "success": r.success,
                    "source": r.source,
                    "error": r.error
                } for r in results
            ]
        }
    
    def get_network_info(self, target: str) -> Dict[str, Any]:
        """Get comprehensive network information"""
        result = self.network_agent.get_network_info(target)
        return {
            "success": result.success,
            "target": target,
            "network_info": result.additional_info if result.success else None,
            "error": result.error
        }
    
    def execute_function(self, function_name: str, **kwargs) -> Dict[str, Any]:
        """
        Execute a network function by name
        """
        try:
            if function_name == "resolve_hostname_to_ip":
                return self.resolve_hostname_to_ip(**kwargs)
            elif function_name == "resolve_ip_to_hostname":
                return self.resolve_ip_to_hostname(**kwargs)
            elif function_name == "bulk_resolve":
                return self.bulk_resolve(**kwargs)
            elif function_name == "get_network_info":
                return self.get_network_info(**kwargs)
            else:
                return {
                    "success": False,
                    "error": f"Unknown function: {function_name}"
                }
        except Exception as e:
            return {
                "success": False,
                "error": f"Function execution failed: {str(e)}"
            }
    
    def chat_with_functions(self, user_message: str, stream: bool = False) -> Dict[str, Any]:
        """
        Send a chat message to Ollama with function calling capability
        """
        system_prompt = f"""You are a network resolution assistant with access to these functions:

{self._generate_function_descriptions()}

When users ask about network resolution, hostnames, IP addresses, or network information, use the appropriate function to help them.

Always provide the function call results in a clear, user-friendly format."""

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
        
        try:
            # Send request to Ollama
            response = requests.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": self.model,
                    "messages": messages,
                    "stream": stream,
                    "tools": self.functions if hasattr(self, 'functions') else []
                },
                timeout=60
            )
            
            if response.status_code == 200:
                if stream:
                    return self._handle_streaming_response(response)
                else:
                    result = response.json()
                    return self._process_ollama_response(result, user_message)
            else:
                return {
                    "success": False,
                    "error": f"Ollama request failed: HTTP {response.status_code}",
                    "response": response.text
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Request failed: {str(e)}"
            }
    
    def _generate_function_descriptions(self) -> str:
        """Generate human-readable function descriptions"""
        descriptions = []
        for func in self.functions:
            desc = f"- {func['name']}: {func['description']}"
            descriptions.append(desc)
        return "\n".join(descriptions)
    
    def _process_ollama_response(self, ollama_response: Dict, original_message: str) -> Dict[str, Any]:
        """
        Process Ollama response and handle function calls
        """
        try:
            message = ollama_response.get("message", {})
            content = message.get("content", "")
            
            # Check if Ollama wants to call a function
            tool_calls = message.get("tool_calls", [])
            
            if tool_calls:
                # Execute function calls
                function_results = []
                for tool_call in tool_calls:
                    function_name = tool_call.get("function", {}).get("name")
                    arguments = tool_call.get("function", {}).get("arguments", {})
                    
                    if isinstance(arguments, str):
                        try:
                            arguments = json.loads(arguments)
                        except:
                            pass
                    
                    result = self.execute_function(function_name, **arguments)
                    function_results.append({
                        "function": function_name,
                        "arguments": arguments,
                        "result": result
                    })
                
                # Format response with function results
                return {
                    "success": True,
                    "response": content,
                    "function_calls": function_results,
                    "has_function_calls": True
                }
            else:
                # Check if response contains network-related requests that need function calls
                response_with_functions = self._detect_and_execute_network_functions(content, original_message)
                return response_with_functions
                
        except Exception as e:
            return {
                "success": False,
                "error": f"Response processing failed: {str(e)}",
                "raw_response": ollama_response
            }
    
    def _detect_and_execute_network_functions(self, response: str, original_message: str) -> Dict[str, Any]:
        """
        Detect if we should execute network functions based on user message
        """
        message_lower = original_message.lower()
        
        # Simple keyword detection for network queries
        if any(keyword in message_lower for keyword in [
            "ip address", "resolve", "hostname", "ping", "network info",
            "what is the ip", "find the ip", "lookup", "dns"
        ]):
            
            # Try to extract hostname/IP from the message
            import re
            
            # Look for hostnames (domain names)
            hostname_pattern = r'\b([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}\b'
            hostnames = re.findall(hostname_pattern, original_message)
            
            # Look for IP addresses
            ip_pattern = r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b'
            ips = re.findall(ip_pattern, original_message)
            
            function_results = []
            
            # Process found hostnames
            for hostname_match in hostnames:
                if isinstance(hostname_match, tuple):
                    hostname = hostname_match[0] + hostname_match[1]
                else:
                    hostname = hostname_match
                
                result = self.resolve_hostname_to_ip(hostname)
                function_results.append({
                    "function": "resolve_hostname_to_ip",
                    "arguments": {"hostname": hostname},
                    "result": result
                })
            
            # Process found IPs
            for ip in ips:
                result = self.resolve_ip_to_hostname(ip)
                function_results.append({
                    "function": "resolve_ip_to_hostname", 
                    "arguments": {"ip_address": ip},
                    "result": result
                })
            
            if function_results:
                # Enhance response with function results
                enhanced_response = response + "\n\n" + self._format_function_results(function_results)
                return {
                    "success": True,
                    "response": enhanced_response,
                    "function_calls": function_results,
                    "has_function_calls": True,
                    "auto_detected": True
                }
        
        return {
            "success": True,
            "response": response,
            "has_function_calls": False
        }
    
    def _format_function_results(self, function_results: List[Dict]) -> str:
        """Format function results for user display"""
        formatted = "\n📡 Network Resolution Results:\n"
        
        for result in function_results:
            func_name = result["function"]
            args = result["arguments"]
            res = result["result"]
            
            if res["success"]:
                if func_name == "resolve_hostname_to_ip":
                    formatted += f"🌐 {args['hostname']} → {res['ip_address']} (via {res['source']})\n"
                elif func_name == "resolve_ip_to_hostname":
                    formatted += f"🔍 {args['ip_address']} → {res['hostname']} (via {res['source']})\n"
            else:
                formatted += f"❌ Failed to resolve {list(args.values())[0]}: {res['error']}\n"
        
        return formatted
    
    def interactive_chat(self):
        """
        Start an interactive chat session with function calling
        """
        print(f"\n🤖 Ollama Network Assistant")
        print(f"Connected to: {self.base_url}")
        print(f"Model: {self.model}")
        print("Ask me about network resolution, IP addresses, hostnames, etc.")
        print("Type 'quit' to exit\n")
        
        while True:
            try:
                user_input = input("You: ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    print("👋 Goodbye!")
                    break
                
                if not user_input:
                    continue
                
                print("🤔 Thinking...")
                response = self.chat_with_functions(user_input)
                
                if response["success"]:
                    print(f"\n🤖 Assistant: {response['response']}")
                    
                    if response.get("has_function_calls"):
                        print("\n📊 Function Execution Details:")
                        for func_call in response.get("function_calls", []):
                            print(f"  • {func_call['function']}: {func_call['result']['success']}")
                else:
                    print(f"\n❌ Error: {response['error']}")
                
                print()  # Add spacing
                
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                break
            except Exception as e:
                print(f"\n❌ Unexpected error: {e}")

def main():
    """Main function to test Ollama integration"""
    
    print("🚀 Ollama Network Agent Setup")
    print("=" * 40)
    
    # Initialize the agent
    agent = OllamaNetworkAgent(
        ollama_host="agx0",
        ollama_port=11434,
        model="llama3.2",  # Adjust based on your available models
        use_router_data=True
    )
    
    # Test connection
    if not agent.test_ollama_connection():
        print("\n❌ Cannot connect to Ollama server.")
        print("Please ensure:")
        print("1. Ollama is running on agx0:11434")
        print("2. The host 'agx0' is reachable from this machine")
        print("3. Port 11434 is open")
        return
    
    print("\n🧪 Testing Network Functions:")
    print("-" * 30)
    
    # Test direct function calls
    result = agent.resolve_hostname_to_ip("google.com")
    print(f"Direct function test: google.com -> {result['ip_address'] if result['success'] else result['error']}")
    
    print("\n🗣️ Testing Chat with Functions:")
    print("-" * 30)
    
    # Test chat with function calling
    test_message = "What is the IP address of github.com?"
    response = agent.chat_with_functions(test_message)
    
    if response["success"]:
        print(f"User: {test_message}")
        print(f"Assistant: {response['response']}")
        
        if response.get("has_function_calls"):
            print(f"Functions executed: {len(response['function_calls'])}")
    else:
        print(f"Chat test failed: {response['error']}")
    
    print("\n" + "=" * 40)
    print("Setup complete! You can now use:")
    print("1. agent.chat_with_functions('your message') - for programmatic use")
    print("2. agent.interactive_chat() - for interactive chat session")
    
    # Ask if user wants to start interactive session
    start_interactive = input("\n🎯 Start interactive chat session? (y/n): ").lower().strip()
    if start_interactive in ['y', 'yes']:
        agent.interactive_chat()

if __name__ == "__main__":
    main()
