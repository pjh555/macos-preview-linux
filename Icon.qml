import QtQuick

Item {
    id: root

    property string name: ""
    property color color: "#ffffff"
    property real strokeWidth: 1.8
    property bool fill: false

    implicitWidth: 18
    implicitHeight: 18

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onStrokeWidthChanged: canvas.requestPaint()
    onFillChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.save();
            ctx.clearRect(0, 0, width, height);
            const factor = Math.min(width, height) / 24;
            ctx.scale(factor, factor);
            ctx.strokeStyle = root.color;
            ctx.fillStyle = root.color;
            ctx.lineWidth = root.strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            function line(x1, y1, x2, y2) {
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
            function poly(points, close, fillIt) {
                ctx.beginPath();
                ctx.moveTo(points[0], points[1]);
                for (let i = 2; i < points.length; i += 2)
                    ctx.lineTo(points[i], points[i + 1]);
                if (close)
                    ctx.closePath();
                if (fillIt)
                    ctx.fill();
                else
                    ctx.stroke();
            }
            function circle(cx, cy, r, fillIt) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                if (fillIt)
                    ctx.fill();
                else
                    ctx.stroke();
            }

            switch (root.name) {
            case "chevron-left":
                poly([15, 5, 8, 12, 15, 19], false, false);
                break;
            case "chevron-right":
                poly([9, 5, 16, 12, 9, 19], false, false);
                break;
            case "chevron-up":
                poly([5, 15, 12, 8, 19, 15], false, false);
                break;
            case "chevron-down":
                poly([5, 9, 12, 16, 19, 9], false, false);
                break;
            case "close":
                line(6, 6, 18, 18);
                line(18, 6, 6, 18);
                break;
            case "minimize":
                line(6, 12, 18, 12);
                break;
            case "maximize":
                line(6, 6, 18, 18);
                line(18, 6, 6, 18);
                break;
            case "fullscreen":
                poly([14, 4, 20, 4, 20, 10], false, false);
                line(20, 4, 13, 11);
                poly([10, 20, 4, 20, 4, 14], false, false);
                line(4, 20, 11, 13);
                break;
            case "exit-fullscreen":
                poly([20, 9, 15, 9, 15, 4], false, false);
                line(15, 9, 21, 3);
                poly([4, 15, 9, 15, 9, 20], false, false);
                line(9, 15, 3, 21);
                break;
            case "sidebar":
                ctx.beginPath();
                ctx.rect(3, 4, 18, 16);
                ctx.stroke();
                ctx.save();
                ctx.globalAlpha = 0.38;
                ctx.fillRect(4, 5, 4.6, 14);
                ctx.restore();
                line(9, 4, 9, 20);
                break;
            case "info":
                circle(12, 12, 8.5, false);
                circle(12, 8, 1.05, true);
                line(12, 11.5, 12, 16.5);
                break;
            case "share":
                poly([8, 10, 5, 10, 5, 20, 19, 20, 19, 10, 16, 10], false, false);
                line(12, 15, 12, 3.5);
                poly([8, 7, 12, 3, 16, 7], false, false);
                break;
            case "grid":
                for (const r of [[4, 4], [13, 4], [4, 13], [13, 13]])
                    ctx.fillRect(r[0], r[1], 7, 7);
                break;
            case "play":
                poly([8, 5.5, 19, 12, 8, 18.5], true, true);
                break;
            case "pause":
                ctx.fillRect(7, 5, 3.4, 14);
                ctx.fillRect(13.6, 5, 3.4, 14);
                break;
            case "replay":
                ctx.beginPath();
                ctx.arc(12, 12, 7.2, -Math.PI * 0.45, Math.PI * 1.25, false);
                ctx.stroke();
                poly([9, 3.5, 14.2, 6.6, 9, 9.2], true, true);
                break;
            case "skip-back":
                poly([17, 5, 8, 12, 17, 19], true, true);
                line(6, 5, 6, 19);
                break;
            case "skip-forward":
                poly([7, 5, 16, 12, 7, 19], true, true);
                line(18, 5, 18, 19);
                break;
            case "rewind-10":
                ctx.beginPath();
                ctx.arc(12, 12, 7.2, -Math.PI * 0.55, Math.PI * 1.25, false);
                ctx.stroke();
                poly([9, 3.5, 14.2, 6.6, 9, 9.2], true, true);
                break;
            case "forward-10":
                ctx.beginPath();
                ctx.arc(12, 12, 7.2, Math.PI * 0.45, -Math.PI * 1.25, true);
                ctx.stroke();
                poly([15, 3.5, 9.8, 6.6, 15, 9.2], true, true);
                break;
            case "zoom-in":
                circle(10.5, 10.5, 5.7, false);
                line(14.8, 14.8, 20, 20);
                line(10.5, 7.9, 10.5, 13.1);
                line(7.9, 10.5, 13.1, 10.5);
                break;
            case "zoom-out":
                circle(10.5, 10.5, 5.7, false);
                line(14.8, 14.8, 20, 20);
                line(7.9, 10.5, 13.1, 10.5);
                break;
            case "fit":
                poly([9, 4, 4, 4, 4, 9], false, false);
                poly([15, 4, 20, 4, 20, 9], false, false);
                poly([9, 20, 4, 20, 4, 15], false, false);
                poly([15, 20, 20, 20, 20, 15], false, false);
                break;
            case "rotate-left":
                ctx.beginPath();
                ctx.arc(12, 12, 7, -Math.PI * 0.15, Math.PI * 1.35, false);
                ctx.stroke();
                poly([5.8, 9.4, 5.3, 3.6, 10.6, 5.7], true, true);
                break;
            case "rotate-right":
                ctx.beginPath();
                ctx.arc(12, 12, 7, Math.PI * 0.85, -Math.PI * 0.35, true);
                ctx.stroke();
                poly([18.2, 9.4, 18.7, 3.6, 13.4, 5.7], true, true);
                break;
            case "volume":
                poly([4, 9, 8, 9, 12, 5, 12, 19, 8, 15, 4, 15], true, true);
                ctx.beginPath();
                ctx.arc(13.5, 12, 3.5, -Math.PI * 0.45, Math.PI * 0.45, false);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(13.5, 12, 6.5, -Math.PI * 0.42, Math.PI * 0.42, false);
                ctx.stroke();
                break;
            case "mute":
                poly([3, 9, 7, 9, 11, 5, 11, 19, 7, 15, 3, 15], true, true);
                line(15, 9, 21, 15);
                line(21, 9, 15, 15);
                break;
            case "ellipsis":
                circle(5.5, 12, 1.6, true);
                circle(12, 12, 1.6, true);
                circle(18.5, 12, 1.6, true);
                break;
            case "folder":
                poly([3, 8, 3, 18.5, 21, 18.5, 21, 7, 12, 7, 10, 4.5, 5, 4.5, 3, 6], true, false);
                break;
            case "image":
                ctx.beginPath();
                ctx.rect(3, 4.5, 18, 15);
                ctx.stroke();
                circle(8.2, 9.2, 1.4, true);
                poly([4.5, 17.5, 9.5, 12.5, 13.2, 16.2, 15.5, 13.6, 19.5, 17.5], false, false);
                break;
            case "video":
                ctx.beginPath();
                ctx.rect(3, 5, 18, 14);
                ctx.stroke();
                poly([10, 9, 15.5, 12, 10, 15], true, true);
                break;
            case "check":
                poly([4.5, 12, 9.5, 17, 19.5, 6.5], false, false);
                break;
            case "external":
                poly([13, 4, 20, 4, 20, 11], false, false);
                line(20, 4, 11, 13);
                poly([18, 14, 18, 20, 4, 20, 4, 6, 10, 6], false, false);
                break;
            case "copy":
                ctx.beginPath();
                ctx.rect(8, 8, 12, 12);
                ctx.stroke();
                poly([16, 5, 4, 5, 4, 17], false, false);
                break;
            case "trash":
                line(4, 6.5, 20, 6.5);
                poly([9, 6.5, 9, 4, 15, 4, 15, 6.5], false, false);
                poly([6, 6.5, 7, 20, 17, 20, 18, 6.5], false, false);
                line(10, 10, 10, 16.5);
                line(14, 10, 14, 16.5);
                break;
            case "sun":
                circle(12, 12, 4, false);
                for (let i = 0; i < 8; ++i) {
                    const angle = i * Math.PI / 4;
                    line(12 + Math.cos(angle) * 7, 12 + Math.sin(angle) * 7, 12 + Math.cos(angle) * 9.5, 12 + Math.sin(angle) * 9.5);
                }
                break;
            case "appearance":
                circle(12, 12, 8, false);
                ctx.beginPath();
                ctx.arc(12, 12, 8, -Math.PI / 2, Math.PI / 2, false);
                ctx.closePath();
                ctx.fill();
                break;
            case "moon":
                ctx.beginPath();
                ctx.arc(13.2, 11.2, 6.5, Math.PI * 0.35, Math.PI * 1.55, false);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(18.5, 4.5, 5.2, 0, Math.PI * 2, false);
                ctx.fill();
                break;
            case "stop":
                ctx.fillRect(6, 6, 12, 12);
                break;
            case "loop":
                ctx.beginPath();
                ctx.arc(12, 12, 7, -Math.PI * 0.1, Math.PI * 1.45, false);
                ctx.stroke();
                poly([17.2, 5.4, 17.4, 10.1, 12.8, 9.2], true, true);
                break;
            case "speed":
                circle(12, 12, 8.5, false);
                line(12, 12, 16.5, 8.2);
                circle(12, 12, 1.2, true);
                break;
            case "file":
                poly([5, 3, 14, 3, 19, 8, 19, 21, 5, 21], true, false);
                poly([14, 3, 14, 8, 19, 8], false, false);
                break;
            case "home":
                poly([3, 11, 12, 3, 21, 11], false, false);
                poly([5.5, 9.5, 5.5, 20, 18.5, 20, 18.5, 9.5], false, false);
                poly([10, 20, 10, 14, 14, 14, 14, 20], false, false);
                break;
            case "desktop":
                ctx.beginPath();
                ctx.rect(3, 4, 18, 12);
                ctx.stroke();
                line(9, 20, 15, 20);
                line(12, 16, 12, 20);
                break;
            case "document":
                poly([5, 3, 14, 3, 19, 8, 19, 21, 5, 21], true, false);
                poly([14, 3, 14, 8, 19, 8], false, false);
                line(8, 12, 16, 12);
                line(8, 15, 16, 15);
                line(8, 18, 13, 18);
                break;
            case "download":
                line(12, 3, 12, 15);
                poly([8, 11, 12, 15, 16, 11], false, false);
                poly([4, 17, 4, 21, 20, 21, 20, 17], false, false);
                break;
            case "music":
                ctx.beginPath();
                ctx.arc(8, 17, 3, 0, Math.PI * 2, false);
                ctx.stroke();
                line(11, 17, 11, 5);
                line(11, 5, 19, 3);
                line(19, 3, 19, 13);
                ctx.beginPath();
                ctx.arc(16, 13, 3, 0, Math.PI * 2, false);
                ctx.stroke();
                break;
            case "computer":
                ctx.beginPath();
                ctx.rect(3, 5, 18, 12);
                ctx.stroke();
                line(7, 20, 17, 20);
                line(12, 17, 12, 20);
                break;
            case "crop":
                poly([7, 3, 7, 17, 21, 17], false, false);
                poly([3, 7, 17, 7, 17, 21], false, false);
                break;
            case "trim":
                circle(8, 17, 2.4, false);
                circle(8, 7, 2.4, false);
                line(10, 8, 20, 17);
                line(10, 16, 20, 7);
                break;
            case "dot":
                circle(12, 12, 3.5, true);
                break;
            case "minus":
                line(5, 12, 19, 12);
                break;
            case "plus":
                line(12, 5, 12, 19);
                line(5, 12, 19, 12);
                break;
            default:
                circle(12, 12, 7, false);
                break;
            }
            ctx.restore();
        }
    }

    function requestPaint() {
        canvas.requestPaint();
    }
}
