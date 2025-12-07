#!/bin/bash
################################################################################
# Script: check_devices.sh
# Purpose: Check robot arm and camera connections
# Usage: ./utils/check_devices.sh
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  SO101 ARM Device Check"
echo "=============================================="
echo ""

# Check robot arms
echo -e "${BLUE}[INFO]${NC} Checking robot arm connections..."
echo ""

if ls /dev/ttyACM* 1> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Found robot arm devices:"
    for device in /dev/ttyACM*; do
        echo "  - $device"
    done
else
    echo -e "${RED}✗${NC} No robot arm devices found (/dev/ttyACM*)"
    echo "  Please connect your SO101 ARM robots via USB"
fi

echo ""

# Check cameras
echo -e "${BLUE}[INFO]${NC} Checking camera connections..."
echo ""

if ls /dev/video* 1> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Found video devices:"
    for device in /dev/video*; do
        # Get device number
        device_num=$(echo "$device" | grep -o '[0-9]*$')
        echo "  - $device (index: $device_num)"
    done
    
    echo ""
    echo -e "${YELLOW}[TIP]${NC} To test cameras with LeRobot:"
    echo "  conda activate lerobot"
    echo "  lerobot-find-cameras opencv"
    echo ""
    echo -e "${YELLOW}[TIP]${NC} To preview a specific camera:"
    echo "  ffplay /dev/video<index>"
else
    echo -e "${RED}✗${NC} No video devices found (/dev/video*)"
    echo "  Please connect your cameras via USB"
fi

echo ""
echo "=============================================="
echo ""