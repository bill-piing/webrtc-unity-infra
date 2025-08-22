#!/bin/bash

echo "Building Unity Docker image..."

# Navigate to the project root
cd "$(dirname "$0")/.." || exit

# Build the Docker image
docker build -t unity-webrtc-streamer .

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Run with: ./scripts/run.sh"
else
    echo "Build failed!"
    exit 1
fi