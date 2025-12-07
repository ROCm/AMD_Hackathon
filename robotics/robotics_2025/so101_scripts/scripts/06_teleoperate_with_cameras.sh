#!/bin/bash
################################################################################
# Script: 06_teleoperate_with_cameras.sh
# Purpose: Full teleoperation test with camera feeds
# Usage: ./scripts/06_teleoperate_with_cameras.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/06_teleoperate_with_cameras_${TIMESTAMP}.log"

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
echo "  Teleoperation with Cameras"
echo "=============================================="
echo ""
log "Starting teleoperation with cameras..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/robot_config.sh"
source "$SCRIPT_DIR/config/camera_config.sh"

# Activate conda environment
log_info "Activating conda environment..."
source "$SCRIPT_DIR/utils/activate_env.sh"

# Check everything
log_info "Checking configuration..."
if [ ! -e "$LEADER_PORT" ] || [ ! -e "$FOLLOWER_PORT" ]; then
    log_error "Robot ports not found"
    exit 1
fi

if [ ! -e "$TOP_CAMERA_DEVICE" ] || [ ! -e "$SIDE_CAMERA_DEVICE" ]; then
    log_error "Camera devices not found"
    log_error "Top: $TOP_CAMERA_DEVICE"
    log_error "Side: $SIDE_CAMERA_DEVICE"
    exit 1
fi

log_success "All devices found"
echo ""

# Display configuration
log_info "Configuration:"
log "  Leader: $LEADER_PORT ($LEADER_ID)"
log "  Follower: $FOLLOWER_PORT ($FOLLOWER_ID)"
log "  Top camera: $TOP_CAMERA_DEVICE (index: $TOP_CAMERA_INDEX)"
log "  Side camera: $SIDE_CAMERA_DEVICE (index: $SIDE_CAMERA_INDEX)"
echo ""

# Display instructions
log_info "Instructions:"
echo ""
echo "  1. Move the LEADER arm to control the FOLLOWER"
echo "  2. Camera feeds will be displayed"
echo "  3. Press Ctrl+C to stop"
echo ""
log_warning "Make sure arms have clearance to move!"
echo ""

read -p "Press Enter to start..."
echo ""

# Run teleoperation with cameras
log_info "Starting teleoperation with cameras..."
echo ""

lerobot-teleoperate \
    --robot.type="$FOLLOWER_TYPE" \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id="$FOLLOWER_ID" \
    --robot.cameras="$CAMERA_CONFIG" \
    --teleop.type="$LEADER_TYPE" \
    --teleop.port="$LEADER_PORT" \
    --teleop.id="$LEADER_ID" \
    --display_data=true 2>&1 | tee -a "$LOG_FILE"

echo ""
log_info "Teleoperation ended"
log_info "Next step: ./scripts/07_record_dataset.sh"
echo ""

exit 0