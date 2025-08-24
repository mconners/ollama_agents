#!/bin/bash

# Intelligent Model Distribution Strategy
# Copies essential models to other nodes based on their capabilities

SOURCE_NODE="192.168.1.154"  # AGX0 with existing models
SOURCE_PATH="/home/mconners/jetson-copilot/ollama_models"

echo "🎯 Ollama Cluster Model Distribution Strategy"
echo "============================================"

# Function to copy models via rsync
copy_models() {
    local target_node=$1
    local target_path=$2
    local models_list=$3
    
    echo "📡 Copying models to $target_node..."
    echo "📋 Models: $models_list"
    
    # Create target directory
    ssh -i ~/.ssh/ollama_cluster_key mconners@$target_node "mkdir -p $target_path"
    
    # Use rsync for efficient copying (only copies differences)
    rsync -avz --progress -e "ssh -i ~/.ssh/ollama_cluster_key" \
        $SOURCE_PATH/manifests/registry.ollama.ai/library/{$models_list} \
        mconners@$target_node:$target_path/manifests/registry.ollama.ai/library/
        
    rsync -avz --progress -e "ssh -i ~/.ssh/ollama_cluster_key" \
        $SOURCE_PATH/blobs/ \
        mconners@$target_node:$target_path/blobs/
        
    echo "✅ Models copied to $target_node"
}

# Model distribution strategy based on node capabilities
case "$1" in
    "pi51-gateway")
        echo "🌐 PI51 Gateway - General purpose models for API serving"
        copy_models "192.168.1.147" "~/ollama-models" "llama3,phi3,gemma2,nomic-embed-text"
        ;;
        
    "orin0-secondary") 
        echo "🔧 ORIN0 Secondary - Code and development focused models"
        copy_models "192.168.1.157" "~/ollama-models" "codellama,qwen2.5-coder,phi3,llama3"
        ;;
        
    "agx0-primary")
        echo "🎮 AGX0 Primary - Already has all models (134GB)"
        echo "✅ No action needed - AGX0 is the source"
        ;;
        
    "all")
        echo "🚀 Distributing models to all nodes..."
        $0 pi51-gateway
        $0 orin0-secondary  
        ;;
        
    "sync")
        echo "🔄 Syncing updated models from AGX0 to all nodes..."
        # Only sync models that have been updated
        echo "📡 Checking for model updates..."
        
        # Add incremental sync logic here
        rsync -avz --dry-run -e "ssh -i ~/.ssh/ollama_cluster_key" \
            mconners@$SOURCE_NODE:$SOURCE_PATH/ \
            ./temp-sync-check/
        ;;
        
    *)
        echo "Usage: $0 {pi51-gateway|orin0-secondary|agx0-primary|all|sync}"
        echo ""
        echo "Strategy:"
        echo "  🌐 PI51 Gateway: General models (llama3, phi3, gemma2, embeddings)"
        echo "  🔧 ORIN0 Secondary: Code models (codellama, qwen2.5-coder, phi3)" 
        echo "  🎮 AGX0 Primary: Full model collection (source node)"
        echo ""
        echo "Benefits:"
        echo "  ✅ No network dependencies during inference"
        echo "  ✅ Each node optimized for its role"
        echo "  ✅ Fast local model access"
        echo "  ✅ Reduced storage duplication vs full replication"
        exit 1
        ;;
esac

echo ""
echo "💡 Next steps:"
echo "1. Update Docker Compose files to use ~/ollama-models:/models"
echo "2. Test local model access"
echo "3. Use 'sync' option to keep models updated"
