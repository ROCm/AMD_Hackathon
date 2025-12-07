#!/bin/bash
################################################################################
# Script: 01_set_permissions.sh
# Purpose: Set USB port permissions for robot arms
# Usage: ./scripts/01_set_permissions.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/01_set_permissions_${TIMESTAMP}.log"

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
echo "  Set USB Port Permissions"
echo "=============================================="
echo ""
log "Starting permission setup..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/robot_config.sh"

# Check for robot devices
log_info "Checking for robot arm devices..."
if ! ls /dev/ttyACM* 1> /dev/null 2>&1; then
    log_error "No robot arm devices found (/dev/ttyACM*)"
    log_error "Please connect your SO101 ARM robots via USB"
    exit 1
fi

log_success "Found robot arm devices:"
for device in /dev/ttyACM*; do
    log "  - $device"
done

echo ""

# Set permissions
log_info "Setting permissions for robot arm devices..."
log_warning "This requires sudo privileges"
echo ""

ERRORS=0
for device in /dev/ttyACM*; do
    log "Setting permissions for $device..."
    if sudo chmod 666 "$device"; then
        log_success "✓ Permissions set for $device"
    else
        log_error "✗ Failed to set permissions for $device"
        ((ERRORS++))
    fi
done

echo ""

# Verify permissions
log_info "Verifying permissions..."
for device in /dev/ttyACM*; do
    perms=$(ls -l "$device" | awk '{print $1}')
    log "  $device: $perms"
done

echo ""

# Summary
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    log_success "All permissions set successfully!"
    echo ""
    log_info "You can now proceed with calibration:"
    log_info "  ./scripts/02_calibrate_follower.sh"
    log_info "  ./scripts/03_calibrate_leader.sh"
else
    log_error "Failed to set permissions for $ERRORS device(s)"
    exit 1
fi
echo "=============================================="
echo ""

exit 0