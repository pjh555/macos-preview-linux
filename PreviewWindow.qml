import QtQuick
import QtQuick.Window
import Qt.labs.folderlistmodel
import QtQuick.Effects

Window {
    id: root

    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    title: root.currentFile !== "" ? root.currentFileName + " — " + Strings.appName : Strings.appName
    width: 1180
    height: 780
    minimumWidth: 720
    minimumHeight: 560

    readonly property bool isFullscreen: root.visibility === Window.FullScreen
    readonly property bool isMaximized: root.visibility === Window.Maximized

    property string home: app.homeDir
    property string folderPath: ""
    property string currentFile: ""
    property int currentIndex: -1
    property string pendingPath: ""
    property bool pendingFirst: false
    property bool loadingFolder: false
    property bool sidebarOpen: true
    property bool infoOpen: false
    property bool gridOpen: false
    property bool shareMenuOpen: false
    property bool fileDialogOpen: false
    property bool moreMenuOpen: false
    property bool slideshow: false
    property bool dropActive: false
    property real contentOpacity: 0
    property string toastText: ""
    property var metadata: ({})
    property var metadataCache: ({})
    property real fileSize: 0
    property real fileModified: 0
    property int imageWidth: 0
    property int imageHeight: 0
    property int frameCount: 0
    property int probeSerial: 0
    property int probeRunningSerial: 0
    property string videoBackdrop: ""
    property string backdropSource: ""
    property string backdropOutput: ""
    property bool trimMode: false
    property int trimStart: 0
    property int trimEnd: 0
    property bool trimBusy: false
    property string trimOutput: ""

    readonly property bool isVideo: Strings.isVideo(currentFile)
    readonly property bool isGif: Strings.isGif(currentFile)
    readonly property bool hasMedia: currentFile !== ""
    readonly property int inspectorWidth: infoOpen ? 304 : 0
    readonly property string currentFileName: Strings.fileName(currentFile)
    readonly property string currentFileUrl: currentFile !== "" ? root.pathToUrl(currentFile) : ""
    readonly property var imageStage: imageLoader.item
    readonly property var videoStage: videoLoader.item
    readonly property string folderName: {
        const path = String(root.folderPath || "");
        const slash = path.lastIndexOf("/");
        return slash >= 0 ? path.slice(slash + 1) : path;
    }
    readonly property string subtitleText: {
        if (!root.hasMedia)
            return "";
        const kind = Strings.kindName(root.currentFile);
        const dimensions = root.effectiveWidth > 0 ? root.effectiveWidth + " × " + root.effectiveHeight : "";
        const count = folderModel.count > 0 ? (root.currentIndex + 1) + " / " + folderModel.count : "";
        return [kind, dimensions, count].filter(part => part !== "").join("  ·  ");
    }
    readonly property int effectiveWidth: root.metadata.width || root.imageWidth || 0
    readonly property int effectiveHeight: root.metadata.height || root.imageHeight || 0

    onClosing: Qt.quit()
    onCurrentFileChanged: {
        if (root.isVideo)
            root.slideshow = false;
        root.trimMode = false;
        root.trimBusy = false;
        if (root.imageStage)
            root.imageStage.cropMode = false;
        root.frameCount = 0;
        root.videoBackdrop = "";
        root.backdropSource = root.currentFile;
        Qt.callLater(function () {
            root.generateVideoBackdrop();
        });
    }
    Component.onCompleted: {
        Theme.dark = app.darkMode;
        Theme.fontFamily = app.systemFontFamily;
        Theme.systemAccent = app.accentColor;
        contentOpacity = 1;
        if (app.initialFiles && app.initialFiles.length > 0)
            root.openPaths(app.initialFiles);
    }

    Connections {
        target: app

        function onFilesReceived(paths) {
            if (paths && paths.length > 0)
                root.openPaths(paths);
            root.bringToFront();
        }

        function onDarkModeChanged() {
            Theme.dark = app.darkMode;
        }

        function onAccentColorChanged() {
            Theme.systemAccent = app.accentColor;
        }
    }

    Connections {
        target: root.videoStage

        function onDurationChanged() {
            if (root.trimMode && root.trimEnd <= 0)
                root.trimEnd = root.videoStage.duration;
        }
    }

    // -- Path and model helpers ------------------------------------------------

    function normalizePath(path) {
        let value = String(path || "");
        if (value.startsWith("file://"))
            value = root.urlToPath(value);
        if (value === "")
            return "";
        if (!value.startsWith("/"))
            value = (app.workingDir || root.home) + "/" + value;
        return value.replace(/\/+/g, "/");
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
        let value = String(path || "");
        if (value.startsWith("file://"))
            return value;
        return "file://" + encodeURI(value).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function splitPath(path) {
        const value = String(path || "");
        const slash = value.lastIndexOf("/");
        return {
            dir: slash > 0 ? value.slice(0, slash) : (slash === 0 ? "/" : ""),
            base: slash >= 0 ? value.slice(slash + 1) : value
        };
    }

    function indexForPath(path) {
        const wanted = root.normalizePath(path);
        for (let i = 0; i < folderModel.count; ++i) {
            if (String(folderModel.get(i, "filePath")) === wanted)
                return i;
        }
        return -1;
    }

    function openPaths(paths) {
        const list = [];
        for (let i = 0; i < paths.length; ++i) {
            const path = root.normalizePath(paths[i]);
            if (path !== "" && !list.includes(path))
                list.push(path);
        }
        if (list.length === 0)
            return;
        root.bringToFront();
        if (app.isDirectory(list[0]))
            root.openFolder(list[0]);
        else
            root.openFile(list[0]);
    }

    function openFile(path) {
        const normalized = root.normalizePath(path);
        if (normalized === "")
            return;
        if (normalized === root.currentFile) {
            root.bringToFront();
            return;
        }

        const parts = root.splitPath(normalized);
        root.currentFile = normalized;
        root.pendingPath = normalized;
        root.pendingFirst = false;
        root.loadingFolder = false;
        root.currentIndex = -1;
        root.metadata = root.metadataCache[normalized] || ({});
        root.imageWidth = 0;
        root.imageHeight = 0;
        root.fileSize = 0;
        root.fileModified = 0;
        root.probe(normalized);
        root.folderPath = parts.dir;

        root.resolvePendingSelection();
    }

    function openFolder(path) {
        const normalized = root.normalizePath(path);
        if (normalized === "")
            return;
        root.folderPath = normalized;
        root.pendingPath = "";
        root.pendingFirst = true;
        root.loadingFolder = true;
        root.currentFile = "";
        root.currentIndex = -1;
        root.metadata = ({});
        root.imageWidth = 0;
        root.imageHeight = 0;
        root.fileSize = 0;
        root.fileModified = 0;
        root.resolvePendingSelection();
    }

    function resolvePendingSelection() {
        if (folderModel.status !== FolderListModel.Ready && folderModel.count === 0)
            return;

        if (root.pendingPath !== "") {
            const index = root.indexForPath(root.pendingPath);
            if (index >= 0) {
                root.pendingPath = "";
                root.loadingFolder = false;
                root.selectIndex(index);
            }
            // Keep waiting while FolderListModel is still populating. Falling
            // back to index 0 here would silently jump away from the requested
            // file on folders with many large images.
        } else if (root.pendingFirst) {
            root.pendingFirst = false;
            root.loadingFolder = false;
            if (folderModel.count > 0)
                root.selectIndex(0);
            else
                root.currentFile = "";
        }
    }

    function selectIndex(index) {
        if (index < 0 || index >= folderModel.count)
            return;
        const path = String(folderModel.get(index, "filePath"));
        root.pendingPath = "";
        root.pendingFirst = false;
        root.loadingFolder = false;
        root.currentIndex = index;
        root.currentFile = path;
        root.metadata = root.metadataCache[path] || ({});
        root.imageWidth = 0;
        root.imageHeight = 0;
        root.frameCount = 0;
        root.fileSize = Number(folderModel.get(index, "fileSize")) || 0;
        const modified = folderModel.get(index, "fileModified");
        root.fileModified = modified instanceof Date ? modified.getTime() : Number(modified) || 0;
        root.probe(path);
    }

    function goPrevious() {
        if (root.currentIndex > 0)
            root.selectIndex(root.currentIndex - 1);
    }

    function goNext() {
        if (root.currentIndex >= 0 && root.currentIndex < folderModel.count - 1)
            root.selectIndex(root.currentIndex + 1);
    }

    function goTo(index) {
        root.selectIndex(index);
    }

    function bringToFront() {
        root.show();
        root.raise();
        root.requestActivate();
        if (root.visibility === Window.Minimized)
            root.showNormal();
        if (app.niriSocket !== "")
            niriFocus.running = true;
    }

    function toggleFullscreen() {
        root.visibility = root.isFullscreen ? Window.Windowed : Window.FullScreen;
    }

    function toggleMaximize() {
        root.visibility = root.isMaximized ? Window.Windowed : Window.Maximized;
    }

    function minimizeWindow() {
        root.showMinimized();
    }

    function cycleAppearance() {
        const order = ["system", "light", "dark"];
        const index = order.indexOf(app.appearanceMode);
        app.appearanceMode = order[(index + 1) % order.length];
    }

    // -- Metadata --------------------------------------------------------------

    function probe(path) {
        if (root.metadataCache[path]) {
            root.metadata = root.metadataCache[path];
            return;
        }
        const serial = ++root.probeSerial;
        root.probeRunningSerial = serial;
        probeProcess.command = ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height,codec_name,duration", "-show_entries", "format=duration,size", "-of", "json", path];
        probeProcess.running = true;
    }

    function applyProbe(path, text) {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (error) {
            return;
        }
        const stream = data && data.streams && data.streams.length > 0 ? data.streams[0] : ({});
        const format = data && data.format ? data.format : ({});
        const result = {
            width: Number(stream.width) || 0,
            height: Number(stream.height) || 0,
            codec: stream.codec_name || "",
            durationMs: Math.round(Number(format.duration || stream.duration || 0) * 1000),
            size: Number(format.size) || 0
        };
        const nextCache = Object.assign({}, root.metadataCache);
        nextCache[path] = result;
        root.metadataCache = nextCache;
        if (root.currentFile === path)
            root.metadata = result;
    }

    function updateImageSize(width, height) {
        root.imageWidth = Math.round(width);
        root.imageHeight = Math.round(height);
        if (root.currentFile !== "")
            root.frameCount = root.isGif && root.imageStage ? root.imageStage.frameCount : 0;
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

    function generateVideoBackdrop() {
        if (!root.isVideo || root.currentFile === "")
            return;
        const output = app.cachePath("preview-backdrop-" + root.hashPath(root.currentFile) + ".jpg");
        root.backdropOutput = output;
        backdropProcess.command = ["ffmpeg", "-v", "error", "-ss", "0.5", "-i", root.currentFile, "-frames:v", "1", "-vf", "scale=960:-2", "-y", output];
        backdropProcess.running = true;
    }

    // -- UI actions ------------------------------------------------------------

    function toggleSidebar() {
        sidebarOpen = !sidebarOpen;
    }

    function toggleInspector() {
        infoOpen = !infoOpen;
        if (infoOpen)
            gridOpen = false;
        closeMenus();
    }

    function toggleGrid() {
        gridOpen = !gridOpen;
        if (gridOpen)
            infoOpen = false;
        closeMenus();
    }

    function closeMenus() {
        shareMenuOpen = false;
        moreMenuOpen = false;
    }

    function toggleSlideshow() {
        if (!root.hasMedia || root.isVideo)
            return;
        root.slideshow = !root.slideshow;
        if (root.slideshow)
            root.infoOpen = false;
    }

    function toggleCrop() {
        if (!root.hasMedia || root.isVideo || root.isGif || !root.imageStage)
            return;
        root.imageStage.cropMode = !root.imageStage.cropMode;
        if (root.imageStage.cropMode) {
            root.slideshow = false;
            root.infoOpen = false;
            root.gridOpen = false;
            root.closeMenus();
        }
    }

    function applyCrop(x, y, width, height) {
        if (!root.hasMedia || !root.imageStage)
            return;
        const fallback = root.imageStage.fallbackImageSource;
        const result = app.cropImage(root.currentFile, x, y, width, height, fallback !== "" ? root.urlToPath(fallback) : "");
        root.imageStage.cropMode = false;
        if (result === "" || result.startsWith("ERROR:")) {
            root.toastText = Strings.cropFailed;
            toastTimer.restart();
            return;
        }
        root.toastText = Strings.cropSaved;
        toastTimer.restart();
        root.openPaths([result]);
    }

    function toggleTrim() {
        if (!root.isVideo || !root.videoStage)
            return;
        root.trimMode = !root.trimMode;
        if (root.trimMode) {
            root.trimStart = 0;
            root.trimEnd = root.videoStage.duration;
            root.slideshow = false;
            root.infoOpen = false;
            root.gridOpen = false;
            root.closeMenus();
        }
    }

    function startTrim() {
        if (!root.videoStage || root.trimBusy)
            return;
        const duration = root.videoStage.duration;
        const start = Math.max(0, Math.min(root.trimStart, duration));
        const end = Math.max(start + 200, Math.min(root.trimEnd, duration));
        if (duration <= 0 || end - start < 200) {
            root.toastText = Strings.trimFailed;
            toastTimer.restart();
            return;
        }
        root.trimOutput = app.uniqueOutputPath(root.currentFile, "trimmed");
        root.trimBusy = true;
        root.toastText = Strings.trimBusy;
        toastTimer.restart();
        trimProcess.command = ["ffmpeg", "-v", "error", "-ss", (start / 1000).toFixed(3), "-i", root.currentFile, "-t", ((end - start) / 1000).toFixed(3), "-map", "0:v:0?", "-map", "0:a?", "-c", "copy", "-avoid_negative_ts", "make_zero", "-y", root.trimOutput];
        trimProcess.running = true;
    }

    function cancelTrim() {
        root.trimMode = false;
    }

    function copyPath() {
        if (!root.hasMedia)
            return;
        app.copyText(root.currentFile);
        root.toastText = Strings.copied;
        toastTimer.restart();
    }

    function showInFolder() {
        if (!root.hasMedia)
            return;
        app.runDetached(["xdg-open", root.folderPath || root.splitPath(root.currentFile).dir]);
    }

    function openWithDefault() {
        if (!root.hasMedia)
            return;
        app.runDetached(["xdg-open", root.currentFile]);
    }

    function handleMenuAction(action) {
        root.closeMenus();
        if (action === "copy-path")
            root.copyPath();
        else if (action === "show-in-folder")
            root.showInFolder();
        else if (action === "open-with")
            root.openWithDefault();
        else if (action === "toggle-sidebar")
            root.toggleSidebar();
        else if (action === "toggle-inspector")
            root.toggleInspector();
        else if (action === "index-sheet")
            root.toggleGrid();
        else if (action === "slideshow")
            root.toggleSlideshow();
        else if (action === "appearance")
            root.cycleAppearance();
        else if (action === "fullscreen")
            root.toggleFullscreen();
        else if (action === "close")
            Qt.quit();
    }

    function handleEscape() {
        if (root.imageStage && root.imageStage.cropMode) {
            root.imageStage.cropMode = false;
        } else if (root.trimMode) {
            root.trimMode = false;
        } else if (root.shareMenuOpen || root.moreMenuOpen) {
            closeMenus();
        } else if (root.gridOpen) {
            root.gridOpen = false;
        } else if (root.infoOpen) {
            root.infoOpen = false;
        } else if (root.isFullscreen) {
            root.visibility = Window.Windowed;
        }
    }

    // -- Dialogs and processes -------------------------------------------------

    FolderListModel {
        id: folderModel

        folder: root.folderPath !== "" ? root.pathToUrl(root.folderPath) : ""
        showFiles: root.folderPath !== ""
        showDirs: false
        showHidden: false
        showDirsFirst: false
        sortField: FolderListModel.Name
        sortReversed: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.tif", "*.tiff", "*.svg", "*.avif", "*.heic", "*.heif", "*.mp4", "*.m4v", "*.webm", "*.mkv", "*.mov", "*.avi", "*.mpg", "*.mpeg", "*.ogv"]

        onCountChanged: root.resolvePendingSelection()
        onStatusChanged: root.resolvePendingSelection()
    }

    Process {
        id: probeProcess

        onFinished: exitCode => {
            if (root.probeRunningSerial !== root.probeSerial)
                return;
            if (exitCode === 0 && root.currentFile !== "")
                root.applyProbe(root.currentFile, probeProcess.output);
        }
    }

    Process {
        id: backdropProcess

        onFinished: exitCode => {
            if (exitCode === 0 && root.isVideo && root.backdropSource === root.currentFile)
                root.videoBackdrop = root.pathToUrl(root.backdropOutput);
        }
    }

    Process {
        id: trimProcess

        onFinished: exitCode => {
            root.trimBusy = false;
            if (exitCode === 0 && root.trimOutput !== "" && app.fileExists(root.trimOutput)) {
                const output = root.trimOutput;
                root.trimMode = false;
                root.toastText = Strings.trimSaved;
                toastTimer.restart();
                root.openPaths([output]);
            } else {
                root.toastText = Strings.trimFailed;
                toastTimer.restart();
            }
        }
    }

    Process {
        id: niriFocus

        command: ["sh", app.scriptPath("niri-focus-window.sh"), String(app.pid)]
    }

    Timer {
        id: slideshowTimer

        interval: 4000
        repeat: true
        running: root.slideshow && root.hasMedia && !root.isVideo
        onTriggered: {
            if (root.currentIndex >= folderModel.count - 1)
                root.selectIndex(0);
            else
                root.goNext();
        }
    }

    Timer {
        id: toastTimer

        interval: 1700
        repeat: false
        onTriggered: root.toastText = ""
    }

    // -- Shortcuts -------------------------------------------------------------

    Shortcut {
        sequence: "Escape"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.handleEscape()
    }
    Shortcut {
        sequence: "Left"
        enabled: root.visible && !root.fileDialogOpen && !root.gridOpen && !root.infoOpen && !(root.imageStage && root.imageStage.cropMode)
        onActivated: root.isVideo && root.videoStage ? root.videoStage.skip(-5000) : root.goPrevious()
    }
    Shortcut {
        sequence: "Right"
        enabled: root.visible && !root.fileDialogOpen && !root.gridOpen && !root.infoOpen && !(root.imageStage && root.imageStage.cropMode)
        onActivated: root.isVideo && root.videoStage ? root.videoStage.skip(5000) : root.goNext()
    }
    Shortcut {
        sequence: "Shift+Left"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.goPrevious()
    }
    Shortcut {
        sequence: "Shift+Right"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.goNext()
    }
    Shortcut {
        sequence: "Up"
        enabled: root.visible && !root.fileDialogOpen && !root.gridOpen && !root.infoOpen && !root.trimMode && !(root.imageStage && root.imageStage.cropMode)
        onActivated: root.goPrevious()
    }
    Shortcut {
        sequence: "Down"
        enabled: root.visible && !root.fileDialogOpen && !root.gridOpen && !root.infoOpen && !root.trimMode && !(root.imageStage && root.imageStage.cropMode)
        onActivated: root.goNext()
    }
    Shortcut {
        sequence: "Space"
        enabled: root.visible && !root.fileDialogOpen && !root.gridOpen && !root.trimMode && !(root.imageStage && root.imageStage.cropMode)
        onActivated: {
            if (root.isVideo && root.videoStage)
                root.videoStage.togglePlay();
            else if (root.isGif && root.imageStage)
                root.imageStage.toggleAnimation();
            else
                root.toggleSlideshow();
        }
    }
    Shortcut {
        sequence: "="
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.zoomIn()
    }
    Shortcut {
        sequence: "-"
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.zoomOut()
    }
    Shortcut {
        sequence: "0"
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.fit()
    }
    Shortcut {
        sequence: "1"
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.actualSize()
    }
    Shortcut {
        sequence: "R"
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.rotateRight()
    }
    Shortcut {
        sequence: "Shift+R"
        enabled: root.visible && !root.fileDialogOpen && root.imageStage && !root.imageStage.cropMode
        onActivated: root.imageStage.rotateLeft()
    }
    Shortcut {
        sequence: "I"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.toggleInspector()
    }
    Shortcut {
        sequence: "G"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.toggleGrid()
    }
    Shortcut {
        sequence: "B"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.toggleSidebar()
    }
    Shortcut {
        sequence: "S"
        enabled: root.visible && !root.fileDialogOpen && !root.trimMode && !(root.imageStage && root.imageStage.cropMode)
        onActivated: root.toggleSlideshow()
    }
    Shortcut {
        sequence: "F"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.toggleFullscreen()
    }
    Shortcut {
        sequence: "M"
        enabled: root.visible && !root.fileDialogOpen && root.isVideo && root.videoStage
        onActivated: root.videoStage.toggleMute()
    }
    Shortcut {
        sequence: "C"
        enabled: root.visible && !root.fileDialogOpen && root.hasMedia && !root.isVideo && !root.isGif
        onActivated: root.toggleCrop()
    }
    Shortcut {
        sequence: "T"
        enabled: root.visible && !root.fileDialogOpen && root.isVideo
        onActivated: root.toggleTrim()
    }
    Shortcut {
        sequence: "["
        enabled: root.visible && !root.fileDialogOpen && root.trimMode && root.videoStage
        onActivated: root.trimStart = Math.max(0, Math.min(root.videoStage.position, root.trimEnd - 200))
    }
    Shortcut {
        sequence: "]"
        enabled: root.visible && !root.fileDialogOpen && root.trimMode && root.videoStage
        onActivated: root.trimEnd = Math.min(root.videoStage.duration, Math.max(root.videoStage.position, root.trimStart + 200))
    }
    Shortcut {
        sequence: "Ctrl+Return"
        enabled: root.visible && !root.fileDialogOpen && root.trimMode && !root.trimBusy
        onActivated: root.startTrim()
    }
    Shortcut {
        sequence: "Ctrl+Shift+A"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: root.cycleAppearance()
    }
    Shortcut {
        sequence: "Ctrl+O"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: fileBrowser.openFile(root.folderPath)
    }
    Shortcut {
        sequence: "Ctrl+Shift+O"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: fileBrowser.openFolder(root.folderPath)
    }
    Shortcut {
        sequence: "Ctrl+W"
        enabled: root.visible && !root.fileDialogOpen
        onActivated: Qt.quit()
    }
    Shortcut {
        sequence: "Ctrl+Shift+C"
        enabled: root.visible && !root.fileDialogOpen && root.hasMedia
        onActivated: root.copyPath()
    }

    // -- Window chrome ---------------------------------------------------------

    RoundedClip {
        id: chrome

        anchors.fill: parent
        radius: Theme.windowRadius
        color: Theme.windowBg
        border.width: 1
        border.color: Theme.windowBorder
        opacity: root.contentOpacity

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: ambient

            anchors.fill: parent
            clip: true

            Image {
                id: ambientSource

                anchors.fill: parent
                source: root.isVideo ? root.videoBackdrop : (root.imageStage && root.imageStage.fallbackImageSource !== "" ? root.imageStage.fallbackImageSource : root.currentFileUrl)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: ambientSource
                blurEnabled: true
                blur: 0.85
                blurMax: 48
                saturation: -0.18
                brightness: -0.28
                opacity: Theme.dark ? 0.52 : 0.34
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Theme.dark ? Qt.rgba(0.05, 0.05, 0.07, 0.38) : Qt.rgba(1, 1, 1, 0.22)
                    }
                    GradientStop {
                        position: 0.55
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1
                        color: Theme.dark ? Qt.rgba(0.02, 0.02, 0.03, 0.62) : Qt.rgba(0.9, 0.9, 0.94, 0.34)
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.alpha(Theme.stageBg, Theme.dark ? 0.22 : 0.10)
        }

        Item {
            id: titlebar

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: Theme.titlebarHeight
            z: 20

            Rectangle {
                anchors.fill: parent
                color: Theme.titlebarBg
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: Theme.separator
                opacity: 0.7
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: app.startSystemMove()
                onDoubleClicked: root.toggleMaximize()
            }

            Row {
                id: trafficLights

                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                TrafficLight {
                    circleColor: Theme.trafficRed
                    glyph: "close"
                    onClicked: Qt.quit()
                }

                TrafficLight {
                    circleColor: Theme.trafficYellow
                    glyph: "minimize"
                    onClicked: root.minimizeWindow()
                }

                TrafficLight {
                    circleColor: Theme.trafficGreen
                    glyph: root.isFullscreen ? "exit-fullscreen" : "fullscreen"
                    onClicked: mouse => {
                        if (mouse.modifiers & Qt.AltModifier)
                            root.toggleMaximize();
                        else
                            root.toggleFullscreen();
                    }
                }
            }

            ToolbarButton {
                id: sidebarButton

                anchors {
                    left: trafficLights.right
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                icon: "sidebar"
                tip: root.sidebarOpen ? Strings.hideSidebar : Strings.showSidebar
                shortcutText: "B"
                active: root.sidebarOpen
                visible: root.folderPath !== "" || root.hasMedia
                onClicked: root.toggleSidebar()
            }

            Column {
                anchors {
                    centerIn: parent
                    verticalCenter: parent.verticalCenter
                }
                width: Math.max(140, Math.min(520, titlebar.width - 420))
                spacing: 1
                visible: titlebar.width > 560

                Text {
                    width: parent.width
                    text: root.hasMedia ? root.currentFileName : Strings.appName
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                Text {
                    width: parent.width
                    text: root.subtitleText !== "" ? root.subtitleText : Strings.appSubtitle
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }
            }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                spacing: 3

                ToolbarButton {
                    icon: "info"
                    tip: root.infoOpen ? Strings.closeInspector : Strings.inspector
                    shortcutText: "I"
                    active: root.infoOpen
                    enabled: root.hasMedia
                    onClicked: root.toggleInspector()
                }

                ToolbarButton {
                    id: shareButton

                    icon: "share"
                    tip: Strings.share
                    enabled: root.hasMedia
                    onClicked: {
                        root.moreMenuOpen = false;
                        root.shareMenuOpen = !root.shareMenuOpen;
                    }
                }

                ToolbarButton {
                    icon: "ellipsis"
                    tip: Strings.more
                    onClicked: {
                        root.shareMenuOpen = false;
                        root.moreMenuOpen = !root.moreMenuOpen;
                    }
                }

                ToolbarButton {
                    icon: root.isFullscreen ? "exit-fullscreen" : "fullscreen"
                    tip: root.isFullscreen ? Strings.exitFullscreen : Strings.fullscreen
                    shortcutText: "F"
                    onClicked: root.toggleFullscreen()
                }
            }
        }

        Item {
            id: contentArea

            anchors {
                top: titlebar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Row {
                anchors.fill: parent

                Item {
                    id: sidebarClip

                    width: root.sidebarOpen && (root.folderPath !== "" || root.hasMedia) ? 236 : 0
                    height: parent.height
                    clip: true

                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    MediaSidebar {
                        width: 236
                        height: parent.height
                        model: folderModel
                        currentIndex: root.currentIndex
                        folderName: root.folderName
                        folderPath: root.folderPath
                        onItemActivated: index => root.selectIndex(index)
                    }
                }

                Item {
                    id: stageHost

                    width: parent.width - sidebarClip.width - root.inspectorWidth
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.alpha(Theme.stageBg, Theme.dark ? 0.20 : 0.08)
                    }

                    Loader {
                        id: imageLoader

                        anchors.fill: parent
                        active: root.hasMedia && !root.isVideo
                        sourceComponent: ImageStage {
                            source: root.currentFileUrl
                            animated: root.isGif
                            sideInset: 48
                            bottomInset: 86
                            onImageLoaded: (width, height) => root.updateImageSize(width, height)
                            onImageFailed: message => root.toastText = message
                            onCropRequested: (x, y, width, height) => root.applyCrop(x, y, width, height)
                        }
                    }

                    Loader {
                        id: videoLoader

                        anchors.fill: parent
                        active: root.hasMedia && root.isVideo
                        sourceComponent: VideoStage {
                            source: root.currentFileUrl
                            bottomInset: 82
                            onRequestFullscreen: root.toggleFullscreen()
                        }
                    }

                    WelcomeView {
                        anchors.fill: parent
                        visible: !root.hasMedia && !root.loadingFolder
                        onOpenFileRequested: fileBrowser.openFile(root.folderPath)
                        onOpenFolderRequested: fileBrowser.openFolder(root.folderPath)
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: root.loadingFolder

                        Item {
                            id: loadingSpinner

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 28
                            height: 28

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
                                running: loadingSpinner.visible
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Strings.loading
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    MediaToolbar {
                        id: mediaToolbar

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 14
                        }
                        visible: root.hasMedia && !(root.imageStage && root.imageStage.cropMode)
                        isVideo: root.isVideo
                        isAnimated: root.isGif
                        animationPlaying: root.imageStage ? root.imageStage.animationPlaying : true
                        videoPlaying: root.videoStage ? root.videoStage.playing : false
                        videoSeekable: root.videoStage ? root.videoStage.seekable : false
                        videoPosition: root.videoStage ? root.videoStage.position : 0
                        videoDuration: root.videoStage ? root.videoStage.duration : 0
                        videoMuted: root.videoStage ? root.videoStage.muted : false
                        videoRate: root.videoStage ? root.videoStage.rate : 1
                        videoLoop: root.videoStage ? root.videoStage.loop : false
                        scaleLabel: root.imageStage ? root.imageStage.scaleLabel : "100%"
                        slideshow: root.slideshow
                        previousEnabled: root.currentIndex > 0
                        nextEnabled: root.currentIndex >= 0 && root.currentIndex < folderModel.count - 1
                        compact: stageHost.width < 620
                        canCrop: !root.isVideo && !root.isGif
                        canTrim: root.isVideo
                        onPrevious: root.goPrevious()
                        onNext: root.goNext()
                        onZoomOut: if (root.imageStage)
                            root.imageStage.zoomOut()
                        onZoomIn: if (root.imageStage)
                            root.imageStage.zoomIn()
                        onToggleZoom: if (root.imageStage)
                            root.imageStage.toggleZoom()
                        onRotateLeft: if (root.imageStage)
                            root.imageStage.rotateLeft()
                        onRotateRight: if (root.imageStage)
                            root.imageStage.rotateRight()
                        onToggleAnimation: if (root.imageStage)
                            root.imageStage.toggleAnimation()
                        onToggleSlideshow: root.toggleSlideshow()
                        onTogglePlay: if (root.videoStage)
                            root.videoStage.togglePlay()
                        onSeek: position => {
                            if (root.videoStage)
                                root.videoStage.seek(position);
                        }
                        onSkip: delta => {
                            if (root.videoStage)
                                root.videoStage.skip(delta);
                        }
                        onToggleMute: if (root.videoStage)
                            root.videoStage.toggleMute()
                        onCycleRate: if (root.videoStage)
                            root.videoStage.cycleRate()
                        onToggleLoop: if (root.videoStage)
                            root.videoStage.loop = !root.videoStage.loop
                        onToggleGrid: root.toggleGrid()
                        onCrop: root.toggleCrop()
                        onTrim: root.toggleTrim()
                    }

                    TrimPanel {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 74
                        }
                        width: Math.min(560, parent.width - 32)
                        visible: root.trimMode
                        duration: root.videoStage ? root.videoStage.duration : 0
                        startValue: root.trimStart
                        endValue: root.trimEnd
                        positionValue: root.videoStage ? root.videoStage.position : 0
                        busy: root.trimBusy
                        onStartMoved: milliseconds => root.trimStart = milliseconds
                        onEndMoved: milliseconds => root.trimEnd = milliseconds
                        onPreview: {
                            if (root.videoStage) {
                                root.videoStage.seek(root.trimStart);
                                root.videoStage.play();
                            }
                        }
                        onTrim: root.startTrim()
                        onCancel: root.cancelTrim()
                    }
                }

                Item {
                    id: inspectorClip

                    width: root.inspectorWidth
                    height: parent.height
                    clip: true
                    visible: width > 1

                    Behavior on width {
                        NumberAnimation {
                            duration: 210
                            easing.type: Easing.OutCubic
                        }
                    }

                    InfoInspector {
                        id: inspector

                        anchors {
                            top: parent.top
                            topMargin: 12
                            right: parent.right
                            rightMargin: 12
                            bottom: parent.bottom
                            bottomMargin: 12
                        }
                        opened: root.infoOpen
                        filePath: root.currentFile
                        fileUrl: root.currentFileUrl
                        previewSource: root.isVideo ? root.videoBackdrop : (root.imageStage && root.imageStage.fallbackImageSource !== "" ? root.imageStage.fallbackImageSource : root.currentFileUrl)
                        meta: root.metadata
                        imageWidth: root.imageWidth
                        imageHeight: root.imageHeight
                        fileSize: root.fileSize
                        fileModified: root.fileModified
                        frameCount: root.imageStage ? root.imageStage.frameCount : root.frameCount
                        onCloseRequested: root.infoOpen = false
                        onOpenWithRequested: root.openWithDefault()
                        onShowInFolderRequested: root.showInFolder()
                        onCopyPathRequested: root.copyPath()
                    }
                }
            }

            MediaGridSheet {
                anchors.fill: parent
                z: 30
                visible: root.gridOpen
                model: folderModel
                currentIndex: root.currentIndex
                onItemActivated: index => {
                    root.selectIndex(index);
                    root.gridOpen = false;
                }
                onCloseRequested: root.gridOpen = false
            }

            Rectangle {
                id: toast

                anchors {
                    top: parent.top
                    topMargin: 14
                    horizontalCenter: parent.horizontalCenter
                }
                width: toastText.implicitWidth + 28
                height: 32
                radius: 16
                color: Theme.glassBg
                border.width: 1
                border.color: Theme.glassBorder
                opacity: root.toastText !== "" ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }

                Text {
                    id: toastText

                    anchors.centerIn: parent
                    text: root.toastText
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        // Click-away layer for the menus.
        MouseArea {
            anchors.fill: parent
            z: 190
            visible: root.shareMenuOpen || root.moreMenuOpen
            acceptedButtons: Qt.LeftButton
            onClicked: root.closeMenus()
        }

        ActionMenu {
            id: shareMenu

            z: 200
            x: parent.width - width - 14
            y: titlebar.height + 6
            opened: root.shareMenuOpen
            title: Strings.share
            items: [
                {
                    icon: "copy",
                    label: Strings.copyPath,
                    shortcut: "Ctrl+Shift+C",
                    action: "copy-path"
                },
                {
                    icon: "folder",
                    label: Strings.showInFolder,
                    action: "show-in-folder"
                },
                {
                    type: "separator"
                },
                {
                    icon: "external",
                    label: Strings.openWithDefault,
                    action: "open-with"
                }
            ]
            onActivated: action => root.handleMenuAction(action)
        }

        ActionMenu {
            id: moreMenu

            z: 200
            x: parent.width - width - 14
            y: titlebar.height + 6
            opened: root.moreMenuOpen
            items: [
                {
                    icon: "sidebar",
                    label: root.sidebarOpen ? Strings.hideSidebar : Strings.showSidebar,
                    shortcut: "B",
                    action: "toggle-sidebar",
                    enabled: root.folderPath !== "" || root.hasMedia
                },
                {
                    icon: "info",
                    label: root.infoOpen ? Strings.closeInspector : Strings.inspector,
                    shortcut: "I",
                    action: "toggle-inspector",
                    enabled: root.hasMedia
                },
                {
                    icon: "grid",
                    label: Strings.indexSheet,
                    shortcut: "G",
                    action: "index-sheet",
                    enabled: root.hasMedia
                },
                {
                    icon: "play",
                    label: Strings.slideshow,
                    shortcut: "S",
                    action: "slideshow",
                    enabled: !root.isVideo && root.hasMedia
                },
                {
                    type: "separator"
                },
                {
                    icon: app.appearanceMode === "dark" ? "moon" : app.appearanceMode === "light" ? "sun" : "appearance",
                    label: app.appearanceMode === "system" ? Strings.appearanceSystem : app.appearanceMode === "light" ? Strings.appearanceLight : Strings.appearanceDark,
                    action: "appearance"
                },
                {
                    icon: root.isFullscreen ? "exit-fullscreen" : "fullscreen",
                    label: root.isFullscreen ? Strings.exitFullscreen : Strings.fullscreen,
                    shortcut: "F",
                    action: "fullscreen"
                },
                {
                    type: "separator"
                },
                {
                    icon: "close",
                    label: Strings.closeWindow,
                    shortcut: "Ctrl+W",
                    action: "close"
                }
            ]
            onActivated: action => root.handleMenuAction(action)
        }

        // Drop target and visual feedback.
        DropArea {
            anchors.fill: parent
            z: 210

            onEntered: drag => {
                if (drag.hasUrls)
                    root.dropActive = true;
            }
            onExited: root.dropActive = false
            onDropped: drop => {
                root.dropActive = false;
                if (!drop.hasUrls)
                    return;
                const paths = [];
                for (let i = 0; i < drop.urls.length; ++i)
                    paths.push(root.urlToPath(drop.urls[i]));
                root.openPaths(paths);
            }
        }

        Rectangle {
            anchors.fill: parent
            z: 220
            visible: root.dropActive
            color: Qt.rgba(0.04, 0.52, 1.0, 0.10)
            border.width: 2
            border.color: Theme.alpha(Theme.accent, 0.85)
            radius: Theme.windowRadius

            Column {
                anchors.centerIn: parent
                spacing: 10

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    height: 36
                    name: "image"
                    color: Theme.accent
                    strokeWidth: 1.5
                }

                Text {
                    text: Strings.dropHint
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }
        }
    }

    // Resize grips for the frameless window.
    Item {
        anchors.fill: parent
        z: 300

        MouseArea {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: 6
            cursorShape: Qt.SizeHorCursor
            onPressed: app.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: 6
            cursorShape: Qt.SizeHorCursor
            onPressed: app.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 6
            cursorShape: Qt.SizeVerCursor
            onPressed: app.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: 6
            cursorShape: Qt.SizeVerCursor
            onPressed: app.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            anchors {
                left: parent.left
                top: parent.top
            }
            width: 12
            height: 12
            cursorShape: Qt.SizeFDiagCursor
            onPressed: app.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
        }
        MouseArea {
            anchors {
                right: parent.right
                top: parent.top
            }
            width: 12
            height: 12
            cursorShape: Qt.SizeBDiagCursor
            onPressed: app.startSystemResize(Qt.RightEdge | Qt.TopEdge)
        }
        MouseArea {
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            width: 12
            height: 12
            cursorShape: Qt.SizeBDiagCursor
            onPressed: app.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
        }
        MouseArea {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            width: 12
            height: 12
            cursorShape: Qt.SizeFDiagCursor
            onPressed: app.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }

    FileBrowserDialog {
        id: fileBrowser

        anchors.fill: parent
        onVisibleChanged: root.fileDialogOpen = visible
        onFileSelected: path => root.openPaths([path])
        onFolderSelected: path => root.openPaths([path])
    }
}
