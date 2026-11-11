pragma Singleton

import QtQuick

QtObject {
    id: root

    // The desktop shell owns the session appearance. Preview follows it and
    // falls back to dark, which is the default Clavis look on this machine.
    property bool dark: true

    property string fontFamily: "Noto Sans"
    readonly property int windowRadius: 14
    readonly property int titlebarHeight: 52
    readonly property int controlRadius: 8

    readonly property color textPrimary: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textSecondary: dark ? "#a1a1a6" : "#6e6e73"
    readonly property color textTertiary: dark ? "#6e6e73" : "#8e8e93"
    property color systemAccent: "transparent"
    readonly property color accent: systemAccent.a > 0 ? systemAccent : (dark ? "#0a84ff" : "#007aff")
    readonly property color danger: "#ff453a"
    readonly property color success: "#30d158"

    readonly property color windowBg: dark ? Qt.rgba(0.075, 0.075, 0.09, 1) : Qt.rgba(0.96, 0.96, 0.97, 1)
    readonly property color windowBorder: dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color titlebarBg: dark ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(0, 0, 0, 0.025)
    readonly property color sidebarBg: dark ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(0, 0, 0, 0.035)
    readonly property color stageBg: dark ? "#101014" : "#f2f2f5"
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.09)

    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.055)
    readonly property color pressed: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color selection: dark ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(0, 0, 0, 0.075)
    readonly property color thumbBg: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06)

    readonly property color glassBg: dark ? Qt.rgba(0.14, 0.14, 0.16, 0.88) : Qt.rgba(1, 1, 1, 0.82)
    readonly property color glassBorder: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.11)
    readonly property color controlBg: dark ? Qt.rgba(1, 1, 1, 0.075) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color controlHover: dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.085)
    readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color knob: "#ffffff"

    readonly property color trafficRed: "#ff5f57"
    readonly property color trafficYellow: "#febc2e"
    readonly property color trafficGreen: "#28c840"

    function alpha(color, value) {
        return Qt.rgba(color.r, color.g, color.b, value);
    }
}
