#!/bin/bash

# Setup script for AWS EC2 g4dn instances with NVIDIA T4 GPU
# Run this on your EC2 instance to prepare it for GPU-accelerated Docker

echo "Setting up EC2 instance for GPU-accelerated Docker..."

# Update system
sudo apt-get update

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install NVIDIA drivers for T4 (if not already installed)
if ! command -v nvidia-smi &> /dev/null; then
    echo "Installing NVIDIA drivers..."
    sudo apt-get install -y linux-headers-$(uname -r)
    
    # Install NVIDIA driver (470 is stable for T4)
    sudo apt-get install -y nvidia-driver-470
    
    echo "NVIDIA driver installed. Please reboot the instance and run this script again."
    exit 0
fi

# Verify NVIDIA driver is working
echo "Checking NVIDIA GPU..."
nvidia-smi
if [ $? -ne 0 ]; then
    echo "ERROR: NVIDIA driver not working properly"
    exit 1
fi

# Install NVIDIA Container Toolkit
echo "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU in Docker
echo "Testing GPU in Docker..."
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

if [ $? -eq 0 ]; then
    echo "✅ GPU support in Docker is working!"
    echo ""
    echo "Next steps:"
    echo "1. Build the GPU Docker image: ./scripts/buildDockerGPU.sh"
    echo "2. Run the container: ./scripts/runDockerGPU.sh"
else
    echo "❌ GPU support in Docker failed. Please check the installation."
fi