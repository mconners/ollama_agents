# 🤖 Ollama Cluster Model Inventory

## 🎮 **AGX0 Primary Node** (192.168.1.154:11434)
**Total Storage:** 134GB of models + 164KB manifests

### Available Models:
| Model | Version/Size | Purpose | Status |
|-------|-------------|---------|--------|
| **codellama** | 34b | Code generation & assistance | ✅ Ready |
| **devstral** | 24b | Development & coding | ✅ Ready |
| **gemma2** | 27b | General purpose chat | ✅ Ready |
| **gemma3** | 4b | Lightweight chat | ✅ Ready |
| **gemma3n** | latest | Newest Gemma variant | ✅ Ready |
| **gpt-oss** | latest | GPT-style responses | ✅ Ready |
| **llama3** | 8b, latest | Meta's flagship model | ✅ Ready |
| **llama3.2** | latest | Latest Llama version | ✅ Ready |
| **mistral-small3.2** | latest | Compact Mistral model | ✅ Ready |
| **mxbai-embed-large** | latest | Text embeddings | ✅ Ready |
| **nomic-embed-text** | latest | Alternative embeddings | ✅ Ready |
| **phi3** | mini | Microsoft's efficient model | ✅ Ready |
| **qwen2.5-coder** | 32b | Advanced coding assistant | ✅ Ready |
| **qwen2.5vl** | 3b | Vision + language model | ✅ Ready |

**🔗 Access:** `http://192.168.1.154:11434`

---

## 🔧 **ORIN0 Secondary Node** (192.168.1.157:11435)
**Shared Access:** All AGX0 models via NFS mount
**Local Storage:** Empty (ready for node-specific models)

### Accessible Models (via NFS):
- ✅ **All AGX0 models** listed above via `/mnt/shared-models`
- 📁 **Local storage** at `./data/ollama-secondary/models` (empty, ready for local pulls)

**🔗 Access:** `http://192.168.1.157:11435`

---

## 🌐 **PI51 Gateway** (192.168.1.147:11434)
**Status:** Not yet deployed with models
**Purpose:** Load balancer and lightweight models

**Planned Models:**
- `phi3:mini` - Lightweight chat
- `gemma2:2b` - Compact general purpose  
- `nomic-embed-text` - Text embeddings

---

## 🎯 **Model Recommendations by Use Case**

### **💻 Code Development:**
- **Primary:** `codellama:34b` (AGX0) - Advanced code generation
- **Secondary:** `qwen2.5-coder:32b` (AGX0) - Excellent coding assistant  
- **Lightweight:** `phi3:mini` (Any node) - Quick code help

### **💬 General Chat:**
- **Best Quality:** `llama3:8b` (AGX0) - Most capable
- **Balanced:** `gemma2:27b` (AGX0) - Good quality, efficient
- **Fast:** `gemma3:4b` (AGX0) - Quick responses

### **🔍 Embeddings/Search:**
- **Primary:** `mxbai-embed-large` (AGX0)
- **Alternative:** `nomic-embed-text` (AGX0)

### **🎨 Multimodal (Vision + Text):**
- **Vision:** `qwen2.5vl:3b` (AGX0) - Can process images

---

## 🚀 **How to Use Your Models**

### **Direct API Access:**
```bash
# Use the most capable coding model
curl -X POST http://192.168.1.154:11434/api/generate \
  -d '{"model":"codellama:34b","prompt":"Write a Python web scraper","stream":false}'

# Use fast general chat  
curl -X POST http://192.168.1.154:11434/api/generate \
  -d '{"model":"llama3:8b","prompt":"Explain quantum computing","stream":false}'

# Use lightweight model for quick responses
curl -X POST http://192.168.1.154:11434/api/generate \
  -d '{"model":"phi3:mini","prompt":"Hello, how are you?","stream":false}'
```

### **List Currently Loaded Models:**
```bash
# AGX0 (main collection)
curl -s http://192.168.1.154:11434/api/tags | jq '.models[].name'

# ORIN0 (shared access)  
curl -s http://192.168.1.157:11435/api/tags | jq '.models[].name'
```

### **Load a Model (if not already loaded):**
```bash
# Load to AGX0
curl -X POST http://192.168.1.154:11434/api/pull -d '{"name":"llama3:8b"}'

# Load to ORIN0  
curl -X POST http://192.168.1.157:11435/api/pull -d '{"name":"phi3:mini"}'
```

---

## 📊 **Storage Summary**
- **Total Models Available:** 14 different models
- **Total Storage Used:** ~134GB (all on AGX0)
- **Shared Access:** ORIN0 can access all AGX0 models via NFS
- **Local Persistence:** Each node can store frequently used models locally

---

## 💡 **Next Steps**
1. **Load models into Ollama** - Models exist on disk but need to be loaded into the API
2. **Deploy PI51 Gateway** - For load balancing and lightweight access
3. **Test specific models** - Try different models for your use cases
4. **Set up model auto-loading** - Configure which models start automatically

---

**🎯 Pro Tip:** Your AGX0 has an incredible collection! The `qwen2.5-coder:32b` and `codellama:34b` are particularly powerful for development work.
