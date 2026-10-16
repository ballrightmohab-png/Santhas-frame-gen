#!/bin/bash
# Manual build script that explicitly links libpreloader.so

set -e

SOURCE_DIR="/storage/emulated/0/Documents/Cerebelo/raw/framegen/source"
BUILD_DIR="/storage/emulated/0/Download/framegen/build"
DIST_DIR="/storage/emulated/0/Download/framegen/dist"
PRELOADER_PATH="/storage/emulated/0/Documents/Cerebelo/raw/framegen/backup/apk_extracted/lib/arm64-v8a/libpreloader.so"

echo "=== Manual FrameGen Build with Preloader ==="
echo "Source: $SOURCE_DIR"
echo "Build:  $BUILD_DIR"
echo "Dist:   $DIST_DIR"
echo "Preloader: $PRELOADER_PATH"
echo ""

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

cd "$BUILD_DIR"

# Compile all source files to object files
echo "Compiling source files..."

CLANGXX="/data/data/com.termux/files/usr/bin/clang++"
CXX_FLAGS="-fPIC -Wall -Wextra -Wno-unused-parameter -O3 -DNDEBUG -std=c++17"
INCLUDES="-I$SOURCE_DIR/include -I$SOURCE_DIR/mock_include"

SRC_FILES=(
    "$SOURCE_DIR/src/framegen/FrameGenMod.cpp"
    "$SOURCE_DIR/src/framegen/PluginRegistration.cpp"
    "$SOURCE_DIR/src/framegen/jni.cpp"
    "$SOURCE_DIR/src/framegen/Factory.cpp"
    "$SOURCE_DIR/src/framegen/config/ConfigManager.cpp"
    "$SOURCE_DIR/src/framegen/interpolation/GlFrameInterpolator.cpp"
    "$SOURCE_DIR/src/framegen/motion/CameraSmoother.cpp"
    "$SOURCE_DIR/src/framegen/pacing/FramePacer.cpp"
    "$SOURCE_DIR/src/framegen/hud/HudRenderer.cpp"
    "$SOURCE_DIR/src/framegen/launcher/LauncherIntegration.cpp"
)

OBJECT_FILES=()

for src in "${SRC_FILES[@]}"; do
    obj=$(basename "$src" .cpp).o
    echo "  Compiling $src..."
    $CLANGXX $CXX_FLAGS $INCLUDES -c "$src" -o "$obj"
    OBJECT_FILES+=("$obj")
done

echo ""
echo "Linking with preloader..."

# Link with explicit preloader library
$CLANGXX -fPIC -shared \
    -Wl,-soname,libframegen.so \
    -Wl,--no-undefined \
    "${OBJECT_FILES[@]}" \
    -llog -ldl -lEGL -lGLESv2 -lGLESv3 -lm -lc \
    /data/data/com.termux/files/usr/lib/libc++_shared.so \
    "$PRELOADER_PATH" \
    -o "$DIST_DIR/libframegen.so"

echo ""
echo "Checking output..."
if [ -f "$DIST_DIR/libframegen.so" ]; then
    echo "SUCCESS: libframegen.so built"
    ls -la "$DIST_DIR/libframegen.so"
    echo ""
    echo "Verifying symbols..."
    readelf -d "$DIST_DIR/libframegen.so" | grep -E "(NEEDED|SONAME)"
    echo ""
    nm -D "$DIST_DIR/libframegen.so" | grep -E "(PLMod_|PLGetModRegistration|JNI_OnLoad|Java_)"
else
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "=== Build Complete ==="
