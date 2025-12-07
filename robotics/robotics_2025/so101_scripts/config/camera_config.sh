#!/bin/bash
################################################################################
# Camera Configuration
# This file is sourced by other scripts to get camera settings
################################################################################

# Load environment variables if available
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

# Camera indices (from .env or defaults)
#   TOP_CAMERA_INDEX  = overhead camera
#   SIDE_CAMERA_INDEX = side camera
#   ARM_CAMERA_INDEX  = camera mounted on the robot arm
export TOP_CAMERA_INDEX="${TOP_CAMERA_INDEX:-8}"
export SIDE_CAMERA_INDEX="${SIDE_CAMERA_INDEX:-6}"
export ARM_CAMERA_INDEX="${ARM_CAMERA_INDEX:-4}"

# Camera settings
# Global defaults (top/side cameras)
export CAMERA_WIDTH="${CAMERA_WIDTH:-640}"
export CAMERA_HEIGHT="${CAMERA_HEIGHT:-480}"
export CAMERA_FPS="${CAMERA_FPS:-30}"

# Arm camera can use a lower FPS to reduce glitches/bandwidth issues
export ARM_CAMERA_FPS="${ARM_CAMERA_FPS:-15}"

# Build camera configuration string for LeRobot
# This is consumed by lerobot-teleoperate / lerobot-record
# and now includes top, side, and arm-mounted cameras.
# Top/side use CAMERA_FPS, arm camera uses ARM_CAMERA_FPS.
export CAMERA_CONFIG="{top: {type: opencv, index_or_path: ${TOP_CAMERA_INDEX}, width: ${CAMERA_WIDTH}, height: ${CAMERA_HEIGHT}, fps: ${CAMERA_FPS}}, side: {type: opencv, index_or_path: ${SIDE_CAMERA_INDEX}, width: ${CAMERA_WIDTH}, height: ${CAMERA_HEIGHT}, fps: ${CAMERA_FPS}}, arm: {type: opencv, index_or_path: ${ARM_CAMERA_INDEX}, width: ${CAMERA_WIDTH}, height: ${CAMERA_HEIGHT}, fps: ${ARM_CAMERA_FPS}}}"

# Camera device paths
export TOP_CAMERA_DEVICE="/dev/video${TOP_CAMERA_INDEX}"
export SIDE_CAMERA_DEVICE="/dev/video${SIDE_CAMERA_INDEX}"
export ARM_CAMERA_DEVICE="/dev/video${ARM_CAMERA_INDEX}"