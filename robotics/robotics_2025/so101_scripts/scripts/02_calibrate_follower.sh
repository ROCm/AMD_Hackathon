#!/bin/bash
################################################################################
# Script: 02_calibrate_follower.sh
# Purpose: Calibrate the follower arm (with gripper)
# Usage: ./scripts/02_calibrate_follower.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/02_calibrate_follower_${TIMESTAMP}.log"

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
echo "  Calibrate Follower ARM"
echo "=============================================="
echo ""
log "Starting follower arm calibration..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/robot_config.sh"

# Activate conda environment
log_info "Activating conda environment..."
source "$SCRIPT_DIR/utils/activate_env.sh"

# Check if follower port exists
if [ ! -e "$FOLLOWER_PORT" ]; then
    log_error "Follower port not found: $FOLLOWER_PORT"
    log_error "Please connect the follower ARM and run ./scripts/01_set_permissions.sh"
    exit 1
fi

log_success "Follower port found: $FOLLOWER_PORT"
echo ""

# Display instructions
log_info "Calibration Instructions:"
echo ""
echo "  1. The follower ARM is the one with the GRIPPER"
echo "  2. Follow the on-screen prompts carefully"
echo "  3. Move the arm to the positions indicated"
echo "  4. Press Enter after each position"
echo ""
log_warning "Make sure the arm has clearance to move!"
echo ""

read -p "Press Enter to start calibration..."
echo ""

# Run calibration
log_info "Running calibration command..."
log "Command: lerobot-calibrate --robot.type=$FOLLOWER_TYPE --robot.port=$FOLLOWER_PORT --robot.id=$FOLLOWER_ID"
echo ""

if lerobot-calibrate \
    --robot.type="$FOLLOWER_TYPE" \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id="$FOLLOWER_ID" 2>&1 | tee -a "$LOG_FILE"; then
    
    echo ""
    log_success "Follower ARM calibration complete!"
    echo ""
    log_info "Calibration data saved for robot ID: $FOLLOWER_ID"
    log_info "Next step: ./scripts/03_calibrate_leader.sh"
else
    echo ""
    log_error "Calibration failed"
    log_error "Check the log file for details: $LOG_FILE"
    exit 1
fi

echo ""
echo "=============================================="
echo ""

exit 0