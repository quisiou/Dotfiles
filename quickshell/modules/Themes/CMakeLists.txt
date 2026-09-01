# quickshell/modules/Themes/CMakeLists.txt


qt_add_library(elysianshell-themes SHARED)

set_source_files_properties(ActiveTheme.qml
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(elysianshell-themes
    URI ElysianShell.Themes
    VERSION 1.0
    QML_FILES
        ActiveTheme.qml
)

target_link_libraries(elysianshell-themes PRIVATE
    Qt6::Core
    Qt6::Quick
)
