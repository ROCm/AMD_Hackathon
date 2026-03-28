#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/phi-media-lab"
EVORL_ROOT="$ROOT/Evo-RL-Phi"
VENV="$ROOT/.venvs/pi05-openpi-ssp/bin"
DATASET_REPO="maxbeau/XLeRobot"
DATASET_ROOT="/root/.cache/huggingface/lerobot/maxbeau/XLeRobot"

VALUE_RUN_DIR="$EVORL_ROOT/outputs/value_train/pi05_acp_stage1"
VALUE_INFER_DIR="$EVORL_ROOT/outputs/value_infer/pi05_acp_stage1"
POLICY_RUN_DIR="$EVORL_ROOT/outputs/train/pi05_acp_policy_stage1"

VALUE_FIELD="complementary_info.value_stage1"
ADV_FIELD="complementary_info.advantage_stage1"
IND_FIELD="complementary_info.acp_indicator_stage1"

export HF_HUB_ENABLE_HF_TRANSFER=1

cd "$EVORL_ROOT"

"$VENV/lerobot-value-train" \
  --dataset.repo_id="$DATASET_REPO" \
  --dataset.video_backend=pyav \
  --value.type=pistar06 \
  --value.device=cuda \
  --value.dtype=float32 \
  --value.normalization_mapping='{"ACTION":"IDENTITY","STATE":"MEAN_STD","VISUAL":"IDENTITY"}' \
  --batch_size=1 \
  --num_workers=0 \
  --steps=20 \
  --save_checkpoint=true \
  --save_freq=10 \
  --wandb.enable=false \
  --output_dir="$VALUE_RUN_DIR" \
  --job_name=pi05_acp_stage1_value

"$VENV/lerobot-value-infer" \
  --dataset.repo_id="$DATASET_REPO" \
  --dataset.video_backend=pyav \
  --dataset.default_success=failure \
  --inference.checkpoint_path="$VALUE_RUN_DIR" \
  --runtime.device=cuda \
  --runtime.batch_size=4 \
  --runtime.num_workers=0 \
  --acp.enable=true \
  --acp.n_step=10 \
  --acp.positive_ratio=0.3 \
  --acp.value_field="$VALUE_FIELD" \
  --acp.advantage_field="$ADV_FIELD" \
  --acp.indicator_field="$IND_FIELD" \
  --output_dir="$VALUE_INFER_DIR" \
  --job_name=pi05_acp_stage1_infer

"$VENV/lerobot-train" \
  --dataset.repo_id="$DATASET_REPO" \
  --dataset.root="$DATASET_ROOT" \
  --dataset.video_backend=pyav \
  --policy.type=pi05 \
  --policy.pretrained_path=lerobot/pi05_base \
  --policy.device=cuda \
  --policy.dtype=float32 \
  --policy.push_to_hub=false \
  --policy.train_expert_only=true \
  --policy.freeze_vision_encoder=true \
  --policy.normalization_mapping='{"ACTION":"MEAN_STD","STATE":"MEAN_STD","VISUAL":"IDENTITY"}' \
  --batch_size=1 \
  --num_workers=0 \
  --steps=20 \
  --save_checkpoint=true \
  --save_freq=10 \
  --wandb.enable=false \
  --acp.enable=true \
  --acp.indicator_field="$IND_FIELD" \
  --acp.indicator_dropout_prob=0.3 \
  --output_dir="$POLICY_RUN_DIR" \
  --job_name=pi05_acp_policy_stage1
