#!/bin/bash

# ==============================================================================
# Deployment Script for LMU Web
# Target: work@47.92.165.32:/var/www/html/lum-web
# ==============================================================================

# Remote Server Configuration
REMOTE_USER="work"
REMOTE_HOST="47.92.165.32"
REMOTE_PATH="/var/www/html/lum-web"
LOCAL_PATH="./" # Current directory

# Exclude patterns (add more as needed)
EXCLUDE_PATTERNS=(
    ".git*"
    ".idea"
    ".DS_Store"
    "deploy.sh"
    "*.log"
)

# Build the exclude arguments for rsync
RSYNC_EXCLUDES=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude='$pattern'"
done

# ANSI colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== LMU Web Deployment ===${NC}"
echo -e "Target: ${YELLOW}${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}${NC}"

# Check if we are in the right directory (simple check for index.html)
if [ ! -f "index.html" ]; then
    echo -e "${RED}Error: index.html not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Dry run option
if [[ "$1" == "--dry-run" ]]; then
    echo -e "${YELLOW}Running in DRY-RUN mode (no files will be changed)...${NC}"
    RSYNC_OPTS="-avzn"
else
    # Confirm before proceeding
    read -p "Are you sure you want to deploy to production? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Deployment cancelled.${NC}"
        exit 1
    fi
    RSYNC_OPTS="-avz"
fi

echo -e "${GREEN}Starting deployment...${NC}"

# Run rsync
# --delete ensures the remote matches exactly with the local project
# --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rwx,Fg=rx,Fo=rx sets permissions to 755 for both dirs and files
eval "rsync $RSYNC_OPTS $RSYNC_EXCLUDES --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rwx,Fg=rx,Fo=rx $LOCAL_PATH $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
else
    echo -e "${RED}❌ Deployment failed. Check your connection or SSH keys.${NC}"
    exit 1
fi
