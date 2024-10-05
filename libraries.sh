#!/bin/bash

# Set the desired versions and paths
FFMPEG_VERSION="7.1"
OPENAL_VERSION="1.23.1"
ANDROID_NDK_PATH="${ANDROID_HOME}/ndk/25.1.8937393"
BUILD_DIR=$(pwd)/build
FINAL_DIR=$(pwd)/final

# Create necessary directories
mkdir -p "${BUILD_DIR}/ffmpeg"
mkdir -p "${BUILD_DIR}/openal"
mkdir -p "${FINAL_DIR}/arm64-v8a"

# Function to install FFmpeg
install_ffmpeg() {
    echo "Building FFmpeg..."

    # Clone FFmpeg
    git clone --depth 1 --branch n${FFMPEG_VERSION} https://git.ffmpeg.org/ffmpeg.git "${BUILD_DIR}/ffmpeg"

    # Navigate to the FFmpeg directory
    cd "${BUILD_DIR}/ffmpeg" || exit 1

    # Configure and build FFmpeg
    ./configure \
        --target-os=android \
        --arch=arm64-v8a \
        --enable-shared \
        --disable-static \
        --prefix="${FINAL_DIR}/arm64-v8a" \
        --disable-doc \
        --disable-programs \
        --enable-cross-compile \
        --cross-prefix="${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-" \
        --sysroot="${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

    make -j$(nproc)
    make install

    # Return to the initial directory
    cd - || exit 1
}

# Function to install OpenAL
install_openal() {
    echo "Building OpenAL..."

    # Clone OpenAL
    git clone --depth 1 --branch ${OPENAL_VERSION} https://github.com/kcat/openal-soft.git "${BUILD_DIR}/openal"

    # Navigate to the OpenAL directory
    cd "${BUILD_DIR}/openal" || exit 1

    # Create build directory and navigate to it
    mkdir -p build && cd build || exit 1

    # Configure and build OpenAL
    cmake .. \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
        -DCMAKE_ANDROID_NDK="${ANDROID_NDK_PATH}" \
        -DCMAKE_INSTALL_PREFIX="${FINAL_DIR}/arm64-v8a" \
        -G Ninja  # Use Ninja for building

    ninja
    ninja install

    # Return to the initial directory
    cd - || exit 1
}

# Run the installation functions
install_ffmpeg
install_openal

# Move built libraries to the target directory
echo "Moving built libraries to target directory..."
mkdir -p src/RyujinxAndroid/app/src/main/jniLibs/arm64-v8a/
cp "${FINAL_DIR}/arm64-v8a/lib/"*.so "src/RyujinxAndroid/app/src/main/jniLibs/arm64-v8a/"

echo "Build and installation completed!"
