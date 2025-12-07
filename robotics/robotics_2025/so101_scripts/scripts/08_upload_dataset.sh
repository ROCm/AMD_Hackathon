#!/bin/bash
################################################################################
# Script: 08_upload_dataset.sh
# Purpose: Upload dataset to HuggingFace Hub
# Usage: ./scripts/08_upload_dataset.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/08_upload_dataset_${TIMESTAMP}.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Print header
echo ""
echo "=============================================="
echo "  Upload Dataset to HuggingFace"
echo "=============================================="
echo ""
log "Starting dataset upload..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/dataset_config.sh"

# Activate conda environment
log_info "Activating conda environment..."
source "$SCRIPT_DIR/utils/activate_env.sh"

# Check HuggingFace login
log_info "Checking HuggingFace authentication..."
if ! huggingface-cli whoami &> /dev/null; then
    log_error "Not logged in to HuggingFace"
    log_info "Please run: ./utils/hf_login.sh"
    exit 1
fi

log_success "HuggingFace authentication verified"
echo ""

# Check if dataset exists
if [ ! -d "$DATASET_ROOT/$DATASET_NAME" ]; then
    log_error "Dataset not found: $DATASET_ROOT/$DATASET_NAME"
    log_error "Please record a dataset first: ./scripts/07_record_dataset.sh"
    exit 1
fi

log_success "Dataset found: $DATASET_ROOT/$DATASET_NAME"
echo ""

# Display upload info
log_info "Upload Configuration:"
log "  Local path: $DATASET_ROOT/$DATASET_NAME"
log "  Repository: $DATASET_REPO_ID"
echo ""

log_warning "This will upload the dataset to HuggingFace Hub"
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Upload cancelled"
    exit 0
fi

echo ""

# Upload dataset
log_info "Uploading dataset..."
log "Command: huggingface-cli upload $DATASET_REPO_ID $DATASET_ROOT/$DATASET_NAME"
echo ""

if huggingface-cli upload "$DATASET_REPO_ID" "$DATASET_ROOT/$DATASET_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    echo ""
    log_success "Dataset uploaded successfully!"
    echo ""
    log_info "Dataset URL: https://huggingface.co/datasets/$DATASET_REPO_ID"
    log_info "You can now train models using this dataset"
    log_info "Next step: ./scripts/09_prepare_training.sh"
else
    echo ""
    log_error "Upload failed"
    log_error "Check the log file for details: $LOG_FILE"
    exit 1
fi

echo ""
echo "=============================================="
echo ""

exit 0