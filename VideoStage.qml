import QtQuick
import QtMultimedia

Item {
    id: root

    property string source: ""
    property bool muted: false
    property real volume: 0.9
    property real rate: 1.0
    property bool loop: false
    property real bottomInset: 78
    property bool ended: false
    property string errorText: ""

    readonly property bool playing: video.playbackState === MediaPlayer.PlayingState
    readonly property int position: video.position
    readonly property int duration: video.duration
    readonly property bool seekable: video.seekable
    readonly property bool loading: root.source !== "" && !video.hasVideo && root.errorText === ""

    signal requestFullscreen

    clip: true

    onSourceChanged: {
        root.ended = false;
        root.errorText = "";
    }

    function play() {
        if (root.ended) {
            video.position = 0;
            root.ended = false;
        }
        video.play();
    }

    function pause() {
        video.pause();
    }

    function togglePlay() {
        if (root.playing)
            root.pause();
        else
            root.play();
    }

    function seek(ms) {
        if (!video.seekable)
            return;
        video.position = Math.max(0, Math.min(root.duration, Math.round(ms)));
        if (root.ended && video.position < root.duration - 200)
            root.ended = false;
    }

    function skip(ms) {
        root.seek(root.position + ms);
    }

    function toggleMute() {
        root.muted = !root.muted;
    }

    function cycleRate() {
        const rates = [0.5, 1.0, 1.5, 2.0];
        let index = rates.indexOf(root.rate);
        if (index < 0)
            index = 1;
        root.rate = rates[(index + 1) % rates.length];
    }

    Video {
        id: video

        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 22
        anchors.bottomMargin: root.bottomInset
        source: root.source
        fillMode: VideoOutput.PreserveAspectFit
        endOfStreamPolicy: VideoOutput.KeepLastFrame
        autoPlay: true
        volume: root.volume
        muted: root.muted
        playbackRate: root.rate
        loops: root.loop ? MediaPlayer.Infinite : 1

        onPositionChanged: {
            if (root.duration > 0 && position >= root.duration - 120 && playbackState !== MediaPlayer.PlayingState)
                root.ended = true;
        }
        onErrorOccurred: (error, errorString) => {
            root.errorText = errorString || Strings.unableToOpen;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: root.requestFullscreen()
    }

    Item {
        id: spinner

        anchors.centerIn: parent
        width: 32
        height: 32
        visible: root.loading

        Icon {
            anchors.fill: parent
            name: "replay"
            color: Theme.textSecondary
            strokeWidth: 1.5
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: spinner.visible
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 68
        height: 68
        radius: 34
        visible: !root.playing && !root.ended && !root.loading && root.errorText === ""
        color: Qt.rgba(0, 0, 0, 0.46)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.24)

        Icon {
            anchors.centerIn: parent
            width: 26
            height: 26
            name: "play"
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.play()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 74
        height: 74
        radius: 37
        visible: root.ended
        color: Qt.rgba(0, 0, 0, 0.5)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.24)

        Icon {
            anchors.centerIn: parent
            width: 30
            height: 30
            name: "replay"
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.play()
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 380)
        spacing: 10
        visible: root.errorText !== ""

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36
            height: 36
            name: "video"
            color: Theme.textTertiary
            strokeWidth: 1.4
        }

        Text {
            width: parent.width
            text: Strings.unableToOpen
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: root.errorText
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
