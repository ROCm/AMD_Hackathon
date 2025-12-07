#!/bin/bash
################################################################################
# Script: activate_env.sh
# Purpose: Helper script to activate the lerobot conda environment
# Usage: source ./utils/activate_env.sh
################################################################################

# Get the conda environment name from .env or use default
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

CONDA_ENV_NAME="${CONDA_ENV_NAME:-lerobot}"

# Initialize conda
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    echo "Error: Conda not found. Please install miniconda or anaconda."
    return 1
fi

# Activate the environment
conda activate "$CONDA_ENV_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Activated conda environment: $CONDA_ENV_NAME"
else
    echo "✗ Failed to activate conda environment: $CONDA_ENV_NAME"
    return 1
fi