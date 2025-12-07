#!/bin/bash
################################################################################
# Update Task Description Based on Episode Count
# This script automatically updates DATASET_TASK in .env based on progress
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Task Update Helper${NC}"
echo "=================================="
echo ""

# Check if .env exists
if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create it first:"
    echo "  cp .env.trash_sorting .env"
    exit 1
fi

# Load environment
source "${ENV_FILE}"

# SIMPLE BATCH-BASED TASK ROTATION
# =================================
# Episode counting via LeRobot's parquet layout is unreliable for quick
# switching, so we rotate tasks purely by batch index:
#   Batch 1 -> PET bottle (episodes 1-10)
#   Batch 2 -> Can        (episodes 11-20)
#   Batch 3 -> Paper cup  (episodes 21-30)
#   Batch 4 -> Sellotape  (episodes 31-40)
#
# Usage expectation:
#   - You run ./scripts/07_record_dataset.sh to record ~10 episodes
#   - Then you run ./scripts/update_task.sh to move to the NEXT batch
#
# We track the current batch using TASK_BATCH_INDEX in .env and assume
# 10 episodes per batch.

# Load or initialize batch index (1-based: 1=PET, 2=Can, 3=Cup, 4=Sellotape)
BATCH_INDEX="${TASK_BATCH_INDEX:-1}"
# Ensure numeric
if ! [[ "${BATCH_INDEX}" =~ ^[0-9]+$ ]]; then
    BATCH_INDEX=1
fi

# When this script is called, we advance to the NEXT batch.
# So if TASK_BATCH_INDEX was 1 (PET), this call sets BATCH_INDEX=2 (Can).
BATCH_INDEX=$((BATCH_INDEX + 1))

# Derive "completed episodes" assuming 10 per completed batch
COMPLETED_EPISODES=$(( (BATCH_INDEX - 1) * 10 ))
NEXT_EPISODE=$(( COMPLETED_EPISODES + 1 ))

CURRENT_EPISODE=${COMPLETED_EPISODES}

# If we've already done 4 batches (40 episodes), stop
if [ "${BATCH_INDEX}" -gt 4 ] || [ "${COMPLETED_EPISODES}" -ge 40 ]; then
    echo -e "${GREEN}✅ All 40 episodes complete (based on TASK_BATCH_INDEX=${TASK_BATCH_INDEX:-4})!${NC}"
    echo "Ready to upload dataset"
    exit 0
fi

NEXT_EPISODE=$((CURRENT_EPISODE + 1))

echo -e "${GREEN}📊 Current Status:${NC}"
echo "  Completed episodes: ${CURRENT_EPISODE}"
echo "  Next episode: ${NEXT_EPISODE}"
echo ""

# Determine which task to use
if [ ${NEXT_EPISODE} -le 10 ]; then
    NEW_TASK="${TASK_1_10:-put the pet bottle in the recycle bin}"
    OBJECT="PET bottle"
    BIN="Recycling"
    BATCH="1-10"
elif [ ${NEXT_EPISODE} -le 20 ]; then
    NEW_TASK="${TASK_11_20:-put the can in the recycle bin}"
    OBJECT="Can"
    BIN="Recycling"
    BATCH="11-20"
elif [ ${NEXT_EPISODE} -le 30 ]; then
    NEW_TASK="${TASK_21_30:-put the paper coffee cup in the burnable bin}"
    OBJECT="Paper coffee cup"
    BIN="Burnable"
    BATCH="21-30"
elif [ ${NEXT_EPISODE} -le 40 ]; then
    NEW_TASK="${TASK_31_40:-put the sellotape holder in the non burnable bin}"
    OBJECT="Sellotape holder"
    BIN="Non-burnable"
    BATCH="31-40"
else
    echo -e "${GREEN}✅ All 40 episodes complete!${NC}"
    echo "Ready to upload dataset"
    exit 0
fi

echo -e "${BLUE}📝 Episode Batch ${BATCH}:${NC}"
echo "  Object: ${OBJECT}"
echo "  Bin: ${BIN}"
echo "  Task: \"${NEW_TASK}\""
echo ""

# Update .env file
echo -e "${YELLOW}🔧 Updating .env file...${NC}"

# Create backup
cp "${ENV_FILE}" "${ENV_FILE}.backup"

# Update DATASET_TASK line
if grep -q "^DATASET_TASK=" "${ENV_FILE}"; then
    sed -i "s|^DATASET_TASK=.*|DATASET_TASK=\"${NEW_TASK}\"|" "${ENV_FILE}"
else
    echo "DATASET_TASK=\"${NEW_TASK}\"" >> "${ENV_FILE}"
fi

# Persist TASK_BATCH_INDEX so next run advances correctly
if grep -q "^TASK_BATCH_INDEX=" "${ENV_FILE}"; then
    sed -i "s|^TASK_BATCH_INDEX=.*|TASK_BATCH_INDEX=${BATCH_INDEX}|" "${ENV_FILE}"
else
    echo "TASK_BATCH_INDEX=${BATCH_INDEX}" >> "${ENV_FILE}"
fi

echo -e "${GREEN}✅ Task updated successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "  1. Prepare ${OBJECT} for recording"
echo "  2. Position near ${BIN} bin"
echo "  3. Run: ./scripts/07_record_dataset.sh"
echo ""
echo -e "${YELLOW}💡 Tip: This script will auto-update after every 10 episodes${NC}"
echo ""

# Show what to record
REMAINING_IN_BATCH=$((((NEXT_EPISODE - 1) / 10 + 1) * 10 - CURRENT_EPISODE))
echo -e "${GREEN}Record ${REMAINING_IN_BATCH} more episodes with ${OBJECT}${NC}"