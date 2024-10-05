include(FetchContent)

# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.
cmake_minimum_required(VERSION 3.22.1)

# Declares and names the project.
project("ryujinxjni")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

# Fetch the adrenotools library
FetchContent_Declare(
    adrenotools
    GIT_REPOSITORY https://github.com/bylaws/libadrenotools.git
    GIT_TAG        deec5f75ee1a8ccbe32c8780b1d17284fc87b0f1 # v1.0-14-gdeec5f7
)
FetchContent_MakeAvailable(adrenotools)

# Create the shared library
add_library( # Sets the name of the library.
            ryujinxjni

            # Sets the library as a shared library.
            SHARED

            # Provides a relative path to your source file(s).
            vulkan_wrapper.cpp
            ryujinx.cpp)

# Searches for the log library
find_library( # Sets the name of the path variable.
              log-lib
              log )

# Specifies libraries CMake should link to your target library.
target_link_libraries( # Specifies the target library.
                       ryujinxjni
                       # Links the target library to the log library
                       # included in the NDK.
                       ${log-lib}
                       -lvulkan
                       -landroid
                       adrenotools)

# Build external libraries if prebuilt files don't exist
set(JNI_PATH ../jniLibs/${CMAKE_ANDROID_ARCH_ABI})
cmake_path(ABSOLUTE_PATH JNI_PATH NORMALIZE)

cmake_path(APPEND JNI_PATH libcrypto.so OUTPUT_VARIABLE LIBCRYPTO_JNI_PATH)
cmake_path(APPEND JNI_PATH libssl.so OUTPUT_VARIABLE LIBSSL_JNI_PATH)

if (NOT (EXISTS ${LIBCRYPTO_JNI_PATH} AND EXISTS ${LIBSSL_JNI_PATH}))
    include(../../../../libryujinx/libs/OpenSSL.cmake)
    add_dependencies(ryujinxjni openssl)
endif()

message(STATUS "Configuring FFmpeg for Android arm64-v8a")

set(FFmpeg_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/externals/ffmpeg)
set(FFmpeg_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-build)
file(MAKE_DIRECTORY ${FFmpeg_BUILD_DIR})

# Define the FFmpeg source URL and commit
set(FFmpeg_GIT_REPOSITORY "https://git.ffmpeg.org/ffmpeg.git")
set(FFmpeg_GIT_TAG "n7.1") # or any specific tag you need

# Fetch FFmpeg
FetchContent_Declare(
    ffmpeg
    GIT_REPOSITORY ${FFmpeg_GIT_REPOSITORY}
    GIT_TAG ${FFmpeg_GIT_TAG}
)
FetchContent_MakeAvailable(ffmpeg)

# Set compiler flags
set(FFmpeg_CROSS_COMPILE_FLAGS
    --arch=arm64
    --enable-cross-compile
    --cross-prefix=${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-
    --sysroot=${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/sysroot
    --target-os=android
    --extra-ldflags="--ld-path=${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/ld.lld"
    --extra-ldflags="-nostdlib"
)

    # Custom command to configure FFmpeg
add_custom_command(
    OUTPUT ${FFmpeg_BUILD_DIR}/Makefile
    COMMAND ${CMAKE_COMMAND} -E echo "Configuring FFmpeg"
    COMMAND git clone ${FFmpeg_GIT_REPOSITORY} ${FFmpeg_BUILD_DIR}
    COMMAND cd ${FFmpeg_BUILD_DIR} && ./configure --disable-static --disable-avdevice --disable-avformat --disable-doc --disable-everything --enable-shared --enable-decoder=h264 --enable-decoder=vp8 --enable-decoder=vp9 --cc=${CMAKE_C_COMPILER} --cxx=${CMAKE_CXX_COMPILER} ${FFmpeg_CROSS_COMPILE_FLAGS}
    WORKING_DIRECTORY ${FFmpeg_BUILD_DIR}
)

# Add custom target for building FFmpeg
add_custom_target(ffmpeg ALL DEPENDS ${FFmpeg_BUILD_DIR}/Makefile)
add_custom_command(
    TARGET ffmpeg
    COMMAND make -C ${FFmpeg_BUILD_DIR}
    DEPENDS ${FFmpeg_BUILD_DIR}/Makefile
)

# Link FFmpeg libraries to your target
target_link_libraries(ryujinxjni
                      ${FFmpeg_BUILD_DIR}/libavcodec.so
                      ${FFmpeg_BUILD_DIR}/libavutil.so
                      ${FFmpeg_BUILD_DIR}/libswscale.so
                      ${FFmpeg_BUILD_DIR}/libswresample.so)
