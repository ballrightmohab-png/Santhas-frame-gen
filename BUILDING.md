# Building LeviFrameGen

## Prerequisites

- Android NDK r26b (recommended) or r28c
- CMake 3.10+
- Ninja or Make
- ARM64 (aarch64) target

## NDK Setup

```bash
# Download NDK r26b
wget https://dl.google.com/android/repository/android-ndk-r26b-linux.zip
unzip android-ndk-r26b-linux.zip
export ANDROID_NDK_HOME=/path/to/android-ndk-r26b
```

## Build

```bash
cd source
./build.sh
```

The script will:
1. Clean previous build
2. Configure CMake with Android toolchain
3. Compile with Clang for arm64-v8a
4. Link against system libraries (log, dl, EGL, GLESv2, GLESv3, m, c, c++_shared)
5. Output `dist/libframegen.so`

## Output

- `dist/libframegen.so` - Main library (ELF 64-bit ARM64)
- `dist/FrameGen.levipack` - Inner levipack for launcher
- `dist/JNG_frame_generator-levipack-arm64-v8a.bin` - Outer package

## Verify

```bash
# Check file type
file dist/libframegen.so

# Check symbols
nm -D dist/libframegen.so | grep -E "(PLMod_|JNI_OnLoad|Java_)"

# Check dependencies
readelf -d dist/libframegen.so | grep NEEDED
```

## Troubleshooting

### NDK not found
Set `ANDROID_NDK_HOME` or modify `build.sh` to point to your NDK.

### CMake version
Requires CMake 3.10+. Termux typically has recent versions.

### Missing libraries
Ensure NDK includes the required system libraries (liblog, libdl, libEGL, libGLESv2, libGLESv3, libm, libc, libc++_shared).