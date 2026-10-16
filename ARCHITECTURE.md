# LeviFrameGen Architecture

## Overview

LeviFrameGen is a modular frame generation mod for Minecraft Bedrock on Android, designed for the Levi Launcher 1.5.26 plugin ecosystem.

## Module Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      FrameGenMod (Main)                         │
│  ┌──────────────┐ ┌─────────────┐ ┌───────────┐ ┌────────────┐  │
│  │ ConfigManager│ │FramePacer   │ │CameraSmth │ │HudRenderer │  │
│  └──────┬───────┘ └──────┬──────┘ └─────┬────┘ └─────┬──────┘  │
│         │                │               │           │          │
│         └────────────────┼───────────────┼───────────┘          │
│                          ▼               ▼                      │
│              ┌─────────────────────────────────────────┐        │
│              │         GlFrameInterpolator             │        │
│              │  ┌─────────┐ ┌──────────┐ ┌──────────┐  │        │
│              │  │ EGL Hook│ │ Synthes. │ │ FrameBuf │  │        │
│              │  └─────────┘ └──────────┘ └──────────┘  │        │
│              └─────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  LauncherIntegration                            │
│  (PLMod_Load/Enable/Disable/Unload + JNI Bridge)               │
└─────────────────────────────────────────────────────────────────┘
```

## Core Interfaces

### IConfigManager
- JSON load/save with key-value apply
- 4 presets: Performance, Balanced, Quality, Custom
- Runtime config updates with persistence

### IFramePacer
- `paceForTargetFps(target_fps, frame_start_ns)` - Adaptive pacing
- `recordFrame(timestamp, type, is_interpolated)` - Telemetry
- VSync modes: Auto, Enabled, Disabled (unlock FPS)
- Percentile metrics (P99, P99.9)

### ICameraSmoother
- `installHooks()` / `uninstallHooks()` - Camera hook lifecycle
- `processTurnDelta(yaw, pitch, timestamp)` - Apply smoothing
- Modes: EMA, Spring, AdaptiveSmart
- Motion history for adaptive algorithm

### IFrameInterpolator
- `initialize(width, height)` - GL resource setup
- `installHook()` / `uninstallHook()` - EGL swap hook
- `onSwapBuffers(display, surface)` - Frame capture & synthesis
- Temporal blend shader with HUD protection

### IHudRenderer
- `initialize(java_vm, config)` - JNI setup
- `publishHud(config, telemetry)` - Overlay rendering
- `clearHud()` - Cleanup

### ILauncherIntegration
- PLMod lifecycle callbacks (Load/Enable/Disable/Unload)
- JNI bridge for native ↔ Java communication
- Config sync and event routing

## Data Flow

1. **Launcher Load**: `PLMod_Load` → creates FrameGenMod → `load()` → initializes subsystems
2. **Launcher Enable**: `PLMod_Enable` → `enable()` → installs EGL hook + camera hooks
3. **Render Loop**: Game calls `eglSwapBuffers` → hook captures frame → interpolates → presents
3. **Frame Pacing**: `paceForTargetFps()` called before/after frame presentation
4. **Camera Smoothing**: `processTurnDelta()` called from hooked camera functions
5. **HUD**: `publishHud()` called per frame with telemetry
6. **Launcher Disable**: `PLMod_Disable` → uninstalls hooks
6. **Launcher Unload**: `PLMod_Unload` → cleanup, delete instance

## Shader Pipeline

### Vertex Shader (`VERTEX_SHADER_SOURCE`)
- Fullscreen quad pass-through
- Position + UV coordinates

### Fragment Shader (`FRAGMENT_SHADER_SOURCE`)
- Temporal blend: `mix(prev.rgb, curr.rgb, blend_factor)`
- HUD protection: luminance difference detection
- Uniforms: prev/curr textures, blend_factor, motion_scale, resolution

## Configuration Schema

```json
{
  "preset": 0-3,
  "frame_gen_mode": 0-3,
  "multiplier": 1.0-10.0,
  "blend_strength": 0.0-1.0,
  "motion_scale": 0.0-2.0,
  "camera_mode": 0-3,
  "camera_smoothing_strength": 0.0-1.0,
  "camera_responsiveness": 0.0-1.0,
  "hud_style": 0-3,
  "hud_optimizer": 0-3,
  "hud_protection": true/false,
  "show_fps_graph": true/false,
  "show_frame_times": true/false,
  "show_memory_usage": true/false,
  "scene_cut_threshold": 0-100,
  "vsync_mode": 0-2,
  "max_fps": 0-5000,
  "min_fps": 10-240,
  "enable_motion_vectors": true/false,
  "enable_optical_flow": true/false,
  "max_interpolation_frames": 1-3,
  "gpu_memory_budget_mb": 16-1024,
  "enable_frame_pacing": true/false,
  "low_latency_mode": true/false,
  "debug_mode": true/false
}
```

## Levi Launcher ABI

External native mods must export:
- `PLMod_Load(void* mod, void* ctx) -> bool`
- `PLMod_Enable(void* mod, void* ctx) -> bool`
- `PLMod_Disable(void* mod, void* ctx) -> void`
- `PLMod_Unload(void* mod, void* ctx) -> void`

JNI entry points:
- `JNI_OnLoad/OnUnload`
- `Java_org_levimc_launcher_core_mods_inbuilt_nativemod_FrameGenMod_native*`

## Known Limitations

1. Optical flow not implemented (too expensive for mobile)
2. Motion vectors from game engine not accessible (no internal access)
3. HUD protection is heuristic-based (luminance diff)
4. Requires Levi Launcher 1.5.26+ for correct ABI
4. Android API 26+ required (Android 8.0+)