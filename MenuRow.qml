import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string shortcutText: ""
    property bool danger: false
    property bool enabled: true
    signal clicked

    implicitHeight: 31
    implicitWidth: 220

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: hover.hovered && root.enabled ? Theme.hover : "transparent"
    }

    Icon {
        id: iconItem

        anchors {
            left: parent.left
            leftMargin: 11
            verticalCenter: parent.verticalCenter
        }
        width: 15
        height: 15
        name: root.icon
        color: !root.enabled ? Theme.textTertiary : root.danger ? Theme.danger : Theme.textPrimary
        visible: root.icon !== ""
    }

    Text {
        anchors {
            left: root.icon !== "" ? iconItem.right : parent.left
            leftMargin: root.icon !== "" ? 9 : 12
            right: shortcut.implicitWidth > 0 ? shortcut.left : parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        color: !root.enabled ? Theme.textTertiary : root.danger ? Theme.danger : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    Text {
        id: shortcut

        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: root.shortcutText
        color: Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
