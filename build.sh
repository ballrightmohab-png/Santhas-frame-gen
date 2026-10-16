#!/bin/bash
# Build script for FrameGen core module

set -e

BUILD_DIR="/storage/emulated/0/Download/framegen/build"
DIST_DIR="/storage/emulated/0/Download/framegen/dist"
SOURCE_DIR="/storage/emulated/0/Download/framegen/source"

echo "=== FrameGen Core Build Script ==="
echo "Source: $SOURCE_DIR"
echo "Build:  $BUILD_DIR"
echo "Dist:   $DIST_DIR"
echo ""

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning previous build..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

cd "$BUILD_DIR"

echo "Running CMake..."
cmake "$SOURCE_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=/data/data/com.termux/files/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/data/data/com.termux/files/usr/bin/clang++ \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=26 \
    -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
    -DCMAKE_ANDROID_STL_TYPE=c++_shared \
    -DCMAKE_ANDROID_NDK=/data/data/com.termux/files/usr \
    2>&1 | tee cmake.log

echo ""
echo "Building with make..."
make -j$(nproc) 2>&1 | tee make.log

echo ""
echo "Checking output..."
if [ -f "liblibframegen.so" ]; then
    echo "SUCCESS: liblibframegen.so built"
    ls -la liblibframegen.so
    
    echo ""
    echo "Copying to dist..."
    cp liblibframegen.so "$DIST_DIR/libframegen.so"
    
    echo ""
    echo "Verifying symbols..."
    if command -v nm &> /dev/null; then
        nm -D "$DIST_DIR/libframegen.so" | grep -E "(PLGetModRegistration|JNI_OnLoad|Java_)" | head -20
    elif command -v readelf &> /dev/null; then
        readelf -s "$DIST_DIR/libframegen.so" | grep -E "(PLGetModRegistration|JNI_OnLoad|Java_)" | head -20
    fi
    
    echo ""
    echo "File info:"
    file "$DIST_DIR/libframegen.so"
    
    echo ""
    echo "SHA-256:"
    sha256sum "$DIST_DIR/libframegen.so"
else
    echo "ERROR: Build failed - liblibframegen.so not found"
    exit 1
fi

echo ""
echo "=== Build Complete ==="