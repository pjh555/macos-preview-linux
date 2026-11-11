import QtQuick
import QtCore
import Qt.labs.folderlistmodel

FocusScope {
    id: dialog

    anchors.fill: parent
    visible: false
    focus: visible
    z: 1000

    property bool folderMode: false
    property string currentFolder: ""
    property int selectedIndex: -1
    property string selectedPath: ""
    property bool selectedIsDir: false

    signal fileSelected(string path)
    signal folderSelected(string path)

    readonly property var breadcrumbs: {
        const result = [];
        if (!dialog.currentFolder.startsWith("/"))
            return result;
        result.push({
            "label": "/",
            "path": "/"
        });
        let accumulated = "";
        const segments = dialog.currentFolder.split("/").filter(segment => segment !== "");
        for (let i = 0; i < segments.length; ++i) {
            accumulated += "/" + segments[i];
            result.push({
                "label": segments[i],
                "path": accumulated
            });
        }
        return result;
    }

    function pathToUrl(path) {
        return "file://" + encodeURI(String(path || "")).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function localPath(value) {
        let path = String(value || "");
        if (path.startsWith("file://")) {
            path = path.slice(7);
            try {
                path = decodeURIComponent(path);
            } catch (error) {}
        }
        return path;
    }

    function parentPath(path) {
        const value = String(path || "");
        if (value === "" || value === "/")
            return "/";
        const trimmed = value.replace(/\/+$/, "");
        const slash = trimmed.lastIndexOf("/");
        return slash <= 0 ? "/" : trimmed.slice(0, slash);
    }

    function fallbackFolder() {
        const pictures = localPath(StandardPaths.writableLocation(StandardPaths.PicturesLocation));
        if (pictures !== "" && app.isDirectory(pictures))
            return pictures;
        return localPath(StandardPaths.writableLocation(StandardPaths.HomeLocation));
    }

    function resetSelection() {
        selectedIndex = -1;
        selectedPath = "";
        selectedIsDir = false;
        fileList.currentIndex = -1;
    }

    function navigateTo(path) {
        if (!app.isDirectory(path))
            return;
        currentFolder = path;
        resetSelection();
    }

    function selectIndex(index) {
        if (index < 0 || index >= folderModel.count) {
            resetSelection();
            return;
        }
        selectedIndex = index;
        selectedPath = String(folderModel.get(index, "filePath") || "");
        selectedIsDir = folderModel.isFolder(index);
    }

    function activateIndex(index) {
        if (index < 0 || index >= folderModel.count)
            return;
        selectIndex(index);
        if (selectedIsDir) {
            dialog.navigateTo(selectedPath);
        } else if (!dialog.folderMode) {
            dialog.fileSelected(selectedPath);
            close();
        }
    }

    function accept() {
        if (dialog.folderMode) {
            const path = dialog.selectedIsDir ? dialog.selectedPath : dialog.currentFolder;
            if (path !== "") {
                dialog.folderSelected(path);
                close();
            }
            return;
        }
        if (dialog.selectedPath !== "" && !dialog.selectedIsDir) {
            dialog.fileSelected(dialog.selectedPath);
            close();
        }
    }

    function openFile(startFolder) {
        folderMode = false;
        currentFolder = startFolder !== "" && app.isDirectory(startFolder) ? startFolder : fallbackFolder();
        resetSelection();
        visible = true;
        Qt.callLater(function () {
            fileList.forceActiveFocus();
        });
    }

    function openFolder(startFolder) {
        folderMode = true;
        currentFolder = startFolder !== "" && app.isDirectory(startFolder) ? startFolder : localPath(StandardPaths.writableLocation(StandardPaths.HomeLocation));
        resetSelection();
        visible = true;
        Qt.callLater(function () {
            fileList.forceActiveFocus();
        });
    }

    function close() {
        visible = false;
    }

    function buildPlaces() {
        placesModel.clear();
        const candidates = [["home", Strings.homePlace, localPath(StandardPaths.writableLocation(StandardPaths.HomeLocation)), "home"], ["desktop", Strings.desktopPlace, localPath(StandardPaths.writableLocation(StandardPaths.DesktopLocation)), "desktop"], ["documents", Strings.documentsPlace, localPath(StandardPaths.writableLocation(StandardPaths.DocumentsLocation)), "document"], ["downloads", Strings.downloadsPlace, localPath(StandardPaths.writableLocation(StandardPaths.DownloadLocation)), "download"], ["pictures", Strings.picturesPlace, localPath(StandardPaths.writableLocation(StandardPaths.PicturesLocation)), "image"], ["videos", Strings.videosPlace, localPath(StandardPaths.writableLocation(StandardPaths.MoviesLocation)), "video"], ["music", Strings.musicPlace, localPath(StandardPaths.writableLocation(StandardPaths.MusicLocation)), "music"]];
        for (let i = 0; i < candidates.length; ++i) {
            const entry = candidates[i];
            if (entry[2] !== "" && app.isDirectory(entry[2]))
                placesModel.append({
                    "label": entry[1],
                    "path": entry[2],
                    "icon": entry[3]
                });
        }
        placesModel.append({
            "label": Strings.computerPlace,
            "path": "/",
            "icon": "computer"
        });
    }

    Component.onCompleted: buildPlaces()

    ListModel {
        id: placesModel
    }

    FolderListModel {
        id: folderModel

        folder: dialog.currentFolder !== "" ? dialog.pathToUrl(dialog.currentFolder) : ""
        showDirs: true
        showFiles: !dialog.folderMode
        showHidden: false
        sortField: FolderListModel.Name
        sortReversed: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.tif", "*.tiff", "*.svg", "*.avif", "*.heic", "*.heif", "*.mp4", "*.m4v", "*.webm", "*.mkv", "*.mov", "*.avi", "*.mpg", "*.mpeg", "*.ogv"]

        onCountChanged: {
            if (dialog.selectedIndex >= count)
                dialog.resetSelection();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.48)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.close()
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(880, parent.width - 40)
        height: Math.min(590, parent.height - 40)
        radius: 14
        color: Theme.windowBg
        border.width: 1
        border.color: Theme.windowBorder

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {}
        }

        Item {
            id: titlebar

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 46

            Text {
                anchors.centerIn: parent
                text: dialog.folderMode ? Strings.folderDialogTitle : Strings.fileDialogTitle
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            ToolbarButton {
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                icon: "close"
                tip: Strings.cancelAction
                onClicked: dialog.close()
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: Theme.separator
            }
        }

        Row {
            anchors {
                top: titlebar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Rectangle {
                id: sidebar

                width: 184
                height: parent.height
                color: Theme.sidebarBg

                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 1
                    color: Theme.separator
                }

                Text {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 14
                        topMargin: 12
                    }
                    text: Strings.places
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                ListView {
                    id: placesList

                    anchors {
                        top: parent.top
                        topMargin: 34
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 7
                        rightMargin: 7
                    }
                    model: placesModel
                    spacing: 1
                    clip: true

                    delegate: Item {
                        id: place

                        required property string label
                        required property string path
                        required property string icon

                        width: ListView.view.width
                        height: 32

                        readonly property bool selected: dialog.currentFolder === place.path

                        HoverHandler {
                            id: placeHover
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 7
                            color: place.selected ? Theme.selection : placeHover.hovered ? Theme.hover : "transparent"
                        }

                        Row {
                            anchors {
                                left: parent.left
                                leftMargin: 9
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 8

                            Icon {
                                width: 14
                                height: 14
                                name: place.icon
                                color: place.selected ? Theme.accent : Theme.textSecondary
                            }

                            Text {
                                text: place.label
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialog.navigateTo(place.path)
                        }
                    }
                }
            }

            Item {
                id: mainArea

                width: parent.width - sidebar.width
                height: parent.height

                Item {
                    id: breadcrumbBar

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: 8
                        leftMargin: 12
                        rightMargin: 12
                    }
                    height: 32

                    ToolbarButton {
                        id: upButton

                        anchors.verticalCenter: parent.verticalCenter
                        icon: "chevron-up"
                        tip: Strings.upOneLevel
                        enabled: dialog.currentFolder !== "/"
                        onClicked: dialog.navigateTo(dialog.parentPath(dialog.currentFolder))
                    }

                    Flickable {
                        anchors {
                            left: upButton.right
                            leftMargin: 4
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        contentWidth: crumbRow.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        onContentWidthChanged: contentX = Math.max(0, contentWidth - width)

                        Row {
                            id: crumbRow

                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Repeater {
                                model: dialog.breadcrumbs

                                Row {
                                    required property var modelData
                                    required property int index

                                    spacing: 2

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        color: index === dialog.breadcrumbs.length - 1 ? Theme.textPrimary : Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: dialog.navigateTo(modelData.path)
                                        }
                                    }

                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 10
                                        height: 10
                                        name: "chevron-right"
                                        color: Theme.textTertiary
                                        visible: index < dialog.breadcrumbs.length - 1
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: columnHeader

                    anchors {
                        top: breadcrumbBar.bottom
                        topMargin: 2
                        left: parent.left
                        right: parent.right
                        leftMargin: 12
                        rightMargin: 12
                    }
                    height: 22

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 40
                            verticalCenter: parent.verticalCenter
                        }
                        text: Strings.nameColumn
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Text {
                        anchors {
                            right: modifiedHeader.left
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: 80
                        text: Strings.sizeColumn
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        visible: !dialog.folderMode
                    }

                    Text {
                        id: modifiedHeader

                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        width: 132
                        text: Strings.modifiedColumn
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                    }
                }

                ListView {
                    id: fileList

                    anchors {
                        top: columnHeader.bottom
                        left: parent.left
                        right: parent.right
                        bottom: footer.top
                        leftMargin: 12
                        rightMargin: 12
                        bottomMargin: 6
                    }
                    model: folderModel
                    spacing: 1
                    clip: true
                    focus: dialog.visible
                    currentIndex: dialog.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 500

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex !== dialog.selectedIndex)
                            dialog.selectIndex(currentIndex);
                    }

                    Keys.onReturnPressed: dialog.activateIndex(currentIndex)
                    Keys.onEnterPressed: dialog.activateIndex(currentIndex)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace) {
                            dialog.navigateTo(dialog.parentPath(dialog.currentFolder));
                            event.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: fileRow

                        required property int index

                        width: ListView.view.width
                        height: 38

                        readonly property string path: String(folderModel.get(index, "filePath") || "")
                        readonly property string name: String(folderModel.get(index, "fileName") || "")
                        readonly property bool isDir: folderModel.isFolder(index)
                        readonly property bool selected: index === dialog.selectedIndex
                        readonly property bool video: Strings.isVideo(path)
                        readonly property bool image: !video && Strings.isImage(path)
                        readonly property real size: isDir ? 0 : Number(folderModel.get(index, "fileSize")) || 0
                        readonly property var modifiedValue: folderModel.get(index, "fileModified")
                        readonly property real modified: modifiedValue instanceof Date ? modifiedValue.getTime() : Number(modifiedValue) || 0

                        HoverHandler {
                            id: rowHover
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: fileRow.selected ? Theme.selection : rowHover.hovered ? Theme.hover : "transparent"
                        }

                        Item {
                            anchors {
                                left: parent.left
                                leftMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            width: 28
                            height: 28

                            Rectangle {
                                anchors.fill: parent
                                radius: 5
                                color: Theme.thumbBg
                                visible: fileRow.isDir || !fileRow.image

                                Icon {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    name: fileRow.isDir ? "folder" : fileRow.video ? "video" : "file"
                                    color: fileRow.isDir ? Theme.accent : Theme.textSecondary
                                }
                            }

                            Thumbnail {
                                anchors.fill: parent
                                visible: fileRow.image
                                source: fileRow.image ? dialog.pathToUrl(fileRow.path) : ""
                                kind: "image"
                                radius: 5
                            }
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 40
                                right: sizeText.left
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: fileRow.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                        }

                        Text {
                            id: sizeText

                            anchors {
                                right: modifiedText.left
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            width: 80
                            text: fileRow.isDir ? "" : Strings.formatBytes(fileRow.size)
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            visible: !dialog.folderMode
                        }

                        Text {
                            id: modifiedText

                            anchors {
                                right: parent.right
                                rightMargin: 4
                                verticalCenter: parent.verticalCenter
                            }
                            width: 132
                            text: fileRow.modified > 0 ? Strings.formatDate(fileRow.modified) : ""
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                fileList.currentIndex = index;
                                dialog.selectIndex(index);
                            }
                            onDoubleClicked: dialog.activateIndex(index)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: folderModel.count === 0
                        text: Strings.noItems
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Item {
                    id: footer

                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 56

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        text: folderModel.count + (Strings.zh ? " 个项目" : " items")
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }

                    Row {
                        anchors {
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 8

                        PillButton {
                            icon: "close"
                            label: Strings.cancelAction
                            onClicked: dialog.close()
                        }

                        PillButton {
                            icon: dialog.folderMode ? "folder" : "file"
                            label: dialog.folderMode ? Strings.folderDialogTitle : Strings.openAction
                            accent: true
                            enabled: dialog.folderMode ? dialog.currentFolder !== "" : dialog.selectedIndex >= 0 && !dialog.selectedIsDir
                            onClicked: dialog.accept()
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: dialog.visible
        onActivated: dialog.close()
    }
}
