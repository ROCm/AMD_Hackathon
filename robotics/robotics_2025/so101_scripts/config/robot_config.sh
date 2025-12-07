#!/bin/bash
################################################################################
# Robot Configuration
# This file is sourced by other scripts to get robot settings
################################################################################

# Load environment variables if available
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Robot ports (from .env or defaults)
export LEADER_PORT="${LEADER_PORT:-/dev/ttyACM0}"
export FOLLOWER_PORT="${FOLLOWER_PORT:-/dev/ttyACM1}"

# Robot IDs (from .env or defaults)
export LEADER_ID="${LEADER_ID:-my_awesome_leader_arm}"
export FOLLOWER_ID="${FOLLOWER_ID:-my_awesome_follower_arm}"

# Robot types
export LEADER_TYPE="so101_leader"
export FOLLOWER_TYPE="so101_follower"