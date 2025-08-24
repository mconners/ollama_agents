#!/bin/bash
# Setup automated backups for Open WebUI
# This configures daily backups at 2 AM

SCRIPT_DIR="/home/mconners/ollama_agents"
CRON_JOB="0 2 * * * $SCRIPT_DIR/backup-openwebui.sh >> $SCRIPT_DIR/logs/backup.log 2>&1"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/backup-openwebui.sh"; then
    echo "⚠️  Automated backup already configured"
    echo "Current backup schedule:"
    crontab -l | grep backup-openwebui
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Automated backup configured!"
    echo "📅 Schedule: Daily at 2:00 AM"
    echo "📁 Logs: $SCRIPT_DIR/logs/backup.log"
fi

echo ""
echo "🔄 Current cron jobs:"
crontab -l

echo ""
echo "💡 Manual backup: ./backup-openwebui.sh"
echo "🔄 View logs: tail -f logs/backup.log"
