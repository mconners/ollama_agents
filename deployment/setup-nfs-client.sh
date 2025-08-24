#!/bin/bash

# Setup NFS Client to Mount Shared Models from AGX0
# Run this on PI51, ORIN0, and other nodes

NODE_NAME=${1:-"unknown"}
NFS_SERVER="192.168.1.154"
MOUNT_POINT="/mnt/shared-models"

echo "📡 Setting up $NODE_NAME as NFS Client"
echo "======================================"

# Install NFS client
echo "📦 Installing NFS client..."
sudo apt update
sudo apt install -y nfs-common

# Create mount point
echo "📁 Creating mount point: $MOUNT_POINT"
sudo mkdir -p $MOUNT_POINT

# Mount shared models (read-only)
echo "🔗 Mounting shared models from AGX0..."
sudo mount -t nfs $NFS_SERVER:/home/mconners/jetson-copilot/ollama_models $MOUNT_POINT

# Add to fstab for persistent mounting
echo "💾 Adding to /etc/fstab for persistent mounting..."
if ! grep -q "$NFS_SERVER:/home/mconners/jetson-copilot/ollama_models" /etc/fstab; then
    echo "$NFS_SERVER:/home/mconners/jetson-copilot/ollama_models $MOUNT_POINT nfs ro,defaults 0 0" | sudo tee -a /etc/fstab
fi

# Verify mount
echo "✅ Verifying mount..."
df -h $MOUNT_POINT
ls -la $MOUNT_POINT

echo ""
echo "🎉 $NODE_NAME now has access to shared models at $MOUNT_POINT"
echo "📝 Update Docker Compose to use: $MOUNT_POINT:/models:ro"
