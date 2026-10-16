cmake_minimum_required(VERSION 3.10)
project(LeviFrameGen LANGUAGES CXX)

# Set the output library name
set(TARGET_NAME framegen)

# C++ Standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/mock_include)

# Android-specific settings
if(ANDROID)
    set(CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION clang)
    set(CMAKE_SYSTEM_NAME Android)
    set(CMAKE_SYSTEM_VERSION 26)
    set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
    set(CMAKE_ANDROID_STL_TYPE c++_shared)
endif()

# Compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wall -Wextra -Wno-unused-parameter")

# Source files
set(SRC_FILES
    # Core
    src/framegen/FrameGenMod.cpp
    src/framegen/PluginRegistration.cpp
    src/framegen/jni.cpp
    src/framegen/Factory.cpp
    
    # Config
    src/framegen/config/ConfigManager.cpp
    
    # Interpolation
    src/framegen/interpolation/GlFrameInterpolator.cpp
    
    # Motion
    src/framegen/motion/CameraSmoother.cpp
    
    # Pacing
    src/framegen/pacing/FramePacer.cpp
    
    # HUD
    src/framegen/hud/HudRenderer.cpp
    
    # Launcher Integration
    src/framegen/launcher/LauncherIntegration.cpp
)

# Find required libraries
find_library(LOG_LIB log)
find_library(DL_LIB dl)
find_library(EGL_LIB EGL)
find_library(GLESv2_LIB GLESv2)
find_library(GLESv3_LIB GLESv3)
find_library(M_LIB m)
find_library(C_LIB c)
find_library(CXX_SHARED_LIB c++_shared)

# Fallback library names
if(NOT LOG_LIB)
    set(LOG_LIB log)
endif()
if(NOT DL_LIB)
    set(DL_LIB dl)
endif()
if(NOT EGL_LIB)
    set(EGL_LIB EGL)
endif()
if(NOT GLESv2_LIB)
    set(GLESv2_LIB GLESv2)
endif()
if(NOT GLESv3_LIB)
    set(GLESv3_LIB GLESv3)
endif()
if(NOT M_LIB)
    set(M_LIB m)
endif()
if(NOT C_LIB)
    set(C_LIB c)
endif()
if(NOT CXX_SHARED_LIB)
    set(CXX_SHARED_LIB c++_shared)
endif()

# Create shared library
add_library(${TARGET_NAME} SHARED ${SRC_FILES})

# CRITICAL: Create an imported target for preloader and link against it
# This is the most reliable way to force a library into NEEDED
set(PRELOADER_PATH "/storage/emulated/0/Documents/Cerebelo/raw/framegen/backup/apk_extracted/lib/arm64-v8a/libpreloader.so")
if(EXISTS "${PRELOADER_PATH}")
    # Create imported shared library target for preloader
    add_library(preloader SHARED IMPORTED)
    set_target_properties(preloader PROPERTIES
        IMPORTED_LOCATION "${PRELOADER_PATH}"
    )
    # Link against the imported target
    target_link_libraries(${TARGET_NAME}
        ${LOG_LIB}
        ${DL_LIB}
        ${EGL_LIB}
        ${GLESv2_LIB}
        ${GLESv3_LIB}
        ${M_LIB}
        ${C_LIB}
        ${CXX_SHARED_LIB}
        preloader
    )
    message(STATUS "Created imported target for preloader: ${PRELOADER_PATH}")
else()
    target_link_libraries(${TARGET_NAME}
        ${LOG_LIB}
        ${DL_LIB}
        ${EGL_LIB}
        ${GLESv2_LIB}
        ${GLESv3_LIB}
        ${M_LIB}
        ${C_LIB}
        ${CXX_SHARED_LIB}
    )
    message(WARNING "preloader library NOT found!")
endif()

# Set target properties
set_target_properties(${TARGET_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_NAME framegen
    ANDROID_SO_UNDEFINED ON
    POSITION_INDEPENDENT_CODE ON
    LINK_FLAGS "-Wl,-soname,libframegen.so -Wl,--no-undefined"
    SUFFIX ".so"
)

# Installation
install(TARGETS ${TARGET_NAME}
    LIBRARY DESTINATION lib
)

# Print configuration
message(STATUS "Building LeviFrameGen")
message(STATUS "  Target: ${TARGET_NAME}")
message(STATUS "  Sources: ${SRC_FILES}")
message(STATUS "  Preloader: ${PRELOADER_PATH}")
