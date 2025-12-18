# Example Commands to Operate SO101 ARM

Suppose:
1. You have set up the Ubuntu + ROCm + PyTorch + LeRobot development environment by following [QuickStart.md](QuickStart.md).
2. You have the SO101 ARM assembled.
    1. The leader is the arm with the handle that you control.
    2. The follower is the arm with the pincher and camera.

Here are some key steps with example commands to use the SO101 ARM.

These examples are based on [LeRobot Tutorial](https://huggingface.co/docs/lerobot/so101) and LeRobot v0.4.1 with some modifications and comments for our setup. YOU MAY NEED TO MAKE SOME MODIFICATIONS FOR YOUR JOBS AS REQUIRED.

## Connect the SO101 ARM
1. Connect the leader ARM with USB UART to PC first and it will get `/dev/ttyACM0` on Ubuntu
2. Connect the follower ARM with USB UART to PC and it will get `/dev/ttyACM1` on Ubuntu

The sequence of the connection of leader ARM and follower ARM will result in different device node names. The following steps assume the following names:
- Leader ARM: /dev/ttyACM0
- Follower ARM: /dev/ttyACM1

LeRobot provides the command `lerobot-find-port` to help find the UART device node of the SO101 ARM.

## Connect the Cameras
Suppose you have two cameras, one named `top` and another named `side`. The `top` camera may be set up to give a bird's eye view of the ARM's workspace. The `side` camera may be set up to give a side view.

1. Please connect the `top` camera first and it will get `/dev/video0` for it.
2. Then connect the `side` camera and it will get `/dev/video2` for it.

Use the lerobot-find-cameras CLI tool to detect available cameras:

```shell
lerobot-find-cameras opencv      # Find OpenCV cameras  
```

You can also use `ffplay` to check the camera angles:
```shell
ffplay /dev/video*    # Fill in with the camera's index/port
```


## Calibrate the SO101 ARM

Details about the steps can be found at https://huggingface.co/docs/lerobot/so101 (you should NOT do the motor ID setup).

Give USB port permissions:
```shell
sudo chmod 666 /dev/ttyACM0
sudo chmod 666 /dev/ttyACM1
```

Calibrate the follower:
>`robot.port` is the port of your follower arm, `robot.id` is a unique name for the follower

```shell
lerobot-calibrate \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm
```

> If you see a `Lock` error, you may need to unplug and replug the power to the arm.

Calibrate the leader:
>`teleop.port` is port of your leader arm, `teleop.id` is a unique name for the leader

```shell
lerobot-calibrate \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm
```

Then you can use the SO101 ARM 

## Teleoperate

```shell
lerobot-teleoperate \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm
```

## Teleoperate with cameras

```shell
lerobot-teleoperate \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}, side: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30}}" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true
```

`top` camera with index_or_path 0 (/dev/video0)
`side` camera with index_or_path 2 (/dev/video2)

## Record the dataset

We will use the leader ARM to teleoperate the follower ARM to perform the actions we want to record into the dataset.

We use the Hugging Face hub features for uploading your dataset. If you haven’t previously used the Hub, make sure you can login via the cli using a write-access token, this token can be generated from the Hugging Face settings.

Add your token to the CLI and login to Hugging Face by running this command:

```shell
hf auth login
```

Then store your Hugging Face repository name in a variable:

```shell
HF_USER=$(hf auth whoami | head -n 1)
echo $HF_USER
```

Now you can record a dataset.

Here's an example command once you have setup your Hugging Face credentials:

```shell
lerobot-record \
    --robot.type=so101_follower \
    --robot.port=/dev/ttyACM1 \
    --robot.id=my_awesome_follower_arm \
    --robot.cameras="{top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}, side: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30}}" \
    --teleop.type=so101_leader \
    --teleop.port=/dev/ttyACM0 \
    --teleop.id=my_awesome_leader_arm \
    --display_data=true \
    --dataset.repo_id=${HF_USER}/record-test \
    --dataset.num_episodes=60 \
    --dataset.episode_time_s=20 \
    --dataset.reset_time_s=10 \
    --dataset.single_task="pickup the cube and place it to the bin" \
    --dataset.root=${HOME}/so101_dataset/
```

- `--dataset.num_episodes=60` means we will record 60 teleoperation sessions.
- `--dataset.episode_time_s=20` means each episode has 20 seconds; this depends on whether it is enough time for your actions.
- `--dataset.reset_time_s=10` means the reset time between episodes. You may use this time slot to reset your environment, like recovering the position of the cube to the source by hand and waiting to start the next episode recording.
- `--dataset.root=${HOME}/stack2cube_dataset` means where your dataset will be saved.

The terminal has logs to notify you when new episodes start, reset, and when the dataset is recorded.

You can use `Ctrl-c` to stop the recording. Use `--resume=true` in the command to continue the dataset recording with the num_episodes added.

To get more detials about the instructions of record from `https://huggingface.co/docs/lerobot/il_robots#record-a-dataset`

After the recording is done, you can use the dataset for training.

### Keyboard controls on Ubuntu

If you want to use the arrow keys to control the recording session, you may need to change your `pynput` version and GUI settings due to a bug with Ubuntu.

First, install the specific `pynput` version:
```shell
pip uninstall pynput && pip install pynput==1.7.7
```

Then, change the Ubuntu GUI settings by logging out of your laptop and, in the login screen, click the setting button and select `Ubuntu with Xorg`.
<img width="968" height="774" alt="image" src="https://github.com/user-attachments/assets/bf3c5262-e75f-45e2-8896-513cf9aca0fa" />


## Training

Refer to the [QuickStart.md](QuickStart.md) to do the training with MI300X on AMD Development Cloud and the Hugging Face + LeRobot instructions here: https://huggingface.co/docs/lerobot/il_robots#train-a-policy.

The checkpoints are generated in `./outputs/train/act_so101_test/checkpoints/` and the last one is `./outputs/train/act_so101_test/checkpoints/last/pretrained_model/`

## Inference Evaluation

Copy the `pretrained_model` under `./outputs/train/act_so101_test/` from cloud back to the Edge platform (PC) for inference evaluation.

```
lerobot-record \
  --robot.type=so101_follower \
  --robot.port=/dev/ttyACM1 \
  --robot.id=my_awesome_follower_arm \
  --robot.cameras="{top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30}, side: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30}}" \
  --dataset.single_task="Pick cube from source position and stack it on the fixed cube at target position" \
  --dataset.repo_id=alexhegit/eval_act_base \
  --dataset.root=${PWD}/eval_lerobot_dataset/ \
  --dataset.episode_time_s=20 \
  --dataset.num_episodes=1 \
  --policy.path=${PWD}/outputs/train/act_so101_test/checkpoints/last/pretrained_model/ \ # path to the pretrained_model
  --dataset.push_to_hub=false
```

Now you have finished the full round of work. Then you can continue the next round from `record dataset` => `training` => `inference evaluation`
