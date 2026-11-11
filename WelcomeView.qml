import QtQuick

Item {
    id: root

    signal openFileRequested
    signal openFolderRequested

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 420)
        spacing: 12

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 104
            height: 104
            source: "assets/icon.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        Item {
            width: parent.width
            height: 10
        }

        Text {
            width: parent.width
            text: Strings.welcomeTitle
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 28
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: Strings.welcomeBody
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Item {
            width: parent.width
            height: 10
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Item {
                id: openFileButton

                width: 138
                height: 36

                HoverHandler {
                    id: openFileHover
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: openFileHover.hovered ? Theme.accent : Qt.rgba(0.04, 0.52, 1.0, 0.92)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        name: "folder"
                        color: "#ffffff"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.openFile
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openFileRequested()
                }
            }

            Item {
                id: openFolderButton

                width: 148
                height: 36

                HoverHandler {
                    id: openFolderHover
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: openFolderHover.hovered ? Theme.controlHover : Theme.controlBg
                    border.width: 1
                    border.color: Theme.separator
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        name: "image"
                        color: Theme.textPrimary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.openFolder
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openFolderRequested()
                }
            }
        }

        Text {
            width: parent.width
            text: Strings.dropHint
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
