# Docker Environment Documentation

## Base Image

### nvidia/cuda:11.8.0-base-ubuntu22.04
**Purpose**: Provides CUDA runtime and NVIDIA GPU driver compatibility  
**Usage**: Unity requires GPU acceleration for real-time rendering and video encoding  
**Considerations**: 
- Version 11.8 chosen for compatibility with T4 GPUs (AWS g4dn instances)
- Update to newer CUDA versions carefully - test Unity compatibility first
- Base image is minimal (~150MB) compared to devel variants (~2GB)

## Package Dependencies

### Essential Tools

| Package | Purpose | Usage |
|---------|---------|---------------------------------------------|
| `wget` | HTTP file downloads | Downloading additional runtime dependencies |
| `curl` | Data transfer tool | API calls and health checks                 |
| `unzip` | Archive extraction | Extracting Unity builds if compressed       |

### Display System

| Package | Purpose | Usage | Considerations |
|---------|---------|---------------------------------------------|----------------|
| `xvfb` | Virtual framebuffer | Provides headless X11 display for Unity rendering | Memory usage scales with resolution |
| `x11-utils` | X11 utilities | Display verification and debugging (`xdpyinfo`, `xwininfo`) | Optional but helpful for troubleshooting |

### OpenGL Libraries

| Package | Purpose | Usage | Considerations |
|---------|---------|--------------------------|----------------|
| `libgl1-mesa-glx` | GLX runtime | OpenGL rendering context creation | Must coexist with NVIDIA libraries |
| `libgl1-mesa-dri` | DRI drivers | Hardware acceleration interface | Fallback when NVIDIA drivers unavailable |
| `libglu1-mesa` | OpenGL Utility Library | Legacy OpenGL functions Unity may use | Required for older Unity projects |
| `mesa-utils` | OpenGL utilities | Includes `glxinfo` for GPU verification | Useful for debugging |

### Vulkan Support

| Package | Purpose | Usage | Considerations |
|---------|---------|-------------------------|----------------|
| `vulkan-tools` | Vulkan utilities | Includes `vulkaninfo` for verification | Optional but recommended |
| `libvulkan1` | Vulkan loader | Required for Vulkan rendering pipeline | Performance improvement over OpenGL |

### NVIDIA Libraries

| Package | Purpose | Usage | Considerations |
|---------|---------|---------------------------|----------------|
| `libnvidia-gl-470` | NVIDIA OpenGL | Hardware-accelerated OpenGL | Version must match driver |
| `libnvidia-encode-470` | NVENC library | H.264/H.265 hardware encoding for WebRTC | Critical for streaming performance |
| `libnvidia-decode-470` | NVDEC library | Hardware video decoding   | May be needed for video input |

**Important**: Version 470 is placeholder - actual version depends on installed NVIDIA driver. Consider using wildcard: `libnvidia-gl-*`

### Audio System

| Package | Purpose | Usage                          | Considerations |
|---------|---------|--------------------------------|----------------|
| `pulseaudio` | Audio server | Virtual audio device for Unity | CPU overhead ~1-2% |
| `alsa-utils` | ALSA utilities | Low-level audio interface      | PulseAudio dependency |

### Unity Runtime Dependencies

| Package | Purpose | Usage |
|---------|---------|---------------|
| `libgconf-2-4` | Configuration system | Legacy Unity UI systems |
| `libxss1` | X11 Screen Saver extension | Display power management |
| `libgtk-3-0` | GTK+ 3 toolkit | File dialogs and UI elements |
| `libxrandr2` | X11 RandR extension | Display configuration |
| `libxtst6` | X11 Testing extension | Input simulation |
| `libnss3` | Network Security Services | SSL/TLS support |
| `libasound2` | ALSA library | Audio output  |
| `libdrm2` | Direct Rendering Manager | GPU memory management |
| `libxcomposite1` | X11 Composite extension | Window compositing |
| `libxdamage1` | X11 Damage extension | Efficient screen updates |
| `libxfixes3` | X11 Fixes extension | Cursor and region operations |
| `libatk-bridge2.0-0` | ATK accessibility bridge | Accessibility support |
| `libatspi2.0-0` | Assistive Technology SPI | Accessibility framework |
| `libgbm1` | Generic Buffer Management | GPU buffer allocation |
| `libxkbcommon0` | Keyboard handling | Input processing |

### Optional Components

| Package | Purpose | Usage | Can Remove If |
|---------|---------|-------|---------------|
| `v4l-utils` | Video4Linux utilities | Camera/webcam access | No camera input needed |

## Environment Variables

### Display Configuration
- `DISPLAY=:99` - Virtual display number for Xvfb
- `LIBGL_ALWAYS_INDIRECT=0` - Force direct rendering (better performance)

### NVIDIA Settings
- `NVIDIA_DRIVER_CAPABILITIES` - Defines GPU features available to container
- `NVIDIA_VISIBLE_DEVICES` - GPU selection (set by orchestrator)

### Performance Optimizations
- `__GL_SYNC_TO_VBLANK=0` - Disable VSync for maximum FPS
- `__GL_SHADER_DISK_CACHE=1` - Enable shader caching
- `__GL_SHADER_DISK_CACHE_SIZE` - 1GB shader cache
- `CUDA_CACHE_MAXSIZE` - 1GB CUDA kernel cache
- `CUDA_FORCE_PTX_JIT=1` - JIT compile for optimal performance

## Size Optimization Opportunities

### Current Image Size: ~1.5GB

Potential reductions:
1. **Multi-stage build** - Compile Unity app separately
2. **Remove mesa-utils** - Save ~10MB if not debugging
3. **Remove x11-utils** - Save ~5MB if not debugging
4. **Custom NVIDIA driver packages** - Save ~200MB with specific versions

### Minimal Production Image

For production, consider removing:
- `mesa-utils`
- `x11-utils`
- `vulkan-tools`
- `v4l-utils`
- `wget` (if not used in startup)

## Troubleshooting Guide

### GPU Not Detected
Check: `libnvidia-gl-*` package version matches host driver

### OpenGL Errors
Verify: `libgl1-mesa-glx` and NVIDIA GL libraries coexist

### Audio Issues
Ensure: PulseAudio daemon starts before Unity

### Performance Problems
Review: Environment variables for optimization settings

## Version Compatibility Matrix

| Component | Version | Compatible With |
|-----------|---------|-----------------|
| CUDA | 11.8 | Driver 450.51+ |
| Ubuntu | 22.04 | Unity 2021.3+ |
| NVIDIA Driver | 470+ | T4, V100, A10G |
| Vulkan | 1.2+ | Unity 2019.3+ |

## Future Considerations

1. **Ubuntu 24.04** - When Unity officially supports it
2. **Wayland** - Future replacement for X11 (not yet Unity-ready)
3. **PipeWire** - Modern audio system replacing PulseAudio
4. **NVIDIA Container Toolkit 2.0** - Improved GPU virtualization
5. **Unity 6** - May require additional dependencies