import QtQuick

Item {
    id: root

    property bool isVideo: false
    property bool isAnimated: false
    property bool animationPlaying: true
    property bool videoPlaying: false
    property bool videoSeekable: false
    property int videoPosition: 0
    property int videoDuration: 0
    property bool videoMuted: false
    property real videoRate: 1.0
    property bool videoLoop: false
    property string scaleLabel: "100%"
    property bool slideshow: false
    property bool previousEnabled: true
    property bool nextEnabled: true
    property bool compact: false
    property bool canCrop: false
    property bool canTrim: false

    signal previous
    signal next
    signal zoomOut
    signal zoomIn
    signal toggleZoom
    signal rotateLeft
    signal rotateRight
    signal toggleAnimation
    signal toggleSlideshow
    signal togglePlay
    signal seek(real position)
    signal skip(real delta)
    signal toggleMute
    signal cycleRate
    signal toggleLoop
    signal toggleGrid
    signal crop
    signal trim

    implicitHeight: 52

    Rectangle {
        id: capsule

        anchors.centerIn: parent
        width: row.implicitWidth + 12
        height: 42
        radius: 21
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder

        Row {
            id: row

            anchors.centerIn: parent
            spacing: 1

            ToolbarButton {
                visible: !root.compact
                icon: "chevron-left"
                tip: Strings.previous
                shortcutText: "←"
                enabled: root.previousEnabled
                onClicked: root.previous()
            }

            ToolbarButton {
                visible: !root.compact
                icon: "chevron-right"
                tip: Strings.next
                shortcutText: "→"
                enabled: root.nextEnabled
                onClicked: root.next()
            }

            Item {
                visible: !root.compact
                width: 9
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 20
                    color: Theme.separator
                }
            }

            ToolbarButton {
                visible: !root.isVideo
                icon: "zoom-out"
                tip: Strings.zoomOut
                shortcutText: "−"
                onClicked: root.zoomOut()
            }

            ToolbarButton {
                visible: !root.isVideo
                label: root.scaleLabel
                tip: Strings.fit
                onClicked: root.toggleZoom()
            }

            ToolbarButton {
                visible: !root.isVideo
                icon: "zoom-in"
                tip: Strings.zoomIn
                shortcutText: "+"
                onClicked: root.zoomIn()
            }

            Item {
                visible: !root.isVideo
                width: 9
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 20
                    color: Theme.separator
                }
            }

            ToolbarButton {
                visible: !root.isVideo
                icon: "rotate-left"
                tip: Strings.rotateLeft
                shortcutText: "⇧R"
                onClicked: root.rotateLeft()
            }

            ToolbarButton {
                visible: !root.isVideo
                icon: "rotate-right"
                tip: Strings.rotateRight
                shortcutText: "R"
                onClicked: root.rotateRight()
            }

            ToolbarButton {
                visible: !root.isVideo && root.canCrop
                icon: "crop"
                tip: Strings.crop
                shortcutText: "C"
                onClicked: root.crop()
            }

            ToolbarButton {
                visible: !root.isVideo
                icon: root.isAnimated ? (root.animationPlaying ? "pause" : "play") : root.slideshow ? "stop" : "play"
                tip: root.isAnimated ? (root.animationPlaying ? Strings.pause : Strings.play) : root.slideshow ? Strings.stopSlideshow : Strings.slideshow
                shortcutText: "Space"
                active: root.slideshow
                onClicked: root.isAnimated ? root.toggleAnimation() : root.toggleSlideshow()
            }

            ToolbarButton {
                icon: "grid"
                tip: Strings.indexSheet
                shortcutText: "G"
                onClicked: root.toggleGrid()
            }

            Item {
                visible: root.isVideo && !root.compact
                width: 5
                height: 30
            }

            ToolbarButton {
                visible: root.isVideo
                icon: root.videoPlaying ? "pause" : root.videoPosition >= root.videoDuration && root.videoDuration > 0 ? "replay" : "play"
                tip: root.videoPlaying ? Strings.pause : Strings.play
                shortcutText: "Space"
                onClicked: root.togglePlay()
            }

            ToolbarButton {
                visible: root.isVideo
                icon: "rewind-10"
                tip: Strings.zh ? "后退 10 秒" : "Back 10 Seconds"
                onClicked: root.skip(-10000)
            }

            ToolbarButton {
                visible: root.isVideo
                icon: "forward-10"
                tip: Strings.zh ? "前进 10 秒" : "Forward 10 Seconds"
                onClicked: root.skip(10000)
            }

            Item {
                visible: root.isVideo
                width: root.compact ? 120 : 178
                height: 30

                VideoTimeline {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    position: root.videoPosition
                    duration: root.videoDuration
                    enabled: root.videoSeekable
                    onSeekRequested: position => root.seek(position)
                }
            }

            Item {
                visible: root.isVideo && !root.compact
                width: 76
                height: 30

                Text {
                    anchors.centerIn: parent
                    text: Strings.formatDuration(root.videoPosition) + " / " + Strings.formatDuration(root.videoDuration)
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            Item {
                visible: root.isVideo && !root.compact
                width: 9
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 20
                    color: Theme.separator
                }
            }

            ToolbarButton {
                visible: root.isVideo
                icon: root.videoMuted ? "mute" : "volume"
                tip: root.videoMuted ? Strings.unmute : Strings.mute
                shortcutText: "M"
                onClicked: root.toggleMute()
            }

            ToolbarButton {
                visible: root.isVideo && !root.compact
                label: (root.videoRate === Math.round(root.videoRate) ? root.videoRate.toFixed(0) : root.videoRate.toFixed(1)) + "×"
                tip: Strings.speed
                onClicked: root.cycleRate()
            }

            ToolbarButton {
                visible: root.isVideo && !root.compact
                icon: "loop"
                tip: Strings.loop
                active: root.videoLoop
                onClicked: root.toggleLoop()
            }

            ToolbarButton {
                visible: root.isVideo && root.canTrim
                icon: "trim"
                tip: Strings.trim
                shortcutText: "T"
                onClicked: root.trim()
            }
        }
    }
}
