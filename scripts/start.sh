#!/bin/bash
# start-gpu.sh - GPU-optimized script to start Unity app in container

echo "Starting Unity Linux app with GPU acceleration..."

# Check for NVIDIA GPU
echo "Checking NVIDIA GPU availability..."
nvidia-smi > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NVIDIA GPU detected!"
    nvidia-smi
else
    echo "WARNING: No NVIDIA GPU detected, falling back to software rendering"
fi

# Start virtual display with GPU acceleration
echo "Starting virtual display..."
Xvfb :99 -screen 0 1920x1080x24 +extension GLX +render -noreset &
sleep 2

# Verify GLX is working
echo "Verifying OpenGL/GLX..."
DISPLAY=:99 glxinfo | grep -i "direct rendering"

# Start PulseAudio for audio
echo "Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 &
sleep 1

# Check if Unity app exists
echo "Checking Unity App..."
if [ ! -f "/home/unity/app/unity-webrtc-streamer.x86_64" ]; then
    echo "Unity app not found at /home/unity/app/unity-webrtc-streamer.x86_64"
    exit 1
fi

# Make sure the app is executable
chmod +x /home/unity/app/unity-webrtc-streamer.x86_64

# Run the Unity app with GPU optimization flags
echo "Starting Unity app with GPU acceleration..."
cd /home/unity/app || exit

# Set thread affinity for better performance
export UNITY_ASYNC_JOB_WORKERS=4
export UNITY_JOB_WORKERS=4

./unity-webrtc-streamer.x86_64 \
    -force-vulkan \
    -gpu-skinning \
    -logFile - \
    -screen-width 1920 \
    -screen-height 1080 \
    -screen-fullscreen 0