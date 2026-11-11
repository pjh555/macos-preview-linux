import QtQuick

Item {
    id: root

    property var model: null
    property int currentIndex: -1
    signal itemActivated(int index)
    signal closeRequested

    function pathToUrl(path) {
        return "file://" + encodeURI(String(path || "")).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.02, 0.03, 0.82)
    }

    Item {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 22
            leftMargin: 28
            rightMargin: 22
        }
        height: 34

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.indexSheet
            color: "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 2
                top: parent.bottom
            }
            text: (root.model ? root.model.count : 0) + (Strings.zh ? " 个项目" : " items")
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        ToolbarButton {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            icon: "close"
            tip: Strings.close
            tooltipBelow: true
            iconColor: "#ffffff"
            onClicked: root.closeRequested()
        }
    }

    GridView {
        id: grid

        anchors {
            top: header.bottom
            topMargin: 22
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 28
            rightMargin: 28
            bottomMargin: 28
        }
        model: root.model
        cellWidth: 170
        cellHeight: 146
        clip: true
        focus: true
        currentIndex: root.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 600

        onVisibleChanged: {
            if (visible)
                forceActiveFocus();
        }

        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: {
            if (currentIndex >= 0)
                root.itemActivated(currentIndex);
        }
        Keys.onEnterPressed: {
            if (currentIndex >= 0)
                root.itemActivated(currentIndex);
        }

        delegate: Item {
            id: cell

            width: grid.cellWidth
            height: grid.cellHeight

            readonly property string filePath: root.model ? String(root.model.get(index, "filePath") || "") : ""
            readonly property string fileName: root.model ? String(root.model.get(index, "fileName") || "") : ""
            readonly property url fileURL: filePath !== "" ? root.pathToUrl(filePath) : ""
            readonly property bool selected: index === root.currentIndex
            readonly property bool isVideo: Strings.isVideo(filePath)

            HoverHandler {
                id: cellHover
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 10
                color: cell.selected ? Qt.rgba(0.04, 0.52, 1.0, 0.22) : cellHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.width: cell.selected ? 1.5 : 0
                border.color: Theme.accent
            }

            Thumbnail {
                anchors {
                    top: parent.top
                    topMargin: 12
                    horizontalCenter: parent.horizontalCenter
                }
                width: grid.cellWidth - 38
                height: 94
                radius: 8
                source: cell.fileURL
                kind: cell.isVideo ? "video" : "image"
                selected: cell.selected
            }

            Text {
                anchors {
                    top: parent.top
                    topMargin: 110
                    left: parent.left
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 10
                }
                text: cell.fileName
                color: "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.itemActivated(index)
            }
        }
    }
}
