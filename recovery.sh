#!/bin/bash

# Post-Reboot Recovery Script for Ollama Cluster
# Fixes common issues after router/network restart

echo "🔄 Ollama Cluster Recovery After Router Reboot"
echo "==============================================="

# Check basic connectivity
echo "📡 Checking node connectivity..."

NODES=("192.168.1.154" "192.168.1.157" "192.168.1.147")
NODE_NAMES=("AGX0" "ORIN0" "PI51")

for i in "${!NODES[@]}"; do
    ip=${NODES[$i]}
    name=${NODE_NAMES[$i]}
    if ping -c 1 -W 3 "$ip" > /dev/null 2>&1; then
        echo "✅ $name ($ip) - Online"
    else
        echo "❌ $name ($ip) - Offline"
    fi
done

echo ""
echo "🔧 Checking and fixing services..."

# Check AGX0 Ollama
echo "Checking AGX0 Ollama..."
if curl -s "http://192.168.1.154:11434/api/tags" > /dev/null; then
    echo "✅ AGX0 Ollama API responding"
else
    echo "⚠️  AGX0 Ollama needs restart"
    ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.154 \
        "cd ~/ollama-containers && ./run.sh --volume ~/ollama:/ollama -e OLLAMA_MODELS=/ollama \$(autotag ollama) --restart" || \
    echo "   Manual restart may be needed on AGX0"
fi

# Check ORIN0 services
echo "Checking ORIN0 services..."
if curl -s "http://192.168.1.157:11435/api/tags" > /dev/null; then
    models_count=$(curl -s "http://192.168.1.157:11435/api/tags" | jq '.models | length' 2>/dev/null || echo "0")
    if [ "$models_count" -gt 0 ]; then
        echo "✅ ORIN0 Ollama API responding with $models_count models"
    else
        echo "⚠️  ORIN0 Ollama has no models - NFS mount issue"
        echo "   Restarting ORIN0 Ollama service..."
        ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker restart ollama-secondary" || echo "   Manual restart needed"
    fi
else
    echo "⚠️  ORIN0 Ollama not responding"
    ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker restart ollama-secondary" || echo "   Manual restart needed"
fi

# Check Open WebUI
echo "Checking Open WebUI..."
if curl -s "http://192.168.1.157:8080" > /dev/null; then
    echo "✅ Open WebUI responding"
else
    echo "⚠️  Open WebUI not responding, restarting..."
    ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker restart open-webui-cluster" || echo "   Manual restart needed"
fi

# Check Code Server
echo "Checking Code Server..."
if curl -s "http://192.168.1.157:8081" > /dev/null; then
    echo "✅ Code Server responding"
else
    echo "⚠️  Code Server not responding"
fi

echo ""
echo "🧪 Testing AI models..."

# Quick test of a lightweight model
response=$(curl -s -X POST "http://192.168.1.154:11434/api/generate" \
    -d '{"model":"phi3:mini","prompt":"Test: What is 1+1?","stream":false}' \
    --max-time 30 | jq -r '.response' 2>/dev/null || echo "Failed")

if [[ "$response" != "Failed" && "$response" != "null" ]]; then
    echo "✅ AI models working: $response" | head -c 100
    echo "..."
else
    echo "⚠️  AI model test failed - may need manual intervention"
fi

echo ""
echo "📋 Recovery Summary:"
echo "===================="
echo "• Open WebUI: http://192.168.1.157:8080"
echo "• Code Server: http://192.168.1.157:8081"
echo "• AGX0 API: http://192.168.1.154:11434"
echo "• ORIN0 API: http://192.168.1.157:11435"
echo ""
echo "🔧 If issues persist, try:"
echo "   ./cluster status"
echo "   ./setup-openwebui.sh restart"
echo "   ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.154"
