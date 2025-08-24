#!/bin/bash
# Open WebUI Data Backup Script
# Backs up user data, chat history, and settings

set -e

BACKUP_DIR="/home/mconners/ollama_agents/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="openwebui-backup-${DATE}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🔄 Starting Open WebUI backup..."
echo "📅 Date: $(date)"
echo "📁 Backup location: $BACKUP_DIR/$BACKUP_FILE"

# Backup Open WebUI data volume
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "
  docker run --rm \
    -v open-webui:/data \
    -v /tmp:/backup \
    alpine tar czf /backup/$BACKUP_FILE -C /data .
"

# Copy backup file to local backup directory
scp -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157:/tmp/$BACKUP_FILE "$BACKUP_DIR/"

# Clean up temporary file on remote
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "sudo rm -f /tmp/$BACKUP_FILE"

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)

echo "✅ Backup completed successfully!"
echo "📊 Backup size: $BACKUP_SIZE"
echo "📁 Location: $BACKUP_DIR/$BACKUP_FILE"

# Keep only last 7 backups
cd "$BACKUP_DIR"
ls -t openwebui-backup-*.tar.gz | tail -n +8 | xargs -r rm -f

echo "🧹 Old backups cleaned up (keeping last 7)"
echo "📋 Available backups:"
ls -lah openwebui-backup-*.tar.gz 2>/dev/null || echo "No backups found"
