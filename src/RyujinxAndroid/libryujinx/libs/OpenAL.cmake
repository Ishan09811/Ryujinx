include(ExternalProject)

# Set OpenAL repository and version
set(OPENAL_VERSION "1.23.1")
set(OPENAL_GIT_REPOSITORY "https://github.com/kcat/openal-soft.git")

# Environment setup for Android NDK
set(PROJECT_ENV "ANDROID_NDK_ROOT=${CMAKE_ANDROID_NDK}")

if (CMAKE_HOST_WIN32)
    # Handle Windows specific setup
    # Your Windows-specific code here...
elseif (CMAKE_HOST_UNIX)
    find_program(MAKE_COMMAND NAMES make REQUIRED)
    list(APPEND PROJECT_ENV "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")
else ()
    message(WARNING "Host system (${CMAKE_HOST_SYSTEM_NAME}) not supported. Treating as unix.")
    find_program(MAKE_COMMAND NAMES make REQUIRED)
    list(APPEND PROJECT_ENV "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")
endif ()

ExternalProject_Add(
    openal
    GIT_REPOSITORY              ${OPENAL_GIT_REPOSITORY}
    GIT_TAG                     ${OPENAL_VERSION}
    LIST_SEPARATOR              "|"
    CONFIGURE_COMMAND           ${CMAKE_COMMAND} -E env ${PROJECT_ENV}
                                    cmake -B${CMAKE_BINARY_DIR}/openal-build -H${SOURCE_DIR}
                                    -DCMAKE_SYSTEM_NAME=Android
                                    -DCMAKE_ANDROID_ARCH_ABI=${CMAKE_ANDROID_ARCH}
                                    -DCMAKE_ANDROID_NDK=${CMAKE_ANDROID_NDK}
                                    -DCMAKE_INSTALL_PREFIX=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
    BUILD_COMMAND               ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}/openal-build --target install
    INSTALL_COMMAND             ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}/openal-build --target install
)
