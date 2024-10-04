include(FetchContent)

# Sets the minimum version of CMake required to build the native library.
cmake_minimum_required(VERSION 3.22.1)

# Declares and names the project.
project("ryujinxjni")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

# Fetch AdrenoTools library
FetchContent_Declare(
    adrenotools
    GIT_REPOSITORY https://github.com/bylaws/libadrenotools.git
    GIT_TAG        deec5f75ee1a8ccbe32c8780b1d17284fc87b0f1 # v1.0-14-gdeec5f7
)

FetchContent_MakeAvailable(adrenotools)

# Fetch FFmpeg libraries (libavcodec, libavutil, libswresample, libswscale)
FetchContent_Declare(
    ffmpeg
    GIT_REPOSITORY https://git.ffmpeg.org/ffmpeg.git
    GIT_TAG        n4.4 # You can change to another stable version if needed
)

FetchContent_MakeAvailable(ffmpeg)

# Fetch OpenAL library
FetchContent_Declare(
    openal
    GIT_REPOSITORY https://github.com/kcat/openal-soft.git
    GIT_TAG        master
)

FetchContent_MakeAvailable(openal)

# Creates and names a library, sets it as either STATIC or SHARED.
add_library(
    ryujinxjni
    SHARED
    vulkan_wrapper.cpp
    ryujinx.cpp
)

# Searches for a specified prebuilt library and stores the path as a variable.
find_library(log-lib log)

# Specifies libraries CMake should link to your target library.
target_link_libraries(
    ryujinxjni
    ${log-lib}
    -lvulkan
    -landroid
    adrenotools
    libavcodec
    libavutil
    libswresample
    libswscale
    libopenal
)

# Build external libraries if prebuilt files don't exist
set(JNI_PATH ../jniLibs/${CMAKE_ANDROID_ARCH_ABI})
cmake_path(ABSOLUTE_PATH JNI_PATH NORMALIZE)
cmake_path(APPEND JNI_PATH libcrypto.so OUTPUT_VARIABLE LIBCRYPTO_JNI_PATH)
cmake_path(APPEND JNI_PATH libssl.so OUTPUT_VARIABLE LIBSSL_JNI_PATH)
cmake_path(APPEND JNI_PATH libavcodec.so OUTPUT_VARIABLE LIBAVCODEC_JNI_PATH)
cmake_path(APPEND JNI_PATH libavutil.so OUTPUT_VARIABLE LIBAVUTIL_JNI_PATH)
cmake_path(APPEND JNI_PATH libswresample.so OUTPUT_VARIABLE LIBSWRESAMPLE_JNI_PATH)
cmake_path(APPEND JNI_PATH libswscale.so OUTPUT_VARIABLE LIBSWSCALE_JNI_PATH)
cmake_path(APPEND JNI_PATH libopenal.so OUTPUT_VARIABLE LIBOPENAL_JNI_PATH)

if (NOT (EXISTS ${LIBAVCODEC_JNI_PATH} AND EXISTS ${LIBAVUTIL_JNI_PATH} AND EXISTS ${LIBSWRESAMPLE_JNI_PATH} AND EXISTS ${LIBSWSCALE_JNI_PATH} AND EXISTS ${LIBOPENAL_JNI_PATH} AND EXISTS ${LIBCRYPTO_JNI_PATH} AND EXISTS ${LIBSSL_JNI_PATH}))
    message(STATUS "Building external libraries (FFmpeg and OpenAL)...")
    include(../../../../libryujinx/libs/OpenSSL.cmake)
    add_dependencies(ryujinxjni ffmpeg openal openssl)
endif()
