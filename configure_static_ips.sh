#!/bin/bash

# OpenWRT Static IP Configuration for Ollama Cluster
# Configures DHCP reservations to ensure consistent IP addresses

set -e

# OpenWRT Router Configuration
ROUTER_IP="192.168.1.1"
ROUTER_USER="root"  # Default OpenWRT admin user

# Cluster Node Configuration
# Format: "hostname:mac_address:desired_ip:description"
CLUSTER_NODES=(
    "pi51:2c:cf:67:37:e1:9a:192.168.1.51:Gateway & Load Balancer"
    "pi52:2c:cf:67:2e:75:29:192.168.1.52:Backend Services"
    "agx0:3c:6d:66:33:ce:58:192.168.1.150:Primary AI Hub"
    "orin0:74:04:f1:c2:1e:56:192.168.1.149:Secondary AI & Image Gen"
    "pi41:dc:a6:32:2b:30:37:192.168.1.41:Utility Services"
    "nano:00:e0:4c:4b:20:d6:192.168.1.191:Edge Inference"
    "pi31:b8:27:eb:af:d4:69:192.168.1.31:Legacy Services"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🌐 OpenWRT Static IP Configuration for Ollama Cluster${NC}"
echo -e "${BLUE}====================================================${NC}"

# Check if we can reach the router
echo -e "${BLUE}🔍 Testing router connectivity...${NC}"
if ! ping -c 1 -W 3 "$ROUTER_IP" >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot reach router at $ROUTER_IP${NC}"
    echo -e "${YELLOW}💡 Make sure you're on the same network as the router${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Router is reachable${NC}"

# Function to configure static DHCP reservation
configure_static_ip() {
    local hostname=$1
    local mac_address=$2
    local ip_address=$3
    local description=$4
    
    echo -e "${BLUE}📌 Configuring static IP for $hostname${NC}"
    echo -e "   MAC: $mac_address → IP: $ip_address"
    echo -e "   Role: $description"
    
    # SSH into router and configure DHCP reservation
    # Note: This requires SSH key access to the router or password authentication
    local uci_commands="
        # Remove any existing reservations for this MAC or IP
        uci delete dhcp.@host[\$(uci show dhcp | grep -n '$mac_address\\|$ip_address' | head -1 | cut -d: -f1 | cut -d. -f2)] 2>/dev/null || true
        
        # Add new DHCP reservation
        uci add dhcp host
        uci set dhcp.@host[-1].name='$hostname'
        uci set dhcp.@host[-1].dns='1'
        uci set dhcp.@host[-1].mac='$mac_address'
        uci set dhcp.@host[-1].ip='$ip_address'
        
        # Commit changes
        uci commit dhcp
    "
    
    if ssh -o ConnectTimeout=5 "$ROUTER_USER@$ROUTER_IP" "$uci_commands" 2>/dev/null; then
        echo -e "${GREEN}   ✅ Static IP configured successfully${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Failed to configure static IP${NC}"
        echo -e "${YELLOW}   💡 Manual configuration required${NC}"
        return 1
    fi
}

# Function to generate manual UCI commands
generate_manual_commands() {
    echo -e "\n${BLUE}📝 Manual OpenWRT Configuration Commands${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${YELLOW}If SSH access to router fails, run these commands manually on the router:${NC}"
    echo
    
    local counter=0
    for node in "${CLUSTER_NODES[@]}"; do
        IFS=':' read -r hostname mac ip description <<< "$node"
        
        echo -e "${BLUE}# $hostname - $description${NC}"
        echo "uci add dhcp host"
        echo "uci set dhcp.@host[-1].name='$hostname'"
        echo "uci set dhcp.@host[-1].dns='1'"
        echo "uci set dhcp.@host[-1].mac='$mac'"
        echo "uci set dhcp.@host[-1].ip='$ip'"
        echo
        
        ((counter++))
    done
    
    echo -e "${BLUE}# Apply all changes${NC}"
    echo "uci commit dhcp"
    echo "/etc/init.d/dnsmasq restart"
    echo
}

# Function to generate web interface instructions
generate_web_instructions() {
    echo -e "\n${BLUE}🌐 Web Interface Configuration (Alternative Method)${NC}"
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${YELLOW}Access OpenWRT web interface at: http://$ROUTER_IP${NC}"
    echo -e "${YELLOW}Go to: Network → DHCP and DNS → Static Leases${NC}"
    echo
    echo -e "${BLUE}Add these static DHCP reservations:${NC}"
    echo
    printf "%-10s %-20s %-15s %s\n" "Hostname" "MAC Address" "IP Address" "Description"
    echo "─────────────────────────────────────────────────────────────────────────"
    
    for node in "${CLUSTER_NODES[@]}"; do
        IFS=':' read -r hostname mac ip description <<< "$node"
        printf "%-10s %-20s %-15s %s\n" "$hostname" "$mac" "$ip" "$description"
    done
    echo
}

# Try to configure each node automatically
echo -e "\n${BLUE}🚀 Configuring static IP reservations...${NC}"

SUCCESSFUL_CONFIGS=0
TOTAL_NODES=${#CLUSTER_NODES[@]}

for node in "${CLUSTER_NODES[@]}"; do
    IFS=':' read -r hostname mac ip description <<< "$node"
    
    if configure_static_ip "$hostname" "$mac" "$ip" "$description"; then
        ((SUCCESSFUL_CONFIGS++))
    fi
    echo
done

# Restart DHCP service if any configurations were successful
if [[ $SUCCESSFUL_CONFIGS -gt 0 ]]; then
    echo -e "${BLUE}🔄 Restarting DHCP service on router...${NC}"
    if ssh -o ConnectTimeout=5 "$ROUTER_USER@$ROUTER_IP" "/etc/init.d/dnsmasq restart" 2>/dev/null; then
        echo -e "${GREEN}✅ DHCP service restarted successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Please restart DHCP service manually on the router${NC}"
    fi
fi

# Summary
echo -e "\n${BLUE}📊 Configuration Summary${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "Successfully configured: ${GREEN}$SUCCESSFUL_CONFIGS${NC}/$TOTAL_NODES nodes"

if [[ $SUCCESSFUL_CONFIGS -eq $TOTAL_NODES ]]; then
    echo -e "${GREEN}🎉 All static IP reservations configured successfully!${NC}"
    echo -e "\n${BLUE}📋 Next Steps:${NC}"
    echo -e "1. ${YELLOW}Reboot cluster nodes${NC} to get new static IPs"
    echo -e "2. ${YELLOW}Wait 2-3 minutes${NC} for DHCP lease renewal"
    echo -e "3. ${YELLOW}Run ping test${NC} to verify new IPs"
    echo -e "4. ${YELLOW}Update deployment scripts${NC} with static IPs"
    
elif [[ $SUCCESSFUL_CONFIGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Partial configuration completed${NC}"
    generate_manual_commands
    generate_web_instructions
else
    echo -e "${RED}❌ Automatic configuration failed${NC}"
    echo -e "${YELLOW}💡 Manual configuration required${NC}"
    generate_manual_commands
    generate_web_instructions
fi

echo -e "\n${BLUE}🔒 Security Note:${NC}"
echo -e "${YELLOW}Static IP assignments ensure consistent addressing for your cluster.${NC}"
echo -e "${YELLOW}This improves security and reliability of automated deployments.${NC}"

echo -e "\n${GREEN}✅ OpenWRT static IP configuration complete!${NC}"
