#!/bin/bash
# Open WebUI Data Restore Script
# Restores user data, chat history, and settings from backup

set -e

BACKUP_DIR="/home/mconners/ollama_agents/backups"

if [ $# -eq 0 ]; then
    echo "🔄 Open WebUI Restore Script"
    echo "Usage: $0 <backup-file>"
    echo ""
    echo "Available backups:"
    ls -lah "$BACKUP_DIR"/openwebui-backup-*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

echo "🔄 Starting Open WebUI restore..."
echo "📅 Date: $(date)"
echo "📁 Restoring from: $BACKUP_DIR/$BACKUP_FILE"

# Confirm restore
read -p "⚠️  This will overwrite current Open WebUI data. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Restore cancelled"
    exit 1
fi

# Stop Open WebUI container
echo "🛑 Stopping Open WebUI..."
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker stop open-webui-cluster || true"

# Copy backup to remote server
echo "📤 Uploading backup file..."
scp -i ~/.ssh/ollama_cluster_key "$BACKUP_DIR/$BACKUP_FILE" mconners@192.168.1.157:/tmp/

# Restore data
echo "🔄 Restoring data..."
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "
  docker run --rm \
    -v open-webui:/data \
    -v /tmp:/backup \
    alpine sh -c 'cd /data && rm -rf * && tar xzf /backup/$BACKUP_FILE'
"

# Clean up temporary file
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "rm -f /tmp/$BACKUP_FILE"

# Restart Open WebUI container
echo "🚀 Restarting Open WebUI..."
ssh -i ~/.ssh/ollama_cluster_key mconners@192.168.1.157 "docker start open-webui-cluster"

# Wait for service to be ready
echo "⏳ Waiting for service to start..."
sleep 10

# Test service
if curl -s http://192.168.1.157:8080/ > /dev/null; then
    echo "✅ Restore completed successfully!"
    echo "🌐 Open WebUI is available at: http://192.168.1.157:8080"
else
    echo "⚠️  Restore completed but service may need more time to start"
    echo "🔍 Check status with: ./cluster status"
fi
