# GPU Acceleration Setup

## Overview

Configure GPU-accelerated Unity WebRTC streaming on AWS EC2 instances with NVIDIA GPUs.

## Prerequisites

### AWS EC2 Instance Requirements
- Instance type: g4dn.xlarge minimum
- Operating system: Ubuntu 22.04 LTS
- GPU: NVIDIA T4 (included with g4dn instances)
- Storage: 100GB EBS volume

## Installation

### Step 1: Environment Setup

Connect to the EC2 instance:
```bash
ssh -i <key-file>.pem ubuntu@<instance-ip>
```

Clone and navigate to the repository:
```bash
git clone <repository-url>
cd webrtc-unity-infra
```

Execute the GPU setup script:
```bash
chmod +x scripts/setup-ec2-gpu.sh
./scripts/setup-ec2-gpu.sh
```

If prompted, reboot the instance:
```bash
sudo reboot
```

After reboot, re-run the setup script to complete installation.

### Step 2: Build Docker Image

Build the container:
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

### Step 3: Launch Container

Start the streaming service:
```bash
chmod +x scripts/run.sh
./scripts/run.sh
```

## Alternative Deployment Methods

### Docker Compose

Start service:
```bash
docker-compose up -d
```

Monitor logs:
```bash
docker-compose logs -f
```

Stop service:
```bash
docker-compose down
```

## AWS ECS Deployment

### Step 1: Push to ECR

Authenticate Docker:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ecr-uri>
```

Tag and push image:
```bash
docker tag unity-webrtc-streamer:latest <ecr-uri>:latest
docker push <ecr-uri>:latest
```

### Step 2: Create ECS Cluster

Create cluster:
```bash
aws ecs create-cluster --cluster-name unity-gpu-cluster
```

Configure Auto Scaling group with g4dn.xlarge instances using ECS-optimized GPU AMI.

### Step 3: Register Task Definition

Update task definition JSON with account ID and ECR URI, then register:
```bash
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition-gpu.json
```

### Step 4: Create Service

Deploy the service:
```bash
aws ecs create-service \
  --cluster unity-gpu-cluster \
  --service-name unity-webrtc-service \
  --task-definition unity-webrtc-streaming-gpu:1 \
  --desired-count 1 \
  --launch-type EC2
```

## Performance Configuration

### Unity Build Settings

Configure the Unity project for Linux deployment:

| Setting | Value |
|---------|-------|
| Graphics API | Vulkan (primary), OpenGL Core 4.5 (fallback) |
| Target Frame Rate | 60 FPS |
| Color Space | Linear |
| Quality Level | Medium-High |

### Container Optimisations

The infrastructure implements:
- Vulkan rendering via `-force-vulkan` flag
- 1GB shared memory allocation
- Direct GPU rendering pipeline
- Full NVIDIA runtime capabilities

### Performance Monitoring

GPU utilisation:
```bash
docker exec unity-webrtc-streamer nvidia-smi
```

Continuous monitoring:
```bash
docker exec unity-webrtc-streamer watch -n 1 nvidia-smi
```

Application logs:
```bash
docker logs unity-webrtc-streamer
```

## Troubleshooting

### GPU Detection Issues

Verify host GPU:
```bash
nvidia-smi
```

Test Docker GPU access:
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Performance Issues

1. Monitor GPU utilisation via `nvidia-smi`
2. Confirm Vulkan rendering in Unity logs
3. Check CPU frequency: `cat /proc/cpuinfo | grep MHz`
4. Review memory usage: `free -h`

### Connection Problems

1. Verify UDP ports 10000-10100 in security group
2. Review container logs for errors
3. Confirm signaling server connectivity

## Expected Performance

### g4dn.xlarge Benchmarks

| Metric | Value |
|--------|-------|
| Resolution | 1920x1080 |
| Frame Rate | 60 FPS |
| Bitrate | 10 Mbps |
| Latency | <100ms |
| GPU Usage | 40-60% |
| CPU Usage | 20-30% |