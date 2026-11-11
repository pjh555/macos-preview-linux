import QtQuick

Item {
    id: root

    property string source: ""
    property string kind: "image"
    property real radius: 7
    property bool selected: false

    implicitWidth: 46
    implicitHeight: 46

    RoundedClip {
        anchors.fill: parent
        radius: root.radius
        color: Theme.thumbBg
        border.width: 1
        border.color: root.selected ? Theme.alpha(Theme.accent, 0.75) : Theme.separator

        Image {
            id: image

            anchors.fill: parent
            source: root.kind === "video" ? "" : root.source
            sourceSize: Qt.size(Math.max(1, root.width * 2), Math.max(1, root.height * 2))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            visible: status === Image.Ready
        }

        Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.42
            height: width
            name: root.kind === "video" ? "video" : "image"
            color: Theme.textSecondary
            visible: root.kind === "video" || (root.kind !== "video" && image.status === Image.Error)
        }

        Rectangle {
            visible: root.kind === "video"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            width: 18
            height: 18
            radius: 9
            color: Qt.rgba(0, 0, 0, 0.55)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)

            Icon {
                anchors.centerIn: parent
                width: 9
                height: 9
                name: "play"
                color: "#ffffff"
            }
        }
    }
}
