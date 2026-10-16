# Reverse Engineering Report: JNG's Frame Generator

## Target Binary

- **File**: `JNG's frame generator-levipack-arm64-v8a.bin`
- **SHA-256**: `b8c48fef6f6df91d75938f607660172585489999d9447eabb1c96aeb25e37f81`
- **Size**: 218,187 bytes (213 KB)
- **Format**: ZIP archive containing nested `.levipack`, library, and manifest

## Package Structure

```
JNG's frame generator-levipack-arm64-v8a.bin (ZIP)
├── FrameGen.levipack (ZIP)
│   ├── manifest.json (449 bytes)
│   ├── libframegen.so (239,832 bytes)
│   └── icon.png (859 bytes)
├── build/libframegen.so (239,832 bytes, same as nested)
└── manifest.json (608 bytes)
```

## Library Analysis

### libframegen.so (Original)

- **SHA-256**: `b9890555131ad58657233a14907b5e5c2b682df1ea7362166d32447288e05f53`
- **Size**: 239,832 bytes
- **Type**: ELF 64-bit LSB shared object, ARM aarch64
- **Android API**: 26 (Android 8.0)
- **NDK**: r26b (10909125)
- **BuildID**: `06323d91bdf01d217d53f42979337a42193c1e38`
- **Stripped**: Yes

### Exported Symbols (Key)

| Symbol | Type | Description |
|--------|------|-------------|
| `PLGetModRegistration` | T | Plugin registration entry (internal C++ mod ABI) |
| `JNI_OnLoad` | T | JNI initialization |
| `Java_..._FpsMod_nativeGetFps` | T | Legacy FPS mod interface |
| `Java_..._FrameGenMod_native*` | T | FrameGen JNI bridge (8 functions) |
| `_ZN8framegen10FramePacer*` | T | Frame pacing (recordFrame, paceForTargetFps, reset) |
| `_ZN8framegen14CameraSmoother*` | T | Camera smoothing (installHooks, processTurnDelta, etc.) |
| `_ZN8framegen19GlFrameInterpolator*` | T | Frame interpolation (installHook, onSwapBuffers, etc.) |
| `_ZN8framegen11HudRenderer*` | T | HUD rendering (publishHud, buildDrawCommands, etc.) |
| `_ZN8framegen11FrameGenMod*` | T | Main module lifecycle |

### Key Observations

1. **ABI Mismatch**: The original binary exports `PLGetModRegistration` returning a `PLModRegistration` struct, which is the **internal C++ mod ABI**. However, the Levi Launcher 1.5.26 expects **external native mods** (loaded via `.levipack`) to export direct lifecycle functions:
   - `PLMod_Load(void* mod, void* ctx) -> bool`
   - `PLMod_Enable(void* mod, void* ctx) -> bool`
   - `PLMod_Disable(void* mod, void* ctx) -> void`
   - `PLMod_Unload(void* mod, void* ctx) -> void`

2. **Crash Root Cause**: The previous SIGILL crash (offset 0x12c0) occurred because the launcher tried to call a function pointer from the `PLModRegistration` struct that pointed to `.rodata` (string data) instead of executable code. This happened because the struct layout was incorrect for the launcher's expectations.

3. **Levi Launcher 1.5.26 Evidence**: From `libpreloader.so`:
   - External mods must export: `PLMod_Load`, `PLMod_Enable`, `PLMod_Disable`, `PLMod_Unload`
   - Strings confirm: `"PLMod_Load"`, `"PLMod_Enable"`, `"PLMod_Disable"`, `"PLMod_Unload"`, `"PLGetModRegistration"`
   - Resolution: `resolveLifecycleLoad` / `resolveLifecycleFunc` find these symbols

## Internal Classes (Demangled)

- `framegen::FrameGenMod` - Main module singleton
- `framegen::GlFrameInterpolator` - EGL hook + frame synthesis
- `framegen::CameraSmoother` - Camera smoothing (EMA, Spring, Adaptive)
- `framegen::FramePacer` - Frame pacing with telemetry
- `framegen::HudRenderer` - HUD overlay via JNI
- `framegen::FrameGenConfig` - Configuration struct
- `framegen::FrameBuffer` - GL frame buffer management
- `framegen::SynthesisProgram` - GLSL shader program
- `framegen::RuntimeTelemetrySnapshot` - Per-frame metrics

## Manifest Analysis

### Outer Manifest (schema_version: 1)
```json
{
  "id": "leviframegen",
  "name": "LeviFrameGen",
  "version": "2.3.0",
  "type": "preload-native",
  "entry": "libframegen.so"
}
```

### Nested Manifest (schema_version: 1)
```json
{
  "id": "leviframegen",
  "name": "LeviFrameGen",
  "version": "2.3.0",
  "type": "preload-native",
  "entry": "libframegen.so",
  "overwrite_files": ["manifest.json", "levimod.json", "libframegen.so", "icon.png", "config/config.json"],
  "overwrite_folders": ["config"]
}
```

## Levi Launcher 1.5.26 Integration

### External Native Mod ABI (from libpreloader.so)
```c
// Required exports for external native mods (.levipack)
bool PLMod_Load(void* mod, void* ctx);      // mod = FrameGenMod**, ctx = ModContext*
bool PLMod_Enable(void* mod, void* ctx);
void PLMod_Disable(void* mod, void* ctx);
void PLMod_Unload(void* mod, void* ctx);
```

### Internal C++ Mod ABI (NOT for external mods)
```c
struct PLModRegistration {
    uint32_t version;
    const char* name;
    bool (*load)(void* mod, void* ctx);
    bool (*enable)(void* mod, void* ctx);
    void (*unload)(void* mod, void* ctx);
    void (*disable)(void* mod, void* ctx);
};
PLModRegistration* PLGetModRegistration();
```

### JNI Interface
```c
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved);
JNIEXPORT jint JNICALL Java_org_levimc_launcher_core_mods_inbuilt_nativemod_FpsMod_nativeGetFps(JNIEnv*, jobject);
JNIEXPORT jint JNICALL Java_..._FrameGenMod_nativeInitialize(JNIEnv*, jobject, jint, jint);
JNIEXPORT void JNICALL Java_..._FrameGenMod_nativeShutdown(JNIEnv*, jobject);
JNIEXPORT void JNICALL Java_..._FrameGenMod_nativeSetConfig(JNIEnv*, jobject, jstring);
JNIEXPORT jstring JNICALL Java_..._FrameGenMod_nativeGetConfig(JNIEnv*, jobject);
JNIEXPORT jstring JNICALL Java_..._FrameGenMod_nativeGetTelemetry(JNIEnv*, jobject);
JNIEXPORT void JNICALL Java_..._FrameGenMod_nativeToggle(JNIEnv*, jobject, jboolean);
JNIEXPORT void JNICALL Java_..._FrameGenMod_nativeCyclePreset(JNIEnv*, jobject);
```

## Shader Analysis

The original binary contains embedded GLSL shaders for frame synthesis:

### Vertex Shader
- Fullscreen quad pass-through
- Inputs: position (vec2), texcoord (vec2)
- Output: texcoord to fragment shader

### Fragment Shader
- Temporal blend: `mix(previous.rgb, current.rgb, blend_factor)`
- HUD protection: luminance difference heuristic
- Uniforms: prev_texture, curr_texture, motion_texture, blend_factor, motion_scale, resolution

## Configuration Schema (from strings)

Supported config keys:
- `preset` (0=Custom, 1=Performance, 2=Balanced, 3=Quality)
- `frame_gen_mode` (0=Off, 1=SingleSwap, 2=DoubleSwap, 3=TripleSwap)
- `multiplier` (1.0-10.0)
- `blend_strength` (0.0-1.0)
- `motion_scale` (0.0-2.0)
- `camera_mode` (0=None, 1=EMA, 2=Spring, 3=AdaptiveSmart)
- `camera_smoothing_strength` (0.0-1.0)
- `camera_responsiveness` (0.0-1.0)
- `hud_style` (0=Minimal, 1=Standard, 2=Detailed, 3=PerformanceGraph)
- `hud_optimizer` (0=None, 1=HideDefaultFPS, 2=HideAllOverlays, 3=CustomOnly)
- `hud_protection` (bool)
- `vsync_mode` (0=Auto, 1=Enabled, 2=Disabled)
- `max_fps` (0=unlimited, 60-5000)
- `enable_optical_flow` (bool)
- `max_interpolation_frames` (1-3)
- `gpu_memory_budget_mb` (16-1024)

## Identified Limitations in Original

1. **Wrong ABI for external mods** - Uses `PLGetModRegistration` instead of direct lifecycle exports
2. **No optical flow implementation** - String present but likely stubbed
3. **HUD protection heuristic only** - Luminance difference, not true UI detection
4. **No motion vector access** - Cannot read game's internal motion vectors
5. **Stripped binary** - No debug info, harder to analyze
6. **API 26 minimum** - Limits device compatibility
7. **NDK r26b specific** - May have issues on different NDK versions

## Reimplementation Strategy

1. **Correct ABI**: Export direct lifecycle functions (`PLMod_Load`, etc.)
2. **Modular architecture**: Separate modules with pure virtual interfaces
3. **Modern C++17**: RAII, smart pointers, atomic operations
4. **Comprehensive config**: JSON load/save with full schema
4. **Shader embedded in source**: No external file dependencies
5. **Comprehensive telemetry**: P99/P99.9 percentiles, jitter, effective FPS
5. **Defensive programming**: Null checks, bounds validation, cleanup
6. **Documentation**: Full architecture, build, and RE report

## Confidence Levels

| Finding | Confidence | Evidence |
|---------|------------|----------|
| Package structure (ZIP > ZIP) | HIGH | Verified by unzip/file/xxd |
| Library SHA-256 | HIGH | Verified by sha256sum |
| PLGetModRegistration export | HIGH | nm -D shows it |
| External mod ABI (PLMod_*) | HIGH | Strings + resolveLifecycleLoad in libpreloader.so |
| Crash cause (SIGILL at 0x12c0) | HIGH | Previous forensic report + ABI mismatch |
| JNI function names | HIGH | nm -D demangled symbols |
| Shader source | MEDIUM | Strings + typical patterns |
| Internal class structure | MEDIUM | Demangled symbol names |
| Optical flow implementation | LOW | String present but no implementation found |
| Config schema completeness | MEDIUM | Strings + typical patterns |