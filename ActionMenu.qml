import QtQuick

Item {
    id: root

    property var items: []
    property bool opened: false
    property string title: ""
    signal activated(string action)

    readonly property int rowHeight: 31
    readonly property int menuWidth: 236
    readonly property int contentHeight: {
        let total = 0;
        for (let i = 0; i < items.length; ++i)
            total += items[i] && items[i].type === "separator" ? 9 : rowHeight;
        return total;
    }

    width: menuWidth
    height: contentHeight + 10 + (title !== "" ? 22 : 0)
    visible: opened
    opacity: opened ? 1 : 0
    scale: opened ? 1 : 0.97

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder
    }

    Column {
        anchors {
            fill: parent
            margins: 5
        }
        spacing: 0

        Item {
            width: parent.width
            height: root.title !== "" ? 22 : 0
            visible: root.title !== ""

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 7
                    verticalCenter: parent.verticalCenter
                }
                text: root.title
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Repeater {
            model: root.items

            delegate: Item {
                id: delegate

                required property var modelData

                width: parent.width
                height: delegate.modelData && delegate.modelData.type === "separator" ? 9 : root.rowHeight

                Rectangle {
                    visible: delegate.modelData && delegate.modelData.type === "separator"
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 7
                        rightMargin: 7
                    }
                    height: 1
                    color: Theme.separator
                }

                MenuRow {
                    anchors.fill: parent
                    visible: !delegate.modelData || delegate.modelData.type !== "separator"
                    icon: delegate.modelData ? (delegate.modelData.icon || "") : ""
                    label: delegate.modelData ? (delegate.modelData.label || "") : ""
                    shortcutText: delegate.modelData ? (delegate.modelData.shortcut || "") : ""
                    danger: delegate.modelData ? !!delegate.modelData.danger : false
                    enabled: delegate.modelData ? delegate.modelData.enabled !== false : true
                    onClicked: root.activated(delegate.modelData.action || "")
                }
            }
        }
    }
}
