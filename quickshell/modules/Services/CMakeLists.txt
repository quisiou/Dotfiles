# quickshell/modules/Services/CMakeLists.txt


qt_add_library(elysianshell-services SHARED)

qt_add_qml_module(elysianshell-services
    URI ElysianShell.Services
    VERSION 1.0
)

add_subdirectory(Battery)
add_subdirectory(Bluetooth)
add_subdirectory(Brightness)
add_subdirectory(Lock)
add_subdirectory(Media)
add_subdirectory(Network)
add_subdirectory(Notification)
add_subdirectory(Volume)
add_subdirectory(Workspace)

target_link_libraries(elysianshell-services PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::DBus
)
