# quickshell/shell/modules/Services/Battery/CMakeLists.txt


set_source_files_properties(BatteryService.qml
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

qt_target_qml_sources(elysianshell-services
    QML_FILES
        BatteryService.qml
)
