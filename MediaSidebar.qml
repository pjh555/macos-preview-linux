import QtQuick

Item {
    id: root

    property var model: null
    property int currentIndex: -1
    property string folderName: ""
    property string folderPath: ""
    signal itemActivated(int index)

    function pathToUrl(path) {
        return "file://" + encodeURI(String(path || "")).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.sidebarBg

        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Theme.separator
        }
    }

    Item {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 54

        Row {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                name: "folder"
                color: Theme.textSecondary
            }

            Column {
                width: parent.width - 23
                spacing: 1

                Text {
                    width: parent.width
                    text: root.folderName || (Strings.zh ? "资料库" : "Library")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideMiddle
                }

                Text {
                    width: parent.width
                    text: (root.model ? root.model.count : 0) + (Strings.zh ? " 个项目" : " items")
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }

    Rectangle {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
        }
        height: 1
        color: Theme.separator
        opacity: 0.55
    }

    ListView {
        id: list

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 7
            bottomMargin: 10
            leftMargin: 7
            rightMargin: 7
        }
        model: root.model
        spacing: 1
        clip: true
        currentIndex: root.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 400

        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Item {
            id: delegate

            width: ListView.view.width
            height: 56

            readonly property string filePath: root.model ? String(root.model.get(index, "filePath") || "") : ""
            readonly property string fileName: root.model ? String(root.model.get(index, "fileName") || "") : ""
            readonly property var fileSize: root.model ? root.model.get(index, "fileSize") : 0
            readonly property url fileURL: filePath !== "" ? root.pathToUrl(filePath) : ""
            readonly property bool isVideo: Strings.isVideo(filePath)
            readonly property bool selected: index === root.currentIndex

            HoverHandler {
                id: hover
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                radius: 8
                color: delegate.selected ? Theme.selection : hover.hovered ? Theme.hover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            Rectangle {
                visible: delegate.selected
                anchors {
                    left: parent.left
                    leftMargin: 2
                    verticalCenter: parent.verticalCenter
                }
                width: 3
                height: 26
                radius: 1.5
                color: Theme.accent
            }

            Row {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 10

                Thumbnail {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42
                    height: 42
                    source: delegate.fileURL
                    kind: delegate.isVideo ? "video" : "image"
                    selected: delegate.selected
                }

                Column {
                    width: parent.width - 52
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: delegate.fileName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                    }

                    Text {
                        width: parent.width
                        text: Strings.kindName(delegate.filePath) + (delegate.fileSize > 0 ? " · " + Strings.formatBytes(delegate.fileSize) : "")
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.itemActivated(index)
            }
        }
    }

    Rectangle {
        id: scrollBar

        visible: list.contentHeight > list.height
        width: 4
        radius: 2
        color: Theme.alpha(Theme.textPrimary, 0.18)
        height: Math.max(28, list.height * list.height / Math.max(1, list.contentHeight))
        x: list.x + list.width - 5
        y: list.y + (list.height - height) * Math.max(0, Math.min(1, list.contentY / Math.max(1, list.contentHeight - list.height)))
    }

    Text {
        visible: root.model && root.model.count === 0 && root.folderPath !== ""
        anchors.centerIn: parent
        width: parent.width - 32
        text: Strings.emptyFolder
        color: Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
