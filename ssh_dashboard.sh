#!/bin/bash

# SSH Key Management Dashboard for Ollama Cluster
# Central management interface for SSH keys and security

set -e

# Configuration
SSH_KEY_PATH="$HOME/.ssh/ollama_cluster_key"
SSH_CONFIG="$HOME/.ssh/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Functions
show_header() {
    clear
    echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${BLUE}│                 🔐 SSH Key Management Dashboard              │${NC}"
    echo -e "${BOLD}${BLUE}│                   Ollama Distributed AI Cluster            │${NC}"
    echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
}

show_key_status() {
    echo -e "${BOLD}${CYAN}📋 Current SSH Key Status${NC}"
    echo -e "${CYAN}─────────────────────────────${NC}"
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        echo -e "${GREEN}✅ SSH Key Pair: EXISTS${NC}"
        echo -e "   📍 Private Key: $SSH_KEY_PATH"
        echo -e "   📍 Public Key: $SSH_KEY_PATH.pub"
        
        # Show key details
        local key_info
        key_info=$(ssh-keygen -lf "$SSH_KEY_PATH.pub" 2>/dev/null)
        echo -e "   🔑 Fingerprint: $key_info"
        
        # Show key age
        local key_age
        key_age=$(stat -c %Y "$SSH_KEY_PATH" 2>/dev/null)
        local current_time
        current_time=$(date +%s)
        local days_old=$(( (current_time - key_age) / 86400 ))
        
        if [[ $days_old -lt 30 ]]; then
            echo -e "   📅 Age: ${GREEN}$days_old days${NC} (Fresh)"
        elif [[ $days_old -lt 90 ]]; then
            echo -e "   📅 Age: ${YELLOW}$days_old days${NC} (Consider rotation)"
        else
            echo -e "   📅 Age: ${RED}$days_old days${NC} (Rotation recommended)"
        fi
    else
        echo -e "${RED}❌ SSH Key Pair: NOT FOUND${NC}"
        echo -e "   💡 Run option 1 to generate keys"
    fi
    
    echo
}

show_ssh_config_status() {
    echo -e "${BOLD}${CYAN}⚙️  SSH Configuration Status${NC}"
    echo -e "${CYAN}─────────────────────────────────${NC}"
    
    if [[ -f "$SSH_CONFIG" ]]; then
        if grep -q "ollama_cluster_key" "$SSH_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}✅ SSH Config: CONFIGURED${NC}"
            echo -e "   📍 Location: $SSH_CONFIG"
            
            # Count configured hosts
            local host_count
            host_count=$(grep -c "^Host.*\(pi51\|agx0\|orin0\|pi52\|pi41\|nano\|pi31\)" "$SSH_CONFIG" 2>/dev/null || echo "0")
            echo -e "   🖥️  Configured Hosts: $host_count"
        else
            echo -e "${YELLOW}⚠️  SSH Config: EXISTS but not configured for cluster${NC}"
        fi
    else
        echo -e "${RED}❌ SSH Config: NOT FOUND${NC}"
    fi
    
    echo
}

show_cluster_connectivity() {
    echo -e "${BOLD}${CYAN}🔌 Quick Connectivity Check${NC}"
    echo -e "${CYAN}─────────────────────────────────${NC}"
    
    local nodes=(
        "192.168.1.51:PI51"
        "192.168.1.150:AGX0"
        "192.168.1.149:ORIN0"  
        "192.168.1.52:PI52"
    )
    
    local connected=0
    local total=${#nodes[@]}
    
    for node in "${nodes[@]}"; do
        IFS=':' read -r ip name <<< "$node"
        echo -n "   🔍 $name ($ip): "
        
        if ssh -o ConnectTimeout=3 -o BatchMode=yes -i "$SSH_KEY_PATH" "mconners@$ip" exit 2>/dev/null; then
            echo -e "${GREEN}✅ CONNECTED${NC}"
            ((connected++))
        else
            echo -e "${RED}❌ UNREACHABLE${NC}"
        fi
    done
    
    echo -e "\n   📊 Connectivity: ${GREEN}$connected${NC}/$total nodes reachable"
    echo
}

show_security_recommendations() {
    echo -e "${BOLD}${CYAN}🛡️  Security Recommendations${NC}"
    echo -e "${CYAN}─────────────────────────────────────${NC}"
    
    # Check key age
    if [[ -f "$SSH_KEY_PATH" ]]; then
        local key_age
        key_age=$(stat -c %Y "$SSH_KEY_PATH" 2>/dev/null)
        local current_time
        current_time=$(date +%s)
        local days_old=$(( (current_time - key_age) / 86400 ))
        
        if [[ $days_old -gt 90 ]]; then
            echo -e "${RED}⚠️  Key rotation overdue (${days_old} days old)${NC}"
        elif [[ $days_old -gt 30 ]]; then
            echo -e "${YELLOW}💡 Consider key rotation (${days_old} days old)${NC}"
        else
            echo -e "${GREEN}✅ Key age acceptable (${days_old} days old)${NC}"
        fi
    fi
    
    # Check file permissions
    if [[ -f "$SSH_KEY_PATH" ]]; then
        local perms
        perms=$(stat -c %a "$SSH_KEY_PATH" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            echo -e "${GREEN}✅ Private key permissions secure (600)${NC}"
        else
            echo -e "${RED}⚠️  Private key permissions insecure ($perms)${NC}"
        fi
    fi
    
    echo -e "${BLUE}🔄 Next rotation recommended: $(date -d '+30 days' '+%Y-%m-%d')${NC}"
    echo
}

show_menu() {
    echo -e "${BOLD}${BLUE}🛠️  Available Actions${NC}"
    echo -e "${BLUE}──────────────────────${NC}"
    echo -e "  ${BOLD}1)${NC} 🔑 Generate new SSH key pair"
    echo -e "  ${BOLD}2)${NC} 🚀 Setup SSH keys on cluster nodes"  
    echo -e "  ${BOLD}3)${NC} 🔄 Rotate SSH keys (security best practice)"
    echo -e "  ${BOLD}4)${NC} 🔍 Test SSH connectivity to all nodes"
    echo -e "  ${BOLD}5)${NC} ⚙️  View/Edit SSH configuration"
    echo -e "  ${BOLD}6)${NC} 📊 Generate connectivity report"
    echo -e "  ${BOLD}7)${NC} 📖 View security guide"
    echo -e "  ${BOLD}0)${NC} 🚪 Exit"
    echo
    echo -n -e "${BOLD}Choose an option [0-7]: ${NC}"
}

# Main menu loop
main_menu() {
    while true; do
        show_header
        show_key_status
        show_ssh_config_status
        show_cluster_connectivity
        show_security_recommendations
        show_menu
        
        read -r choice
        case $choice in
            1)
                echo -e "\n${BLUE}🔑 Generating new SSH key pair...${NC}"
                ./setup_ssh_keys.sh
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            2)
                echo -e "\n${BLUE}🚀 Setting up SSH keys on cluster...${NC}"
                ./setup_ssh_keys.sh
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            3)
                echo -e "\n${BLUE}🔄 Rotating SSH keys...${NC}"
                ./rotate_ssh_keys.sh
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            4)
                echo -e "\n${BLUE}🔍 Testing SSH connectivity...${NC}"
                ./test_ssh_connectivity.sh
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            5)
                echo -e "\n${BLUE}⚙️  Opening SSH configuration...${NC}"
                ${EDITOR:-nano} "$SSH_CONFIG"
                ;;
            6)
                echo -e "\n${BLUE}📊 Generating connectivity report...${NC}"
                ./test_ssh_connectivity.sh > "ssh_connectivity_report_$(date +%Y%m%d_%H%M%S).txt"
                echo -e "${GREEN}✅ Report saved${NC}"
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            7)
                echo -e "\n${BLUE}📖 Opening security guide...${NC}"
                ${PAGER:-less} SSH_SECURITY_GUIDE.md
                ;;
            0)
                echo -e "\n${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}❌ Invalid option. Please choose 0-7.${NC}"
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Check if we're in the right directory
if [[ ! -f "setup_ssh_keys.sh" ]]; then
    echo -e "${RED}❌ Error: Please run from the ollama_agents directory${NC}"
    exit 1
fi

# Start the dashboard
main_menu
