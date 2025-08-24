#!/usr/bin/env python3
"""
OpenWRT Router Query Tool
A virtual directory-based Python script to query Linksys router running OpenWRT
for IP addresses and hostnames.

Author: Assistant
"""

import os
import sys
import json
import time
import socket
import logging
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from pathlib import Path

# Virtual directory structure
VIRTUAL_DIRS = {
    'config': 'Configuration files and settings',
    'modules': 'Core functionality modules', 
    'utils': 'Utility functions',
    'output': 'Output and logging',
    'tests': 'Test files'
}

@dataclass
class RouterDevice:
    """Represents a device connected to the router"""
    ip_address: str
    hostname: str
    mac_address: str
    lease_time: Optional[str] = None
    interface: Optional[str] = None

class RouterConfig:
    """Configuration manager for router connection"""
    
    def __init__(self):
        self.config_file = Path('config/router_config.json')
        self.default_config = {
            "router_ip": "192.168.1.1",
            "router_user": "root",
            "router_password": "",
            "ssh_port": 22,
            "web_port": 80,
            "use_https": False,
            "timeout": 30,
            "method": "ssh"  # ssh, web, or both
        }
        self._ensure_virtual_dirs()
        
    def _ensure_virtual_dirs(self):
        """Create virtual directory structure"""
        for dir_name in VIRTUAL_DIRS.keys():
            os.makedirs(dir_name, exist_ok=True)
            
    def load_config(self) -> Dict:
        """Load configuration from file or create default"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults for missing keys
                    for key, value in self.default_config.items():
                        if key not in config:
                            config[key] = value
                    return config
            except Exception as e:
                logging.error(f"Error loading config: {e}")
                
        # Create default config file
        self.save_config(self.default_config)
        return self.default_config.copy()
        
    def save_config(self, config: Dict):
        """Save configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            logging.error(f"Error saving config: {e}")

class OpenWRTQuerySSH:
    """SSH-based querying for OpenWRT router"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.ssh_available = self._check_ssh_available()
        
    def _check_ssh_available(self) -> bool:
        """Check if paramiko is available for SSH connections"""
        try:
            import paramiko
            return True
        except ImportError:
            return False
            
    def query_dhcp_leases(self) -> List[RouterDevice]:
        """Query DHCP leases via SSH"""
        if not self.ssh_available:
            raise ImportError("paramiko required for SSH connections. Install with: pip install paramiko")
            
        import paramiko
        
        devices = []
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        try:
            ssh.connect(
                hostname=self.config['router_ip'],
                username=self.config['router_user'],
                password=self.config['router_password'],
                port=self.config['ssh_port'],
                timeout=self.config['timeout']
            )
            
            # Query DHCP leases
            stdin, stdout, stderr = ssh.exec_command('cat /tmp/dhcp.leases')
            leases_output = stdout.read().decode('utf-8')
            
            # Query ARP table for additional info
            stdin, stdout, stderr = ssh.exec_command('cat /proc/net/arp')
            arp_output = stdout.read().decode('utf-8')
            
            devices = self._parse_dhcp_leases(leases_output, arp_output)
            
        except Exception as e:
            logging.error(f"SSH connection error: {e}")
            raise
        finally:
            ssh.close()
            
        return devices
        
    def _parse_dhcp_leases(self, leases_data: str, arp_data: str) -> List[RouterDevice]:
        """Parse DHCP leases and ARP table data"""
        devices = []
        arp_map = {}
        
        # Parse ARP table for MAC addresses
        for line in arp_data.strip().split('\n')[1:]:  # Skip header
            parts = line.split()
            if len(parts) >= 4:
                ip = parts[0]
                mac = parts[3]
                arp_map[ip] = mac
                
        # Parse DHCP leases
        for line in leases_data.strip().split('\n'):
            if line.strip():
                parts = line.split()
                if len(parts) >= 4:
                    lease_time = parts[0]
                    mac_address = parts[1]
                    ip_address = parts[2]
                    hostname = parts[3] if parts[3] != '*' else f"device-{ip_address.split('.')[-1]}"
                    
                    device = RouterDevice(
                        ip_address=ip_address,
                        hostname=hostname,
                        mac_address=mac_address,
                        lease_time=lease_time
                    )
                    devices.append(device)
                    
        return devices

class OpenWRTQueryWeb:
    """Web interface-based querying for OpenWRT router"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.requests_available = self._check_requests_available()
        
    def _check_requests_available(self) -> bool:
        """Check if requests library is available"""
        try:
            import requests
            return True
        except ImportError:
            return False
            
    def query_dhcp_clients(self) -> List[RouterDevice]:
        """Query DHCP clients via web interface"""
        if not self.requests_available:
            raise ImportError("requests required for web connections. Install with: pip install requests")
            
        import requests
        from urllib.parse import urljoin
        
        protocol = "https" if self.config['use_https'] else "http"
        port = self.config['web_port']
        base_url = f"{protocol}://{self.config['router_ip']}:{port}"
        
        # This is a simplified approach - actual implementation would depend on
        # the specific OpenWRT web interface and authentication method
        logging.warning("Web interface querying is router-specific and may need customization")
        
        devices = []
        # Placeholder for web-based implementation
        # Would require parsing the specific web interface of your router
        
        return devices

class RouterQueryManager:
    """Main manager for router queries"""
    
    def __init__(self):
        self.config_manager = RouterConfig()
        self.config = self.config_manager.load_config()
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging configuration"""
        log_file = Path('output/router_query.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
    def get_connected_devices(self, method: Optional[str] = None) -> List[RouterDevice]:
        """Get list of connected devices using specified method"""
        query_method = method or self.config['method']
        devices = []
        
        try:
            if query_method == 'ssh' or query_method == 'both':
                ssh_query = OpenWRTQuerySSH(self.config)
                devices.extend(ssh_query.query_dhcp_leases())
                logging.info(f"Found {len(devices)} devices via SSH")
                
            if query_method == 'web' or query_method == 'both':
                web_query = OpenWRTQueryWeb(self.config)
                web_devices = web_query.query_dhcp_clients()
                # Merge devices, avoiding duplicates
                existing_ips = {device.ip_address for device in devices}
                for device in web_devices:
                    if device.ip_address not in existing_ips:
                        devices.append(device)
                        
        except Exception as e:
            logging.error(f"Error querying router: {e}")
            raise
            
        return devices
        
    def save_device_list(self, devices: List[RouterDevice], format_type: str = 'json'):
        """Save device list to file"""
        timestamp = int(time.time())
        
        if format_type == 'json':
            filename = f'output/devices_{timestamp}.json'
            data = [
                {
                    'ip_address': device.ip_address,
                    'hostname': device.hostname,
                    'mac_address': device.mac_address,
                    'lease_time': device.lease_time,
                    'interface': device.interface
                }
                for device in devices
            ]
            
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
                
        elif format_type == 'csv':
            filename = f'output/devices_{timestamp}.csv'
            with open(filename, 'w') as f:
                f.write('IP Address,Hostname,MAC Address,Lease Time\n')
                for device in devices:
                    f.write(f'{device.ip_address},{device.hostname},{device.mac_address},{device.lease_time}\n')
                    
        logging.info(f"Device list saved to {filename}")
        return filename
        
    def print_device_table(self, devices: List[RouterDevice]):
        """Print devices in a formatted table"""
        if not devices:
            print("No devices found.")
            return
            
        print(f"\n{'IP Address':<15} {'Hostname':<20} {'MAC Address':<18} {'Lease Time':<12}")
        print("-" * 67)
        
        for device in sorted(devices, key=lambda x: socket.inet_aton(x.ip_address)):
            lease_display = device.lease_time or "N/A"
            print(f"{device.ip_address:<15} {device.hostname:<20} {device.mac_address:<18} {lease_display:<12}")
            
        print(f"\nTotal devices: {len(devices)}")

def main():
    """Main entry point"""
    print("OpenWRT Router Query Tool")
    print("=" * 40)
    
    # Display virtual directory structure
    print("\nVirtual Directory Structure:")
    for dir_name, description in VIRTUAL_DIRS.items():
        print(f"  {dir_name}/  - {description}")
    
    try:
        manager = RouterQueryManager()
        
        print(f"\nQuerying router at {manager.config['router_ip']}...")
        devices = manager.get_connected_devices()
        
        # Display results
        manager.print_device_table(devices)
        
        # Save results
        if devices:
            json_file = manager.save_device_list(devices, 'json')
            csv_file = manager.save_device_list(devices, 'csv')
            print(f"\nResults saved to:")
            print(f"  - {json_file}")
            print(f"  - {csv_file}")
            
    except ImportError as e:
        print(f"\nDependency missing: {e}")
        print("To install required dependencies:")
        print("  pip install paramiko requests")
        
    except Exception as e:
        print(f"\nError: {e}")
        logging.error(f"Application error: {e}")

if __name__ == "__main__":
    main()
