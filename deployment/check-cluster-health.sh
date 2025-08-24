#!/bin/bash

# Ollama Cluster Health Check Script

echo "🔍 Ollama Cluster Health Check"
echo "==============================="
echo "$(date)"
echo ""

# Node definitions
declare -A NODES=(
    ["PI51"]="192.168.1.147:11434"
    ["ORIN0"]="192.168.1.157:11435" 
    ["AGX0"]="192.168.1.154:11434"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local name=$1
    local endpoint=$2
    local url="http://$endpoint"
    
    printf "%-10s " "$name:"
    
    if curl -s --connect-timeout 5 "$url/api/tags" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ UP${NC}"
        
        # Get model count
        local model_count=$(curl -s "$url/api/tags" | jq '.models | length' 2>/dev/null || echo "?")
        echo "           └─ Models: $model_count"
        
        # Check if it's a GPU node
        if [[ "$name" == "ORIN0" || "$name" == "AGX0" ]]; then
            local gpu_status="Unknown"
            case $name in
                "ORIN0") 
                    gpu_status=$(ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A'")
                    ;;
                "AGX0")
                    gpu_status=$(ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.154 "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A'") 
                    ;;
            esac
            echo "           └─ GPU: ${gpu_status}%"
        fi
    else
        echo -e "${RED}❌ DOWN${NC}"
    fi
    echo ""
}

check_web_service() {
    local name=$1
    local url=$2
    
    printf "%-10s " "$name:"
    
    if curl -s --connect-timeout 5 -I "$url" | grep -q "HTTP.*200\|HTTP.*302"; then
        echo -e "${GREEN}✅ UP${NC}"
    else
        echo -e "${RED}❌ DOWN${NC}"
    fi
}

echo "🤖 Ollama API Services:"
echo "----------------------"
for node in "${!NODES[@]}"; do
    check_service "$node" "${NODES[$node]}"
done

echo ""
echo "💻 Web Services:"
echo "---------------"
check_web_service "PI51-Code" "http://192.168.1.147:8080"
check_web_service "ORIN0-Code" "http://192.168.1.157:8081"  
check_web_service "PI51-Web" "http://192.168.1.147/"

echo ""
echo "🗄️ Database Services:"
echo "--------------------"
printf "%-10s " "PostgreSQL:"
if nc -z 192.168.1.157 5433 2>/dev/null; then
    echo -e "${GREEN}✅ UP${NC}"
else  
    echo -e "${RED}❌ DOWN${NC}"
fi

echo ""
echo "📁 Shared Storage:"
echo "-----------------"
printf "%-10s " "NFS:"
if ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "ls /mnt/shared-models/manifests >/dev/null 2>&1"; then
    echo -e "${GREEN}✅ MOUNTED${NC}"
    local model_count=$(ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "ls /mnt/shared-models/manifests/registry.ollama.ai/library/ 2>/dev/null | wc -l")
    echo "           └─ Shared models: $model_count"
else
    echo -e "${RED}❌ NOT MOUNTED${NC}"
fi

echo ""
echo "🎯 Quick Access URLs:"
echo "--------------------"
echo "• Main Gateway:    http://192.168.1.147/"
echo "• PI51 Code:       http://192.168.1.147:8080/ (password: jetsoncopilot)"
echo "• ORIN0 Code:      http://192.168.1.157:8081/ (password: ollama-cluster-dev)"
echo "• AGX0 Ollama:     http://192.168.1.154:11434/"
echo ""
echo "🔧 Management Commands:"
echo "----------------------"
echo "• Check logs:      ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] 'docker logs [container]'"
echo "• Restart services: ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] 'docker compose -f docker-compose-shared.yml restart'"
echo "• Monitor GPU:     ssh -i ~/.ssh/ollama_cluster_key mconners@[NODE_IP] 'nvidia-smi'"
