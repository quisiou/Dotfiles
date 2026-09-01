# quickshell/modules/Services/Workspace/CMakeLists.txt


set_source_files_properties(WorkspaceService.qml
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

qt_target_qml_sources(elysianshell-services
    QML_FILES
        WorkspaceService.qml
)
