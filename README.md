# LeviFrameGen

An open-source frame generation mod for Minecraft Bedrock Edition on Android, compatible with Levi Launcher 1.5.26.

## Features

- **Frame Generation**: Temporal frame interpolation (2x/3x/4x) with HUD protection
- **Camera Smoothing**: EMA, Spring-damper, and AdaptiveSmart algorithms
- **Frame Pacing**: Configurable 60-5000 FPS with VSync modes (Auto/Enabled/Disabled)
- **HUD Overlay**: Real-time telemetry with FPS, frame time, jitter, and percentile metrics
- **Configuration**: JSON-based with presets (Performance, Balanced, Quality, Custom)

## Architecture

```
source/
├── include/framegen/           # Public headers
│   ├── FrameGenCore.hpp        # Core types and interfaces
│   ├── FrameGenMod.hpp         # Main module class
│   ├── PluginRegistration.hpp  # Levi Launcher ABI
│   ├── jni.hpp                 # JNI entry points
│   ├── config/ConfigManager.hpp
│   ├── interpolation/GlFrameInterpolator.hpp
│   ├── motion/CameraSmoother.hpp
│   ├── pacing/FramePacer.hpp
│   ├── hud/HudRenderer.hpp
│   └── launcher/LauncherIntegration.hpp
├── src/framegen/               # Implementation
│   ├── FrameGenMod.cpp
│   ├── PluginRegistration.cpp
│   ├── jni.cpp
│   ├── Factory.cpp
│   ├── config/ConfigManager.cpp
│   ├── interpolation/GlFrameInterpolator.cpp
│   ├── motion/CameraSmoother.cpp
│   ├── pacing/FramePacer.cpp
│   ├── hud/HudRenderer.cpp
│   └── launcher/LauncherIntegration.cpp
├── shaders/                    # GLSL shaders (embedded in source)
└── CMakeLists.txt
```

## Requirements

- Android NDK r26b (or compatible)
- Android API 26+ (Android 8.0+)
- Levi Launcher 1.5.26+
- ARM64 (arm64-v8a) device

## Build

```bash
cd source
./build.sh
```

The build produces `dist/libframegen.so` ready for packaging.

## Installation

1. Build the library: `cd source && ./build.sh`
2. The levipack is created at `dist/FrameGen.levipack`
3. Import via Levi Launcher → Mods → Import levipack
4. Enable in Mod Menu

## Compatibility

- **Levi Launcher**: 1.5.26 (tested)
- **Minecraft Bedrock**: 1.20+ (via Levi Launcher)
- **Architecture**: ARM64 (arm64-v8a)
- **Android**: API 26+ (Android 8.0+)

## License

MIT License - see LICENSE file