# Troubleshooting Guide - SO-101 ARM

## 📁 Common Recording Errors

### Error: "FileExistsError: File exists: '/home/amdemo/so101_datasets'"

**What This Means:**
You're trying to create a new dataset, but a dataset with that name already exists.

**Quick Fix:**

```bash
# Option 1: Use a different dataset name
nano .env
# Change: DATASET_NAME=trash_sorting_40ep_v2

# Option 2: Delete the old dataset (if you don't need it)
rm -rf ~/so101_datasets/trash_sorting_40ep

# Option 3: Resume recording (if you want to continue)
# The script will ask if you want to resume
./scripts/07_record_dataset.sh
```

**Recommended:** Use Option 1 (new name) to keep your previous attempts as backup.

---

## 🔴 Hardware Communication Errors

## 🔴 Common Error: "There is no status packet!"

### Error Message
```
ConnectionError: Failed to write 'Lock' on id_=5 with '1' after 1 tries. 
[TxRxResult] There is no status packet!
```

### What This Means
The follower arm's motor (ID 5) is not responding. This is a **hardware communication issue**, not a software problem.

---

## 🔧 Quick Fixes (Try in Order)

### Fix 1: Power Cycle the Follower Arm

```bash
# 1. Unplug the follower arm's USB cable
# 2. Wait 5 seconds
# 3. Plug it back in
# 4. Wait 5 seconds
# 5. Try again

./scripts/06_teleoperate_with_cameras.sh
```

### Fix 2: Check USB Connection

```bash
# Check which ports are connected
ls -l /dev/ttyACM*

# You should see:
# /dev/ttyACM0  (usually leader)
# /dev/ttyACM1  (usually follower)

# If you only see one, the follower isn't connected
```

**Solution:** Reconnect the follower arm's USB cable

### Fix 3: Swap USB Ports

Sometimes the ports get assigned differently:

```bash
# Try swapping in your .env file
nano .env

# Change:
LEADER_PORT=/dev/ttyACM1   # Was ACM0
FOLLOWER_PORT=/dev/ttyACM0  # Was ACM1

# Save and try again
./scripts/06_teleoperate_with_cameras.sh
```

### Fix 4: Re-run Permissions

```bash
# USB permissions might have reset
./scripts/01_set_permissions.sh

# Then try again
./scripts/06_teleoperate_with_cameras.sh
```

### Fix 5: Recalibrate Follower

```bash
# The follower might need recalibration
./scripts/02_calibrate_follower.sh

# Then test
./scripts/04_test_teleoperate.sh
```

---

## 🔍 Diagnostic Steps

### Step 1: Check USB Devices

```bash
# List all USB serial devices
ls -l /dev/ttyACM*

# Expected output:
# crw-rw-rw- 1 root dialout ... /dev/ttyACM0
# crw-rw-rw- 1 root dialout ... /dev/ttyACM1
```

**If you see only one device:**
- Follower arm is not connected
- USB cable is loose
- USB port is not working

### Step 2: Check Permissions

```bash
# Check if you have access
ls -l /dev/ttyACM*

# Should show: crw-rw-rw- (666 permissions)
# If not, run: ./scripts/01_set_permissions.sh
```

### Step 3: Test Leader Only

```bash
# Test if leader arm works alone
./scripts/03_calibrate_leader.sh

# If leader works, problem is with follower
```

### Step 4: Check Motor Power

**Physical checks:**
1. Is the follower arm powered on?
2. Are the motors making any sound?
3. Can you manually move the arm (should have resistance)?
4. Are there any LED indicators on the arm?

---

## 🚨 Specific Error Solutions

### Error: "Failed to write 'Lock' on id_=5"

**Motor ID 5 is not responding**

**Solutions:**
1. Power cycle the follower arm
2. Check USB connection
3. Verify motor is powered
4. Try different USB port
5. Recalibrate follower

### Error: "Failed to write 'Lock' on id_=1"

**Motor ID 1 is not responding (different motor)**

**Solutions:**
1. Same as above, but check all motors
2. One motor might be disconnected internally
3. May need hardware inspection

### Error: "Port already in use"

**Another process is using the USB port**

**Solution:**
```bash
# Find and kill the process
sudo lsof /dev/ttyACM0
sudo lsof /dev/ttyACM1

# Kill the process (replace PID with actual number)
kill -9 PID

# Or reboot
sudo reboot
```

---

## 🔄 Complete Reset Procedure

If nothing works, try this complete reset:

```bash
# 1. Stop all processes
pkill -f lerobot

# 2. Unplug both arms
# Wait 10 seconds

# 3. Plug in leader first
# Wait 5 seconds

# 4. Plug in follower second
# Wait 5 seconds

# 5. Check connections
ls -l /dev/ttyACM*

# 6. Set permissions
./scripts/01_set_permissions.sh

# 7. Recalibrate follower
./scripts/02_calibrate_follower.sh

# 8. Recalibrate leader
./scripts/03_calibrate_leader.sh

# 9. Test
./scripts/04_test_teleoperate.sh
```

---

## 📋 Pre-Recording Checklist

Before starting to record, verify:

```bash
# 1. Both arms connected
ls -l /dev/ttyACM*
# Should show ACM0 and ACM1

# 2. Permissions set
./scripts/01_set_permissions.sh

# 3. Leader works
./scripts/03_calibrate_leader.sh

# 4. Follower works
./scripts/02_calibrate_follower.sh

# 5. Teleoperation works
./scripts/04_test_teleoperate.sh

# 6. Cameras work
./scripts/05_test_cameras.sh

# 7. Full system works
./scripts/06_teleoperate_with_cameras.sh
```

---

## 🆘 Still Not Working?

### Check Hardware

1. **USB Cable**
   - Try a different USB cable
   - Some cables are power-only (no data)
   - Use a known-good cable

2. **USB Port**
   - Try a different USB port on your computer
   - Some ports have better power delivery
   - Avoid USB hubs if possible

3. **Power Supply**
   - Ensure follower arm has adequate power
   - Check if power LED is on
   - Try different power source

4. **Motor Connection**
   - Motors might be loose internally
   - Check if all motors respond
   - May need hardware inspection

### Get Help

If hardware issues persist:

1. **Check LeRobot Documentation**
   - https://huggingface.co/docs/lerobot/so101
   - Known issues and solutions

2. **LeRobot GitHub Issues**
   - https://github.com/huggingface/lerobot/issues
   - Search for similar problems

3. **SO-101 Community**
   - Discord/forums for SO-101 users
   - Hardware-specific help

---

## 💡 Prevention Tips

### Before Each Session

1. **Gentle Handling**
   - Don't force the arms
   - Avoid sudden movements
   - Keep cables secure

2. **Consistent Setup**
   - Use same USB ports
   - Same power source
   - Same connection order

3. **Regular Checks**
   - Test before recording
   - Verify calibration
   - Check all motors

### During Recording

1. **Monitor for Issues**
   - Watch for error messages
   - Listen for unusual sounds
   - Check arm responsiveness

2. **Take Breaks**
   - Don't run continuously for hours
   - Let motors cool down
   - Check connections periodically

---

## 📝 Error Log

Keep track of errors for troubleshooting:

```bash
# Save error output
./scripts/06_teleoperate_with_cameras.sh 2>&1 | tee error.log

# Review later
cat error.log
```

---

## ✅ Success Indicators

You know it's working when:

- ✅ Both arms connect without errors
- ✅ Leader arm movements are smooth
- ✅ Follower arm mirrors leader exactly
- ✅ No "status packet" errors
- ✅ All motors respond
- ✅ Cameras show clear images

---

**Current Issue:** Motor ID 5 not responding
**Most Likely Fix:** Power cycle the follower arm and check USB connection
**Next Step:** Try Fix 1 above, then proceed through the list