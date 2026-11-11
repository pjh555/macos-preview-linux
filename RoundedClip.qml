import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.5
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        radius: root.radius
        color: "white"
        visible: false
        layer.enabled: true
    }
}
