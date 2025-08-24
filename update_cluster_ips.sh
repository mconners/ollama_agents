#!/bin/bash

# Update all deployment scripts with current and target IP addresses
# This script updates the IP addresses in all deployment and SSH scripts

set -e

# Current IP mappings (from router scan)
declare -A CURRENT_IPS=(
    ["pi51"]="192.168.1.147"
    ["pi52"]="192.168.1.247" 
    ["agx0"]="192.168.1.154"
    ["orin0"]="192.168.1.157"
    ["pi41"]="192.168.1.204"
    ["nano"]="192.168.1.159"
    ["pi31"]="192.168.1.234"
)

# Target static IP mappings (desired final addresses)
declare -A STATIC_IPS=(
    ["pi51"]="192.168.1.51"
    ["pi52"]="192.168.1.52"
    ["agx0"]="192.168.1.150"
    ["orin0"]="192.168.1.149"
    ["pi41"]="192.168.1.41"
    ["nano"]="192.168.1.191"
    ["pi31"]="192.168.1.31"
)

# MAC addresses for static DHCP reservations
declare -A MAC_ADDRESSES=(
    ["pi51"]="2c:cf:67:37:e1:9a"
    ["pi52"]="2c:cf:67:2e:75:29"
    ["agx0"]="3c:6d:66:33:ce:58"
    ["orin0"]="74:04:f1:c2:1e:56"
    ["pi41"]="dc:a6:32:2b:30:37"
    ["nano"]="00:e0:4c:4b:20:d6"
    ["pi31"]="b8:27:eb:af:d4:69"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Updating Deployment Scripts with Current IP Addresses${NC}"
echo -e "${BLUE}=======================================================${NC}"

# Function to update IP addresses in a file
update_ips_in_file() {
    local file=$1
    local use_static=${2:-false}
    
    if [[ ! -f "$file" ]]; then
        echo -e "${YELLOW}⚠️  File not found: $file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📝 Updating $file...${NC}"
    
    # Choose which IP set to use
    local -n ip_array
    if [[ "$use_static" == "true" ]]; then
        ip_array=STATIC_IPS
        echo -e "   Using static IP addresses"
    else
        ip_array=CURRENT_IPS
        echo -e "   Using current IP addresses"
    fi
    
    # Create backup
    cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update each node's IP
    for node in pi51 pi52 agx0 orin0 pi41 nano pi31; do
        local current_ip="${CURRENT_IPS[$node]}"
        local new_ip="${ip_array[$node]}"
        
        if [[ "$current_ip" != "$new_ip" ]]; then
            echo -e "   🔄 $node: $current_ip → $new_ip"
            sed -i "s/$current_ip/$new_ip/g" "$file"
        fi
    done
    
    echo -e "${GREEN}   ✅ Updated successfully${NC}"
}

# Update SSH key setup script with current IPs
echo -e "\n${BLUE}🔑 Updating SSH configuration scripts...${NC}"
update_ips_in_file "setup_ssh_keys.sh" false

# Update deployment scripts with current IPs  
echo -e "\n${BLUE}🚀 Updating deployment scripts...${NC}"
update_ips_in_file "deployment/deploy_system.sh" false
update_ips_in_file "deployment/cleanup_system.sh" false

# Update connectivity test script
update_ips_in_file "test_ssh_connectivity.sh" false

# Update SSH dashboard
update_ips_in_file "ssh_dashboard.sh" false

# Update key rotation script
update_ips_in_file "rotate_ssh_keys.sh" false

# Generate OpenWRT static IP configuration guide
echo -e "\n${BLUE}📋 Generating OpenWRT configuration guide...${NC}"

cat > "OPENWRT_STATIC_IP_GUIDE.md" << 'EOF'
# OpenWRT Static IP Configuration Guide

## 🎯 Objective
Configure static DHCP reservations for Ollama cluster nodes to ensure consistent IP addresses.

## 🌐 Web Interface Method (Recommended)

### Access OpenWRT Admin Panel
1. Open browser and go to: **http://192.168.1.1**
2. Login with admin credentials
3. Navigate to: **Network → DHCP and DNS → Static Leases**

### Add Static DHCP Reservations

Click "Add" and configure each node:

| Hostname | MAC Address | IP Address | Description |
|----------|-------------|------------|-------------|
| pi51 | 2c:cf:67:37:e1:9a | 192.168.1.51 | Gateway & Load Balancer |
| pi52 | 2c:cf:67:2e:75:29 | 192.168.1.52 | Backend Services |
| agx0 | 3c:6d:66:33:ce:58 | 192.168.1.150 | Primary AI Hub |
| orin0 | 74:04:f1:c2:1e:56 | 192.168.1.149 | Secondary AI & Image Gen |
| pi41 | dc:a6:32:2b:30:37 | 192.168.1.41 | Utility Services |
| nano | 00:e0:4c:4b:20:d6 | 192.168.1.191 | Edge Inference |
| pi31 | b8:27:eb:af:d4:69 | 192.168.1.31 | Legacy Services |

### Apply Configuration
1. Click **"Save & Apply"** after adding all reservations
2. Restart DHCP service: **System → Startup → dnsmasq → Restart**

## 🖥️ SSH/CLI Method (Alternative)

If you have SSH access to the router:

```bash
# SSH into router
ssh root@192.168.1.1

# Add static DHCP reservations
uci add dhcp host
uci set dhcp.@host[-1].name='pi51'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='2c:cf:67:37:e1:9a'
uci set dhcp.@host[-1].ip='192.168.1.51'

uci add dhcp host
uci set dhcp.@host[-1].name='pi52'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='2c:cf:67:2e:75:29'
uci set dhcp.@host[-1].ip='192.168.1.52'

uci add dhcp host
uci set dhcp.@host[-1].name='agx0'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='3c:6d:66:33:ce:58'
uci set dhcp.@host[-1].ip='192.168.1.150'

uci add dhcp host
uci set dhcp.@host[-1].name='orin0'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='74:04:f1:c2:1e:56'
uci set dhcp.@host[-1].ip='192.168.1.149'

uci add dhcp host
uci set dhcp.@host[-1].name='pi41'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='dc:a6:32:2b:30:37'
uci set dhcp.@host[-1].ip='192.168.1.41'

uci add dhcp host
uci set dhcp.@host[-1].name='nano'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='00:e0:4c:4b:20:d6'
uci set dhcp.@host[-1].ip='192.168.1.191'

uci add dhcp host
uci set dhcp.@host[-1].name='pi31'
uci set dhcp.@host[-1].dns='1'
uci set dhcp.@host[-1].mac='b8:27:eb:af:d4:69'
uci set dhcp.@host[-1].ip='192.168.1.31'

# Commit changes and restart DHCP
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## 🔄 After Configuration

### Renew DHCP Leases on Cluster Nodes

SSH to each node and renew its DHCP lease:

```bash
# Method 1: Release and renew DHCP lease
sudo dhclient -r && sudo dhclient

# Method 2: Restart networking
sudo systemctl restart networking

# Method 3: Reboot (most reliable)
sudo reboot
```

### Verify Static IPs

After 2-3 minutes, check that nodes have the new static IPs:

```bash
# Test connectivity to new static IPs
ping 192.168.1.51   # pi51
ping 192.168.1.52   # pi52  
ping 192.168.1.150  # agx0
ping 192.168.1.149  # orin0
ping 192.168.1.41   # pi41
ping 192.168.1.191  # nano
ping 192.168.1.31   # pi31
```

## ✅ Benefits of Static IPs

- **Consistent addressing**: No more IP address changes
- **Reliable automation**: Deployment scripts always work
- **Better security**: Firewall rules and access control
- **Easier troubleshooting**: Predictable network layout
- **DNS resolution**: Hostnames resolve consistently

## 🔧 Troubleshooting

### If a node doesn't get the static IP:
1. Check MAC address is correct in OpenWRT config
2. Release DHCP lease: `sudo dhclient -r`
3. Renew DHCP lease: `sudo dhclient`
4. Reboot the node if necessary

### If OpenWRT web interface is inaccessible:
1. Check router connection: `ping 192.168.1.1`
2. Try different browser or incognito mode
3. Clear browser cache and cookies
4. Factory reset router if necessary (last resort)

### Check current DHCP leases:
In OpenWRT web interface: **Status → Overview → DHCP Leases**
EOF

# Generate summary
echo -e "\n${BLUE}📊 Update Summary${NC}"
echo -e "${BLUE}=================${NC}"

echo -e "${GREEN}✅ Updated deployment scripts with current IP addresses${NC}"
echo -e "${GREEN}✅ Generated OpenWRT configuration guide${NC}"

echo -e "\n${BLUE}📋 Current IP Mappings:${NC}"
for node in pi51 pi52 agx0 orin0 pi41 nano pi31; do
    echo -e "  $node: ${CURRENT_IPS[$node]} → ${STATIC_IPS[$node]} (target)"
done

echo -e "\n${BLUE}🎯 Next Steps:${NC}"
echo -e "1. ${YELLOW}Configure static IPs in OpenWRT${NC} (see OPENWRT_STATIC_IP_GUIDE.md)"
echo -e "2. ${YELLOW}Reboot cluster nodes${NC} to get static IPs"  
echo -e "3. ${YELLOW}Test SSH connectivity${NC} with new IPs"
echo -e "4. ${YELLOW}Deploy the system${NC} using updated scripts"

echo -e "\n${GREEN}✅ IP address update complete!${NC}"
