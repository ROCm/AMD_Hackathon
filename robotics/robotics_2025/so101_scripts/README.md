# SO101 ARM Workflow Scripts

Automated scripts for operating the SO101 ARM robot - from calibration to dataset recording and training preparation.

## 🚀 Quick Start

### 1. Initial Setup (One-time)

```bash
cd robotics/robotics_2025/so101_scripts

# Copy and configure environment variables
cp .env.example .env
nano .env  # Edit with your credentials

# Make scripts executable
chmod +x scripts/*.sh utils/*.sh

# Verify your setup
./scripts/00_verify_setup.sh
```

### 2. Configure Your Credentials

Edit `.env` file with your information:

```bash
# Required: HuggingFace credentials
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxx
HF_USER=your_username

# Optional: Weights & Biases for training visualization
WANDB_TOKEN=your_wandb_token

# Dataset configuration
DATASET_NAME=my_robot_task
DATASET_TASK="describe your task here"
```

### 3. First-Time Calibration

```bash
# Set USB permissions (may need sudo password)
./scripts/01_set_permissions.sh

# Calibrate follower arm (follow on-screen instructions)
./scripts/02_calibrate_follower.sh

# Calibrate leader arm (follow on-screen instructions)
./scripts/03_calibrate_leader.sh
```

### 4. Test Your Setup

```bash
# Test basic teleoperation
./scripts/04_test_teleoperate.sh

# Test camera feeds
./scripts/05_test_cameras.sh

# Test full system with cameras
./scripts/06_teleoperate_with_cameras.sh
```

### 5. Record Dataset

```bash
# Record training episodes
./scripts/07_record_dataset.sh

# Upload to HuggingFace
./scripts/08_upload_dataset.sh
```

### 6. Prepare for Training

```bash
# Generate training commands and documentation
./scripts/09_prepare_training.sh
```

## 📁 Directory Structure

```
so101_scripts/
├── README.md                    # This file
├── PLAN.md                      # Detailed architecture
├── .env.example                 # Environment template
├── .env                         # Your credentials (gitignored)
├── config/                      # Configuration files
│   ├── camera_config.sh
│   ├── robot_config.sh
│   └── dataset_config.sh
├── scripts/                     # Main workflow scripts
│   ├── 00_verify_setup.sh
│   ├── 01_set_permissions.sh
│   ├── 02_calibrate_follower.sh
│   ├── 03_calibrate_leader.sh
│   ├── 04_test_teleoperate.sh
│   ├── 05_test_cameras.sh
│   ├── 06_teleoperate_with_cameras.sh
│   ├── 07_record_dataset.sh
│   ├── 08_upload_dataset.sh
│   └── 09_prepare_training.sh
├── utils/                       # Helper utilities
│   ├── check_devices.sh
│   ├── activate_env.sh
│   └── hf_login.sh
├── logs/                        # Execution logs
└── datasets/                    # Local dataset storage
```

## 🎥 Camera Configuration

Your camera setup:

| Device | Purpose | LeRobot Index |
|--------|---------|---------------|
| `/dev/video8` | Overhead (top) | 8 |
| `/dev/video6` | Side view | 6 |
| `/dev/video4` | Arm-mounted | 4 (optional) |

The scripts are pre-configured to use video8 (top) and video6 (side) cameras.

## 🤖 Robot Configuration

Default configuration:

| Component | Device | ID |
|-----------|--------|-----|
| Leader ARM | `/dev/ttyACM0` | `my_awesome_leader_arm` |
| Follower ARM | `/dev/ttyACM1` | `my_awesome_follower_arm` |

**Note:** Device names may change based on connection order. Use `utils/check_devices.sh` to verify.

## 📝 Detailed Workflow

### Phase 1: Setup & Verification

**Script:** `00_verify_setup.sh`

Checks:
- ✅ Conda environment activated
- ✅ LeRobot installation
- ✅ Robot arm connections
- ✅ Camera availability
- ✅ Environment variables configured

**Script:** `01_set_permissions.sh`

- Grants USB port access for robot arms
- Required after system reboot
- Needs sudo privileges

### Phase 2: Calibration

**Script:** `02_calibrate_follower.sh`

Calibrates the follower arm (the one with the gripper):
1. Follow on-screen prompts
2. Move arm to specified positions
3. Calibration data saved automatically

**Script:** `03_calibrate_leader.sh`

Calibrates the leader arm (the one you control):
1. Follow on-screen prompts
2. Move arm to specified positions
3. Calibration data saved automatically

**Important:** Calibration only needs to be done once per robot unless you change the hardware setup.

### Phase 3: Testing

**Script:** `04_test_teleoperate.sh`

Tests basic arm control:
- Move the leader arm
- Follower arm should mirror movements
- No camera display
- Press Ctrl+C to exit

**Script:** `05_test_cameras.sh`

Preview camera feeds:
- Shows each camera view using ffplay
- Verify camera angles and positioning
- Press 'q' to close each preview

**Script:** `06_teleoperate_with_cameras.sh`

Full system test:
- Teleoperation with live camera feeds
- Verify everything works together
- Press Ctrl+C to exit

### Phase 4: Data Collection

**Script:** `07_record_dataset.sh`

Records training episodes:
- Configure in `.env`:
  - `DATASET_NUM_EPISODES` - Number of episodes (default: 60)
  - `DATASET_EPISODE_TIME` - Duration per episode (default: 20s)
  - `DATASET_RESET_TIME` - Time between episodes (default: 10s)
  - `DATASET_TASK` - Task description

**Recording Process:**
1. Script starts recording
2. Perform your task with the leader arm
3. Episode ends automatically after configured time
4. Reset environment during reset time
5. Next episode starts automatically
6. Press Ctrl+C to stop early

**Resume Recording:**
If interrupted, the script will ask if you want to resume from the last episode.

**Script:** `08_upload_dataset.sh`

Uploads dataset to HuggingFace:
- Uploads to `${HF_USER}/${DATASET_NAME}`
- Verifies upload success
- Dataset becomes available for training

### Phase 5: Training Preparation

**Script:** `09_prepare_training.sh`

Generates training resources:
- Training command templates for ACT and VLA models
- Cloud training notebook
- Dataset documentation
- Configuration summary

## 🔧 Utility Scripts

### `utils/check_devices.sh`

Checks hardware connections:
```bash
./utils/check_devices.sh
```

Shows:
- Connected robot arms and their ports
- Available cameras and their indices
- Current device status

### `utils/activate_env.sh`

Helper to activate conda environment:
```bash
source ./utils/activate_env.sh
```

### `utils/hf_login.sh`

HuggingFace authentication helper:
```bash
./utils/hf_login.sh
```

## 🎓 Training Your Model

After recording and uploading your dataset, train on the cloud:

### ACT (Action Chunking Transformer)

```bash
lerobot-train \
  --dataset.repo_id=${HF_USER}/${DATASET_NAME} \
  --policy.type=act \
  --batch_size=64 \
  --steps=10000 \
  --output_dir=outputs/train/act_${DATASET_NAME} \
  --job_name=act_${DATASET_NAME} \
  --policy.device=cuda \
  --wandb.enable=true
```

### VLA (Vision-Language-Action)

```bash
# First install VLA dependencies
pip install -e ".[smolvla]"

# Then train
lerobot-train \
  --dataset.repo_id=${HF_USER}/${DATASET_NAME} \
  --policy.type=smolvla \
  --batch_size=32 \
  --steps=10000 \
  --output_dir=outputs/train/smolvla_${DATASET_NAME} \
  --job_name=smolvla_${DATASET_NAME} \
  --policy.device=cuda \
  --wandb.enable=true
```

See [`training-models-on-rocm.ipynb`](../training-models-on-rocm.ipynb) for detailed training instructions.

## 🐛 Troubleshooting

### "command not found" errors

**Problem:** LeRobot commands not found

**Solution:**
```bash
conda activate lerobot
# Or use the helper
source ./utils/activate_env.sh
```

### USB Permission Denied

**Problem:** Cannot access robot arms

**Solution:**
```bash
./scripts/01_set_permissions.sh
# May need to re-run after reboot
```

### Camera Not Detected

**Problem:** Camera not showing up

**Solution:**
1. Check physical connections
2. Run: `./utils/check_devices.sh`
3. Verify camera indices in `.env`

### Calibration Data Lost

**Problem:** Need to recalibrate

**Solution:**
```bash
# Recalibrate follower
./scripts/02_calibrate_follower.sh

# Recalibrate leader
./scripts/03_calibrate_leader.sh
```

### Dataset Recording Interrupted

**Problem:** Recording stopped unexpectedly

**Solution:**
- Re-run `./scripts/07_record_dataset.sh`
- Script will ask if you want to resume
- Choose 'yes' to continue from last episode

### Wrong Camera Indices

**Problem:** Cameras showing wrong views

**Solution:**
1. Test cameras: `./scripts/05_test_cameras.sh`
2. Update `.env` with correct indices:
   ```bash
   TOP_CAMERA_INDEX=8    # Your overhead camera
   SIDE_CAMERA_INDEX=6   # Your side camera
   ```

## 📊 Logs and Debugging

All scripts create detailed logs in the `logs/` directory:

```bash
# View latest log
ls -lt logs/*.log | head -1 | xargs cat

# View specific script log
cat logs/07_record_dataset_YYYYMMDD_HHMMSS.log

# Monitor log in real-time
tail -f logs/07_record_dataset_YYYYMMDD_HHMMSS.log
```

## 🔐 Security Notes

- `.env` file is gitignored - never commit it
- Keep your HuggingFace token private
- Use `.env.example` as a template
- Tokens are stored locally only

## 📚 Additional Resources

- [LeRobot Documentation](https://huggingface.co/docs/lerobot/index)
- [SO101 Tutorial](https://huggingface.co/docs/lerobot/so101)
- [Architecture Plan](PLAN.md) - Detailed technical documentation
- [QuickStart Guide](../QuickStart.md) - Environment setup
- [SO101 Examples](../so101_example.md) - Command reference
- [Training Notebook](../training-models-on-rocm.ipynb) - Cloud training

## 🎯 Best Practices

### Dataset Recording

1. **Episode Length:** 15-30 seconds per episode
2. **Reset Time:** 10-15 seconds (adjust based on task complexity)
3. **Number of Episodes:** Start with 50-100 for initial training
4. **Task Description:** Be specific and descriptive
5. **Environment:** Keep consistent lighting and background

### Camera Setup

1. **Overhead Camera:** Bird's eye view of workspace
2. **Side Camera:** Profile view of arm and objects
3. **Positioning:** Ensure full workspace visibility
4. **Lighting:** Consistent, avoid shadows and glare

### Calibration

1. **Frequency:** Only when hardware changes
2. **Accuracy:** Follow prompts carefully
3. **Backup:** Calibration data auto-backed up
4. **Verification:** Test with teleoperation after calibrating

## 🚦 Getting Started Checklist

- [ ] Copy `.env.example` to `.env`
- [ ] Configure HuggingFace credentials in `.env`
- [ ] Run `00_verify_setup.sh`
- [ ] Set USB permissions with `01_set_permissions.sh`
- [ ] Calibrate follower arm
- [ ] Calibrate leader arm
- [ ] Test teleoperation
- [ ] Test cameras
- [ ] Record first dataset
- [ ] Upload to HuggingFace
- [ ] Start training on cloud

## 💡 Tips

- Always activate conda environment first: `conda activate lerobot`
- Check logs if something goes wrong
- Use `utils/check_devices.sh` to verify hardware
- Start with fewer episodes for testing
- Increase episodes for production training
- Use descriptive dataset names
- Document your task clearly

## 🤝 Support

For issues:
1. Check the logs in `logs/` directory
2. Review troubleshooting section above
3. Consult [PLAN.md](PLAN.md) for architecture details
4. Check [SO101 examples](../so101_example.md)
5. Review [LeRobot documentation](https://huggingface.co/docs/lerobot/index)

---

**Ready to start?** Run `./scripts/00_verify_setup.sh` to begin! 🚀