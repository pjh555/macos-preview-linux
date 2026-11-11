import QtQuick

Item {
    id: root

    property real position: 0
    property real duration: 0
    property bool enabled: true
    signal seekRequested(real position)

    implicitWidth: 190
    implicitHeight: 20

    readonly property real progress: root.duration > 0 ? Math.max(0, Math.min(1, root.position / root.duration)) : 0

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: hover.hovered || dragArea.pressed ? 5 : 4
        radius: height / 2
        color: Theme.track

        Behavior on height {
            NumberAnimation {
                duration: 100
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: track.verticalCenter
        width: Math.max(0, track.width * root.progress)
        height: track.height
        radius: height / 2
        color: Theme.accent
    }

    Rectangle {
        id: knob

        anchors.verticalCenter: track.verticalCenter
        x: Math.max(0, Math.min(root.width - width, track.width * root.progress - width / 2))
        width: hover.hovered || dragArea.pressed ? 13 : 10
        height: width
        radius: width / 2
        color: "#ffffff"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.18)
        visible: root.duration > 0
        opacity: hover.hovered || dragArea.pressed ? 1 : 0.85

        Behavior on width {
            NumberAnimation {
                duration: 100
            }
        }
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent
        enabled: root.enabled && root.duration > 0
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        function seekAt(x) {
            const ratio = Math.max(0, Math.min(1, x / Math.max(1, root.width)));
            root.seekRequested(ratio * root.duration);
        }

        onPressed: mouse => seekAt(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                seekAt(mouse.x);
        }
        onReleased: mouse => seekAt(mouse.x)
    }
}
