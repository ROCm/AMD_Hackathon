#!/bin/bash
################################################################################
# Script: 07_record_dataset.sh
# Purpose: Record training dataset with teleoperation
# Usage: ./scripts/07_record_dataset.sh
################################################################################

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/logs/07_record_dataset_${TIMESTAMP}.log"

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
echo "  Record Training Dataset"
echo "=============================================="
echo ""
log "Starting dataset recording..."
log "Log file: $LOG_FILE"
echo ""

# Load configuration
source "$SCRIPT_DIR/.env"
source "$SCRIPT_DIR/config/robot_config.sh"
source "$SCRIPT_DIR/config/camera_config.sh"
source "$SCRIPT_DIR/config/dataset_config.sh"

# Activate conda environment
log_info "Activating conda environment..."
source "$SCRIPT_DIR/utils/activate_env.sh"

# Check HuggingFace login
log_info "Checking HuggingFace authentication..."
if ! huggingface-cli whoami &> /dev/null; then
    log_warning "Not logged in to HuggingFace"
    log_info "Running HuggingFace login..."
    "$SCRIPT_DIR/utils/hf_login.sh"
fi

log_success "HuggingFace authentication verified"
echo ""

# Check devices
log_info "Checking devices..."
if [ ! -e "$LEADER_PORT" ] || [ ! -e "$FOLLOWER_PORT" ]; then
    log_error "Robot ports not found"
    exit 1
fi

if [ ! -e "$TOP_CAMERA_DEVICE" ] || [ ! -e "$SIDE_CAMERA_DEVICE" ]; then
    log_error "Camera devices not found"
    exit 1
fi

log_success "All devices found"
echo ""

# Configure arm camera for optimal performance
log_info "Configuring arm camera to reduce flickering..."
if "$SCRIPT_DIR/utils/configure_arm_camera.sh"; then
    log_success "Arm camera configured successfully"
else
    log_warning "Arm camera configuration failed, continuing anyway..."
fi
echo ""

# Display configuration
log_info "Dataset Configuration:"
log "  Name: $DATASET_NAME"
log "  Task: $DATASET_TASK"
log "  Episodes: $DATASET_NUM_EPISODES"
log "  Episode duration: ${DATASET_EPISODE_TIME}s"
log "  Reset time: ${DATASET_RESET_TIME}s"
log "  Repository: $DATASET_REPO_ID"

# Compute effective dataset root to avoid collisions and FileExistsError
BASE_ROOT="${HOME}/so101_datasets"
EFFECTIVE_DATASET_ROOT="${DATASET_ROOT}"

# If user pointed to the base root, scope it by dataset name
if [ "${EFFECTIVE_DATASET_ROOT}" = "${BASE_ROOT}" ]; then
    EFFECTIVE_DATASET_ROOT="${BASE_ROOT}/${DATASET_NAME}"
fi

# If that directory already exists, append a version suffix _vN
if [ -d "${EFFECTIVE_DATASET_ROOT}" ]; then
    i=1
    while [ -d "${EFFECTIVE_DATASET_ROOT}_v${i}" ]; do
        i=$((i + 1))
    done
    EFFECTIVE_DATASET_ROOT="${EFFECTIVE_DATASET_ROOT}_v${i}"
fi

# Export back so downstream scripts (and logs) see the final root
export DATASET_ROOT="${EFFECTIVE_DATASET_ROOT}"
log "  Local storage: $DATASET_ROOT"
echo ""

# NOTE:
# Do NOT create $DATASET_ROOT here.
# LeRobot's LeRobotDatasetMetadata.create() expects the root directory
# to NOT exist and will create it itself with exist_ok=False.
# Pre-creating it here causes the FileExistsError you were seeing.

# Display instructions
log_info "Recording Instructions:"
echo ""
echo "  1. Each episode lasts ${DATASET_EPISODE_TIME} seconds"
echo "  2. Perform your task: $DATASET_TASK"
echo "  3. After each episode, you have ${DATASET_RESET_TIME} seconds to reset"
echo "  4. Press Ctrl+C to stop early (can resume later)"
echo ""
log_warning "Make sure your workspace is set up and ready!"
echo ""

read -p "Press Enter to start recording..."
echo ""

# Run dataset recording
log_info "Starting dataset recording..."
log "This will record $DATASET_NUM_EPISODES episodes"
echo ""

lerobot-record \
    --robot.type="$FOLLOWER_TYPE" \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id="$FOLLOWER_ID" \
    --robot.cameras="$CAMERA_CONFIG" \
    --teleop.type="$LEADER_TYPE" \
    --teleop.port="$LEADER_PORT" \
    --teleop.id="$LEADER_ID" \
    --display_data="$DISPLAY_DATA" \
    --dataset.repo_id="$DATASET_REPO_ID" \
    --dataset.num_episodes="$DATASET_NUM_EPISODES" \
    --dataset.episode_time_s="$DATASET_EPISODE_TIME" \
    --dataset.reset_time_s="$DATASET_RESET_TIME" \
    --dataset.single_task="$DATASET_TASK" \
    --dataset.root="$DATASET_ROOT" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "=============================================="
log_success "Dataset recording complete!"
echo ""
log_info "Dataset saved to: $DATASET_ROOT"
log_info "Next step: ./scripts/08_upload_dataset.sh"
echo "=============================================="
echo ""

exit 0