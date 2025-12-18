# QuickStart 

To set up the LeRobot development environment for both edge and cloud with AMD ROCm Platform.

## Setup the Edge Development

The edge platform is based on an AMD Ryzen AI PC, which is used to drive the SO-101 ARM for dataset creation and inference. The integrated GPU (iGPU) of the Ryzen AI processor accelerates model inference using ROCm.

### Target Enviroment

```text
AMD Ryzen AI 9 HX370 PC
OS: ubuntu 24.04
ROCm v6.3+
PyTorch v2.7.x
LeRobot: v0.4.1
```

### Pre-requisites

#### Install Ubuntu 24.04 LTS on the AMD Ryzen AI PC

```shell
alex@SER9:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04.3 LTS
Release:        24.04
Codename:       noble
alex@SER9:~$ uname -r
6.14.0-27-generic
alex@SER9:~$
alex@SER9:~$ lsmod | grep amdgpu
amdgpu              19714048  1
amdxcp                 12288  1 amdgpu
drm_panel_backlight_quirks    12288  1 amdgpu
drm_buddy              24576  1 amdgpu
drm_ttm_helper         16384  1 amdgpu
ttm                   118784  2 amdgpu,drm_ttm_helper
drm_exec               12288  1 amdgpu
drm_suballoc_helper    20480  1 amdgpu
drm_display_helper    278528  1 amdgpu
cec                    94208  2 drm_display_helper,amdgpu
i2c_algo_bit           16384  1 amdgpu
gpu_sched              61440  2 amdxdna,amdgpu
video                  77824  1 amdgpu
```

### Setup the ROCm Development Environment for the LeRobot

As of now (2025/11), LeRobot depends on PyTorch version >=2.2.1, <2.8.0 (see `pyproject.toml`).

We recommend using ROCm 6.3 and PyTorch 2.7 to ensure compatibility with LeRobot.

#### Install ROCm 6.3.x,

``` shell
sudo apt update
sudo apt install "linux-headers-$(uname -r)"
sudo apt install python3-setuptools python3-wheel
sudo usermod -a -G render,video $LOGNAME # Add the current user to the render and video groups


wget https://repo.radeon.com/amdgpu-install/6.3.4/ubuntu/noble/amdgpu-install_6.3.60304-1_all.deb
sudo apt install ./amdgpu-install_6.3.60304-1_all.deb
amdgpu-install -y --usecase=rocm --no-dkms

sudo reboot
```

**NOTE**: Ensure `--no-dkms` is set so the built-in kernel driver is used.

For more details, refer to the official documentation: https://rocm.docs.amd.com/projects/radeon-ryzen/en/docs-6.3.4/docs/install/native_linux/install-radeon.html.

#### Install PyTorch with ROCm

Since LeRobot depends on PyTorch version >=2.2.1, <2.8.0 (see `pyproject.toml`) and the latest PyTorch-ROCm version is v2.8.0+, we must install an older ROCm-compatible PyTorch release.

The LeRobot GitHub repository uses Miniconda for environment management. We can use the same approach with minor modifications for PyTorch-ROCm.

Set the iGPU on Ryzen AI 300 series to run at gfx1100 compatible mode:
```
echo "export HSA_OVERRIDE_GFX_VERSION=11.0.0" >> ~/.bashrc
source ~/.bashrc
```

Install Miniconda following the official docs: https://www.anaconda.com/docs/getting-started/miniconda/install.

Then, you can create a conda environment and install the compatible PyTorch versions.

```shell
conda create -n lerobot python=3.10
conda activate lerobot

pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 --index-url https://download.pytorch.org/whl/rocm6.3

# Check the installation
pip list | grep rocm
pytorch-triton-rocm    3.3.1
torch                  2.7.1+rocm6.3
torchaudio             2.7.1+rocm6.3
torchvision            0.22.1+rocm6.3
```

Now, the Ryzen AI iGPU will appear as a CUDA-compatible device in PyTorch.

```shell
python3 -c 'import torch; print(torch.cuda.is_available())'
```
It will get `True`.

```shell
python3 -c "import torch; print(f'device name [0]:', torch.cuda.get_device_name(0))"
```
It will get ` device name [0]: AMD Radeon Graphics`.


#### Setup LeRobot Development Environment

More installation info can be found at https://github.com/huggingface/lerobot/blob/main/README.md.

```shell
conda install ffmpeg=7.1.1 -c conda-forge
```

```shell
git clone https://github.com/huggingface/lerobot.git
cd lerobot

# let’s synchronize using this version
git checkout -b v0.4.1 v0.4.1
pip install -e .
```

Check the Installation
```shell
pip list | grep lerobot
lerobot                0.4.1          /home/alex/lerobot
```

Install the feetech-servo-sdk for SO-ARM101 in this Hackation.

```shell
pip install 'lerobot[feetech]'      # Feetech motor support
```

The edge development environment is ready. Please refer to the [so101_example.md](so101_example.md) for the calibration, teleop, dataset collection, and inference evalution with the SO-101 ARM.

## Setup the Training Environment

Please refer to [training-models-on-rocm.ipynb](training-models-on-rocm.ipynb)

## Ready To Go

Get start your hackathon challenge with LeRobot. 

Good Luck~


## Reference

[LeRobot Documentation](https://huggingface.co/docs/lerobot/index)
