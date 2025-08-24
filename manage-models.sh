#!/bin/bash

# Model Management Script for Ollama Cluster
# Loads and tests your existing 134GB model collection

AGX0_API="http://192.168.1.154:11434"
ORIN0_API="http://192.168.1.157:11435"

echo "🤖 Ollama Cluster Model Manager"
echo "==============================="

# Available models based on your inventory
AVAILABLE_MODELS=(
    "phi3:mini"
    "llama3:8b"
    "gemma3:4b"
    "codellama:34b" 
    "qwen2.5-coder:32b"
    "gemma2:27b"
    "llama3:latest"
)

show_loaded_models() {
    local api_url=$1
    local node_name=$2
    
    echo "📋 Currently loaded models on $node_name:"
    local models=$(curl -s "$api_url/api/tags" | jq -r '.models[]?.name' 2>/dev/null)
    
    if [ -z "$models" ]; then
        echo "   ⚠️  No models currently loaded"
    else
        echo "$models" | sed 's/^/   ✅ /'
    fi
    echo
}

load_model() {
    local model_name=$1
    local api_url=$2
    local node_name=$3
    
    echo "📥 Loading $model_name on $node_name..."
    
    # Start the pull in background and show progress
    curl -X POST "$api_url/api/pull" -d "{\"name\":\"$model_name\"}" &
    local curl_pid=$!
    
    # Wait a moment for it to start
    sleep 2
    
    # Check if model is now available
    local retries=0
    while [ $retries -lt 30 ]; do
        if curl -s "$api_url/api/tags" | jq -r '.models[]?.name' | grep -q "^$model_name$"; then
            echo "   ✅ $model_name loaded successfully!"
            return 0
        fi
        echo -n "."
        sleep 2
        ((retries++))
    done
    
    echo "   ⚠️  $model_name may still be loading (check manually)"
    return 1
}

test_model() {
    local model_name=$1
    local api_url=$2
    local prompt=${3:-"Hello! Can you help me?"}
    
    echo "🧪 Testing $model_name..."
    
    local response=$(curl -s -X POST "$api_url/api/generate" \
        -d "{\"model\":\"$model_name\",\"prompt\":\"$prompt\",\"stream\":false}" \
        | jq -r '.response' 2>/dev/null)
    
    if [ "$response" != "null" ] && [ -n "$response" ]; then
        echo "   💬 Response: ${response:0:100}..."
        echo "   ✅ $model_name is working!"
    else
        echo "   ❌ $model_name did not respond properly"
    fi
    echo
}

case "$1" in
    "status")
        echo "📊 Current cluster status:"
        echo
        show_loaded_models "$AGX0_API" "AGX0 Primary"
        show_loaded_models "$ORIN0_API" "ORIN0 Secondary"
        ;;
        
    "load")
        if [ -z "$2" ]; then
            echo "Available models to load:"
            printf "   %s\n" "${AVAILABLE_MODELS[@]}"
            echo
            echo "Usage: $0 load <model_name> [node]"
            echo "Nodes: agx0 (default), orin0"
            exit 1
        fi
        
        model=$2
        node=${3:-"agx0"}
        
        case $node in
            "agx0")
                load_model "$model" "$AGX0_API" "AGX0"
                ;;
            "orin0") 
                load_model "$model" "$ORIN0_API" "ORIN0"
                ;;
            *)
                echo "Unknown node: $node. Use 'agx0' or 'orin0'"
                exit 1
                ;;
        esac
        ;;
        
    "test")
        model=${2:-"phi3:mini"}
        node=${3:-"agx0"}
        prompt=${4:-"Write a simple Python function to add two numbers."}
        
        case $node in
            "agx0")
                test_model "$model" "$AGX0_API" "$prompt"
                ;;
            "orin0")
                test_model "$model" "$ORIN0_API" "$prompt"  
                ;;
            *)
                echo "Unknown node: $node"
                exit 1
                ;;
        esac
        ;;
        
    "quick-start")
        echo "🚀 Quick start: Loading lightweight models for testing..."
        echo
        
        load_model "phi3:mini" "$AGX0_API" "AGX0"
        sleep 5
        load_model "phi3:mini" "$ORIN0_API" "ORIN0"
        
        echo
        echo "🧪 Testing loaded models..."
        test_model "phi3:mini" "$AGX0_API" "Hello!"
        test_model "phi3:mini" "$ORIN0_API" "Hello!"
        ;;
        
    "heavy-duty")
        echo "💪 Loading heavy-duty models on AGX0..."
        echo
        
        load_model "codellama:34b" "$AGX0_API" "AGX0"
        sleep 10
        load_model "qwen2.5-coder:32b" "$AGX0_API" "AGX0"
        
        echo
        echo "🧪 Testing coding capabilities..."
        test_model "codellama:34b" "$AGX0_API" "Write a Python class for a binary search tree."
        ;;
        
    *)
        echo "Usage: $0 {status|load|test|quick-start|heavy-duty}"
        echo
        echo "Commands:"
        echo "  status        - Show currently loaded models"
        echo "  load <model>  - Load a specific model"  
        echo "  test <model>  - Test a loaded model"
        echo "  quick-start   - Load lightweight models for immediate use"
        echo "  heavy-duty    - Load powerful coding models"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 load phi3:mini"
        echo "  $0 load codellama:34b agx0"
        echo "  $0 test llama3:8b agx0 'Explain machine learning'"
        echo "  $0 quick-start"
        exit 1
        ;;
esac
