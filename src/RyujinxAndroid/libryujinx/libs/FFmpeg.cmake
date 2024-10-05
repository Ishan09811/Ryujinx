include(ExternalProject)

# Set the FFmpeg version and repository
set(FFMPEG_VERSION "7.1")
set(FFMPEG_GIT_REPOSITORY "https://git.ffmpeg.org/ffmpeg.git")

# Environment setup for Android NDK
set(ANDROID_TOOLCHAIN_PREFIX "${CMAKE_ANDROID_TOOLCHAIN_PREFIX}")
set(PROJECT_ENV "ANDROID_NDK_ROOT=${CMAKE_ANDROID_NDK}")

if (CMAKE_HOST_WIN32)
    # Handle Windows specific setup
    # Your Windows-specific code here...
elseif (CMAKE_HOST_UNIX)
    find_program(MAKE_COMMAND NAMES make REQUIRED)
    list(APPEND PROJECT_ENV "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")
else ()
    message(WARNING "Host system (${CMAKE_HOST_SYSTEM_NAME}) not supported. Treating as Unix.")
    find_program(MAKE_COMMAND NAMES make REQUIRED)
    list(APPEND PROJECT_ENV "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")
endif ()

ExternalProject_Add(
    ffmpeg
    GIT_REPOSITORY              ${FFMPEG_GIT_REPOSITORY}
    GIT_TAG                     n${FFMPEG_VERSION}
    LIST_SEPARATOR              "|"
    CONFIGURE_COMMAND           ${CMAKE_COMMAND} -E env ${PROJECT_ENV}
                                    ./configure
                                    --target-os=android
                                    --arch=${CMAKE_ANDROID_ARCH}
                                    --enable-shared
                                    --disable-static
                                    --prefix=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
                                    --disable-doc
                                    --disable-programs
                                    --enable-cross-compile
                                    --cross-prefix=${ANDROID_TOOLCHAIN_ROOT}/bin/${ANDROID_TOOLCHAIN_PREFIX}-
                                    --sysroot=${CMAKE_ANDROID_SYSROOT}
                                    --extra-cflags="-D__ANDROID_API__=${CMAKE_SYSTEM_VERSION}"
                                    --extra-ldflags="-L${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/lib"
    BUILD_COMMAND               ${CMAKE_COMMAND} -E env ${PROJECT_ENV} make
    INSTALL_COMMAND             ${CMAKE_COMMAND} -E env ${PROJECT_ENV} make install
)
