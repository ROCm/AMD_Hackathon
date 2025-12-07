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
export DATASET_ROOT="${DATASET_ROOT:-${HOME}/so101_datasets}"

# HuggingFace settings
export HF_USER="${HF_USER:-your_huggingface_username}"
export DATASET_REPO_ID="${HF_USER}/${DATASET_NAME}"

# Display settings
export DISPLAY_DATA="${DISPLAY_DATA:-true}"
export PUSH_TO_HUB="${PUSH_TO_HUB:-true}"