# SSH Key Authentication Setup Guide

## 🔐 Enhanced Security for Your Ollama Distributed AI Cluster

This guide sets up SSH key-based authentication to eliminate passwords and improve security.

## ✅ Benefits of SSH Key Authentication

- **🚫 No more passwords**: Automatic login without typing passwords  
- **🔒 Stronger security**: Cryptographic keys vs. password guessing
- **🔄 Easy rotation**: Centrally manage and rotate keys
- **🤖 Automation ready**: Scripts run without manual intervention
- **📝 Audit trail**: Better logging and access control

## 🚀 Quick Setup Process

### Step 1: Generate SSH Key (Already Done!)
```bash
# Key pair has been generated at:
# ~/.ssh/ollama_cluster_key      # Private key
# ~/.ssh/ollama_cluster_key.pub  # Public key
```

### Step 2: SSH Config (Already Created!)
Your `~/.ssh/config` now includes convenient aliases:
```bash
ssh pi51          # Gateway node
ssh agx0          # Primary AI node  
ssh orin0         # Secondary AI node
ssh backend       # Backend services
ssh utility       # Utility node
ssh edge          # Edge inference
ssh legacy        # Legacy node
```

### Step 3: Manual Key Distribution (If Needed)

If you need to manually copy keys to each node:

```bash
# For each node, run this command (replace NODE_IP):
ssh-copy-id -i ~/.ssh/ollama_cluster_key.pub mconners@NODE_IP

# Example for your main nodes:
ssh-copy-id -i ~/.ssh/ollama_cluster_key.pub mconners@192.168.1.51   # PI51
ssh-copy-id -i ~/.ssh/ollama_cluster_key.pub mconners@192.168.1.150  # AGX0  
ssh-copy-id -i ~/.ssh/ollama_cluster_key.pub mconners@192.168.1.149  # ORIN0
ssh-copy-id -i ~/.ssh/ollama_cluster_key.pub mconners@192.168.1.52   # PI52
```

### Step 4: Test SSH Key Access

```bash
# Test each node (should connect without password):
ssh pi51 'echo "✅ Gateway accessible"'
ssh agx0 'echo "✅ Primary AI accessible"'  
ssh orin0 'echo "✅ Secondary AI accessible"'
ssh backend 'echo "✅ Backend accessible"'
```

## 🛠️ Available Scripts

### 1. **setup_ssh_keys.sh** - Initial Setup
```bash
./setup_ssh_keys.sh
```
- Generates SSH key pair
- Creates SSH config with node aliases  
- Attempts to distribute keys to all nodes

### 2. **rotate_ssh_keys.sh** - Security Rotation  
```bash
./rotate_ssh_keys.sh
```
- Generates new SSH keys
- Rotates keys across all nodes
- Removes old keys for security
- **Run monthly for best security practices**

### 3. **Updated Deployment Scripts**
All deployment scripts now use SSH keys:
- `deployment/deploy_system.sh` - Uses `~/.ssh/ollama_cluster_key`
- `deployment/cleanup_system.sh` - Uses `~/.ssh/ollama_cluster_key`
- No more password prompts during deployment!

## 🔒 Security Best Practices

### Key Management
- **Rotate keys monthly**: `./rotate_ssh_keys.sh`
- **Backup keys securely**: Store in encrypted location
- **Limit key access**: `chmod 600 ~/.ssh/ollama_cluster_key`

### Access Control  
- **Use specific keys**: Each cluster has dedicated keys
- **Monitor access**: Check SSH logs regularly
- **Revoke compromised keys**: Quick removal from all nodes

### Network Security
- **VPN recommended**: For remote cluster access
- **Firewall rules**: Limit SSH access by IP
- **Fail2ban**: Automatic blocking of brute force attempts

## 🎯 Node-Specific Information

| Node | IP | SSH Alias | Role |
|------|----|-----------| -----|
| PI51 | 192.168.1.51 | `pi51`, `gateway` | API Gateway & Load Balancer |
| AGX0 | 192.168.1.150 | `agx0`, `primary-ai` | Primary AI Hub (18 models) |
| ORIN0 | 192.168.1.149 | `orin0`, `secondary-ai` | Image Gen & Code Analysis |
| PI52 | 192.168.1.52 | `pi52`, `backend` | PostgreSQL, Redis, MinIO |
| PI41 | 192.168.1.41 | `pi41`, `utility` | Monitoring & Utilities |
| NANO | 192.168.1.191 | `nano`, `edge` | Edge Inference |
| PI31 | 192.168.1.31 | `pi31`, `legacy` | Legacy Services |

## 🚨 Troubleshooting

### Connection Issues
```bash
# Check SSH connectivity:
ssh -v pi51    # Verbose connection debugging

# Test key authentication:
ssh -o PasswordAuthentication=no pi51

# Verify key permissions:
chmod 600 ~/.ssh/ollama_cluster_key
chmod 644 ~/.ssh/ollama_cluster_key.pub
```

### Key Distribution Issues
```bash
# Manual key addition to remote node:
cat ~/.ssh/ollama_cluster_key.pub | ssh mconners@192.168.1.51 \
  'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

### Permission Problems
```bash
# Fix SSH directory permissions on remote node:
ssh mconners@192.168.1.51 'chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'
```

## ✅ Verification Checklist

- [ ] SSH key pair generated (`~/.ssh/ollama_cluster_key*`)
- [ ] SSH config updated with cluster aliases
- [ ] Keys distributed to all accessible nodes
- [ ] Password-less SSH working for main nodes
- [ ] Deployment scripts updated to use keys
- [ ] Key rotation script ready for monthly use

## 🎉 Ready for Deployment!

Once SSH keys are working, your deployment process becomes:

```bash
# Deploy the entire distributed AI system:
cd deployment/
./deploy_system.sh

# No password prompts!
# Automatic, secure, and reliable deployment
```

Your cluster now has **enterprise-grade SSH security** with easy management and automated deployment capabilities!
