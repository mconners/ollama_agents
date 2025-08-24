#!/usr/bin/env python3
"""
Network utility functions for OpenWRT router querying
"""

import socket
import subprocess
import ipaddress
from typing import List, Dict, Optional


def ping_host(host: str, timeout: int = 5) -> bool:
    """
    Ping a host to check if it's reachable
    
    Args:
        host: IP address or hostname to ping
        timeout: Timeout in seconds
        
    Returns:
        True if host is reachable, False otherwise
    """
    try:
        # Use ping command
        result = subprocess.run(
            ['ping', '-c', '1', '-W', str(timeout), host],
            capture_output=True,
            text=True,
            timeout=timeout + 2
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def is_valid_ip(ip_string: str) -> bool:
    """
    Check if string is a valid IP address
    
    Args:
        ip_string: String to validate
        
    Returns:
        True if valid IP address, False otherwise
    """
    try:
        ipaddress.ip_address(ip_string)
        return True
    except ValueError:
        return False


def is_private_ip(ip_string: str) -> bool:
    """
    Check if IP address is in private range
    
    Args:
        ip_string: IP address string
        
    Returns:
        True if private IP, False otherwise
    """
    try:
        ip = ipaddress.ip_address(ip_string)
        return ip.is_private
    except ValueError:
        return False


def get_network_range(router_ip: str) -> Optional[str]:
    """
    Get the network range based on router IP
    
    Args:
        router_ip: Router IP address
        
    Returns:
        Network range in CIDR notation or None if invalid
    """
    try:
        ip = ipaddress.ip_address(router_ip)
        if ip.is_private:
            # Common private network assumptions
            if str(ip).startswith('192.168.'):
                return f"{'.'.join(str(ip).split('.')[:-1])}.0/24"
            elif str(ip).startswith('10.'):
                return "10.0.0.0/8"
            elif str(ip).startswith('172.'):
                return "172.16.0.0/12"
        return None
    except ValueError:
        return None


def resolve_hostname(ip_address: str) -> Optional[str]:
    """
    Try to resolve IP address to hostname
    
    Args:
        ip_address: IP address to resolve
        
    Returns:
        Hostname if resolved, None otherwise
    """
    try:
        hostname, _, _ = socket.gethostbyaddr(ip_address)
        return hostname
    except socket.herror:
        return None


def get_mac_vendor(mac_address: str) -> Optional[str]:
    """
    Get vendor information from MAC address OUI
    
    Args:
        mac_address: MAC address in format XX:XX:XX:XX:XX:XX
        
    Returns:
        Vendor name if found in built-in database, None otherwise
    """
    # Simple vendor lookup based on OUI (first 3 octets)
    # This is a basic implementation - full OUI database would be much larger
    oui_database = {
        '00:0C:29': 'VMware',
        '00:50:56': 'VMware',
        '08:00:27': 'Oracle VirtualBox',
        '52:54:00': 'QEMU/KVM',
        'DC:A6:32': 'Raspberry Pi Foundation',
        'B8:27:EB': 'Raspberry Pi Foundation',
        'E4:5F:01': 'Raspberry Pi Foundation',
        '28:CD:C4': 'Apple',
        '3C:15:C2': 'Apple',
        'F4:0F:24': 'Apple',
        '98:01:A7': 'Apple',
        '00:1B:63': 'Apple',
        'D4:9A:20': 'Apple',
        'AC:BC:32': 'Apple',
        '40:A3:6B': 'Apple',
        'F0:18:98': 'Apple',
        '90:72:40': 'Apple',
        'A4:83:E7': 'Apple',
        '00:23:DF': 'Apple',
        '00:26:BB': 'Apple',
        '1C:AB:A7': 'Google',
        'DA:A1:19': 'Google',
        '6C:AD:F8': 'AzureWave Technology',
        '18:CF:5E': 'Google Nest',
        'F4:F5:D8': 'Google',
        '54:60:09': 'Google',
        '00:1A:11': 'Google'
    }
    
    if not mac_address or len(mac_address) < 8:
        return None
        
    # Extract OUI (first 3 octets)
    oui = mac_address.upper()[:8]  # XX:XX:XX
    
    return oui_database.get(oui, None)


def format_mac_address(mac: str) -> str:
    """
    Format MAC address to standard XX:XX:XX:XX:XX:XX format
    
    Args:
        mac: MAC address in various formats
        
    Returns:
        Formatted MAC address
    """
    # Remove common separators and convert to uppercase
    clean_mac = mac.upper().replace(':', '').replace('-', '').replace('.', '')
    
    if len(clean_mac) == 12:
        # Insert colons every 2 characters
        return ':'.join(clean_mac[i:i+2] for i in range(0, 12, 2))
    
    return mac  # Return original if can't format


def scan_network_range(network_range: str, timeout: int = 1) -> List[str]:
    """
    Scan network range for active hosts using ping
    
    Args:
        network_range: Network in CIDR notation (e.g., '192.168.1.0/24')
        timeout: Ping timeout in seconds
        
    Returns:
        List of active IP addresses
    """
    active_hosts = []
    
    try:
        network = ipaddress.ip_network(network_range, strict=False)
        
        # Limit scan to reasonable size to avoid long execution times
        if network.num_addresses > 254:
            print(f"Network range {network_range} is too large for scanning")
            return active_hosts
            
        print(f"Scanning {network_range}...")
        
        for ip in network.hosts():
            if ping_host(str(ip), timeout):
                active_hosts.append(str(ip))
                print(f"  Found active host: {ip}")
                
    except ValueError as e:
        print(f"Invalid network range: {e}")
        
    return active_hosts
