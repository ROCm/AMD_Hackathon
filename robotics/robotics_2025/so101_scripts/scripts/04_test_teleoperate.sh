#!/bin/bash
################################################################################
# Script: 04_test_teleoperate.sh
# Purpose: Test basic teleoperation without cameras
# Usage: ./scripts/04_test_teleoperate.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/04_test_teleoperate_${TIMESTAMP}.log"

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
echo "  Test Teleoperation (No Cameras)"
echo "=============================================="
echo ""
log "Starting teleoperation test..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/robot_config.sh"

# Activate conda environment
log_info "Activating conda environment..."
source "$SCRIPT_DIR/utils/activate_env.sh"

# Check ports
if [ ! -e "$LEADER_PORT" ] || [ ! -e "$FOLLOWER_PORT" ]; then
    log_error "Robot ports not found"
    log_error "Leader: $LEADER_PORT"
    log_error "Follower: $FOLLOWER_PORT"
    exit 1
fi

log_success "Robot ports found"
echo ""

# Display instructions
log_info "Teleoperation Test Instructions:"
echo ""
echo "  1. Move the LEADER arm (with handle)"
echo "  2. The FOLLOWER arm (with gripper) should mirror movements"
echo "  3. Test all joints and the gripper"
echo "  4. Press Ctrl+C to stop"
echo ""
log_warning "Make sure both arms have clearance to move!"
echo ""

read -p "Press Enter to start teleoperation test..."
echo ""

# Run teleoperation
log_info "Starting teleoperation..."
log "Command: lerobot-teleoperate --robot.type=$FOLLOWER_TYPE --robot.port=$FOLLOWER_PORT --robot.id=$FOLLOWER_ID --teleop.type=$LEADER_TYPE --teleop.port=$LEADER_PORT --teleop.id=$LEADER_ID"
echo ""

lerobot-teleoperate \
    --robot.type="$FOLLOWER_TYPE" \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id="$FOLLOWER_ID" \
    --teleop.type="$LEADER_TYPE" \
    --teleop.port="$LEADER_PORT" \
    --teleop.id="$LEADER_ID" 2>&1 | tee -a "$LOG_FILE"

echo ""
log_info "Teleoperation test ended"
log_info "Next step: ./scripts/05_test_cameras.sh"
echo ""

exit 0