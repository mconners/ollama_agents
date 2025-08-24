#!/bin/bash

# SSH Connectivity Test for Ollama Distributed AI Cluster
# Verifies SSH key authentication is working across all nodes

set -e

# Configuration
CLUSTER_NODES=(
    "192.168.1.147:pi51:gateway"
    "192.168.1.247:pi52:backend"  
    "192.168.1.154:agx0:primary-ai"
    "192.168.1.157:orin0:secondary-ai"
    "192.168.1.204:pi41:utility"
    "192.168.1.159:nano:edge"
    "192.168.1.234:pi31:legacy"
)

USERNAME="mconners"
SSH_KEY="$HOME/.ssh/ollama_cluster_key"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 SSH Connectivity Test for Ollama Cluster${NC}"
echo -e "${BLUE}===========================================${NC}"

# Check if SSH key exists
if [[ ! -f "$SSH_KEY" ]]; then
    echo -e "${RED}❌ SSH key not found: $SSH_KEY${NC}"
    echo -e "${YELLOW}💡 Run ./setup_ssh_keys.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH key found: $SSH_KEY${NC}"
echo -e "${YELLOW}📋 Key fingerprint:${NC}"
ssh-keygen -lf "$SSH_KEY.pub"
echo

# Test function
test_node_connectivity() {
    local ip=$1
    local alias=$2  
    local role=$3
    
    echo -e "${BLUE}🔌 Testing $alias ($role) at $ip${NC}"
    
    # Test direct IP connection with key
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY" "$USERNAME@$ip" 'echo "Direct IP: OK"' 2>/dev/null; then
        echo -e "  ${GREEN}✅ Direct IP authentication: SUCCESS${NC}"
    else
        echo -e "  ${RED}❌ Direct IP authentication: FAILED${NC}"
        return 1
    fi
    
    # Test SSH alias connection  
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$alias" 'echo "Alias: OK"' 2>/dev/null; then
        echo -e "  ${GREEN}✅ SSH alias authentication: SUCCESS${NC}"
    else
        echo -e "  ${YELLOW}⚠️  SSH alias authentication: FAILED${NC}"
        echo -e "    ${YELLOW}(Direct IP works, alias needs SSH config update)${NC}"
    fi
    
    # Get system info
    local system_info
    system_info=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY" "$USERNAME@$ip" \
        'uname -m && docker --version 2>/dev/null || echo "Docker: Not installed"' 2>/dev/null || echo "System info unavailable")
    
    echo -e "  ${BLUE}ℹ️  System: $system_info${NC}"
    echo
    
    return 0
}

# Test all nodes
echo -e "${BLUE}🚀 Testing connectivity to all cluster nodes${NC}"
echo -e "${BLUE}============================================${NC}"

SUCCESSFUL_NODES=0
TOTAL_NODES=${#CLUSTER_NODES[@]}

for node in "${CLUSTER_NODES[@]}"; do
    IFS=':' read -r ip alias role <<< "$node"
    
    if test_node_connectivity "$ip" "$alias" "$role"; then
        ((SUCCESSFUL_NODES++))
    fi
done

# Summary
echo -e "${BLUE}📊 Connectivity Test Summary${NC}"
echo -e "${BLUE}============================${NC}"
echo -e "Connected nodes: ${GREEN}$SUCCESSFUL_NODES${NC}/$TOTAL_NODES"

if [[ $SUCCESSFUL_NODES -eq $TOTAL_NODES ]]; then
    echo -e "${GREEN}🎉 All nodes accessible via SSH key authentication!${NC}"
    echo -e "${GREEN}✅ Ready for automated deployment${NC}"
elif [[ $SUCCESSFUL_NODES -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Partial connectivity - some nodes may need SSH key setup${NC}"
    echo -e "${BLUE}💡 For unreachable nodes, run:${NC}"
    echo -e "   ${BLUE}ssh-copy-id -i $SSH_KEY.pub mconners@<NODE_IP>${NC}"
else
    echo -e "${RED}❌ No nodes accessible - SSH key setup required${NC}"
    echo -e "${BLUE}💡 Run: ./setup_ssh_keys.sh${NC}"
fi

echo -e "\n${BLUE}🔒 Security Status${NC}"
echo -e "${BLUE}=================${NC}"

if [[ $SUCCESSFUL_NODES -gt 0 ]]; then
    echo -e "${GREEN}✅ SSH key authentication working${NC}"
    echo -e "${GREEN}✅ Password-less access enabled${NC}" 
    echo -e "${GREEN}✅ Deployment automation ready${NC}"
    
    echo -e "\n${BLUE}🛠️  Next Steps:${NC}"
    echo -e "• Deploy system: ${YELLOW}cd deployment/ && ./deploy_system.sh${NC}"
    echo -e "• Monitor cluster: ${YELLOW}ssh agx0 'docker ps'${NC}"
    echo -e "• Rotate keys monthly: ${YELLOW}./rotate_ssh_keys.sh${NC}"
else
    echo -e "${YELLOW}⚠️  Manual SSH key setup required${NC}"
    echo -e "• Review: ${YELLOW}SSH_SECURITY_GUIDE.md${NC}"
    echo -e "• Setup keys: ${YELLOW}./setup_ssh_keys.sh${NC}"
fi
