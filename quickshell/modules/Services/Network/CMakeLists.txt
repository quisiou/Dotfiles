# quickshell/modules/Services/Network/CMakeLists.txt


target_sources(elysianshell-services PRIVATE
    NetworkService.hpp
    NetworkService.cpp
)

target_include_directories(elysianshell-services PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

