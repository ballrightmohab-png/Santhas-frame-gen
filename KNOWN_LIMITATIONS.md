# Known Limitations

This document lists the known limitations of the LeviFrameGen reimplementation. These are areas where the current implementation is incomplete, uses heuristics, or differs from the original binary's capabilities.

## 1. Optical Flow / Motion Vectors

**Status**: NOT IMPLEMENTED

**Details**: 
- The original binary contains strings referencing "optical flow" and "motion vectors", but no implementation was found in the disassembly.
- True optical flow requires access to per-pixel motion data from the game's render pipeline, which is not accessible through public EGL/OpenGL ES APIs.
- The current implementation uses simple temporal blending without motion compensation.

**Impact**: 
- Fast-moving objects may show ghosting or blur
- Camera rotation can cause smearing artifacts
- Quality preset enables `enable_optical_flow = true` but it has no effect

**Future Work**: 
- Would require hooking into the game's internal motion vector buffers (if they exist)
- Could use compute shaders for block-matching optical flow (expensive on mobile)

## 2. HUD Protection

**Status**: HEURISTIC ONLY

**Details**:
- Current implementation detects HUD elements by luminance difference between consecutive frames
- High luminance differences are assumed to be UI/text and are protected from blending
- This is a crude heuristic that can fail on:
  - Dark HUD elements (low luminance diff)
  - Bright game content changes (false positives)
  - Transparent/translucent HUD elements
  - Particle effects and explosions

**Impact**:
- Some HUD elements may still be blurred
- Occasional ghosting on bright game transitions

**Future Work**:
- Would need access to game's UI layer or depth/stencil buffers
- Could use alpha channel detection if available

## 3. Motion Vector Access

**Status**: NOT AVAILABLE

**Details**:
- The game engine's internal motion vectors (from vertex shaders or compute passes) are not exposed via EGL/OpenGL ES
- The reimplementation cannot read per-object or per-pixel motion vectors
- This limits the quality of frame interpolation to simple temporal blending

**Impact**:
- No true motion-compensated interpolation
- Quality limited to simple blending

## 4. Scene Cut Detection

**Status**: BASIC HEURISTIC

**Details**:
- Uses simple frame difference threshold (`scene_cut_threshold`)
- Can produce false positives on:
  - Flash effects
  - Lightning
  - Rapid camera cuts with similar content
  - Large particle effects

**Impact**:
- May disable interpolation during false scene cuts
- May miss actual scene cuts with similar frames

## 5. Android API Compatibility

**Status**: API 26+ REQUIRED

**Details**:
- Built targeting Android API 26 (Android 8.0)
- Original library targeted API 26
- Some EGL extensions (EGL_ANDROID_presentation_time) may not be available on all devices
- `eglQuerySurface` used for frame dimensions

## 5. Shader Limitations

**Status**: SIMPLE TEMPORAL BLEND

**Details**:
- Only implements basic temporal blending
- No motion compensation
- No depth-aware blending
- No occlusion handling
- No transparency handling

## 6. Camera Smoothing Integration

**Status**: HOOK-BASED, NOT INTEGRATED WITH GAME ENGINE

**Details**:
- Uses `pl::memory::hook` to intercept camera functions
- The actual hook targets (`processTurnDelta`, `getFov`, etc.) are resolved at runtime via signatures
- Signature resolution is fragile and may break on game updates
- Smoothing is applied to input deltas, not camera state directly

## 7. Frame Pacing Precision

**Status**: NANOSLEEP + BUSY WAIT

**Details**:
- Uses `nanosleep` + busy wait for frame pacing
- Not synchronized with display refresh (no `EGL_ANDROID_presentation_time` implementation)
- Can have 1-2ms jitter depending on scheduler
- No VSync integration (uses manual pacing)

## 8. Memory Management

**Status**: BASIC

**Details**:
- Frame buffers allocated at initialization, not dynamically
- Fixed ring buffer of 4 frames
- No dynamic GPU memory budget enforcement
- `gpu_memory_budget_mb` config is advisory only

## 9. Levi Launcher Version Dependency

**Status**: TIED TO 1.5.26 ABI

**Details**:
- ABI validated against Levi Launcher 1.5.26 (`libpreloader.so`)
- May break on future launcher versions
- `pl::memory::hook` signature resolution is version-dependent
- No version negotiation mechanism

## 10. Testing Coverage

**Status**: BUILD ONLY, NO DEVICE TESTING

**Details**:
- Library compiles and exports correct symbols
- No on-device testing performed
- EGL hook behavior untested on real hardware
- Camera hook signatures unverified on live game
- HUD overlay rendering untested
- Frame interpolation visual quality untested

## 11. NDK Version Sensitivity

**Status**: BUILT WITH NDK r30, ORIGINAL r26b

**Details**:
- Reimplementation built with NDK r30 (Termux default)
- Original used NDK r26b
- May have subtle ABI differences
- `ANDROID_SO_UNDEFINED ON` may mask issues

## 12. OpenGL ES Version

**Status**: GLESv2/v3 REQUIRED

**Details**:
- Uses GLESv3 features (VAO, `glBlitFramebuffer`, etc.)
- May not work on older devices without GLESv3 support
- Mock headers used for compilation (no real EGL/GLES headers in Termux)