pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property bool zh: String(Qt.locale().name || "").toLowerCase().startsWith("zh")

    readonly property string appName: zh ? "预览" : "Preview"
    readonly property string appSubtitle: zh ? "图片与视频" : "Images & videos"
    readonly property string openFile: zh ? "打开文件…" : "Open File…"
    readonly property string openFolder: zh ? "打开文件夹…" : "Open Folder…"
    readonly property string dropHint: zh ? "将图片或视频拖放到这里" : "Drop an image or video here"
    readonly property string welcomeTitle: zh ? "预览" : "Preview"
    readonly property string welcomeBody: zh ? "打开图片或视频，开始快速查看。" : "Open an image or video to take a quick look."
    readonly property string emptyFolder: zh ? "这个文件夹里没有可查看的图片或视频。" : "No images or videos in this folder."
    readonly property string loading: zh ? "正在载入…" : "Loading…"
    readonly property string unableToOpen: zh ? "无法打开此项目" : "Unable to open this item"
    readonly property string noSelection: zh ? "未选择项目" : "No item selected"

    readonly property string previous: zh ? "上一个" : "Previous"
    readonly property string next: zh ? "下一个" : "Next"
    readonly property string zoomOut: zh ? "缩小" : "Zoom Out"
    readonly property string zoomIn: zh ? "放大" : "Zoom In"
    readonly property string fit: zh ? "适合窗口" : "Fit to Window"
    readonly property string actualSize: zh ? "实际大小" : "Actual Size"
    readonly property string rotateLeft: zh ? "向左旋转" : "Rotate Left"
    readonly property string rotateRight: zh ? "向右旋转" : "Rotate Right"
    readonly property string slideshow: zh ? "幻灯片" : "Slideshow"
    readonly property string stopSlideshow: zh ? "停止幻灯片" : "Stop Slideshow"
    readonly property string indexSheet: zh ? "索引表" : "Index Sheet"
    readonly property string showSidebar: zh ? "显示侧边栏" : "Show Sidebar"
    readonly property string hideSidebar: zh ? "隐藏侧边栏" : "Hide Sidebar"
    readonly property string inspector: zh ? "显示简介" : "Show Inspector"
    readonly property string inspectorTitle: zh ? "简介" : "Inspector"
    readonly property string closeInspector: zh ? "隐藏简介" : "Hide Inspector"
    readonly property string fullscreen: zh ? "进入全屏幕" : "Enter Full Screen"
    readonly property string exitFullscreen: zh ? "退出全屏幕" : "Exit Full Screen"
    readonly property string play: zh ? "播放" : "Play"
    readonly property string pause: zh ? "暂停" : "Pause"
    readonly property string replay: zh ? "重播" : "Replay"
    readonly property string mute: zh ? "静音" : "Mute"
    readonly property string unmute: zh ? "取消静音" : "Unmute"
    readonly property string loop: zh ? "循环播放" : "Loop"
    readonly property string speed: zh ? "播放速度" : "Playback Speed"
    readonly property string share: zh ? "共享" : "Share"
    readonly property string copyPath: zh ? "复制路径" : "Copy Path"
    readonly property string showInFolder: zh ? "在文件夹中显示" : "Show in Folder"
    readonly property string openWithDefault: zh ? "用默认应用打开" : "Open with Default App"
    readonly property string more: zh ? "更多" : "More"
    readonly property string appearance: zh ? "外观" : "Appearance"
    readonly property string appearanceSystem: zh ? "外观：跟随系统" : "Appearance: System"
    readonly property string appearanceLight: zh ? "外观：浅色" : "Appearance: Light"
    readonly property string appearanceDark: zh ? "外观：深色" : "Appearance: Dark"
    readonly property string close: zh ? "关闭" : "Close"
    readonly property string closeWindow: zh ? "关闭窗口" : "Close Window"
    readonly property string copied: zh ? "已复制路径" : "Path copied"
    readonly property string fileDialogTitle: zh ? "打开文件" : "Open File"
    readonly property string folderDialogTitle: zh ? "打开文件夹" : "Open Folder"
    readonly property string places: zh ? "位置" : "Places"
    readonly property string homePlace: zh ? "主目录" : "Home"
    readonly property string desktopPlace: zh ? "桌面" : "Desktop"
    readonly property string documentsPlace: zh ? "文稿" : "Documents"
    readonly property string downloadsPlace: zh ? "下载" : "Downloads"
    readonly property string picturesPlace: zh ? "图片" : "Pictures"
    readonly property string videosPlace: zh ? "影片" : "Videos"
    readonly property string musicPlace: zh ? "音乐" : "Music"
    readonly property string computerPlace: zh ? "计算机" : "Computer"
    readonly property string nameColumn: zh ? "名称" : "Name"
    readonly property string sizeColumn: zh ? "大小" : "Size"
    readonly property string modifiedColumn: zh ? "修改日期" : "Modified"
    readonly property string openAction: zh ? "打开" : "Open"
    readonly property string cancelAction: zh ? "取消" : "Cancel"
    readonly property string upOneLevel: zh ? "上一级" : "Up One Level"
    readonly property string noItems: zh ? "此文件夹为空" : "This folder is empty"
    readonly property string backOneLevel: zh ? "返回上一级" : "Back"
    readonly property string crop: zh ? "裁剪" : "Crop"
    readonly property string cropHint: zh ? "拖动或调整裁剪框，然后点按“裁剪”" : "Drag or resize the crop box, then press Crop"
    readonly property string cropApply: zh ? "裁剪" : "Crop"
    readonly property string cropCancel: zh ? "取消" : "Cancel"
    readonly property string cropSaved: zh ? "已保存裁剪结果" : "Cropped image saved"
    readonly property string cropFailed: zh ? "裁剪失败" : "Could not crop this image"
    readonly property string trim: zh ? "修剪" : "Trim"
    readonly property string trimTitle: zh ? "修剪视频" : "Trim Video"
    readonly property string trimPreview: zh ? "预览" : "Preview"
    readonly property string trimApply: zh ? "修剪" : "Trim"
    readonly property string trimBusy: zh ? "正在修剪…" : "Trimming…"
    readonly property string trimSaved: zh ? "已保存修剪结果" : "Trimmed video saved"
    readonly property string trimFailed: zh ? "修剪失败" : "Could not trim this video"

    readonly property string infoKind: zh ? "种类" : "Kind"
    readonly property string infoSize: zh ? "大小" : "Size"
    readonly property string infoDimensions: zh ? "尺寸" : "Dimensions"
    readonly property string infoDuration: zh ? "时长" : "Duration"
    readonly property string infoCodec: zh ? "编码" : "Codec"
    readonly property string infoModified: zh ? "修改日期" : "Modified"
    readonly property string infoLocation: zh ? "位置" : "Location"
    readonly property string infoFrames: zh ? "帧" : "Frames"

    function kindName(path) {
        const ext = extension(path);
        const map = {
            "png": "PNG",
            "jpg": "JPEG",
            "jpeg": "JPEG",
            "webp": "WebP",
            "gif": "GIF",
            "bmp": "BMP",
            "tif": "TIFF",
            "tiff": "TIFF",
            "svg": "SVG",
            "avif": "AVIF",
            "heic": "HEIC",
            "heif": "HEIF",
            "mp4": "MPEG-4",
            "m4v": "MPEG-4",
            "webm": "WebM",
            "mkv": "Matroska",
            "mov": "QuickTime",
            "avi": "AVI",
            "mpg": "MPEG",
            "mpeg": "MPEG",
            "ogv": "Ogg Video"
        };
        return map[ext] || (ext ? ext.toUpperCase() : (zh ? "媒体" : "Media"));
    }

    function kindDescription(path) {
        if (isVideo(path))
            return zh ? "视频" : "Video";
        if (isGif(path))
            return zh ? "动画图像" : "Animated Image";
        return zh ? "图像" : "Image";
    }

    function extension(path) {
        const name = String(path || "").split("/").pop() || "";
        const dot = name.lastIndexOf(".");
        return dot >= 0 ? name.slice(dot + 1).toLowerCase() : "";
    }

    function isVideo(path) {
        return ["mp4", "m4v", "webm", "mkv", "mov", "avi", "mpg", "mpeg", "ogv"].includes(extension(path));
    }

    function isGif(path) {
        return extension(path) === "gif";
    }

    function isImage(path) {
        return !isVideo(path) && ["png", "jpg", "jpeg", "webp", "gif", "bmp", "tif", "tiff", "svg", "avif", "heic", "heif"].includes(extension(path));
    }

    function fileName(path) {
        return String(path || "").split("/").pop() || "";
    }

    function formatBytes(bytes) {
        const value = Number(bytes) || 0;
        if (value <= 0)
            return "—";
        if (value < 1000)
            return value + " B";
        if (value < 1000 * 1000)
            return (value / 1000).toFixed(value < 10000 ? 1 : 0) + " KB";
        if (value < 1000 * 1000 * 1000)
            return (value / 1000 / 1000).toFixed(value < 10000000 ? 1 : 0) + " MB";
        return (value / 1000 / 1000 / 1000).toFixed(2) + " GB";
    }

    function formatDuration(ms) {
        const total = Math.max(0, Math.round((Number(ms) || 0) / 1000));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const padded = seconds < 10 ? "0" + seconds : String(seconds);
        if (hours > 0)
            return hours + ":" + (minutes < 10 ? "0" + minutes : minutes) + ":" + padded;
        return minutes + ":" + padded;
    }

    function formatDate(ms) {
        const value = Number(ms) || 0;
        if (value <= 0)
            return "—";
        const date = new Date(value);
        return zh ? Qt.formatDateTime(date, "yyyy年M月d日 HH:mm") : Qt.formatDateTime(date, "MMM d, yyyy HH:mm");
    }

    function formatPercent(scale) {
        return Math.round((Number(scale) || 0) * 100) + "%";
    }
}
