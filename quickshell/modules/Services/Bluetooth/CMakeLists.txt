# quickshell/modules/Services/Bluetooth/CMakeLists.txt


target_sources(elysianshell-services PRIVATE
    BluetoothService.hpp
    BluetoothService.cpp
)

target_include_directories(elysianshell-services PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

