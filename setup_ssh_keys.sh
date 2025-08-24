#!/bin/bash

# SSH Key Setup for Ollama Distributed AI Cluster
# Eliminates password authentication for better security

set -e

# Configuration
CLUSTER_NODES=(
    "192.168.1.51"  # PI51 - Gateway
    "192.168.1.52"  # PI52 - Backend  
    "192.168.1.150" # AGX0 - Primary AI
    "192.168.1.149" # ORIN0 - Secondary AI
    "192.168.1.41"  # PI41 - Utility
    "192.168.1.191" # NANO - Edge
    "192.168.1.31"  # PI31 - Legacy
)

USERNAME="mconners"
SSH_KEY_PATH="$HOME/.ssh/ollama_cluster_key"
SSH_PUB_KEY_PATH="$HOME/.ssh/ollama_cluster_key.pub"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Setting up SSH Key Authentication for Ollama Cluster${NC}"
echo -e "${BLUE}=================================================${NC}"

# Verify key exists
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo -e "${RED}❌ SSH key not found at $SSH_KEY_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH key pair found${NC}"
echo -e "${YELLOW}📋 Public key fingerprint:${NC}"
ssh-keygen -lf "$SSH_PUB_KEY_PATH"

# Function to setup SSH key on a node
setup_node_ssh() {
    local node_ip=$1
    local node_name=$2
    
    echo -e "\n${BLUE}🔧 Setting up SSH key for ${node_name} (${node_ip})${NC}"
    
    # Test current connectivity
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY_PATH" "$USERNAME@$node_ip" exit 2>/dev/null; then
        echo -e "${GREEN}✅ ${node_name}: SSH key already configured${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📤 Copying SSH key to ${node_name}...${NC}"
    
    # Copy the public key (will prompt for password one last time)
    if ssh-copy-id -i "$SSH_PUB_KEY_PATH" "$USERNAME@$node_ip" 2>/dev/null; then
        echo -e "${GREEN}✅ ${node_name}: SSH key installed successfully${NC}"
        
        # Test the key-based authentication
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY_PATH" "$USERNAME@$node_ip" exit 2>/dev/null; then
            echo -e "${GREEN}✅ ${node_name}: Key-based authentication verified${NC}"
        else
            echo -e "${RED}❌ ${node_name}: Key-based authentication test failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ${node_name}: Failed to install SSH key${NC}"
        return 1
    fi
}

# Setup SSH config for easy access
echo -e "\n${BLUE}📝 Creating SSH config for cluster nodes${NC}"

SSH_CONFIG="$HOME/.ssh/config"
CLUSTER_CONFIG="
# Ollama Distributed AI Cluster Configuration
# Generated: $(date)

Host pi51 gateway
    HostName 192.168.1.51
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host pi52 backend
    HostName 192.168.1.52
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host agx0 primary-ai
    HostName 192.168.1.150
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host orin0 secondary-ai
    HostName 192.168.1.149
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host pi41 utility
    HostName 192.168.1.41
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host nano edge
    HostName 192.168.1.191
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

Host pi31 legacy
    HostName 192.168.1.31
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes

# Global settings for cluster
Host 192.168.1.51 192.168.1.52 192.168.1.150 192.168.1.149 192.168.1.41 192.168.1.191 192.168.1.31
    User mconners
    IdentityFile ~/.ssh/ollama_cluster_key
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
"

# Backup existing config
if [[ -f "$SSH_CONFIG" ]]; then
    cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}📋 Backed up existing SSH config${NC}"
fi

# Add cluster config (remove any existing cluster config first)
grep -v "# Ollama Distributed AI Cluster Configuration" "$SSH_CONFIG" 2>/dev/null > "$SSH_CONFIG.tmp" || true
echo "$CLUSTER_CONFIG" >> "$SSH_CONFIG.tmp"
mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"

echo -e "${GREEN}✅ SSH config updated with cluster shortcuts${NC}"

# Distribute keys to all nodes
echo -e "\n${BLUE}🚀 Distributing SSH keys to cluster nodes${NC}"
echo -e "${YELLOW}Note: You'll be prompted for passwords one last time per node${NC}"

SUCCESSFUL_NODES=0
TOTAL_NODES=${#CLUSTER_NODES[@]}

for i in "${!CLUSTER_NODES[@]}"; do
    node_ip="${CLUSTER_NODES[$i]}"
    case "$node_ip" in
        "192.168.1.51") node_name="PI51-Gateway" ;;
        "192.168.1.52") node_name="PI52-Backend" ;;
        "192.168.1.150") node_name="AGX0-PrimaryAI" ;;
        "192.168.1.149") node_name="ORIN0-SecondaryAI" ;;
        "192.168.1.41") node_name="PI41-Utility" ;;
        "192.168.1.191") node_name="NANO-Edge" ;;
        "192.168.1.31") node_name="PI31-Legacy" ;;
        *) node_name="Unknown" ;;
    esac
    
    if setup_node_ssh "$node_ip" "$node_name"; then
        ((SUCCESSFUL_NODES++))
    fi
done

# Summary
echo -e "\n${BLUE}📊 SSH Key Setup Summary${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "${GREEN}✅ Successfully configured: $SUCCESSFUL_NODES/$TOTAL_NODES nodes${NC}"

if [[ $SUCCESSFUL_NODES -eq $TOTAL_NODES ]]; then
    echo -e "${GREEN}🎉 All nodes configured successfully!${NC}"
    echo -e "\n${BLUE}💡 Usage Examples:${NC}"
    echo -e "  ssh pi51        # Connect to gateway"
    echo -e "  ssh agx0        # Connect to primary AI node" 
    echo -e "  ssh orin0       # Connect to secondary AI node"
    echo -e "  ssh backend     # Connect to backend services"
else
    echo -e "${YELLOW}⚠️  Some nodes may need manual configuration${NC}"
fi

echo -e "\n${BLUE}🔒 Security Benefits:${NC}"
echo -e "  • No more password prompts"
echo -e "  • Stronger cryptographic authentication"
echo -e "  • Easy key rotation and revocation"
echo -e "  • Automated deployment script compatibility"

echo -e "\n${GREEN}✅ SSH key authentication setup complete!${NC}"
