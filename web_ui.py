#!/usr/bin/env python3
"""
Interactive Web Interface for Ollama Cluster
Launch this for a simple web UI to your AI models
"""

import streamlit as st
import requests
import json

# Cluster endpoints
ENDPOINTS = {
    "AGX0 (Main)": "http://192.168.1.154:11434",
    "ORIN0 (Secondary)": "http://192.168.1.157:11435"
}

MODELS = [
    "codellama:34b", "qwen2.5-coder:32b", "gemma2:27b", "devstral:24b",
    "llama3:8b", "phi3:mini", "qwen2.5vl:3b", "mistral-small3.2:latest"
]

st.title("🤖 Ollama AI Cluster Interface")
st.write("Your distributed AI system with 134GB of models")

# Sidebar
st.sidebar.title("Configuration")
selected_endpoint = st.sidebar.selectbox("Choose Node:", list(ENDPOINTS.keys()))
selected_model = st.sidebar.selectbox("Choose Model:", MODELS)

endpoint_url = ENDPOINTS[selected_endpoint]

# Main interface
st.write(f"**Active Node:** {selected_endpoint}")
st.write(f"**Model:** {selected_model}")
st.write(f"**Endpoint:** {endpoint_url}")

# Chat interface
if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("Ask your AI cluster anything..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        with st.spinner(f"Thinking with {selected_model}..."):
            try:
                response = requests.post(
                    f"{endpoint_url}/api/generate",
                    json={
                        "model": selected_model,
                        "prompt": prompt,
                        "stream": False
                    },
                    timeout=120
                )
                
                if response.status_code == 200:
                    result = response.json()
                    ai_response = result.get('response', 'No response received')
                    st.markdown(ai_response)
                    st.session_state.messages.append({"role": "assistant", "content": ai_response})
                else:
                    error_msg = f"Error {response.status_code}: {response.text}"
                    st.error(error_msg)
                    
            except requests.exceptions.Timeout:
                st.error("Request timed out. Model might be loading or busy.")
            except Exception as e:
                st.error(f"Connection error: {str(e)}")

# Status check
with st.sidebar:
    st.write("---")
    if st.button("Check Status"):
        for name, url in ENDPOINTS.items():
            try:
                response = requests.get(f"{url}/api/tags", timeout=5)
                if response.status_code == 200:
                    models = response.json().get('models', [])
                    st.success(f"{name}: ✅ ({len(models)} models)")
                else:
                    st.error(f"{name}: ❌")
            except:
                st.error(f"{name}: ❌ Offline")

st.sidebar.write("---")
st.sidebar.write("**Quick Commands:**")
st.sidebar.code("./cluster status")
st.sidebar.code("./cluster coding") 
st.sidebar.code("./cluster chat")
