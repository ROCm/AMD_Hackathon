# PI05 Evo-RL ACP Execution Plan

## Goal

Reference `AMD_Hackathon` ROCm setup guidance to:

1. validate a ROCm-backed LeRobot runtime,
2. attempt `pi05` inference on this machine,
3. run the `pi05` Evo-RL ACP workflow end-to-end.

## Current Machine Status

- ROCm runtime detected via `rocminfo`
- GPU detected: `AMD Instinct MI300X VF`
- Python: `3.12.3`
- Torch: `2.6.0+rocm7.0.2`
- LeRobot: `0.4.4`
- `lerobot-info`, `lerobot-train --help`, `lerobot-eval --help` all work

Validation commands already executed:

```bash
python3 - <<'PY'
import torch
print(torch.__version__)
print(torch.cuda.is_available())
print(torch.cuda.get_device_name(0))
PY

cd /root/phi-media-lab/Evo-RL-Phi
python3 -m lerobot.scripts.lerobot_info
python3 -m lerobot.scripts.lerobot_train --help
python3 -m lerobot.scripts.lerobot_eval --help
```

## Code Changes Applied

These local changes were made in `Evo-RL-Phi` to unblock validation:

1. `src/lerobot/policies/pi05/modeling_pi05.py`
   Relaxed the brittle `transformers.models.siglip.check` import requirement. The check now runs only when that helper exists.
2. `src/lerobot/policies/pi05/configuration_pi05.py`
   Added `tokenizer_name` as a config field.
3. `src/lerobot/policies/pi05/processor_pi05.py`
   Switched tokenizer loading from a hard-coded value to `config.tokenizer_name`.
4. `src/lerobot/policies/pi05/modeling_pi05.py`
   Added a tied-weight fallback so `lerobot/pi05_base` can load when the checkpoint only exposes `lm_head.weight`.
5. `src/lerobot/configs/value.py`
   Added `dataset.video_backend` so `lerobot-value-infer` can avoid broken `torchcodec` default selection on this ROCm environment.
6. `src/lerobot/scripts/lerobot_value_infer.py`
   Passed `dataset.video_backend` through to `LeRobotDataset`.

Editable install refreshed:

```bash
cd /root/phi-media-lab/Evo-RL-Phi
python3 -m pip install -e .
```

## Validation Results

### Passed

- ROCm tensor allocation and compute
- LeRobot CLI runtime
- ACP prompt injection path into `pi05`
- OpenPI-patched `transformers` environment for `pi05`
- `pi05` GPU smoke test on ROCm with mocked tokenizer
- real `pi05` pretrained inference with `lerobot/pi05_base`
- `pistar06` value training smoke run on `maxbeau/XLeRobot`
- `lerobot-value-infer` writing ACP labels back to the local dataset cache
- `pi05` ACP policy-training smoke run on the labeled dataset

Command:

```bash
cd /root/phi-media-lab/Evo-RL-Phi
pytest -q tests/training/test_acp_pi05_prompt_pipeline.py -q
```

Result: passed on `DEVICE='cuda'`

### OpenPI-Patched Environment Created

Isolated environment:

```bash
/root/phi-media-lab/.venvs/pi05-openpi-ssp
```

OpenPI source:

```bash
/root/phi-media-lab/openpi
```

Environment preparation that was executed:

```bash
python3 -m venv --system-site-packages /root/phi-media-lab/.venvs/pi05-openpi-ssp
git clone --depth=1 --recurse-submodules https://github.com/Physical-Intelligence/openpi.git /root/phi-media-lab/openpi
/root/phi-media-lab/.venvs/pi05-openpi-ssp/bin/python -m pip install 'transformers==4.53.2'
/root/phi-media-lab/.venvs/pi05-openpi-ssp/bin/python -m pip install -e /root/phi-media-lab/Evo-RL-Phi --no-deps
cp -r /root/phi-media-lab/openpi/src/openpi/models_pytorch/transformers_replace/* \
  /root/phi-media-lab/.venvs/pi05-openpi-ssp/lib/python3.12/site-packages/transformers/
echo '/opt/venv/lib/python3.12/site-packages' > \
  /root/phi-media-lab/.venvs/pi05-openpi-ssp/lib/python3.12/site-packages/_opt_venv.pth
```

Patch verification:

```text
transformers 4.53.2
GemmaRMSNorm.forward(self, x, cond=None)
siglip_check_result True
```

### `pi05` ROCm Smoke Test

In the patched venv, a minimal GPU forward + `select_action` test passed when tokenizer access was mocked:

```text
smoke_ok
loss 2.579069137573242
loss_keys ['loss', 'loss_per_dim']
action_shape (1, 7)
action_device cpu
```

This confirms:

- ROCm backend is usable for `pi05`
- OpenPI transformer patches are sufficient for model execution
- the remaining blocker is no longer model-side

### Real `pi05` Inference Result

After refreshing Hugging Face auth and using the OpenPI-patched venv, real tokenizer/model access worked.

Successful path:

```text
google/paligemma-3b-pt-224
lerobot/pi05_base
```

Observed result:

```text
real_infer_ok
action_shape (1, 32)
action_mean 0.02885555289685726
action_std 0.09869649261236191
```

Important runtime note:

- the saved `policy_preprocessor.json` in `lerobot/pi05_base` targets `cpu`, so the processed batch had to be moved to `cuda` before `select_action`

### ACP Workflow Smoke Result

Dataset used:

```text
maxbeau/XLeRobot
```

Dataset compatibility findings:

- `episode_success` is absent, so value training/inference used `--dataset.default_success=failure`
- default `torchcodec` decoding is not usable in this ROCm environment for DataLoader CPU-side video decode
- `pyav` works and must be forced for both training and value inference
- the dataset lacks state quantiles, so `STATE` normalization had to be switched from `QUANTILES` to `MEAN_STD`

Successful smoke sequence:

```bash
lerobot-value-train \
  --dataset.repo_id=maxbeau/XLeRobot \
  --dataset.video_backend=pyav \
  --value.type=pistar06 \
  --value.device=cuda \
  --value.dtype=float32 \
  --value.normalization_mapping='{"ACTION":"IDENTITY","STATE":"MEAN_STD","VISUAL":"IDENTITY"}' \
  --batch_size=1 \
  --num_workers=0 \
  --steps=1 \
  --save_checkpoint=true \
  --save_freq=1 \
  --wandb.enable=false \
  --output_dir=/root/phi-media-lab/Evo-RL-Phi/outputs/value_train/pi05_acp_ckpt_meanstd

lerobot-value-infer \
  --dataset.repo_id=maxbeau/XLeRobot \
  --dataset.video_backend=pyav \
  --dataset.default_success=failure \
  --inference.checkpoint_path=/root/phi-media-lab/Evo-RL-Phi/outputs/value_train/pi05_acp_ckpt_meanstd \
  --runtime.device=cuda \
  --runtime.batch_size=1 \
  --runtime.num_workers=0 \
  --acp.enable=true \
  --acp.n_step=5 \
  --acp.positive_ratio=0.3 \
  --acp.value_field=complementary_info.value_smoke \
  --acp.advantage_field=complementary_info.advantage_smoke \
  --acp.indicator_field=complementary_info.acp_indicator_smoke

lerobot-train \
  --dataset.repo_id=maxbeau/XLeRobot \
  --dataset.root=/root/.cache/huggingface/lerobot/maxbeau/XLeRobot \
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
  --steps=1 \
  --save_checkpoint=false \
  --wandb.enable=false \
  --acp.enable=true \
  --acp.indicator_field=complementary_info.acp_indicator_smoke \
  --acp.indicator_dropout_prob=0.3
```

Key observed outputs:

```text
ACP stats | n_step=5 positive_ratio_target=0.3000 positive_ratio_observed=0.3001
Wrote value annotations to dataset root: /root/.cache/huggingface/lerobot/maxbeau/XLeRobot
ACP indicator stats (hf_dataset_scan): field='complementary_info.acp_indicator_smoke' ratio=0.300135 positive=446 total=1486
First policy prompt (task):
Task: pick up the block Advantage: negative, State: ...
End of training
```

## Smoke-Test Summary

What has been proven:

- ROCm backend is healthy
- `pi05` processor + ACP prompt path is healthy
- local `pi05` code can instantiate further than before after removing the brittle SigLIP helper check
- OpenPI-patched `transformers` makes real `pi05` model execution possible on ROCm
- real `pi05` forward + `select_action` succeed with `lerobot/pi05_base`
- `pistar06 -> value_infer -> ACP label writeback -> pi05 ACP train` has been smoke-tested end to end

What is not yet proven:

- stable multi-step or full-length `pi05` training on this dataset
- production-quality ACP behavior with meaningful value targets, because the smoke run treated all episodes as `failure`
- whether `maxbeau/XLeRobot` should be augmented with quantile stats instead of using `MEAN_STD`

## Required Next Actions

### Next Practical Steps

1. Decide whether to keep using local cache path `/root/.cache/huggingface/lerobot/maxbeau/XLeRobot` for ACP-labeled experiments or push a cleaned dataset variant to a new HF repo.
2. Either augment dataset quantile stats or keep explicit `MEAN_STD` overrides for `STATE`/`ACTION`.
3. Increase `steps`, `batch_size`, and checkpointing from the smoke setup once you want a real training run.
4. If value targets should reflect true success, add `episode_success` metadata instead of relying on `default_success=failure`.

## Large Download Note

Public `lerobot/pi05_base` exists and the `model.safetensors` size is approximately:

```text
14,467,165,872 bytes
```

Do not download it until the tokenizer and patched-transformers issues are solved, otherwise the model still will not run.
