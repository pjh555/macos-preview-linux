import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string tip: ""
    property string shortcutText: ""
    property bool active: false
    property bool showTooltip: true
    property bool tooltipBelow: false
    property bool enabled: true
    property color iconColor: active ? Theme.accent : Theme.textPrimary
    signal clicked(var mouse)

    implicitWidth: label !== "" ? Math.max(42, labelText.implicitWidth + 18) : 30
    implicitHeight: 30

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (hovered) {
                if (root.showTooltip && root.tip !== "")
                    tipTimer.restart();
            } else {
                tipTimer.stop();
                tip.visible = false;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: !root.enabled ? "transparent" : root.active ? Theme.selection : hover.hovered ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }
    }

    Icon {
        id: iconItem

        anchors.centerIn: parent
        width: 17
        height: 17
        name: root.icon
        color: root.enabled ? root.iconColor : Theme.textTertiary
        visible: root.icon !== ""
    }

    Text {
        id: labelText

        anchors.centerIn: parent
        text: root.label
        color: root.enabled ? root.iconColor : Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        visible: root.label !== ""
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.clicked(mouse)
    }

    Timer {
        id: tipTimer

        interval: 420
        repeat: false
        onTriggered: tip.visible = true
    }

    Rectangle {
        id: tip

        z: 2000
        visible: false
        width: tipText.implicitWidth + 16
        height: 26
        radius: 6
        color: Theme.dark ? Qt.rgba(0.16, 0.16, 0.18, 0.97) : Qt.rgba(0.98, 0.98, 0.99, 0.98)
        border.width: 1
        border.color: Theme.glassBorder
        x: Math.round((root.width - width) / 2)
        y: root.tooltipBelow ? root.height + 7 : -height - 7

        Text {
            id: tipText

            anchors.centerIn: parent
            text: root.shortcutText !== "" ? root.tip + "   " + root.shortcutText : root.tip
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }
    }
}
