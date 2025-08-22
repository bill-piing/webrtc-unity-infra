#!/bin/bash

# Check if nvidia-docker is available
if ! command -v nvidia-smi &> /dev/null; then
    echo "WARNING: nvidia-smi not found. Make sure NVIDIA drivers are installed."
fi

# Check if Docker has NVIDIA runtime
docker info | grep -i nvidia > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "WARNING: NVIDIA Docker runtime not detected."
    echo "Please install nvidia-container-toolkit:"
    echo "  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -"
    echo "  distribution=\$(. /etc/os-release;echo \$ID\$VERSION_ID)"
    echo "  curl -s -L https://nvidia.github.io/nvidia-docker/\$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list"
    echo "  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
    echo "  sudo systemctl restart docker"
fi

echo "Starting Unity app with GPU acceleration..."

# Run with GPU support
docker run -it --rm \
    --gpus all \
    --runtime=nvidia \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e DISPLAY=:99 \
    -p 8080:8080 \
    -p 10000-10100:10000-10100/udp \
    --shm-size=1g \
    --name unity-webrtc-streamer \
    unity-webrtc-streamer

# Note: --shm-size=1g increases shared memory for better GPU performance