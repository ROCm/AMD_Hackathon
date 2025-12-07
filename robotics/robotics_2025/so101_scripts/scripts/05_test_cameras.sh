#!/bin/bash
################################################################################
# Script: 05_test_cameras.sh
# Purpose: Test camera feeds with ffplay
# Usage: ./scripts/05_test_cameras.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/05_test_cameras_${TIMESTAMP}.log"

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
echo "  Test Camera Feeds"
echo "=============================================="
echo ""
log "Starting camera test..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/camera_config.sh"

# Check if ffplay is available
if ! command -v ffplay &> /dev/null; then
    log_error "ffplay not found"
    log_error "Please install ffmpeg: conda install ffmpeg -c conda-forge"
    exit 1
fi

log_success "ffplay is available"
echo ""

# Test top camera
log_info "Testing TOP camera: $TOP_CAMERA_DEVICE"
if [ -e "$TOP_CAMERA_DEVICE" ]; then
    log_success "Top camera device found"
    echo ""
    echo "  Opening top camera preview..."
    echo "  Press 'q' to close the preview"
    echo ""
    sleep 2
    ffplay "$TOP_CAMERA_DEVICE" 2>&1 | tee -a "$LOG_FILE" || true
else
    log_error "Top camera not found: $TOP_CAMERA_DEVICE"
fi

echo ""

# Test side camera
log_info "Testing SIDE camera: $SIDE_CAMERA_DEVICE"
if [ -e "$SIDE_CAMERA_DEVICE" ]; then
    log_success "Side camera device found"
    echo ""
    echo "  Opening side camera preview..."
    echo "  Press 'q' to close the preview"
    echo ""
    sleep 2
    ffplay "$SIDE_CAMERA_DEVICE" 2>&1 | tee -a "$LOG_FILE" || true
else
    log_error "Side camera not found: $SIDE_CAMERA_DEVICE"
fi

echo ""

# Test arm-mounted camera
log_info "Testing ARM camera (mounted on robot): $ARM_CAMERA_DEVICE"
if [ -e "$ARM_CAMERA_DEVICE" ]; then
    log_success "Arm camera device found"
    echo ""
    echo "  Opening arm camera preview..."
    echo "  Press 'q' to close the preview"
    echo ""
    sleep 2
    ffplay "$ARM_CAMERA_DEVICE" 2>&1 | tee -a "$LOG_FILE" || true
else
    log_error "Arm camera not found: $ARM_CAMERA_DEVICE"
fi

echo ""
echo "=============================================="
log_info "Camera test complete"
log_info "Next step: ./scripts/06_teleoperate_with_cameras.sh"
echo "=============================================="
echo ""

exit 0