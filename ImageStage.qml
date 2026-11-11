import QtQuick

Item {
    id: root

    property string source: ""
    property bool animated: false
    property int naturalWidth: 0
    property int naturalHeight: 0
    property real zoom: 1.0
    property int rotation: 0
    property real panX: 0
    property real panY: 0
    property real sideInset: 44
    property real bottomInset: 82
    property bool animationPlaying: true
    property string errorText: ""
    property string fallbackImageSource: ""
    property bool fallbackTried: false
    property string fallbackOriginalSource: ""
    property string fallbackOutput: ""
    property bool cropMode: false
    property real cropX: 0
    property real cropY: 0
    property real cropW: 0
    property real cropH: 0

    readonly property rect imageDisplayRect: Qt.rect(image.x, image.y, image.width, image.height)
    readonly property var cropPixels: {
        const rect = root.imageDisplayRect;
        const left = Math.max(rect.x, root.cropX);
        const top = Math.max(rect.y, root.cropY);
        const right = Math.min(rect.x + rect.width, root.cropX + root.cropW);
        const bottom = Math.min(rect.y + rect.height, root.cropY + root.cropH);
        const scale = rect.width > 0 ? root.naturalWidth / rect.width : 1;
        return {
            x: Math.max(0, Math.round((left - rect.x) * scale)),
            y: Math.max(0, Math.round((top - rect.y) * scale)),
            w: Math.max(0, Math.round((right - left) * scale)),
            h: Math.max(0, Math.round((bottom - top) * scale))
        };
    }
    readonly property int cropPixelWidth: root.cropPixels.w
    readonly property int cropPixelHeight: root.cropPixels.h

    signal cropRequested(int x, int y, int width, int height)

    readonly property int loadStatus: root.animated ? animatedImage.status : image.status
    readonly property int frameCount: root.animated ? animatedImage.frameCount : 0
    readonly property bool ready: loadStatus === Image.Ready
    readonly property bool loading: loadStatus === Image.Loading
    readonly property bool failed: loadStatus === Image.Error
    readonly property bool quarterTurn: Math.abs(root.rotation % 180) === 90
    readonly property real fitScale: {
        const contentW = root.quarterTurn ? root.naturalHeight : root.naturalWidth;
        const contentH = root.quarterTurn ? root.naturalWidth : root.naturalHeight;
        if (contentW <= 0 || contentH <= 0)
            return 1;
        const availableW = Math.max(1, root.width - root.sideInset * 2);
        const availableH = Math.max(1, root.height - root.sideInset - root.bottomInset);
        return Math.min(availableW / contentW, availableH / contentH);
    }
    readonly property real scaledWidth: root.naturalWidth * root.fitScale * root.zoom
    readonly property real scaledHeight: root.naturalHeight * root.fitScale * root.zoom
    readonly property real displayedWidth: root.quarterTurn ? root.scaledHeight : root.scaledWidth
    readonly property real displayedHeight: root.quarterTurn ? root.scaledWidth : root.scaledHeight
    readonly property real displayScale: root.fitScale * root.zoom
    readonly property bool canPan: root.displayedWidth > root.width - root.sideInset || root.displayedHeight > root.height - root.sideInset - root.bottomInset
    readonly property string scaleLabel: Strings.formatPercent(root.displayScale)

    signal imageLoaded(int width, int height)
    signal imageFailed(string message)

    clip: true

    onSourceChanged: {
        root.naturalWidth = 0;
        root.naturalHeight = 0;
        root.zoom = 1;
        root.rotation = 0;
        root.panX = 0;
        root.panY = 0;
        root.animationPlaying = true;
        root.errorText = "";
        root.fallbackImageSource = "";
        root.fallbackTried = false;
        root.fallbackOriginalSource = "";
        root.fallbackOutput = "";
        root.cropMode = false;
        if (fallbackProcess.running)
            fallbackProcess.running = false;
    }
    onWidthChanged: {
        root.scheduleClamp();
        if (root.cropMode)
            Qt.callLater(root.clampCropSelection);
    }
    onHeightChanged: {
        root.scheduleClamp();
        if (root.cropMode)
            Qt.callLater(root.clampCropSelection);
    }
    onCropModeChanged: {
        if (root.cropMode) {
            root.zoom = 1;
            root.rotation = 0;
            root.panX = 0;
            root.panY = 0;
            Qt.callLater(root.resetCropSelection);
        }
        surface.enabled = !root.cropMode;
        wheelHandler.enabled = !root.cropMode;
    }
    onZoomChanged: root.scheduleClamp()
    onRotationChanged: root.scheduleClamp()

    function scheduleClamp() {
        Qt.callLater(root.clampPan);
    }

    function clampPan() {
        const maxX = Math.max(0, (root.displayedWidth - root.width) / 2 + root.sideInset * 0.4);
        const maxY = Math.max(0, (root.displayedHeight - (root.height - root.bottomInset)) / 2 + root.sideInset * 0.4);
        root.panX = Math.max(-maxX, Math.min(maxX, root.panX));
        root.panY = Math.max(-maxY, Math.min(maxY, root.panY));
    }

    function zoomIn() {
        root.zoom = Math.min(40, root.zoom * 1.25);
    }

    function zoomOut() {
        root.zoom = Math.max(0.04, root.zoom / 1.25);
    }

    function fit() {
        root.zoom = 1;
        root.panX = 0;
        root.panY = 0;
    }

    function actualSize() {
        if (root.fitScale <= 0)
            return;
        root.zoom = Math.max(0.04, Math.min(40, 1 / root.fitScale));
        root.panX = 0;
        root.panY = 0;
        root.scheduleClamp();
    }

    function toggleZoom() {
        if (Math.abs(root.displayScale - 1) < 0.02) {
            root.fit();
        } else {
            root.actualSize();
        }
    }

    function rotateLeft() {
        root.rotation = (root.rotation + 270) % 360;
        root.panX = 0;
        root.panY = 0;
    }

    function rotateRight() {
        root.rotation = (root.rotation + 90) % 360;
        root.panX = 0;
        root.panY = 0;
    }

    function toggleAnimation() {
        root.animationPlaying = !root.animationPlaying;
    }

    function urlToPath(url) {
        let value = String(url || "");
        if (value.startsWith("file://")) {
            value = value.slice(7);
            try {
                value = decodeURIComponent(value);
            } catch (error) {}
        }
        return value;
    }

    function pathToUrl(path) {
        return "file://" + encodeURI(String(path || "")).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function hashPath(path) {
        let hash = 2166136261;
        const text = String(path || "");
        for (let i = 0; i < text.length; ++i) {
            hash ^= text.charCodeAt(i);
            hash = Math.imul(hash, 16777619);
        }
        return (hash >>> 0).toString(16);
    }

    // Qt's image plugins do not cover every format that ffmpeg understands
    // (WebP and AVIF are common examples). Decode one frame into the shell
    // cache and display that instead of giving up on the file.
    function tryFallback() {
        if (root.animated || root.source === "" || root.fallbackTried)
            return;
        root.fallbackTried = true;
        root.fallbackOriginalSource = root.source;
        const input = root.urlToPath(root.source);
        const output = app.cachePath("preview-image-" + root.hashPath(input) + ".png");
        root.fallbackOutput = output;
        fallbackProcess.command = ["ffmpeg", "-v", "error", "-i", input, "-frames:v", "1", "-y", output];
        fallbackProcess.running = true;
    }

    function resetCropSelection() {
        const rect = root.imageDisplayRect;
        if (rect.width < 2 || rect.height < 2)
            return;
        const margin = Math.max(4, Math.min(rect.width, rect.height) * 0.1);
        root.cropX = rect.x + margin;
        root.cropY = rect.y + margin;
        root.cropW = Math.max(16, rect.width - margin * 2);
        root.cropH = Math.max(16, rect.height - margin * 2);
    }

    function clampCropSelection() {
        const rect = root.imageDisplayRect;
        let left = Math.max(rect.x, Math.min(root.cropX, rect.x + rect.width - 16));
        let top = Math.max(rect.y, Math.min(root.cropY, rect.y + rect.height - 16));
        let right = Math.min(rect.x + rect.width, Math.max(left + 16, root.cropX + root.cropW));
        let bottom = Math.min(rect.y + rect.height, Math.max(top + 16, root.cropY + root.cropH));
        root.cropX = left;
        root.cropY = top;
        root.cropW = right - left;
        root.cropH = bottom - top;
    }

    function applyCrop() {
        const pixels = root.cropPixels;
        if (pixels.w < 1 || pixels.h < 1)
            return;
        root.cropRequested(pixels.x, pixels.y, pixels.w, pixels.h);
    }

    function handleLoaded(width, height) {
        const w = Math.round(width);
        const h = Math.round(height);
        if (w <= 0 || h <= 0)
            return;
        if (root.naturalWidth === w && root.naturalHeight === h)
            return;
        root.naturalWidth = w;
        root.naturalHeight = h;
        root.scheduleClamp();
        root.imageLoaded(w, h);
    }

    Item {
        id: viewport

        anchors.fill: parent
        clip: true

        Image {
            id: image

            visible: !root.animated
            source: root.animated ? "" : root.fallbackImageSource !== "" ? root.fallbackImageSource : root.source
            width: Math.max(1, root.scaledWidth)
            height: Math.max(1, root.scaledHeight)
            x: Math.round((viewport.width - width) / 2 + root.panX)
            y: Math.round((viewport.height - height) / 2 + root.panY)
            rotation: root.rotation
            transformOrigin: Item.Center
            asynchronous: true
            cache: true
            smooth: true
            mipmap: true
            opacity: root.ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            onStatusChanged: {
                if (status === Image.Ready) {
                    root.errorText = "";
                    root.handleLoaded(implicitWidth, implicitHeight);
                } else if (status === Image.Error) {
                    if (!root.animated && root.fallbackImageSource === "" && !root.fallbackTried) {
                        root.tryFallback();
                    } else {
                        root.errorText = image.errorString || Strings.unableToOpen;
                        root.imageFailed(root.errorText);
                    }
                }
            }
        }

        AnimatedImage {
            id: animatedImage

            visible: root.animated
            source: root.animated ? root.source : ""
            width: Math.max(1, root.scaledWidth)
            height: Math.max(1, root.scaledHeight)
            x: Math.round((viewport.width - width) / 2 + root.panX)
            y: Math.round((viewport.height - height) / 2 + root.panY)
            rotation: root.rotation
            transformOrigin: Item.Center
            asynchronous: true
            cache: false
            smooth: true
            playing: root.animationPlaying
            opacity: root.ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            onStatusChanged: {
                if (status === Image.Ready) {
                    root.handleLoaded(implicitWidth, implicitHeight);
                } else if (status === Image.Error) {
                    root.errorText = animatedImage.errorString || Strings.unableToOpen;
                    root.imageFailed(root.errorText);
                }
            }
        }

        Item {
            id: cropOverlay

            anchors.fill: parent
            visible: root.cropMode
            z: 30

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: Math.max(0, root.cropY)
                color: Qt.rgba(0, 0, 0, 0.62)
            }
            Rectangle {
                x: 0
                y: root.cropY + root.cropH
                width: parent.width
                height: Math.max(0, parent.height - (root.cropY + root.cropH))
                color: Qt.rgba(0, 0, 0, 0.62)
            }
            Rectangle {
                x: 0
                y: root.cropY
                width: Math.max(0, root.cropX)
                height: root.cropH
                color: Qt.rgba(0, 0, 0, 0.62)
            }
            Rectangle {
                x: root.cropX + root.cropW
                y: root.cropY
                width: Math.max(0, parent.width - (root.cropX + root.cropW))
                height: root.cropH
                color: Qt.rgba(0, 0, 0, 0.62)
            }

            Rectangle {
                x: root.cropX
                y: root.cropY
                width: root.cropW
                height: root.cropH
                color: "transparent"
                border.width: 1
                border.color: "#ffffff"
            }

            Rectangle {
                x: root.cropX + root.cropW / 3
                y: root.cropY
                width: 1
                height: root.cropH
                color: Qt.rgba(1, 1, 1, 0.35)
            }
            Rectangle {
                x: root.cropX + root.cropW * 2 / 3
                y: root.cropY
                width: 1
                height: root.cropH
                color: Qt.rgba(1, 1, 1, 0.35)
            }
            Rectangle {
                x: root.cropX
                y: root.cropY + root.cropH / 3
                width: root.cropW
                height: 1
                color: Qt.rgba(1, 1, 1, 0.35)
            }
            Rectangle {
                x: root.cropX
                y: root.cropY + root.cropH * 2 / 3
                width: root.cropW
                height: 1
                color: Qt.rgba(1, 1, 1, 0.35)
            }

            Repeater {
                model: [[0, 0], [1, 0], [0, 1], [1, 1]]

                Rectangle {
                    required property var modelData

                    x: root.cropX + modelData[0] * root.cropW - width / 2
                    y: root.cropY + modelData[1] * root.cropH - height / 2
                    width: 10
                    height: 10
                    radius: 2
                    color: "#ffffff"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.25)
                }
            }

            MouseArea {
                id: cropArea

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.CrossCursor
                property string dragMode: "new"
                property real pressX: 0
                property real pressY: 0
                property real startX: 0
                property real startY: 0
                property real startW: 0
                property real startH: 0

                function clampSelection() {
                    const r = root.imageDisplayRect;
                    const left = Math.max(r.x, Math.min(root.cropX, r.x + r.width - 1));
                    const top = Math.max(r.y, Math.min(root.cropY, r.y + r.height - 1));
                    const right = Math.min(r.x + r.width, Math.max(left + 1, root.cropX + root.cropW));
                    const bottom = Math.min(r.y + r.height, Math.max(top + 1, root.cropY + root.cropH));
                    root.cropX = left;
                    root.cropY = top;
                    root.cropW = right - left;
                    root.cropH = bottom - top;
                }

                onPressed: mouse => {
                    const near = 18;
                    const left = root.cropX;
                    const top = root.cropY;
                    const right = root.cropX + root.cropW;
                    const bottom = root.cropY + root.cropH;
                    const nearLeft = Math.abs(mouse.x - left) <= near;
                    const nearRight = Math.abs(mouse.x - right) <= near;
                    const nearTop = Math.abs(mouse.y - top) <= near;
                    const nearBottom = Math.abs(mouse.y - bottom) <= near;

                    if (nearLeft && nearTop)
                        dragMode = "nw";
                    else if (nearRight && nearTop)
                        dragMode = "ne";
                    else if (nearLeft && nearBottom)
                        dragMode = "sw";
                    else if (nearRight && nearBottom)
                        dragMode = "se";
                    else if (mouse.x > left && mouse.x < right && mouse.y > top && mouse.y < bottom)
                        dragMode = "move";
                    else
                        dragMode = "new";

                    pressX = mouse.x;
                    pressY = mouse.y;
                    startX = root.cropX;
                    startY = root.cropY;
                    startW = root.cropW;
                    startH = root.cropH;

                    if (dragMode === "new") {
                        root.cropX = mouse.x;
                        root.cropY = mouse.y;
                        root.cropW = 0;
                        root.cropH = 0;
                    }
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    if (dragMode === "new") {
                        root.cropX = Math.min(pressX, mouse.x);
                        root.cropY = Math.min(pressY, mouse.y);
                        root.cropW = Math.abs(mouse.x - pressX);
                        root.cropH = Math.abs(mouse.y - pressY);
                    } else if (dragMode === "move") {
                        root.cropX = startX + (mouse.x - pressX);
                        root.cropY = startY + (mouse.y - pressY);
                    } else {
                        let left = startX;
                        let top = startY;
                        let right = startX + startW;
                        let bottom = startY + startH;
                        if (dragMode.indexOf("w") >= 0)
                            left = mouse.x;
                        if (dragMode.indexOf("e") >= 0)
                            right = mouse.x;
                        if (dragMode.indexOf("n") >= 0)
                            top = mouse.y;
                        if (dragMode.indexOf("s") >= 0)
                            bottom = mouse.y;
                        root.cropX = Math.min(left, right);
                        root.cropY = Math.min(top, bottom);
                        root.cropW = Math.abs(right - left);
                        root.cropH = Math.abs(bottom - top);
                    }
                    clampSelection();
                }
                onReleased: {
                    if (root.cropW < 24 || root.cropH < 24)
                        root.resetCropSelection();
                }
            }
        }
    }

    Process {
        id: fallbackProcess

        onFinished: exitCode => {
            if (root.source !== root.fallbackOriginalSource)
                return;
            if (exitCode === 0) {
                root.errorText = "";
                root.fallbackImageSource = root.pathToUrl(root.fallbackOutput);
            } else {
                root.errorText = Strings.unableToOpen;
                root.imageFailed(root.errorText);
            }
        }
    }

    MouseArea {
        id: surface

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: root.canPan ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
        property real startX: 0
        property real startY: 0
        property real startPanX: 0
        property real startPanY: 0

        onPressed: mouse => {
            surface.startX = mouse.x;
            surface.startY = mouse.y;
            surface.startPanX = root.panX;
            surface.startPanY = root.panY;
        }
        onPositionChanged: mouse => {
            if (!pressed || !root.canPan)
                return;
            root.panX = surface.startPanX + (mouse.x - surface.startX);
            root.panY = surface.startPanY + (mouse.y - surface.startY);
            root.clampPan();
        }
        onDoubleClicked: root.toggleZoom()
    }

    WheelHandler {
        id: wheelHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y === 0)
                return;
            if (event.angleDelta.y > 0)
                root.zoomIn();
            else
                root.zoomOut();
            event.accepted = true;
        }
    }

    Shortcut {
        sequence: "Return"
        enabled: root.cropMode
        onActivated: root.applyCrop()
    }

    Rectangle {
        id: cropBar

        visible: root.cropMode
        z: 50
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 16
        }
        width: Math.min(340, parent.width - 16)
        height: 44
        radius: 22
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cropPixelWidth + " × " + root.cropPixelHeight
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            PillButton {
                icon: "close"
                label: Strings.cropCancel
                onClicked: root.cropMode = false
            }

            PillButton {
                icon: "crop"
                label: Strings.cropApply
                accent: true
                enabled: root.cropPixelWidth > 0 && root.cropPixelHeight > 0
                onClicked: root.applyCrop()
            }
        }
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

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 360)
        spacing: 10
        visible: root.failed

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 34
            name: "image"
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
