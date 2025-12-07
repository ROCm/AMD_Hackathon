#!/bin/bash
################################################################################
# Dataset Configuration
# This file is sourced by other scripts to get dataset settings
################################################################################

# Load environment variables if available
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Dataset settings (from .env or defaults)
export DATASET_NAME="${DATASET_NAME:-so101_dataset}"
export DATASET_TASK="${DATASET_TASK:-pickup the cube and place it to the bin}"
export DATASET_NUM_EPISODES="${DATASET_NUM_EPISODES:-60}"
export DATASET_EPISODE_TIME="${DATASET_EPISODE_TIME:-20}"
export DATASET_RESET_TIME="${DATASET_RESET_TIME:-10}"

# Dataset root handling
# Default behavior:
#   - Root directory:   ${HOME}/so101_datasets/${DATASET_NAME}
#   - This avoids FileExistsError when ${HOME}/so101_datasets already exists
if [ -z "${DATASET_ROOT:-}" ]; then
    DATASET_ROOT="${HOME}/so101_datasets/${DATASET_NAME}"
elif [ "${DATASET_ROOT}" = "${HOME}/so101_datasets" ]; then
    # If user set the old base path, automatically scope by dataset name
    DATASET_ROOT="${HOME}/so101_datasets/${DATASET_NAME}"
fi

# If the computed root already exists, append a numeric suffix _vN to avoid
# LeRobot's internal `exist_ok=False` FileExistsError when creating metadata.
if [ -d "${DATASET_ROOT}" ]; then
    i=1
    BASE_ROOT="${DATASET_ROOT}"
    while [ -d "${BASE_ROOT}_v${i}" ]; do
        i=$((i + 1))
    done
    DATASET_ROOT="${BASE_ROOT}_v${i}"
fi
export DATASET_ROOT

# HuggingFace settings
export HF_USER="${HF_USER:-your_huggingface_username}"
export DATASET_REPO_ID="${HF_USER}/${DATASET_NAME}"

# Display settings
export DISPLAY_DATA="${DISPLAY_DATA:-true}"
export PUSH_TO_HUB="${PUSH_TO_HUB:-true}"