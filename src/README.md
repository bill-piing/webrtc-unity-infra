# Unity WebRTC Streaming - Pulumi Infrastructure

## Overview
This Pulumi project manages the deployment of Unity WebRTC streaming application to AWS ECS with GPU support on your existing g4dn.xlarge instance.

## Prerequisites
- Pulumi CLI installed
- AWS CLI configured with credentials
- Node.js 18+ installed
- Docker installed locally for building images

## Setup

### 1. Install Dependencies
```bash
cd src
npm install
```

### 2. Initialize Pulumi Stack
```bash
# Using local backend (stores state locally)
pulumi login --local

# Or using Pulumi Cloud (recommended for teams)
pulumi login

# Create a new stack
pulumi stack init dev
```

### 3. Verify Configuration
The `Pulumi.dev.yaml` file contains configuration for your existing AWS resources:
- ECS Cluster: `unity-streaming-test`
- EC2 Instance: `i-0c44b75175752eb0a` (g4dn.xlarge)
- ECR Repository: `piing-streaming/unity`
- Security Group: `sg-02d32309b1810e22a`

## Deployment

### Preview Changes
```bash
pulumi preview
```

### Deploy
```bash
pulumi up
```

### View Outputs
```bash
# All outputs
pulumi stack output

# Specific output
pulumi stack output webrtcEndpoint
```

## What This Deploys

1. **Docker Image Build & Push**
   - Builds GPU-optimized Docker image
   - Pushes to your existing ECR repository

2. **ECS Task Definition**
   - GPU resource requirement (1 GPU)
   - 2048 CPU units, 4096 MB memory
   - NVIDIA environment variables for GPU access
   - Port mappings for WebRTC

3. **ECS Service**
   - Runs on your existing ECS cluster
   - Constrained to your g4dn.xlarge instance
   - Auto-restarts on failure

4. **CloudWatch Logs**
   - Log group: `/ecs/unity-streaming-test`
   - 7-day retention

5. **Lambda Function** (optional)
   - Start/stop EC2 instance to save costs

## Managing the Deployment

### Start EC2 Instance (if stopped)
```bash
aws ec2 start-instances --instance-ids i-0c44b75175752eb0a
```

### Scale Service
```bash
# Stop service (keeps infrastructure)
aws ecs update-service --cluster unity-streaming-test --service unity-webrtc-service --desired-count 0

# Start service
aws ecs update-service --cluster unity-streaming-test --service unity-webrtc-service --desired-count 1
```

### View Logs
```bash
aws logs tail /ecs/unity-streaming-test --follow
```

### Update Deployment
After making changes to the code:
```bash
pulumi up
```

### Destroy Infrastructure
```bash
# This will only remove managed resources (service, task definition, etc.)
# Your EC2 instance and ECS cluster remain untouched
pulumi destroy
```

## Cost Management

To minimize AWS costs:

1. **Stop EC2 when not in use:**
   ```bash
   aws ec2 stop-instances --instance-ids i-0c44b75175752eb0a
   ```

2. **Use the Lambda function to schedule start/stop:**
   ```bash
   # Get Lambda function name
   pulumi stack output startStopLambdaArn
   
   # Invoke to stop
   aws lambda invoke --function-name unity-streaming-start-stop \
     --payload '{"action":"stop"}' response.json
   ```

## Troubleshooting

### Check ECS Task Status
```bash
aws ecs list-tasks --cluster unity-streaming-test
aws ecs describe-tasks --cluster unity-streaming-test --tasks <task-arn>
```

### Check GPU Availability
```bash
aws ecs describe-container-instances --cluster unity-streaming-test \
  --container-instances <instance-arn> \
  --query "containerInstances[0].remainingResources[?name=='GPU']"
```

### Force New Deployment
```bash
aws ecs update-service --cluster unity-streaming-test \
  --service unity-webrtc-service --force-new-deployment
```

## Architecture Notes

- Uses existing infrastructure (no new EC2/ECS resources created)
- GPU acceleration via NVIDIA Container Runtime
- Vulkan rendering forced for optimal Linux performance
- Shared memory increased to 1GB for GPU operations
- WebRTC ports: 8080 (HTTP), 3478-3479 (STUN), 49152-65535 (RTP/RTCP)
