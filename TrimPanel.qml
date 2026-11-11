import QtQuick

Item {
    id: root

    property int duration: 0
    property int startValue: 0
    property int endValue: 0
    property int positionValue: 0
    property bool busy: false

    signal startMoved(int milliseconds)
    signal endMoved(int milliseconds)
    signal preview
    signal trim
    signal cancel

    implicitHeight: 106

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder
    }

    Column {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 7

        Item {
            width: parent.width
            height: 18

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Strings.trimTitle
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            Text {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: Strings.formatDuration(root.startValue) + "  –  " + Strings.formatDuration(root.endValue)
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        TrimRange {
            width: parent.width
            height: 30
            duration: root.duration
            startValue: root.startValue
            endValue: root.endValue
            positionValue: root.positionValue
            onStartMoved: milliseconds => root.startMoved(Math.round(milliseconds))
            onEndMoved: milliseconds => root.endMoved(Math.round(milliseconds))
        }

        Item {
            width: parent.width
            height: 28

            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "play"
                label: Strings.trimPreview
                enabled: !root.busy
                onClicked: root.preview()
            }

            Row {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                PillButton {
                    icon: "close"
                    label: Strings.cropCancel
                    enabled: !root.busy
                    onClicked: root.cancel()
                }

                PillButton {
                    icon: "trim"
                    label: root.busy ? Strings.trimBusy : Strings.trimApply
                    accent: true
                    enabled: !root.busy && root.duration > 0 && root.endValue - root.startValue >= 200
                    onClicked: root.trim()
                }
            }
        }
    }
}
