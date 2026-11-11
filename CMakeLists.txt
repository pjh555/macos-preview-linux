cmake_minimum_required(VERSION 3.21)
project(preview VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Network Svg)
qt_standard_project_setup()

qt_add_executable(preview
    src/main.cpp
    src/appcontroller.cpp
    src/appcontroller.h
    src/process.cpp
    src/process.h
)

set_source_files_properties(Theme.qml Strings.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(preview
    URI Preview
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        Main.qml
        FileBrowserDialog.qml
        PreviewWindow.qml
        ActionMenu.qml
        Icon.qml
        ImageStage.qml
        InfoInspector.qml
        InfoRow.qml
        MediaGridSheet.qml
        MediaSidebar.qml
        MediaToolbar.qml
        MenuRow.qml
        PillButton.qml
        Thumbnail.qml
        ToolbarButton.qml
        TrafficLight.qml
        VideoStage.qml
        VideoTimeline.qml
        WelcomeView.qml
        RoundedClip.qml
        TrimRange.qml
        TrimPanel.qml
        Theme.qml
        Strings.qml
)

qt_add_resources(preview "preview_assets"
    PREFIX "/qt/qml/Preview"
    FILES assets/icon.svg
)

target_link_libraries(preview PRIVATE
    Qt6::Quick
    Qt6::Network
    Qt6::Svg
)

target_compile_definitions(preview PRIVATE PREVIEW_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

install(TARGETS preview RUNTIME DESTINATION lib/preview)
install(PROGRAMS scripts/launch.sh DESTINATION bin RENAME preview)
install(PROGRAMS
    scripts/niri-focus-window.sh
    DESTINATION lib/preview/scripts
)
