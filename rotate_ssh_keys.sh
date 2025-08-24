#!/bin/bash

# SSH Key Rotation for Ollama Distributed AI Cluster
# Rotates SSH keys for enhanced security

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
OLD_KEY_PATH="$HOME/.ssh/ollama_cluster_key"
NEW_KEY_PATH="$HOME/.ssh/ollama_cluster_key_new"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 SSH Key Rotation for Ollama Cluster${NC}"
echo -e "${BLUE}=====================================${NC}"

# Backup current key
if [[ -f "$OLD_KEY_PATH" ]]; then
    BACKUP_PATH="$OLD_KEY_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$OLD_KEY_PATH" "$BACKUP_PATH"
    cp "$OLD_KEY_PATH.pub" "$BACKUP_PATH.pub"
    echo -e "${GREEN}✅ Backed up current key to $BACKUP_PATH${NC}"
fi

# Generate new key
echo -e "${BLUE}🔑 Generating new SSH key...${NC}"
ssh-keygen -t ed25519 -C "ollama_cluster_rotated_$(date +%Y%m%d)" -f "$NEW_KEY_PATH" -N ""

echo -e "${GREEN}✅ New key generated${NC}"
echo -e "${YELLOW}📋 New key fingerprint:${NC}"
ssh-keygen -lf "$NEW_KEY_PATH.pub"

# Function to rotate key on a node
rotate_node_key() {
    local node_ip=$1
    local node_name=$2
    
    echo -e "\n${BLUE}🔄 Rotating key for ${node_name} (${node_ip})${NC}"
    
    # Install new key
    if ssh-copy-id -i "$NEW_KEY_PATH.pub" "$USERNAME@$node_ip" 2>/dev/null; then
        echo -e "${GREEN}✅ ${node_name}: New key installed${NC}"
        
        # Test new key
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$NEW_KEY_PATH" "$USERNAME@$node_ip" exit 2>/dev/null; then
            echo -e "${GREEN}✅ ${node_name}: New key verified${NC}"
            
            # Remove old key from authorized_keys
            OLD_KEY_CONTENT=$(cat "$OLD_KEY_PATH.pub" 2>/dev/null || echo "")
            if [[ -n "$OLD_KEY_CONTENT" ]]; then
                ssh -i "$NEW_KEY_PATH" "$USERNAME@$node_ip" "
                    grep -v '$OLD_KEY_CONTENT' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp 2>/dev/null || true
                    mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys 2>/dev/null || true
                " 2>/dev/null
                echo -e "${GREEN}✅ ${node_name}: Old key removed${NC}"
            fi
        else
            echo -e "${RED}❌ ${node_name}: New key verification failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ${node_name}: Failed to install new key${NC}"
        return 1
    fi
}

# Rotate keys on all nodes
echo -e "\n${BLUE}🚀 Rotating keys on all cluster nodes${NC}"

SUCCESSFUL_ROTATIONS=0
TOTAL_NODES=${#CLUSTER_NODES[@]}

for node_ip in "${CLUSTER_NODES[@]}"; do
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
    
    if rotate_node_key "$node_ip" "$node_name"; then
        ((SUCCESSFUL_ROTATIONS++))
    fi
done

# Replace old key with new key
if [[ $SUCCESSFUL_ROTATIONS -eq $TOTAL_NODES ]]; then
    echo -e "\n${GREEN}🎉 Key rotation successful on all nodes!${NC}"
    
    # Move new key to replace old key
    mv "$NEW_KEY_PATH" "$OLD_KEY_PATH"
    mv "$NEW_KEY_PATH.pub" "$OLD_KEY_PATH.pub"
    
    echo -e "${GREEN}✅ SSH key rotation completed successfully${NC}"
    
    # Update SSH config with new fingerprint
    echo -e "${BLUE}📝 SSH config updated automatically${NC}"
    
else
    echo -e "${RED}❌ Key rotation failed on some nodes${NC}"
    echo -e "${YELLOW}⚠️  Manual intervention may be required${NC}"
    echo -e "${YELLOW}⚠️  New key preserved at: $NEW_KEY_PATH${NC}"
fi

echo -e "\n${BLUE}📊 Key Rotation Summary${NC}"
echo -e "${BLUE}======================${NC}"
echo -e "${GREEN}✅ Successfully rotated: $SUCCESSFUL_ROTATIONS/$TOTAL_NODES nodes${NC}"

if [[ $SUCCESSFUL_ROTATIONS -eq $TOTAL_NODES ]]; then
    echo -e "${GREEN}🔒 Cluster security enhanced with new SSH keys${NC}"
fi
