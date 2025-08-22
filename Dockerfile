# Use NVIDIA CUDA base image for GPU support
FROM nvidia/cuda:11.8.0-base-ubuntu22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies with GPU support
RUN apt-get update && apt-get install -y \
    # Essential tools
    wget \
    curl \
    unzip \
    # X11 and display libraries
    xvfb \
    x11-utils \
    # OpenGL libraries with NVIDIA support
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libglu1-mesa \
    mesa-utils \
    # Vulkan support
    vulkan-tools \
    libvulkan1 \
    # NVIDIA specific libraries for encoding/decoding
    libnvidia-gl-470 \
    libnvidia-encode-470 \
    libnvidia-decode-470 \
    # Audio system
    pulseaudio \
    alsa-utils \
    # Unity dependencies
    libgconf-2-4 \
    libxss1 \
    libgtk-3-0 \
    libxrandr2 \
    libxtst6 \
    libnss3 \
    libasound2 \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libgbm1 \
    libxkbcommon0 \
    # For camera access (if needed)
    v4l-utils \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables (NVIDIA_VISIBLE_DEVICES is set by ECS)
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute,display,video
ENV DISPLAY=:99
ENV LIBGL_ALWAYS_INDIRECT=0

# Performance optimizations
ENV __GL_SYNC_TO_VBLANK=0
ENV __GL_SHADER_DISK_CACHE=1
ENV __GL_SHADER_DISK_CACHE_SIZE=1073741824
ENV CUDA_CACHE_MAXSIZE=1073741824
ENV CUDA_FORCE_PTX_JIT=1

# Create a non-root user
RUN useradd -m -s /bin/bash unity
USER unity
WORKDIR /home/unity

# Create app directory
RUN mkdir -p /home/unity/app

# Copy Unity app
COPY --chown=unity:unity ./builds /home/unity/app

# Copy GPU-optimized start script
COPY --chown=unity:unity scripts/start.sh /home/unity/start.sh

# Make scripts executable
RUN chmod +x /home/unity/start.sh && \
    chmod +x /home/unity/app/unity-webrtc-streamer.x86_64

CMD ["/home/unity/start.sh"]