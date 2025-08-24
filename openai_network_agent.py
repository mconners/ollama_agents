#!/usr/bin/env python3
"""
OpenAI-Compliant Network Resolution Agent
Provides hostname to IP and IP to hostname resolution capabilities
Compatible with OpenAI's function calling interface
"""

import json
import socket
import subprocess
import ipaddress
import logging
import time
from typing import Dict, List, Optional, Union, Any
from dataclasses import dataclass, asdict
from pathlib import Path
import sys
import os

# Import our existing router functionality
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
try:
    from openwrt_query import RouterQueryManager
    ROUTER_AVAILABLE = True
except ImportError:
    ROUTER_AVAILABLE = False

@dataclass
class ResolutionResult:
    """Standard result format for all resolution operations"""
    success: bool
    query: str
    result: Optional[str] = None
    source: str = "unknown"
    additional_info: Optional[Dict] = None
    error: Optional[str] = None
    timestamp: float = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()

class NetworkResolutionAgent:
    """OpenAI-compliant agent for network hostname/IP resolution"""
    
    def __init__(self, use_router_data: bool = True, router_config_path: str = None):
        """
        Initialize the network resolution agent
        
        Args:
            use_router_data: Whether to use router data for local network resolution
            router_config_path: Path to router configuration file
        """
        self.use_router_data = use_router_data and ROUTER_AVAILABLE
        self.router_config_path = router_config_path
        self.router_manager = None
        self.cached_devices = {}
        self.cache_timestamp = 0
        self.cache_ttl = 300  # 5 minutes
        
        self.setup_logging()
        
        if self.use_router_data:
            self._init_router_manager()
    
    def setup_logging(self):
        """Setup logging for the agent"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def _init_router_manager(self):
        """Initialize router manager if available"""
        try:
            if ROUTER_AVAILABLE:
                self.router_manager = RouterQueryManager()
                self.logger.info("Router manager initialized for local network queries")
        except Exception as e:
            self.logger.warning(f"Could not initialize router manager: {e}")
            self.use_router_data = False
    
    def _refresh_router_cache(self) -> bool:
        """Refresh the router device cache if needed"""
        current_time = time.time()
        if current_time - self.cache_timestamp > self.cache_ttl:
            try:
                if self.router_manager:
                    devices = self.router_manager.get_connected_devices()
                    self.cached_devices = {
                        device.hostname.lower(): device.ip_address for device in devices
                    }
                    # Also create IP to hostname mapping
                    self.cached_devices.update({
                        device.ip_address: device.hostname for device in devices
                    })
                    self.cache_timestamp = current_time
                    self.logger.info(f"Refreshed router cache with {len(devices)} devices")
                    return True
            except Exception as e:
                self.logger.error(f"Failed to refresh router cache: {e}")
        return len(self.cached_devices) > 0
    
    def resolve_hostname_to_ip(self, hostname: str, include_router_data: bool = True) -> ResolutionResult:
        """
        Resolve a hostname to IP address
        
        Args:
            hostname: The hostname to resolve
            include_router_data: Whether to check local router data first
            
        Returns:
            ResolutionResult with the IP address or error information
        """
        hostname = hostname.strip().lower()
        
        # First try router data for local network devices
        if include_router_data and self.use_router_data:
            if self._refresh_router_cache() and hostname in self.cached_devices:
                ip = self.cached_devices[hostname]
                if self._is_valid_ip(ip):  # Make sure it's actually an IP, not another hostname
                    return ResolutionResult(
                        success=True,
                        query=hostname,
                        result=ip,
                        source="router_data",
                        additional_info={"cache_age": time.time() - self.cache_timestamp}
                    )
        
        # Try DNS resolution
        try:
            ip_address = socket.gethostbyname(hostname)
            additional_info = {"method": "dns_lookup"}
            
            # Get additional DNS information if possible
            try:
                addr_info = socket.getaddrinfo(hostname, None)
                additional_info["address_family"] = addr_info[0][0] if addr_info else None
            except:
                pass
                
            return ResolutionResult(
                success=True,
                query=hostname,
                result=ip_address,
                source="dns",
                additional_info=additional_info
            )
        except socket.gaierror as e:
            return ResolutionResult(
                success=False,
                query=hostname,
                source="dns",
                error=f"DNS resolution failed: {str(e)}"
            )
        except Exception as e:
            return ResolutionResult(
                success=False,
                query=hostname,
                source="dns",
                error=f"Unexpected error: {str(e)}"
            )
    
    def resolve_ip_to_hostname(self, ip_address: str, include_router_data: bool = True) -> ResolutionResult:
        """
        Resolve an IP address to hostname
        
        Args:
            ip_address: The IP address to resolve
            include_router_data: Whether to check local router data first
            
        Returns:
            ResolutionResult with the hostname or error information
        """
        ip_address = ip_address.strip()
        
        # Validate IP address format
        if not self._is_valid_ip(ip_address):
            return ResolutionResult(
                success=False,
                query=ip_address,
                source="validation",
                error="Invalid IP address format"
            )
        
        # First try router data for local network devices
        if include_router_data and self.use_router_data:
            if self._refresh_router_cache() and ip_address in self.cached_devices:
                hostname = self.cached_devices[ip_address]
                if not self._is_valid_ip(hostname):  # Make sure it's actually a hostname, not another IP
                    return ResolutionResult(
                        success=True,
                        query=ip_address,
                        result=hostname,
                        source="router_data",
                        additional_info={"cache_age": time.time() - self.cache_timestamp}
                    )
        
        # Try reverse DNS lookup
        try:
            hostname, _, _ = socket.gethostbyaddr(ip_address)
            return ResolutionResult(
                success=True,
                query=ip_address,
                result=hostname,
                source="reverse_dns",
                additional_info={"method": "reverse_dns_lookup"}
            )
        except socket.herror as e:
            # Try alternative methods for local networks
            if self._is_private_ip(ip_address):
                # Try ping with hostname resolution
                hostname = self._try_ping_hostname_resolution(ip_address)
                if hostname:
                    return ResolutionResult(
                        success=True,
                        query=ip_address,
                        result=hostname,
                        source="ping_resolution",
                        additional_info={"method": "ping_hostname"}
                    )
            
            return ResolutionResult(
                success=False,
                query=ip_address,
                source="reverse_dns",
                error=f"Reverse DNS lookup failed: {str(e)}"
            )
        except Exception as e:
            return ResolutionResult(
                success=False,
                query=ip_address,
                source="reverse_dns",
                error=f"Unexpected error: {str(e)}"
            )
    
    def bulk_resolve(self, queries: List[str], auto_detect_type: bool = True) -> List[ResolutionResult]:
        """
        Resolve multiple hostnames or IP addresses
        
        Args:
            queries: List of hostnames or IP addresses
            auto_detect_type: Automatically detect if input is hostname or IP
            
        Returns:
            List of ResolutionResult objects
        """
        results = []
        for query in queries:
            if auto_detect_type:
                if self._is_valid_ip(query):
                    result = self.resolve_ip_to_hostname(query)
                else:
                    result = self.resolve_hostname_to_ip(query)
            else:
                # If auto-detection is off, treat as hostname by default
                result = self.resolve_hostname_to_ip(query)
            results.append(result)
        return results
    
    def get_network_info(self, target: str) -> ResolutionResult:
        """
        Get comprehensive network information about a target
        
        Args:
            target: Hostname or IP address
            
        Returns:
            ResolutionResult with comprehensive network information
        """
        is_ip = self._is_valid_ip(target)
        
        info = {
            "input_type": "ip_address" if is_ip else "hostname",
            "is_private": False,
            "is_local": False,
            "ping_successful": False
        }
        
        try:
            if is_ip:
                # Start with IP, get hostname
                hostname_result = self.resolve_ip_to_hostname(target, include_router_data=True)
                info["ip_address"] = target
                info["hostname"] = hostname_result.result if hostname_result.success else None
                info["is_private"] = self._is_private_ip(target)
            else:
                # Start with hostname, get IP
                ip_result = self.resolve_hostname_to_ip(target, include_router_data=True)
                info["hostname"] = target
                info["ip_address"] = ip_result.result if ip_result.success else None
                if info["ip_address"]:
                    info["is_private"] = self._is_private_ip(info["ip_address"])
            
            # Test connectivity
            if info["ip_address"]:
                info["ping_successful"] = self._ping_host(info["ip_address"])
                info["is_local"] = info["is_private"] and info["ping_successful"]
            
            # Get additional router information if available
            if self.use_router_data and info["is_private"]:
                self._refresh_router_cache()
                # Look for additional device information
                for device_key, device_value in self.cached_devices.items():
                    if device_key == target or device_value == target:
                        info["found_in_router"] = True
                        break
                else:
                    info["found_in_router"] = False
            
            return ResolutionResult(
                success=True,
                query=target,
                result=None,  # Complex result in additional_info
                source="network_info",
                additional_info=info
            )
            
        except Exception as e:
            return ResolutionResult(
                success=False,
                query=target,
                source="network_info",
                error=f"Network info gathering failed: {str(e)}"
            )
    
    def _is_valid_ip(self, ip_string: str) -> bool:
        """Check if string is a valid IP address"""
        try:
            ipaddress.ip_address(ip_string)
            return True
        except ValueError:
            return False
    
    def _is_private_ip(self, ip_string: str) -> bool:
        """Check if IP address is in private range"""
        try:
            ip = ipaddress.ip_address(ip_string)
            return ip.is_private
        except ValueError:
            return False
    
    def _ping_host(self, host: str, timeout: int = 3) -> bool:
        """Ping a host to check if it's reachable"""
        try:
            result = subprocess.run(
                ['ping', '-c', '1', '-W', str(timeout), host],
                capture_output=True,
                text=True,
                timeout=timeout + 2
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False
    
    def _try_ping_hostname_resolution(self, ip_address: str) -> Optional[str]:
        """Try to get hostname through ping command"""
        try:
            result = subprocess.run(
                ['ping', '-c', '1', '-a', ip_address],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                # Parse output for hostname
                lines = result.stdout.split('\n')
                for line in lines:
                    if 'PING' in line and '(' in line:
                        # Extract hostname from "PING hostname (ip_address)"
                        hostname = line.split('PING')[1].split('(')[0].strip()
                        if hostname and hostname != ip_address:
                            return hostname
        except:
            pass
        return None

    # OpenAI Function Calling Schemas
    @staticmethod
    def get_openai_function_schemas() -> List[Dict[str, Any]]:
        """
        Get OpenAI-compatible function schemas for this agent
        
        Returns:
            List of function schema dictionaries
        """
        return [
            {
                "name": "resolve_hostname_to_ip",
                "description": "Resolve a hostname to its IP address using DNS lookup and local network data",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "hostname": {
                            "type": "string",
                            "description": "The hostname to resolve (e.g., 'google.com', 'router.local', 'my-laptop')"
                        },
                        "include_router_data": {
                            "type": "boolean",
                            "description": "Whether to check local router/network data first for faster resolution",
                            "default": True
                        }
                    },
                    "required": ["hostname"]
                }
            },
            {
                "name": "resolve_ip_to_hostname",
                "description": "Resolve an IP address to its hostname using reverse DNS and local network data",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "ip_address": {
                            "type": "string",
                            "description": "The IP address to resolve (e.g., '192.168.1.100', '8.8.8.8')"
                        },
                        "include_router_data": {
                            "type": "boolean",
                            "description": "Whether to check local router/network data first for faster resolution",
                            "default": True
                        }
                    },
                    "required": ["ip_address"]
                }
            },
            {
                "name": "bulk_resolve",
                "description": "Resolve multiple hostnames or IP addresses in a single request",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "queries": {
                            "type": "array",
                            "items": {
                                "type": "string"
                            },
                            "description": "List of hostnames or IP addresses to resolve"
                        },
                        "auto_detect_type": {
                            "type": "boolean",
                            "description": "Automatically detect whether each query is a hostname or IP address",
                            "default": True
                        }
                    },
                    "required": ["queries"]
                }
            },
            {
                "name": "get_network_info",
                "description": "Get comprehensive network information about a hostname or IP address",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "target": {
                            "type": "string",
                            "description": "The hostname or IP address to analyze"
                        }
                    },
                    "required": ["target"]
                }
            }
        ]

    def execute_function(self, function_name: str, **kwargs) -> Dict[str, Any]:
        """
        Execute a function by name with given arguments
        Compatible with OpenAI function calling
        
        Args:
            function_name: Name of the function to execute
            **kwargs: Arguments to pass to the function
            
        Returns:
            Dictionary with function result
        """
        try:
            if function_name == "resolve_hostname_to_ip":
                result = self.resolve_hostname_to_ip(**kwargs)
            elif function_name == "resolve_ip_to_hostname":
                result = self.resolve_ip_to_hostname(**kwargs)
            elif function_name == "bulk_resolve":
                results = self.bulk_resolve(**kwargs)
                return {
                    "success": True,
                    "function": function_name,
                    "results": [asdict(r) for r in results],
                    "count": len(results)
                }
            elif function_name == "get_network_info":
                result = self.get_network_info(**kwargs)
            else:
                return {
                    "success": False,
                    "function": function_name,
                    "error": f"Unknown function: {function_name}"
                }
            
            return {
                "success": True,
                "function": function_name,
                **asdict(result)
            }
            
        except Exception as e:
            return {
                "success": False,
                "function": function_name,
                "error": f"Function execution failed: {str(e)}"
            }

def create_openai_agent_instance(use_router_data: bool = True) -> NetworkResolutionAgent:
    """Factory function to create a configured agent instance"""
    return NetworkResolutionAgent(use_router_data=use_router_data)

# Example usage and testing
if __name__ == "__main__":
    # Create agent
    agent = create_openai_agent_instance(use_router_data=True)
    
    print("OpenAI Network Resolution Agent")
    print("=" * 40)
    
    # Show available functions
    print("\nAvailable OpenAI Functions:")
    schemas = agent.get_openai_function_schemas()
    for schema in schemas:
        print(f"- {schema['name']}: {schema['description']}")
    
    print(f"\nFull Function Schemas (for OpenAI integration):")
    print(json.dumps(schemas, indent=2))
    
    # Test some example queries
    print(f"\nTesting Resolution Functions:")
    print("-" * 30)
    
    # Test hostname to IP
    result = agent.resolve_hostname_to_ip("google.com")
    print(f"Hostname to IP: google.com -> {result.result if result.success else result.error}")
    
    # Test IP to hostname  
    result = agent.resolve_ip_to_hostname("8.8.8.8")
    print(f"IP to Hostname: 8.8.8.8 -> {result.result if result.success else result.error}")
    
    # Test local network (if available)
    result = agent.resolve_hostname_to_ip("router.local")
    print(f"Local network: router.local -> {result.result if result.success else result.error}")
    
    # Test network info
    result = agent.get_network_info("google.com")
    if result.success and result.additional_info:
        info = result.additional_info
        print(f"Network info for google.com:")
        print(f"  - IP: {info.get('ip_address')}")
        print(f"  - Private: {info.get('is_private')}")
        print(f"  - Reachable: {info.get('ping_successful')}")
