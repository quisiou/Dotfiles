# quickshell/modules/Services/Volume/CMakeLists.txt


set_source_files_properties(VolumeService.qml
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

qt_target_qml_sources(elysianshell-services
    QML_FILES
        VolumeService.qml
)
