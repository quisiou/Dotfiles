# quickshell/shell/CMakeLists.txt


# QML modules
cmake_minimum_required(VERSION 3.20)
project(ElysianShell)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

find_package(Qt6 REQUIRED COMPONENTS Core Quick DBus ShaderTools)

add_subdirectory(modules/Services)
add_subdirectory(modules/Themes)


# C daemons
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

file(GLOB C_HELPER_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.c")

foreach(src_file ${C_HELPER_SOURCES})
    get_filename_component(bin_name ${src_file} NAME_WE)
    add_executable(${bin_name} ${src_file})
    target_compile_options(${bin_name} PRIVATE -Wall -Wextra -O2 -march=native)
    target_link_options(${bin_name} PRIVATE -s)
endforeach()

# GPU info helper needs libdl for dlopen/dlsym
if(TARGET get_gpu_info)
    target_link_libraries(get_gpu_info PRIVATE dl)
endif()

# Symlink to shell
set(SHELL_BIN_LINK "${CMAKE_SOURCE_DIR}/shell/bin")
if(NOT IS_SYMLINK "${SHELL_BIN_LINK}")
    file(RELATIVE_PATH SHELL_BIN_RELPATH
        "${CMAKE_SOURCE_DIR}/shell"
        "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
    )
    file(CREATE_LINK "${SHELL_BIN_RELPATH}" "${SHELL_BIN_LINK}" SYMBOLIC)
endif()
