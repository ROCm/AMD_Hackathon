# PI05 Evo-RL ACP Runbook

## Fixed Constraints

- Use the patched environment: `/root/phi-media-lab/.venvs/pi05-openpi-ssp`
- Force dataset decoding with `--dataset.video_backend=pyav`
- Use local labeled dataset cache for policy training: `/root/.cache/huggingface/lerobot/maxbeau/XLeRobot`
- Use `MEAN_STD` for `STATE` and `ACTION` unless the dataset is augmented with quantile stats

## Ready-To-Run Scripts

Smoke validation:

```bash
bash /root/phi-media-lab/AMD_Hackathon/run_pi05_acp_smoke.sh
```

Short pilot run with checkpoints:

```bash
bash /root/phi-media-lab/AMD_Hackathon/run_pi05_acp_pilot.sh
```

## Pilot Output Paths

Value checkpoint:

```text
/root/phi-media-lab/Evo-RL-Phi/outputs/value_train/pi05_acp_pilot/checkpoints/000005/pretrained_model
```

Policy checkpoint:

```text
/root/phi-media-lab/Evo-RL-Phi/outputs/train/pi05_acp_policy_pilot/checkpoints/000005/pretrained_model
```

ACP-labeled dataset fields written into local cache:

```text
complementary_info.value_pilot
complementary_info.advantage_pilot
complementary_info.acp_indicator_pilot
```

## Current Data Assumptions

- Dataset repo: `maxbeau/XLeRobot`
- Dataset does not contain `episode_success`
- Current runs therefore rely on `--dataset.default_success=failure`

## When To Change The Defaults

Switch away from the current overrides only if one of these is true:

1. `XLeRobot` gets quantile stats, then `STATE` and `ACTION` can go back to `QUANTILES`
2. `episode_success` gets written into episode metadata, then value targets can use real success labels
3. ACP-labeled outputs are pushed to a dedicated Hub dataset, then policy training can point at that repo instead of the local cache root
