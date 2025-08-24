# Deployment Templates

This directory contains sanitized template files for deployment. 

**Important**: The actual deployment files with credentials are excluded from git via `.gitignore`.

## Files excluded from repository:
- Files with hardcoded passwords (admin123, fieldday, etc.)
- SSH keys and certificates
- Router configuration with credentials
- Any file containing actual API keys or tokens

## To use:
1. Copy template files and add your actual credentials
2. Never commit files with real passwords/keys
3. Use environment variables or secure vaults for credentials

## Template files available:
- `docker-compose-template.yml` - Generic compose template
- `setup-template.sh` - Setup script template
- `config-template.json` - Configuration template
