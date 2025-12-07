#!/bin/bash
################################################################################
# Script: 08_upload_dataset_v5.sh
# Purpose: Upload trash_sorting_40ep_v5 (11 episodes) to HuggingFace Hub
# Usage:  ./scripts/08_upload_dataset_v5.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/08_upload_dataset_v5_${TIMESTAMP}.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

echo ""
echo "=============================================="
echo "  Upload Dataset v5 (11 episodes)"
echo "=============================================="
echo ""
log "Starting dataset upload (v5)..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration (.env provides HF_USER / HF_TOKEN)
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    log_error "Missing .env file at $SCRIPT_DIR/.env"
    log_error "Create it from .env.trash_sorting or .env.example first."
    exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPT_DIR/.env"

# Activate conda environment
if [ -f "$SCRIPT_DIR/utils/activate_env.sh" ]; then
    log_info "Activating conda environment..."
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/utils/activate_env.sh"
else
    log_warning "activate_env.sh not found, continuing without conda activation..."
fi
echo ""

# Basic HF_USER sanity check
if [ -z "${HF_USER:-}" ] || [ "$HF_USER" = "your_huggingface_username" ]; then
    log_error "HF_USER is not set correctly in .env"
    exit 1
fi

# Dataset configuration for v5
DATASET_PATH="${HOME}/so101_datasets/trash_sorting_40ep_v5"
DATASET_REPO_ID="${HF_USER}/trash_sorting_11ep"

log_info "Upload configuration:"
log "  Local path : $DATASET_PATH"
log "  Repo ID    : $DATASET_REPO_ID"
echo ""

# Check HuggingFace authentication
log_info "Checking HuggingFace authentication..."
if ! huggingface-cli whoami &> /dev/null; then
    log_error "Not logged in to HuggingFace"
    log_info "Run: $SCRIPT_DIR/utils/hf_login.sh"
    exit 1
fi

log_success "HuggingFace authentication verified"
echo ""

# Verify dataset directory exists
if [ ! -d "$DATASET_PATH" ]; then
    log_error "Dataset directory not found: $DATASET_PATH"
    exit 1
fi

# Check episode count from meta/info.json (best-effort, non-fatal)
INFO_JSON="${DATASET_PATH}/meta/info.json"
EPISODE_COUNT="(unknown)"
if [ -f "$INFO_JSON" ]; then
    EPISODE_COUNT="$(python3 -c 'import json,sys; info=json.load(open(sys.argv[1])); print(info.get("total_episodes","unknown"))' "$INFO_JSON" 2>/dev/null || echo "(error)")"
fi

log_info "Detected episodes: $EPISODE_COUNT"
echo ""

log_warning "This will upload the dataset to HuggingFace Hub:"
log "  https://huggingface.co/datasets/$DATASET_REPO_ID"
read -p "Continue with upload? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Upload cancelled by user"
    exit 0
fi

echo ""
log_info "Uploading dataset... this may take several minutes."
log "Command: huggingface-cli upload \"$DATASET_REPO_ID\" \"$DATASET_PATH\" --repo-type=dataset"
echo ""

if huggingface-cli upload "$DATASET_REPO_ID" "$DATASET_PATH" --repo-type=dataset 2>&1 | tee -a "$LOG_FILE"; then
    echo ""
    log_success "Dataset uploaded successfully!"
    log_info "Dataset URL: https://huggingface.co/datasets/$DATASET_REPO_ID"
    echo ""
    log_info "Next: run the v8 uploader for the 30-episode dataset once you're ready."
else
    echo ""
    log_error "Upload failed"
    log_error "See log file for details: $LOG_FILE"
    exit 1
fi

echo ""
echo "=============================================="
echo ""

exit 0
