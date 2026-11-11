import QtQuick

Item {
    id: root

    property real duration: 0
    property real startValue: 0
    property real endValue: 0
    property real positionValue: 0

    signal startMoved(real milliseconds)
    signal endMoved(real milliseconds)

    implicitHeight: 32

    readonly property real startX: root.duration > 0 ? root.width * Math.max(0, Math.min(1, root.startValue / root.duration)) : 0
    readonly property real endX: root.duration > 0 ? root.width * Math.max(0, Math.min(1, root.endValue / root.duration)) : root.width
    readonly property real positionX: root.duration > 0 ? root.width * Math.max(0, Math.min(1, root.positionValue / root.duration)) : 0

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: hover.hovered || dragArea.pressed ? 6 : 5
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
        x: root.startX
        width: Math.max(0, root.endX - root.startX)
        height: track.height
        radius: height / 2
        color: Theme.alpha(Theme.accent, 0.85)
    }

    Rectangle {
        anchors.verticalCenter: track.verticalCenter
        x: Math.max(0, Math.min(parent.width - 2, root.positionX))
        width: 2
        height: 18
        radius: 1
        color: "#ffffff"
        opacity: 0.85
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - 12, root.startX - 6))
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 22
        radius: 5
        color: "#ffffff"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.18)
    }

    Rectangle {
        x: Math.max(0, Math.min(parent.width - 12, root.endX - 6))
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 22
        radius: 5
        color: "#ffffff"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.18)
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent
        enabled: root.duration > 0
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        property string dragMode: "start"

        function timeAt(x) {
            return Math.max(0, Math.min(root.duration, x / Math.max(1, root.width) * root.duration));
        }

        function moveTo(x) {
            const time = timeAt(x);
            if (dragMode === "start")
                root.startMoved(Math.max(0, Math.min(time, root.endValue - 200)));
            else
                root.endMoved(Math.min(root.duration, Math.max(time, root.startValue + 200)));
        }

        onPressed: mouse => {
            dragMode = Math.abs(mouse.x - root.startX) <= Math.abs(mouse.x - root.endX) ? "start" : "end";
            moveTo(mouse.x);
        }
        onPositionChanged: mouse => {
            if (pressed)
                moveTo(mouse.x);
        }
    }
}
