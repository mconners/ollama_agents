#!/bin/bash

# Import existing models into Ollama without internet dependency
# Works with your 134GB local model collection

AGX0_IP="192.168.1.154"
AGX0_API="http://$AGX0_IP:11434"

echo "🔧 Loading Your Complex Models into Ollama"
echo "=========================================="

# Your most powerful models for complex tasks
COMPLEX_MODELS=(
    "codellama:34b"      # 34B parameter coding model
    "qwen2.5-coder:32b"  # 32B parameter advanced coder
    "gemma2:27b"         # 27B parameter general purpose
    "devstral:24b"       # 24B parameter development focused
    "llama3:8b"          # 8B parameter Meta flagship
)

# Function to force load a model that exists locally
force_load_model() {
    local model_name=$1
    echo "🚀 Loading $model_name..."
    
    # Try to directly access the model (this should trigger loading from local storage)
    echo "   📡 Sending test prompt to trigger model loading..."
    
    response=$(curl -s -m 60 -X POST "$AGX0_API/api/generate" \
        -d "{\"model\":\"$model_name\",\"prompt\":\"Hello\",\"stream\":false}" 2>/dev/null)
    
    if echo "$response" | grep -q '"response"'; then
        echo "   ✅ $model_name loaded and responding!"
        # Get a proper response
        actual_response=$(echo "$response" | jq -r '.response' 2>/dev/null)
        echo "   💬 Response: ${actual_response:0:80}..."
        return 0
    elif echo "$response" | grep -q '"error"'; then
        error_msg=$(echo "$response" | jq -r '.error' 2>/dev/null)
        echo "   ⚠️  $model_name error: $error_msg"
        return 1
    else
        echo "   ⏳ $model_name may be loading... (large models take time)"
        return 2
    fi
}

# Function to test model with a complex prompt
test_complex_model() {
    local model_name=$1
    local task_type=$2
    
    case $task_type in
        "coding")
            prompt="Write a Python class for a binary search tree with insert, search, and delete methods. Include proper documentation."
            ;;
        "analysis")
            prompt="Explain the differences between supervised and unsupervised machine learning, with examples of algorithms for each."
            ;;
        "architecture")
            prompt="Design a microservices architecture for an e-commerce platform. Include API gateway, databases, and service communication."
            ;;
        *)
            prompt="Provide a detailed explanation of how neural networks learn through backpropagation."
            ;;
    esac
    
    echo "🧠 Testing $model_name with complex $task_type task..."
    echo "   📝 Prompt: ${prompt:0:80}..."
    
    start_time=$(date +%s)
    response=$(curl -s -m 120 -X POST "$AGX0_API/api/generate" \
        -d "{\"model\":\"$model_name\",\"prompt\":\"$prompt\",\"stream\":false}")
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if echo "$response" | grep -q '"response"'; then
        actual_response=$(echo "$response" | jq -r '.response' 2>/dev/null)
        response_length=${#actual_response}
        echo "   ✅ Generated ${response_length} characters in ${duration}s"
        echo "   🎯 Preview: ${actual_response:0:200}..."
        echo ""
    else
        echo "   ❌ No response received"
        echo ""
    fi
}

# Check current status
echo "📊 Current Ollama status:"
current_models=$(curl -s "$AGX0_API/api/tags" | jq -r '.models[]?.name' 2>/dev/null)
if [ -z "$current_models" ]; then
    echo "   ⚠️  No models currently loaded in Ollama API"
else
    echo "$current_models" | sed 's/^/   ✅ /'
fi
echo ""

# Try to load complex models
echo "🚀 Attempting to load complex models..."
echo ""

loaded_models=()
for model in "${COMPLEX_MODELS[@]}"; do
    if force_load_model "$model"; then
        loaded_models+=("$model")
    fi
    echo ""
done

# Test the loaded models with complex tasks
if [ ${#loaded_models[@]} -gt 0 ]; then
    echo "🧪 Testing loaded models with complex tasks..."
    echo ""
    
    for model in "${loaded_models[@]}"; do
        case $model in
            *"codellama"*|*"coder"*)
                test_complex_model "$model" "coding"
                ;;
            *"gemma"*|*"llama"*)
                test_complex_model "$model" "analysis"
                ;;
            *"devstral"*)
                test_complex_model "$model" "architecture"
                ;;
            *)
                test_complex_model "$model" "general"
                ;;
        esac
    done
else
    echo "⚠️  No complex models loaded successfully."
    echo "   This might be due to:"
    echo "   • Models needing more time to load (they're very large)"
    echo "   • Memory constraints"
    echo "   • Model format compatibility"
    echo ""
    echo "💡 Alternative approaches:"
    echo "   1. Try loading one model at a time"
    echo "   2. Use the web interface at http://$AGX0_IP:8888 (when AGX0 fully deployed)"
    echo "   3. Check Docker container logs: docker logs ollama-agx0-models"
fi

echo ""
echo "🎯 Summary of Complex Models Available:"
echo "======================================="
for model in "${COMPLEX_MODELS[@]}"; do
    echo "• $model - Stored locally (134GB collection)"
done

echo ""
echo "💻 Direct API Usage Examples:"
echo "-----------------------------"
echo "# Use your most powerful coding model:"
echo "curl -X POST $AGX0_API/api/generate \\"
echo "  -d '{\"model\":\"codellama:34b\",\"prompt\":\"Create a REST API in Python\",\"stream\":false}'"
echo ""
echo "# Use advanced coder for complex algorithms:"
echo "curl -X POST $AGX0_API/api/generate \\"
echo "  -d '{\"model\":\"qwen2.5-coder:32b\",\"prompt\":\"Implement quicksort algorithm\",\"stream\":false}'"
