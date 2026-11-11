import QtQuick

Item {
    id: root

    property string label: ""
    property string value: ""
    property bool wrap: false
    property bool mono: false

    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight) + 9
    width: 200

    Text {
        id: labelText

        anchors {
            left: parent.left
            top: parent.top
            topMargin: 4
        }
        width: 74
        text: root.label
        color: Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    Text {
        id: valueText

        anchors {
            left: labelText.right
            leftMargin: 8
            right: parent.right
            top: parent.top
            topMargin: 4
        }
        text: root.value || "—"
        color: Theme.textPrimary
        font.family: root.mono ? "Noto Sans Mono" : Theme.fontFamily
        font.pixelSize: 11
        horizontalAlignment: Text.AlignRight
        wrapMode: root.wrap ? Text.WordWrap : Text.NoWrap
        elide: root.wrap ? Text.ElideNone : Text.ElideMiddle
    }
}
