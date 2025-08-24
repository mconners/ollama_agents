# Unified AI API Client
# Python client library for the distributed AI system

import requests
import json
import time
from typing import Dict, List, Optional, Union, Iterator
from dataclasses import dataclass
import websocket
import threading

@dataclass
class AIResponse:
    """Response from AI services"""
    content: str
    model: str
    service: str
    tokens_used: Optional[int] = None
    response_time: Optional[float] = None
    metadata: Optional[Dict] = None

class DistributedAIClient:
    """
    Unified client for the distributed AI system
    Provides access to coding assistance, chat, and image generation
    """
    
    def __init__(self, gateway_url: str = "http://192.168.1.147"):
        """
        Initialize the AI client
        
        Args:
            gateway_url: Base URL of the API gateway (PI51)
        """
        self.gateway_url = gateway_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'DistributedAI-Client/1.0'
        })
        
    def _make_request(self, endpoint: str, data: Dict, timeout: int = 30) -> Dict:
        """Make HTTP request to the gateway"""
        url = f"{self.gateway_url}{endpoint}"
        start_time = time.time()
        
        try:
            response = self.session.post(url, json=data, timeout=timeout)
            response.raise_for_status()
            result = response.json()
            result['_response_time'] = time.time() - start_time
            return result
        except requests.exceptions.RequestException as e:
            raise Exception(f"API request failed: {e}")
    
    # ========== CODING ASSISTANT ==========
    
    def code_complete(self, code: str, language: str = "python", 
                     max_tokens: int = 500) -> AIResponse:
        """
        Get code completion suggestions
        
        Args:
            code: Partial code to complete
            language: Programming language
            max_tokens: Maximum tokens in response
        """
        data = {
            "action": "complete",
            "code": code,
            "language": language,
            "max_tokens": max_tokens
        }
        
        response = self._make_request("/api/v1/code", data, timeout=60)
        
        return AIResponse(
            content=response.get('completion', ''),
            model=response.get('model', 'codellama'),
            service='code_complete',
            tokens_used=response.get('tokens'),
            response_time=response.get('_response_time'),
            metadata={'language': language}
        )
    
    def code_review(self, code: str, language: str = "python") -> AIResponse:
        """
        Get code review and suggestions
        
        Args:
            code: Code to review
            language: Programming language
        """
        data = {
            "action": "review",
            "code": code,
            "language": language
        }
        
        response = self._make_request("/api/v1/code", data, timeout=90)
        
        return AIResponse(
            content=response.get('review', ''),
            model=response.get('model', 'codellama'),
            service='code_review',
            response_time=response.get('_response_time'),
            metadata={'language': language}
        )
    
    def code_debug(self, code: str, error_message: str, 
                   language: str = "python") -> AIResponse:
        """
        Get debugging help for code errors
        
        Args:
            code: Code with errors
            error_message: Error message received
            language: Programming language
        """
        data = {
            "action": "debug",
            "code": code,
            "error": error_message,
            "language": language
        }
        
        response = self._make_request("/api/v1/code", data, timeout=90)
        
        return AIResponse(
            content=response.get('solution', ''),
            model=response.get('model', 'codellama'),
            service='code_debug',
            response_time=response.get('_response_time'),
            metadata={'language': language, 'error': error_message}
        )
    
    # ========== GENERAL CHAT ==========
    
    def chat(self, message: str, conversation_id: Optional[str] = None,
             model: str = "llama3.2", max_tokens: int = 1000) -> AIResponse:
        """
        Send a chat message
        
        Args:
            message: User message
            conversation_id: Optional conversation ID for context
            model: Model to use (llama3.2, gpt-oss, etc.)
            max_tokens: Maximum tokens in response
        """
        data = {
            "model": model,
            "messages": [{"role": "user", "content": message}],
            "max_tokens": max_tokens,
            "conversation_id": conversation_id
        }
        
        response = self._make_request("/api/v1/chat/completions", data)
        
        # Extract content from OpenAI-compatible format
        content = ""
        if 'choices' in response and response['choices']:
            content = response['choices'][0]['message']['content']
        
        return AIResponse(
            content=content,
            model=response.get('model', model),
            service='chat',
            tokens_used=response.get('usage', {}).get('total_tokens'),
            response_time=response.get('_response_time')
        )
    
    def chat_stream(self, message: str, conversation_id: Optional[str] = None,
                   model: str = "llama3.2") -> Iterator[str]:
        """
        Stream chat response (if supported)
        
        Args:
            message: User message
            conversation_id: Optional conversation ID
            model: Model to use
            
        Yields:
            Chunks of the response as they arrive
        """
        data = {
            "model": model,
            "messages": [{"role": "user", "content": message}],
            "stream": True,
            "conversation_id": conversation_id
        }
        
        url = f"{self.gateway_url}/api/v1/chat/completions"
        
        with self.session.post(url, json=data, stream=True, timeout=180) as response:
            response.raise_for_status()
            for line in response.iter_lines():
                if line:
                    try:
                        chunk = json.loads(line.decode('utf-8'))
                        if 'choices' in chunk and chunk['choices']:
                            delta = chunk['choices'][0].get('delta', {})
                            if 'content' in delta:
                                yield delta['content']
                    except json.JSONDecodeError:
                        continue
    
    # ========== IMAGE GENERATION ==========
    
    def generate_image(self, prompt: str, negative_prompt: str = "",
                      width: int = 1024, height: int = 1024,
                      steps: int = 20, cfg_scale: float = 7.0) -> Dict:
        """
        Generate an image from text prompt
        
        Args:
            prompt: Text description of desired image
            negative_prompt: What to avoid in the image
            width: Image width
            height: Image height  
            steps: Number of inference steps
            cfg_scale: CFG scale for guidance
            
        Returns:
            Dict with image_url, generation_id, and metadata
        """
        data = {
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "width": width,
            "height": height,
            "steps": steps,
            "cfg_scale": cfg_scale
        }
        
        response = self._make_request("/api/v1/image/generate", data, timeout=300)
        return response
    
    def upscale_image(self, image_path: str, scale: int = 2) -> Dict:
        """
        Upscale an existing image
        
        Args:
            image_path: Path to image file  
            scale: Upscaling factor (2x, 4x)
            
        Returns:
            Dict with upscaled image info
        """
        # TODO: Implement image upload and upscaling
        raise NotImplementedError("Image upscaling not yet implemented")
    
    # ========== UTILITY METHODS ==========
    
    def health_check(self) -> Dict:
        """Check system health"""
        try:
            response = self.session.get(f"{self.gateway_url}/health", timeout=10)
            return {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "gateway": "online",
                "response_time": response.elapsed.total_seconds()
            }
        except requests.exceptions.RequestException as e:
            return {
                "status": "unhealthy",
                "gateway": "offline",
                "error": str(e)
            }
    
    def list_models(self) -> List[str]:
        """Get list of available models"""
        try:
            response = self.session.get(f"{self.gateway_url}/ollama/api/tags", timeout=10)
            if response.status_code == 200:
                data = response.json()
                return [model['name'] for model in data.get('models', [])]
        except:
            pass
        return []
    
    def get_system_status(self) -> Dict:
        """Get detailed system status"""
        try:
            response = self.session.get(f"{self.gateway_url}/api/v1/status", timeout=10)
            if response.status_code == 200:
                return response.json()
        except:
            pass
        
        return {
            "gateway": self.health_check(),
            "models": self.list_models(),
            "timestamp": time.time()
        }

# ========== USAGE EXAMPLES ==========

def example_usage():
    """Example usage of the distributed AI client"""
    
    # Initialize client
    client = DistributedAIClient("http://192.168.1.147")
    
    # Check system health
    print("🔍 System Health:")
    health = client.health_check()
    print(f"Gateway: {health['status']}")
    
    # List available models
    print("\n🤖 Available Models:")
    models = client.list_models()
    for model in models[:5]:  # Show first 5
        print(f"  - {model}")
    
    # ========== CODING ASSISTANT EXAMPLES ==========
    
    print("\n💻 Code Completion Example:")
    code_response = client.code_complete(
        code="def fibonacci(n):\n    if n <= 1:\n        return n\n    else:",
        language="python"
    )
    print(f"Model: {code_response.model}")
    print(f"Completion:\n{code_response.content}")
    
    print("\n🔍 Code Review Example:")
    review_response = client.code_review(
        code="""
def divide(a, b):
    return a / b
    
result = divide(10, 0)
print(result)
""",
        language="python"
    )
    print(f"Review:\n{review_response.content}")
    
    # ========== CHAT EXAMPLES ==========
    
    print("\n💬 Chat Example:")
    chat_response = client.chat(
        message="Explain quantum computing in simple terms",
        model="llama3.2"
    )
    print(f"Model: {chat_response.model}")
    print(f"Response: {chat_response.content[:200]}...")
    
    print("\n🌊 Streaming Chat Example:")
    print("Streaming response: ", end="", flush=True)
    for chunk in client.chat_stream("Tell me a short joke about AI"):
        print(chunk, end="", flush=True)
    print("\n")
    
    # ========== IMAGE GENERATION EXAMPLES ==========
    
    print("\n🎨 Image Generation Example:")
    try:
        image_response = client.generate_image(
            prompt="A futuristic robot writing code in a neon-lit room",
            width=512,
            height=512,
            steps=15
        )
        print(f"Image generated: {image_response.get('image_url', 'N/A')}")
    except Exception as e:
        print(f"Image generation error: {e}")

if __name__ == "__main__":
    example_usage()
