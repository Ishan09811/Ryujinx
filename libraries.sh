#!/bin/bash

set -e

# Install required dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y cmake ninja-build git wget

# Variables
NDK_PATH=${ANDROID_HOME}/ndk/25.1.8937393
BUILD_DIR=$(pwd)/build
FFMPEG_DIR=${BUILD_DIR}/ffmpeg
OPENAL_DIR=${BUILD_DIR}/openal
TARGET_DIR=src/RyujinxAndroid/app/src/main/jniLibs/arm64-v8a

# Create build directory
mkdir -p ${BUILD_DIR}

# Build FFmpeg
echo "Building FFmpeg..."
git clone https://git.ffmpeg.org/ffmpeg.git ${FFMPEG_DIR}
cd ${FFMPEG_DIR}
git checkout b08d7969c550a804a59511c7b83f2dd8cc0499b8

# Configure FFmpeg
export PATH=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
./configure --target-os=android --arch=arm64 --cpu=arm64-v8a \
            --cross-prefix=aarch64-linux-android- --sysroot=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
            --enable-shared --disable-static --disable-doc \
            --enable-cross-compile

# Compile FFmpeg
make -j$(nproc)

# Move FFmpeg libraries to the target directory with the correct names
echo "Moving FFmpeg libraries..."
mkdir -p ${TARGET_DIR}
cp ${FFMPEG_DIR}/libavcodec/*.so ${TARGET_DIR}/libavcodec.so
cp ${FFMPEG_DIR}/libavutil/*.so ${TARGET_DIR}/libavutil.so
cp ${FFMPEG_DIR}/libswresample/*.so ${TARGET_DIR}/libswresample.so
cp ${FFMPEG_DIR}/libswscale/*.so ${TARGET_DIR}/libswscale.so

# Build OpenAL
echo "Building OpenAL..."
git clone https://github.com/kcat/openal-soft.git ${OPENAL_DIR}
cd ${OPENAL_DIR}
git checkout d3875f333fb6abe2f39d82caca329414871ae53b

# Configure OpenAL
cmake -G Ninja -DANDROID_ABI=arm64-v8a -DANDROID_NDK=${NDK_PATH} -DANDROID_PLATFORM=android-21 -B build
cmake --build build

# Move OpenAL library to the target directory with the correct name
echo "Moving OpenAL library..."
cp ${OPENAL_DIR}/build/libOpenAL.so ${TARGET_DIR}/libopenal.so

echo "Build and installation completed!"
