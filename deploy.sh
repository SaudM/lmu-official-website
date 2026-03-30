#!/bin/bash

# ==============================================================================
# Deployment Script for LMU Web (with Cache Busting)
# Target: work@47.92.165.32:/var/www/html/lum-web
# ==============================================================================

# Remote Server Configuration
REMOTE_USER="work"
REMOTE_HOST="47.92.165.32"
REMOTE_PATH="/var/www/html/lum-web"
LOCAL_PATH="./" # Current directory
BUILD_DIR=".deploy_build"

# Version string (Timestamp)
VERSION=$(date +%Y%m%d%H%M%S)

# Exclude patterns
EXCLUDE_PATTERNS=(
    ".git*"
    ".idea"
    ".DS_Store"
    "deploy.sh"
    "*.log"
    "$BUILD_DIR"
    "implementation_plan.md"
)

# ANSI colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== LMU Web Deployment (Cache Busting) ===${NC}"
echo -e "Target: ${YELLOW}${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}${NC}"
echo -e "Version ID: ${YELLOW}${VERSION}${NC}"

# Check if we are in the right directory
if [ ! -f "index.html" ]; then
    echo -e "${RED}Error: index.html not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Confirmation
if [[ "$1" != "--dry-run" ]]; then
    read -p "Are you sure you want to deploy to production? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Deployment cancelled.${NC}"
        exit 1
    fi
fi

# 1. Prepare Build Directory
echo -e "${GREEN}Preparing build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy files to build directory (excluding unnecessary files)
RSYNC_EXCLUDES=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude='$pattern'"
done

eval "rsync -a $RSYNC_EXCLUDES $LOCAL_PATH $BUILD_DIR/"

# 2. Inject Versioning into HTML files (Cache Busting)
echo -e "${GREEN}Injecting asset versions into HTML files...${NC}"
# Find all HTML files in the build directory
find "$BUILD_DIR" -name "*.html" -type f | while read -r html_file; do
    # macOS sed syntax (-i '')
    # Replace href="xxx.css" with href="xxx.css?v=TIMESTAMP" (avoiding external URLs)
    sed -i '' "s|href=\"\([^/][^\":]*\.css\)\"|href=\"\1?v=$VERSION\"|g" "$html_file"
    sed -i '' "s|href=\"/\([^\":]*\.css\)\"|href=\"/\1?v=$VERSION\"|g" "$html_file"
    
    # Same for JS scripts
    sed -i '' "s|src=\"\([^/][^\":]*\.js\)\"|src=\"\1?v=$VERSION\"|g" "$html_file"
    sed -i '' "s|src=\"/\([^\":]*\.js\)\"|src=\"/\1?v=$VERSION\"|g" "$html_file"
done

# 3. Dry Run Check
if [[ "$1" == "--dry-run" ]]; then
    echo -e "${YELLOW}Running in DRY-RUN mode (syncing from $BUILD_DIR to remote server)...${NC}"
    RSYNC_OPTS="-avzn"
else
    RSYNC_OPTS="-avz"
fi

# 4. Sync Build to Server
# --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rwx,Fg=rx,Fo=rx sets permissions to 755
eval "rsync $RSYNC_OPTS --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rwx,Fg=rx,Fo=rx $BUILD_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful! (Version: $VERSION)${NC}"
else
    echo -e "${RED}❌ Deployment failed.${NC}"
    # Cleanup on failure too
    rm -rf "$BUILD_DIR"
    exit 1
fi

# 5. Cleanup
echo -e "${GREEN}Cleaning up...${NC}"
rm -rf "$BUILD_DIR"
