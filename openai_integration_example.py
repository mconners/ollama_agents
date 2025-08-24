#!/usr/bin/env python3
"""
OpenAI Integration Example for Network Resolution Agent
Shows how to integrate the NetworkResolutionAgent with OpenAI's function calling
"""

import json
import os
from typing import Dict, List, Any, Optional
from openai_network_agent import NetworkResolutionAgent, create_openai_agent_instance

class OpenAINetworkAgentWrapper:
    """
    Wrapper class for integrating NetworkResolutionAgent with OpenAI
    Provides a clean interface for OpenAI function calling
    """
    
    def __init__(self, use_router_data: bool = True):
        self.agent = create_openai_agent_instance(use_router_data=use_router_data)
        self.function_schemas = self.agent.get_openai_function_schemas()
        
    def get_functions_for_openai(self) -> List[Dict[str, Any]]:
        """Get function definitions for OpenAI API calls"""
        return self.function_schemas
    
    def execute_function_call(self, function_call: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a function call from OpenAI
        
        Args:
            function_call: Dictionary with 'name' and 'arguments' keys
            
        Returns:
            Dictionary with execution results
        """
        function_name = function_call.get('name')
        
        # Parse arguments (might be JSON string)
        arguments = function_call.get('arguments', {})
        if isinstance(arguments, str):
            try:
                arguments = json.loads(arguments)
            except json.JSONDecodeError:
                return {
                    "success": False,
                    "error": "Invalid JSON in function arguments"
                }
        
        return self.agent.execute_function(function_name, **arguments)
    
    def handle_multiple_function_calls(self, function_calls: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Handle multiple function calls in sequence"""
        results = []
        for function_call in function_calls:
            result = self.execute_function_call(function_call)
            results.append(result)
        return results

def example_openai_integration():
    """
    Example showing how to integrate with OpenAI's function calling
    This would be used in conjunction with the OpenAI Python client
    """
    
    print("OpenAI Network Agent Integration Example")
    print("=" * 50)
    
    # Create the wrapper
    wrapper = OpenAINetworkAgentWrapper(use_router_data=True)
    
    # Get function definitions for OpenAI
    functions = wrapper.get_functions_for_openai()
    
    print("Available Functions for OpenAI:")
    for i, func in enumerate(functions, 1):
        print(f"{i}. {func['name']}")
        print(f"   Description: {func['description']}")
        print()
    
    # Simulate function calls that would come from OpenAI
    print("Simulating OpenAI Function Calls:")
    print("-" * 40)
    
    # Example 1: Hostname to IP
    function_call_1 = {
        "name": "resolve_hostname_to_ip",
        "arguments": {
            "hostname": "google.com",
            "include_router_data": True
        }
    }
    
    result_1 = wrapper.execute_function_call(function_call_1)
    print("1. Resolve google.com to IP:")
    print(f"   Success: {result_1['success']}")
    if result_1['success']:
        print(f"   Result: {result_1['result']}")
        print(f"   Source: {result_1['source']}")
    else:
        print(f"   Error: {result_1['error']}")
    print()
    
    # Example 2: IP to Hostname
    function_call_2 = {
        "name": "resolve_ip_to_hostname",
        "arguments": {
            "ip_address": "8.8.8.8"
        }
    }
    
    result_2 = wrapper.execute_function_call(function_call_2)
    print("2. Resolve 8.8.8.8 to hostname:")
    print(f"   Success: {result_2['success']}")
    if result_2['success']:
        print(f"   Result: {result_2['result']}")
        print(f"   Source: {result_2['source']}")
    else:
        print(f"   Error: {result_2['error']}")
    print()
    
    # Example 3: Bulk Resolution
    function_call_3 = {
        "name": "bulk_resolve",
        "arguments": {
            "queries": ["google.com", "8.8.8.8", "github.com", "192.168.1.1"],
            "auto_detect_type": True
        }
    }
    
    result_3 = wrapper.execute_function_call(function_call_3)
    print("3. Bulk resolve multiple targets:")
    print(f"   Success: {result_3['success']}")
    if result_3['success']:
        print(f"   Processed: {result_3['count']} items")
        for i, res in enumerate(result_3['results']):
            status = "✓" if res['success'] else "✗"
            result_text = res['result'] if res['success'] else res['error']
            print(f"   {status} {res['query']} -> {result_text}")
    print()
    
    # Example 4: Network Info
    function_call_4 = {
        "name": "get_network_info",
        "arguments": {
            "target": "google.com"
        }
    }
    
    result_4 = wrapper.execute_function_call(function_call_4)
    print("4. Get network info for google.com:")
    print(f"   Success: {result_4['success']}")
    if result_4['success'] and result_4['additional_info']:
        info = result_4['additional_info']
        print(f"   Type: {info.get('input_type')}")
        print(f"   IP: {info.get('ip_address')}")
        print(f"   Hostname: {info.get('hostname')}")
        print(f"   Private: {info.get('is_private')}")
        print(f"   Reachable: {info.get('ping_successful')}")
    print()

def create_openai_client_example():
    """
    Example of how to use this with the actual OpenAI Python client
    Note: This requires the 'openai' package and valid API key
    """
    
    example_code = '''
import openai
from openai_integration_example import OpenAINetworkAgentWrapper

# Initialize the agent wrapper
agent_wrapper = OpenAINetworkAgentWrapper(use_router_data=True)

# Get function definitions
functions = agent_wrapper.get_functions_for_openai()

# Example OpenAI client usage (requires openai package and API key)
client = openai.OpenAI(api_key="your-api-key-here")

# Create a chat completion with function calling
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {
            "role": "user", 
            "content": "What is the IP address of google.com and can you tell me if it's reachable?"
        }
    ],
    functions=functions,
    function_call="auto"
)

# Handle function calls in the response
if response.choices[0].message.function_call:
    function_call = response.choices[0].message.function_call
    
    # Execute the function using our agent
    result = agent_wrapper.execute_function_call({
        "name": function_call.name,
        "arguments": function_call.arguments
    })
    
    # Send the result back to OpenAI for the final response
    second_response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {
                "role": "user",
                "content": "What is the IP address of google.com and can you tell me if it's reachable?"
            },
            response.choices[0].message,
            {
                "role": "function",
                "name": function_call.name,
                "content": json.dumps(result)
            }
        ]
    )
    
    print(second_response.choices[0].message.content)
'''
    
    print("OpenAI Client Integration Example:")
    print("=" * 40)
    print(example_code)

def generate_function_schemas_json():
    """Generate JSON file with function schemas for external use"""
    wrapper = OpenAINetworkAgentWrapper(use_router_data=True)
    functions = wrapper.get_functions_for_openai()
    
    schemas_file = Path("output/openai_function_schemas.json")
    
    with open(schemas_file, 'w') as f:
        json.dump({
            "description": "OpenAI Function Calling Schemas for Network Resolution Agent",
            "functions": functions,
            "usage_example": {
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
                        "auto_detect_type": True
                    }
                },
                "network_info": {
                    "name": "get_network_info",
                    "arguments": {
                        "target": "google.com"
                    }
                }
            }
        }, f, indent=2)
    
    print(f"Function schemas saved to: {schemas_file}")
    return schemas_file

if __name__ == "__main__":
    from pathlib import Path
    
    # Run the integration example
    example_openai_integration()
    
    print("\n" + "=" * 50)
    
    # Show OpenAI client example
    create_openai_client_example()
    
    print("\n" + "=" * 50)
    
    # Generate schemas file
    generate_function_schemas_json()
    
    print("\nIntegration Setup Complete!")
    print("\nTo use with OpenAI:")
    print("1. Install OpenAI client: pip install openai")
    print("2. Set your OpenAI API key")
    print("3. Use the function schemas and wrapper as shown above")
    print("4. The agent will automatically use router data for local network queries")
    print("5. Check output/openai_function_schemas.json for the complete schema definitions")
