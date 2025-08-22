# Unity WebRTC Streaming Infrastructure

## Overview

Docker-based infrastructure for running Unity WebRTC streaming applications with GPU acceleration on cloud platforms.

## System Requirements

### Hardware
- NVIDIA GPU (T4 or equivalent)
- 4+ vCPUs
- 16GB+ RAM
- 100GB storage

### Software
- Ubuntu 22.04 LTS
- Docker 24.0+
- NVIDIA Container Toolkit
- NVIDIA Driver 525+

## Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd webrtc-unity-infra
```

### 2. Setup GPU Environment
```bash
chmod +x scripts/setup-ec2-gpu.sh
./scripts/setup-ec2-gpu.sh
```

### 3. Build Docker Image
```bash
./scripts/build.sh
```

### 4. Run Container
```bash
./scripts/run.sh
```

## Architecture

### Components
- **Unity Application**: Linux build with WebRTC streaming capability
- **Docker Container**: GPU-accelerated environment with Vulkan rendering
- **Virtual Display**: Xvfb for headless operation
- **Audio System**: PulseAudio for audio capture

### Network Configuration
- HTTP: Port 8080
- WebRTC: UDP ports 10000-10100
- STUN: Google public servers

## Deployment Options

### Docker Compose
```bash
docker-compose up -d
```

### AWS ECS
See [AWS Deployment Guide](docs/aws-deployment.md)

### Manual Docker
```bash
docker run --gpus all \
  -p 8080:8080 \
  -p 10000-10100:10000-10100/udp \
  unity-webrtc-streamer:latest
```

## Performance Specifications

| Metric | Target |
|--------|--------|
| Resolution | 1920x1080 |
| Frame Rate | 60 FPS |
| Bitrate | 10 Mbps |
| Latency | <100ms |
| GPU Usage | 40-60% |

## Monitoring

### GPU Utilization
```bash
docker exec unity-webrtc-streamer nvidia-smi
```

### Application Logs
```bash
docker logs unity-webrtc-streamer
```

## Troubleshooting

### GPU Not Detected
Verify NVIDIA driver installation:
```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Performance Issues
1. Check GPU utilization
2. Verify Vulkan rendering in logs
3. Monitor CPU and memory usage

### Connection Problems
1. Verify UDP ports 10000-10100 are open
2. Check signaling server connectivity
3. Review container logs for errors

## Documentation

- [GPU Setup Guide](GPU-SETUP.md)
- [Cost Estimation](COST_ESTIMATION.md)
- [Docker Environment](DOCKER_ENVIRONMENT.md)

## License

[License Type]