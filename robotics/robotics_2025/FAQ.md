# Pre-Hackathon Preparation

Please do the item ahead to join the Hackathon in field. That would save your time to focus on the Missions.

1. Understand the rules well by reading the [AMD Open Robotics Hackathon](https://amdroboticshackathon.datamonsters.com/)
2. Read the documentation from [ROCm/AMD_Hackathon Repo](https://github.com/ROCm/AMD_Hackathon/tree/main/robotics/robotics_2025) on how to set up the environment and what you need to submit for the Missions.
3. To store your datasets, models, and training logs, register for your personal Hugging Face and Weights & Biases (W&B) accounts before the Hackathon begins.
4. Go through https://huggingface.co/docs/lerobot/main/en/il_robots if this is your first time using LeRobot and the SO101 Arm.
5. Learn to use Jupyter Notebook. We will assign an MI300X Virtual Machine (VM) to each team for training and for copying data between your local machine and the VM.

# FAQ


1. How to get support for LeRobot with AI?

    A: Recommend to chat with deepwiki for using LeRobot by https://deepwiki.com/huggingface/lerobot or other LLM tools you want.

2. If the video captuer is not stable (shaking)?

    A: Connect the cameras with different USB port/hub with the PC (laptop) for smooth video capture.

3. How to fast download files(datasets, models, wandb) from the Cloud VM?

    A: please use tar the files which you want to download first in terminal of Jupyter Notebook and then download it.
    The example tar command,
    
    ```shell
    tar cjvf your_model.tar.bz2 your_model
    ```

4. Why do I get error like `Runtime Error: Could not push packet to decoder: Invalid data found when processing input` during `lerobot-train`?    
   A: It indicates that one of the video files in your dataset is corrupted.  The command `ffmpeg -v error -i file-000.mp4 -f null -` is a diagnostic command used to check a video file for corruption.    
    Here is the breakdown of each part:    
    - `ffmpeg`: The command-line tool for processing video and audio.
    - `-v error`: Sets the logging verbosity to error. This means ffmpeg will run silently and only print text if it encounters an actual error (like a corrupted frame or header). If the file is healthy, it will produce no output.
    - `-i file-000.mp4`: Specifies the input file you want to check.
    - `-f null: Sets the output format to null. This is a special format that discards all output data. It tells ffmpeg to go through the process of decoding the video (which reveals corruption) but not to actually write the video anywhere.
    - `-`: Specifies the output destination as standard output (stdout). Combined with -f null, this effectively sends the decoded data to "nowhere" (/dev/null).    
    **In summary**: It forces your computer to decode every single frame of the video but throw away the result. If any frame is broken, ffmpeg will scream about it in the terminal. If the terminal stays silent, the video is valid.    
    The most common root cause for video corruption in datasets is **Interrupted Recording/Writing**. The recording process (the robot collection script) was killed (SIGINT/Ctrl+C) or crashed while it was writing the video file.



