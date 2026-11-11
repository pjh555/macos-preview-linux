import QtQuick

Item {
    id: root

    property bool opened: false
    property string filePath: ""
    property string fileUrl: ""
    property string previewSource: ""
    property var meta: ({})
    property int imageWidth: 0
    property int imageHeight: 0
    property real fileSize: 0
    property real fileModified: 0
    property int frameCount: 0
    signal closeRequested
    signal openWithRequested
    signal showInFolderRequested
    signal copyPathRequested

    width: 292
    opacity: opened ? 1 : 0
    visible: opened

    readonly property bool video: Strings.isVideo(root.filePath)
    readonly property int widthValue: root.meta.width || root.imageWidth || 0
    readonly property int heightValue: root.meta.height || root.imageHeight || 0
    readonly property real durationValue: root.meta.durationMs || 0
    readonly property real sizeValue: root.meta.size || root.fileSize || 0
    readonly property string codecValue: root.meta.codec || ""
    readonly property string kindValue: Strings.kindName(root.filePath) + " · " + Strings.kindDescription(root.filePath)
    readonly property string folderValue: {
        const path = String(root.filePath || "");
        const slash = path.lastIndexOf("/");
        return slash > 0 ? path.slice(0, slash) : path;
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder
    }

    Item {
        anchors {
            fill: parent
            margins: 14
        }

        Item {
            id: header

            width: parent.width
            height: 24

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.inspectorTitle
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            ToolbarButton {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                width: 26
                height: 26
                icon: "close"
                tip: Strings.close
                onClicked: root.closeRequested()
            }
        }

        Flickable {
            id: flick

            anchors {
                top: header.bottom
                topMargin: 5
                left: parent.left
                right: parent.right
                bottom: buttons.top
                bottomMargin: 12
            }
            contentWidth: width
            contentHeight: content.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content

                width: flick.width
                spacing: 11

                RoundedClip {
                    width: parent.width
                    height: 148
                    radius: 9
                    color: Theme.thumbBg
                    border.width: 1
                    border.color: Theme.separator

                    Image {
                        id: preview

                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.previewSource !== "" ? root.previewSource : (root.video ? "" : root.fileUrl)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Icon {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        name: root.video ? "video" : "image"
                        color: Theme.textSecondary
                        visible: preview.status === Image.Error || (root.video && root.previewSource === "")
                    }

                    Rectangle {
                        visible: root.video
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: 8
                        }
                        width: 26
                        height: 26
                        radius: 13
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)

                        Icon {
                            anchors.centerIn: parent
                            width: 11
                            height: 11
                            name: "play"
                            color: "#ffffff"
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: Strings.fileName(root.filePath)
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideMiddle
                    }

                    Text {
                        width: parent.width
                        text: root.kindValue
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.separator
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoKind
                    value: root.kindValue
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoSize
                    value: Strings.formatBytes(root.sizeValue)
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoDimensions
                    value: root.widthValue > 0 ? root.widthValue + " × " + root.heightValue : "—"
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoDuration
                    value: root.video ? Strings.formatDuration(root.durationValue) : "—"
                    visible: root.video
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoCodec
                    value: root.codecValue
                    visible: root.video && root.codecValue !== ""
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoFrames
                    value: String(root.frameCount)
                    visible: root.frameCount > 0
                }

                InfoRow {
                    width: parent.width
                    label: Strings.infoModified
                    value: Strings.formatDate(root.fileModified)
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.separator
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        text: Strings.infoLocation
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        width: parent.width
                        text: root.folderValue || "—"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        Row {
            id: buttons

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            spacing: 6

            PillButton {
                icon: "external"
                label: Strings.zh ? "打开" : "Open"
                onClicked: root.openWithRequested()
            }

            PillButton {
                icon: "folder"
                label: Strings.zh ? "显示" : "Show"
                onClicked: root.showInFolderRequested()
            }

            PillButton {
                icon: "copy"
                label: Strings.zh ? "复制" : "Copy"
                onClicked: root.copyPathRequested()
            }
        }
    }
}
