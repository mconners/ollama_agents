#!/usr/bin/env python3
"""
OpenWRT Web Interface Query Module
Enhanced web-based querying for OpenWRT routers
"""

import json
import re
import time
from typing import Dict, List, Optional, Tuple
from urllib.parse import urljoin, urlparse
import logging

try:
    import requests
    from requests.auth import HTTPBasicAuth, HTTPDigestAuth
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False


class OpenWRTWebAuth:
    """Handle OpenWRT web authentication"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.session = requests.Session() if REQUESTS_AVAILABLE else None
        self.authenticated = False
        self.base_url = self._get_base_url()
        
    def _get_base_url(self) -> str:
        """Get base URL for router"""
        protocol = "https" if self.config.get('use_https', False) else "http"
        port = self.config.get('web_port', 80)
        router_ip = self.config['router_ip']
        
        if (protocol == "http" and port == 80) or (protocol == "https" and port == 443):
            return f"{protocol}://{router_ip}"
        else:
            return f"{protocol}://{router_ip}:{port}"
    
    def authenticate(self) -> bool:
        """Authenticate with OpenWRT web interface"""
        if not REQUESTS_AVAILABLE:
            raise ImportError("requests library required for web interface")
            
        try:
            # Try to access the main page first
            response = self.session.get(
                self.base_url,
                timeout=self.config.get('timeout', 30),
                verify=False  # Ignore SSL certificate issues
            )
            
            # Check if we're redirected to login page
            if 'login' in response.url.lower() or response.status_code == 401:
                return self._perform_login()
            elif response.status_code == 200:
                self.authenticated = True
                return True
                
        except requests.RequestException as e:
            logging.error(f"Web authentication error: {e}")
            
        return False
        
    def _perform_login(self) -> bool:
        """Perform login to OpenWRT web interface"""
        login_data = {
            'luci_username': self.config.get('router_user', 'root'),
            'luci_password': self.config.get('router_password', ''),
        }
        
        try:
            # Try LuCI login endpoint
            login_url = urljoin(self.base_url, '/cgi-bin/luci/')
            response = self.session.post(
                login_url,
                data=login_data,
                timeout=self.config.get('timeout', 30),
                verify=False
            )
            
            if response.status_code == 200 and 'login' not in response.url.lower():
                self.authenticated = True
                logging.info("Successfully authenticated to OpenWRT web interface")
                return True
                
            # Try alternative login methods
            for endpoint in ['/cgi-bin/luci/admin/system/admin', '/login']:
                login_url = urljoin(self.base_url, endpoint)
                response = self.session.post(
                    login_url,
                    data=login_data,
                    timeout=self.config.get('timeout', 30),
                    verify=False
                )
                
                if response.status_code == 200 and 'login' not in response.url.lower():
                    self.authenticated = True
                    logging.info(f"Successfully authenticated via {endpoint}")
                    return True
                    
        except requests.RequestException as e:
            logging.error(f"Login error: {e}")
            
        return False


class OpenWRTWebQuery:
    """Query OpenWRT router via web interface"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.auth = OpenWRTWebAuth(config)
        
    def get_dhcp_clients(self) -> List[Dict]:
        """Get DHCP clients from web interface"""
        if not self.auth.authenticate():
            raise ConnectionError("Failed to authenticate to router web interface")
            
        devices = []
        
        # Try different endpoints for DHCP client information
        endpoints = [
            '/cgi-bin/luci/admin/status/overview',
            '/cgi-bin/luci/admin/network/dhcp',
            '/cgi-bin/luci/admin/status/processes',
            '/status/dhcp_clients',
            '/api/dhcp/clients'
        ]
        
        for endpoint in endpoints:
            try:
                devices = self._query_endpoint(endpoint)
                if devices:
                    logging.info(f"Successfully retrieved {len(devices)} devices from {endpoint}")
                    break
            except Exception as e:
                logging.debug(f"Failed to query {endpoint}: {e}")
                continue
                
        return devices
        
    def _query_endpoint(self, endpoint: str) -> List[Dict]:
        """Query specific endpoint for device information"""
        url = urljoin(self.auth.base_url, endpoint)
        
        try:
            response = self.auth.session.get(
                url,
                timeout=self.config.get('timeout', 30),
                verify=False
            )
            
            if response.status_code == 200:
                return self._parse_response(response.text, endpoint)
                
        except requests.RequestException as e:
            logging.debug(f"Request to {url} failed: {e}")
            
        return []
        
    def _parse_response(self, content: str, endpoint: str) -> List[Dict]:
        """Parse response content based on endpoint"""
        devices = []
        
        try:
            # Try parsing as JSON first
            if content.strip().startswith('{') or content.strip().startswith('['):
                json_data = json.loads(content)
                devices = self._parse_json_response(json_data, endpoint)
            else:
                # Parse HTML content
                devices = self._parse_html_response(content, endpoint)
                
        except Exception as e:
            logging.debug(f"Failed to parse response from {endpoint}: {e}")
            
        return devices
        
    def _parse_json_response(self, data: Dict, endpoint: str) -> List[Dict]:
        """Parse JSON response for device information"""
        devices = []
        
        # Handle different JSON structures
        if isinstance(data, list):
            for item in data:
                if isinstance(item, dict) and 'ip' in item:
                    devices.append(self._extract_device_info(item))
        elif isinstance(data, dict):
            # Look for device arrays in various keys
            for key in ['clients', 'devices', 'dhcp_clients', 'leases']:
                if key in data and isinstance(data[key], list):
                    for item in data[key]:
                        if isinstance(item, dict):
                            devices.append(self._extract_device_info(item))
                            
        return devices
        
    def _parse_html_response(self, content: str, endpoint: str) -> List[Dict]:
        """Parse HTML response for device information"""
        devices = []
        
        # Common patterns for extracting device information from HTML
        patterns = [
            # Pattern for IP, MAC, Hostname in table rows
            r'<tr[^>]*>.*?(\d+\.\d+\.\d+\.\d+).*?([0-9a-fA-F:]{17}).*?([^<>\s]+).*?</tr>',
            # Pattern for JSON embedded in JavaScript
            r'var\s+\w+\s*=\s*(\[.*?\]);',
            r'dhcp_clients\s*[:=]\s*(\[.*?\])',
            # Pattern for DHCP lease information
            r'(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F:]{17})\s+([^\s<>]+)'
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, content, re.IGNORECASE | re.DOTALL)
            for match in matches:
                try:
                    if match.group(1).startswith('['):
                        # JSON array found
                        json_data = json.loads(match.group(1))
                        for item in json_data:
                            if isinstance(item, dict):
                                devices.append(self._extract_device_info(item))
                    else:
                        # Individual device info
                        device_info = {
                            'ip_address': match.group(1),
                            'mac_address': match.group(2) if len(match.groups()) >= 2 else '',
                            'hostname': match.group(3) if len(match.groups()) >= 3 else 'Unknown'
                        }
                        devices.append(device_info)
                except Exception as e:
                    logging.debug(f"Failed to parse match: {e}")
                    
        return devices
        
    def _extract_device_info(self, data: Dict) -> Dict:
        """Extract device information from various data formats"""
        device = {}
        
        # Map various key names to standard format
        key_mappings = {
            'ip_address': ['ip', 'ipaddr', 'ip_address', 'address'],
            'hostname': ['hostname', 'name', 'device_name', 'client_name'],
            'mac_address': ['mac', 'macaddr', 'mac_address', 'hwaddr'],
            'lease_time': ['lease', 'lease_time', 'expires', 'expiry']
        }
        
        for standard_key, possible_keys in key_mappings.items():
            for key in possible_keys:
                if key in data and data[key]:
                    device[standard_key] = str(data[key])
                    break
                    
        # Set defaults for missing information
        device.setdefault('ip_address', 'Unknown')
        device.setdefault('hostname', 'Unknown')
        device.setdefault('mac_address', 'Unknown')
        
        return device
        
    def get_system_info(self) -> Dict:
        """Get router system information"""
        if not self.auth.authenticate():
            return {}
            
        try:
            response = self.auth.session.get(
                urljoin(self.auth.base_url, '/cgi-bin/luci/admin/status/overview'),
                timeout=self.config.get('timeout', 30),
                verify=False
            )
            
            if response.status_code == 200:
                return self._parse_system_info(response.text)
                
        except Exception as e:
            logging.error(f"Failed to get system info: {e}")
            
        return {}
        
    def _parse_system_info(self, content: str) -> Dict:
        """Parse system information from HTML"""
        info = {}
        
        # Extract common system information
        patterns = {
            'model': r'Model[:\s]*([^<>\n]+)',
            'firmware': r'Firmware[:\s]*([^<>\n]+)',
            'kernel': r'Kernel[:\s]*([^<>\n]+)',
            'uptime': r'Uptime[:\s]*([^<>\n]+)',
            'load': r'Load[:\s]*([^<>\n]+)'
        }
        
        for key, pattern in patterns.items():
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                info[key] = match.group(1).strip()
                
        return info
