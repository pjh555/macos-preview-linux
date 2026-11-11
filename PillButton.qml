import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool enabled: true
    property bool accent: false
    signal clicked

    implicitWidth: Math.max(66, measure.implicitWidth + (root.icon !== "" ? 44 : 20))
    implicitHeight: 28

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: !root.enabled ? "transparent" : root.accent ? (hover.hovered ? Qt.lighter(Theme.accent, 1.10) : Theme.accent) : hover.hovered ? Theme.controlHover : Theme.controlBg
        border.width: 1
        border.color: root.accent ? "transparent" : Theme.separator
    }

    Icon {
        id: iconItem

        anchors {
            left: parent.left
            leftMargin: 9
            verticalCenter: parent.verticalCenter
        }
        width: 14
        height: 14
        name: root.icon
        color: root.enabled ? (root.accent ? "#ffffff" : Theme.textPrimary) : Theme.textTertiary
        visible: root.icon !== ""
    }

    Text {
        id: measure

        visible: false
        text: root.label
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    Text {
        id: textItem

        anchors {
            left: root.icon !== "" ? iconItem.right : parent.left
            leftMargin: root.icon !== "" ? 6 : 10
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        color: root.enabled ? (root.accent ? "#ffffff" : Theme.textPrimary) : Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
