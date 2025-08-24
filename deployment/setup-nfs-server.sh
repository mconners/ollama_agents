#!/bin/bash

# Setup AGX0 as NFS Server for Shared Models
# This allows other nodes to mount AGX0's ~/ollama directory

echo "🗄️ Setting up AGX0 as NFS Server for Model Sharing"
echo "=================================================="

# Install NFS server
sudo apt update
sudo apt install -y nfs-kernel-server

# Create NFS export configuration
echo "📝 Configuring NFS exports..."
sudo tee -a /etc/exports << EOF

# Ollama Models Share
/home/mconners/jetson-copilot/ollama_models 192.168.1.0/24(ro,sync,no_subtree_check,no_root_squash)
EOF

# Restart NFS service
echo "🔄 Starting NFS services..."
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server
sudo exportfs -a

# Show exports
echo "✅ NFS Server configured. Available exports:"
sudo exportfs -v

echo ""
echo "🌐 Other nodes can mount with:"
echo "  sudo mount -t nfs 192.168.1.154:/home/mconners/jetson-copilot/ollama_models /mnt/shared-models"
echo ""
echo "📋 To make permanent, add to /etc/fstab:"
echo "  192.168.1.154:/home/mconners/jetson-copilot/ollama_models /mnt/shared-models nfs ro,defaults 0 0"
