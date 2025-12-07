#!/bin/bash
################################################################################
# Script: hf_login.sh
# Purpose: HuggingFace authentication helper
# Usage: ./utils/hf_login.sh
################################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  HuggingFace Authentication"
echo "=============================================="
echo ""

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    echo -e "${GREEN}✓${NC} Loaded configuration from .env"
else
    echo -e "${RED}✗${NC} .env file not found"
    echo "  Please copy .env.example to .env and configure it"
    exit 1
fi

# Check if HF_TOKEN is set
if [ -z "${HF_TOKEN:-}" ] || [ "$HF_TOKEN" == "your_huggingface_token_here" ]; then
    echo -e "${RED}✗${NC} HF_TOKEN not configured in .env"
    echo ""
    echo "Please:"
    echo "  1. Get your token from: https://huggingface.co/settings/tokens"
    echo "  2. Edit .env and set HF_TOKEN=your_actual_token"
    exit 1
fi

# Check if HF_USER is set
if [ -z "${HF_USER:-}" ] || [ "$HF_USER" == "your_huggingface_username" ]; then
    echo -e "${RED}✗${NC} HF_USER not configured in .env"
    echo ""
    echo "Please edit .env and set HF_USER=your_username"
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Logging in to HuggingFace..."
echo "  User: $HF_USER"
echo ""

# Activate conda environment
source "$SCRIPT_DIR/utils/activate_env.sh"

# Login to HuggingFace
if huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential; then
    echo ""
    echo -e "${GREEN}✓${NC} Successfully logged in to HuggingFace"
    echo ""
    
    # Verify login
    echo -e "${BLUE}[INFO]${NC} Verifying authentication..."
    if huggingface-cli whoami; then
        echo ""
        echo -e "${GREEN}✓${NC} Authentication verified"
    fi
else
    echo ""
    echo -e "${RED}✗${NC} Failed to login to HuggingFace"
    echo "  Please check your token and try again"
    exit 1
fi

echo ""
echo "=============================================="
echo ""