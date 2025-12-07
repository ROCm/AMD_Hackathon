#!/bin/bash
################################################################################
# Script: 00_verify_setup.sh
# Purpose: Verify SO101 ARM setup and environment
# Usage: ./scripts/00_verify_setup.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/00_verify_setup_${TIMESTAMP}.log"

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
echo "  SO101 ARM Setup Verification"
echo "=============================================="
echo ""
log "Starting setup verification..."
log "Log file: $LOG_FILE"
echo ""

ERRORS=0

# Check 1: Environment file
log_info "Checking environment configuration..."
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    log_success ".env file found and loaded"
    
    # Check critical variables
    if [ -z "${HF_TOKEN:-}" ] || [ "$HF_TOKEN" == "your_huggingface_token_here" ]; then
        log_error "HF_TOKEN not configured in .env"
        ((ERRORS++))
    else
        log_success "HF_TOKEN is configured"
    fi
    
    if [ -z "${HF_USER:-}" ] || [ "$HF_USER" == "your_huggingface_username" ]; then
        log_error "HF_USER not configured in .env"
        ((ERRORS++))
    else
        log_success "HF_USER is configured: $HF_USER"
    fi
else
    log_error ".env file not found"
    log_error "Please copy .env.example to .env and configure it"
    ((ERRORS++))
fi

echo ""

# Check 2: Conda environment
log_info "Checking conda environment..."
if command -v conda &> /dev/null; then
    log_success "Conda is installed"
    
    # Try to activate environment
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    fi
    
    CONDA_ENV_NAME="${CONDA_ENV_NAME:-lerobot}"
    if conda env list | grep -q "^${CONDA_ENV_NAME} "; then
        log_success "Conda environment '$CONDA_ENV_NAME' exists"
        
        # Activate and check LeRobot
        conda activate "$CONDA_ENV_NAME" 2>/dev/null || true
        if python -c "import lerobot" 2>/dev/null; then
            LEROBOT_VER=$(python -c "import lerobot; print(lerobot.__version__)" 2>/dev/null || echo "unknown")
            log_success "LeRobot is installed (version: $LEROBOT_VER)"
        else
            log_error "LeRobot is not installed in '$CONDA_ENV_NAME'"
            ((ERRORS++))
        fi
    else
        log_error "Conda environment '$CONDA_ENV_NAME' not found"
        ((ERRORS++))
    fi
else
    log_error "Conda is not installed"
    ((ERRORS++))
fi

echo ""

# Check 3: Robot arms
log_info "Checking robot arm connections..."
if ls /dev/ttyACM* 1> /dev/null 2>&1; then
    log_success "Found robot arm devices:"
    for device in /dev/ttyACM*; do
        log "  - $device"
    done
else
    log_warning "No robot arm devices found (/dev/ttyACM*)"
    log_warning "Please connect your SO101 ARM robots via USB"
fi

echo ""

# Check 4: Cameras
log_info "Checking camera connections..."
if ls /dev/video* 1> /dev/null 2>&1; then
    log_success "Found video devices:"
    for device in /dev/video*; do
        device_num=$(echo "$device" | grep -o '[0-9]*$')
        log "  - $device (index: $device_num)"
    done
    
    # Check specific cameras from config
    source "$SCRIPT_DIR/config/camera_config.sh"
    if [ -e "$TOP_CAMERA_DEVICE" ]; then
        log_success "Top camera found: $TOP_CAMERA_DEVICE"
    else
        log_warning "Top camera not found: $TOP_CAMERA_DEVICE"
    fi
    
    if [ -e "$SIDE_CAMERA_DEVICE" ]; then
        log_success "Side camera found: $SIDE_CAMERA_DEVICE"
    else
        log_warning "Side camera not found: $SIDE_CAMERA_DEVICE"
    fi
else
    log_warning "No video devices found (/dev/video*)"
    log_warning "Please connect your cameras via USB"
fi

echo ""

# Check 5: Directories
log_info "Checking directory structure..."
for dir in logs datasets; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        log_success "Directory exists: $dir/"
    else
        log_warning "Directory missing: $dir/"
        mkdir -p "$SCRIPT_DIR/$dir"
        log_info "Created directory: $dir/"
    fi
done

echo ""

# Summary
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    log_success "All critical checks passed!"
    echo ""
    log_info "You can proceed with:"
    log_info "  1. ./scripts/01_set_permissions.sh"
    log_info "  2. ./scripts/02_calibrate_follower.sh"
    log_info "  3. ./scripts/03_calibrate_leader.sh"
else
    log_error "Found $ERRORS error(s)"
    echo ""
    log_info "Please fix the errors above before proceeding"
    exit 1
fi
echo "=============================================="
echo ""

exit 0