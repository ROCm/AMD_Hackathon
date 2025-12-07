# SO101 ARM Troubleshooting Guide

## Issue: Robot Arms Not Detected (No /dev/ttyACM* devices)

### Symptoms
- Red lights on robot arms (power is working)
- Arms connected via USB
- No `/dev/ttyACM*` or `/dev/ttyUSB*` devices appear
- `lsusb` doesn't show the robot arms

### Root Cause
The USB-to-serial drivers (cdc_acm) are not loaded in the kernel.

### Solutions

#### Solution 1: Load the cdc_acm Driver (Quick Fix)

```bash
# Load the USB ACM driver
sudo modprobe cdc_acm

# Verify it's loaded
lsmod | grep cdc_acm

# Now unplug and replug the robot arms
# Check if devices appear
ls /dev/ttyACM*
```

#### Solution 2: Install USB Serial Drivers

If modprobe doesn't work, you may need to install the drivers:

```bash
# Install USB serial support
sudo apt update
sudo apt install linux-modules-extra-$(uname -r)

# Reboot
sudo reboot

# After reboot, check again
ls /dev/ttyACM*
```

#### Solution 3: Try Different USB Ports

The issue might be with the USB hubs:

1. **Try direct connection**: Connect arms directly to laptop USB ports (not through hubs)
2. **Try different ports**: Some USB ports may have better compatibility
3. **One at a time**: Connect one arm first, verify it appears, then connect the second

#### Solution 4: Check USB Cable Quality

- SO101 arms need **data-capable USB cables** (not just power cables)
- Try different USB-C cables if available
- Ensure cables are fully inserted

### Verification Steps

After trying solutions, verify the connection:

```bash
# 1. Check if devices appear
ls -la /dev/ttyACM*

# 2. Check USB devices
lsusb | grep -i "serial\|acm\|uart"

# 3. Run our verification script
cd robotics/robotics_2025/so101_scripts
./scripts/00_verify_setup.sh

# 4. Use LeRobot's port finder
conda activate lerobot
lerobot-find-port
```

### Expected Output

When working correctly, you should see:

```bash
$ ls /dev/ttyACM*
/dev/ttyACM0  /dev/ttyACM1
```

- `/dev/ttyACM0` - First arm connected (usually leader)
- `/dev/ttyACM1` - Second arm connected (usually follower)

### Connection Order Matters

The device names depend on connection order:

1. **Connect LEADER first** → gets `/dev/ttyACM0`
2. **Connect FOLLOWER second** → gets `/dev/ttyACM1`

If you connect in different order, update your `.env` file:

```bash
# Edit .env
nano .env

# Update these lines:
LEADER_PORT=/dev/ttyACM0    # or /dev/ttyACM1
FOLLOWER_PORT=/dev/ttyACM1  # or /dev/ttyACM0
```

### Still Not Working?

#### Check Kernel Messages (requires sudo)

```bash
# Watch for USB events in real-time
sudo dmesg -w

# In another terminal, unplug and replug an arm
# Look for messages about USB devices
```

#### Check if Arms are in Bootloader Mode

Some SO101 arms have a button that puts them in bootloader mode:
- Make sure the arm is in **normal mode**, not bootloader mode
- Try pressing any buttons on the control board

#### Verify Arm Power

- Red LED should be solid (not blinking)
- Try different power sources if using external power
- Some arms need both USB data AND external power

### Hardware Checklist

- [ ] Arms have red LED lights on
- [ ] Using data-capable USB cables (not charge-only)
- [ ] Cables fully inserted on both ends
- [ ] Tried direct connection (no hubs)
- [ ] Tried different USB ports
- [ ] cdc_acm driver loaded (`lsmod | grep cdc_acm`)
- [ ] Connected arms one at a time to test

### Quick Diagnostic Script

Run this to get full diagnostic info:

```bash
#!/bin/bash
echo "=== USB Devices ==="
lsusb

echo -e "\n=== Serial Devices ==="
ls -la /dev/tty{ACM,USB}* 2>&1

echo -e "\n=== Loaded Drivers ==="
lsmod | grep -E "(cdc_acm|ch341|cp210x|ftdi)"

echo -e "\n=== Kernel Version ==="
uname -r

echo -e "\n=== USB Modules ==="
ls /lib/modules/$(uname -r)/kernel/drivers/usb/serial/ 2>&1
```

Save as `diagnose.sh`, make executable, and run:

```bash
chmod +x diagnose.sh
./diagnose.sh
```

### Common Error Messages

**"No such file or directory" for /dev/ttyACM***
- Driver not loaded or arms not detected
- Try Solution 1 or 2 above

**"Permission denied" when accessing /dev/ttyACM***
- Run: `./scripts/01_set_permissions.sh`
- Or manually: `sudo chmod 666 /dev/ttyACM*`

**Arms detected but calibration fails**
- Wrong port assignment (leader/follower swapped)
- Check connection order
- Update `.env` file

### Getting Help

If still having issues:

1. Run the diagnostic script above
2. Check the logs in `logs/` directory
3. Review LeRobot documentation: https://huggingface.co/docs/lerobot/so101
4. Check SO101 hardware documentation

### Next Steps After Fix

Once arms are detected:

```bash
cd robotics/robotics_2025/so101_scripts

# 1. Verify setup
./scripts/00_verify_setup.sh

# 2. Set permissions
./scripts/01_set_permissions.sh

# 3. Calibrate
./scripts/02_calibrate_follower.sh
./scripts/03_calibrate_leader.sh
```

---

**Last Updated:** 2025-12-07