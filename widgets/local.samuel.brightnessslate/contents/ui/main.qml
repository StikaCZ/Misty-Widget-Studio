import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    ThemePalette { id: studioPalette }

    // The legacy widgetOpacity setting now affects backgrounds only. Foreground stays fully visible.
    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

    id: root
    // Recolour only the rectangle fill; do not change Rectangle.opacity
    // because its text/Canvas/controls may be children.
    function fadeBackground(c) {
        const tint = Qt.lighter(c, 1.0)
        return Qt.rgba(tint.r, tint.g, tint.b, tint.a * Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100)))
    }

    // Style Studio Complete: user styles, no network access and no extra process.
    property string studioMode: Plasmoid.configuration.widgetStyle || "normal"
    property color studioAccent: studioPalette.paint(Plasmoid.configuration.accentColor || "#9FB6A2", "accent")
    property int studioGlassOpacity: Math.max(25, Math.min(98, Plasmoid.configuration.glassOpacity ?? 78))
    property int studioCornerRadius: Math.max(4, Math.min(30, Plasmoid.configuration.cornerRadius ?? 18))
    property real studioTextScale: Math.max(0.75, Math.min(1.5, (Plasmoid.configuration.textScale ?? 100) / 100.0))
    property bool studioLowPower: Plasmoid.configuration.lowPower === undefined ? true : Plasmoid.configuration.lowPower

    function studioColor(hex) {
        if (studioMode === "normal") return hex
        const text = String(hex).replace("#", "")
        if (text.length !== 6 && text.length !== 8) return hex
        let alpha = 1.0, v = text
        if (text.length === 8) { alpha = parseInt(text.slice(0,2),16)/255; v = text.slice(2) }
        const r = parseInt(v.slice(0,2),16)/255, g = parseInt(v.slice(2,4),16)/255, b = parseInt(v.slice(4,6),16)/255
        const lum = 0.2126*r + 0.7152*g + 0.0722*b
        if (studioMode === "glass") {
            if (lum < 0.35) return Qt.rgba(0.10, 0.16, 0.17, Math.max(0.1, alpha * studioGlassOpacity/100.0))
            if (lum < 0.67) return Qt.rgba(0.57, 0.71, 0.67, Math.max(0.25, alpha*0.72))
            return Qt.rgba(0.93,0.96,0.96,Math.max(0.55,alpha))
        }
        if (studioMode === "terminal") {
            if (lum < 0.35) return Qt.rgba(0.06,0.09,0.08,Math.max(0.35,alpha*0.96))
            if (lum < 0.67) return Qt.rgba(studioAccent.r*0.72,studioAccent.g*0.72,studioAccent.b*0.72,Math.max(0.4,alpha))
            return Qt.rgba(0.82,0.88,0.80,Math.max(0.64,alpha))
        }
        if (lum < 0.35) return Qt.rgba(0.10,0.12,0.12,Math.min(0.25,alpha*0.3))
        if (lum < 0.67) return Qt.rgba(0.60,0.67,0.63,Math.max(0.45,alpha))
        return Qt.rgba(0.87,0.91,0.88,Math.max(0.6,alpha))
    }
    function studioFont(original) { return studioMode === "terminal" ? "JetBrains Mono" : studioMode === "glass" ? "Noto Sans" : original }

        StudioGlass {
            anchors.fill: parent
            visible: root.studioMode === "glass"
            z: 0
            tintColor: studioPalette.paint(root.mistyGlassTint, "accent")
            alphaPercent: root.studioGlassOpacity
            blurStrength: Plasmoid.configuration.glassBlur ?? 45
            radiusSize: root.studioCornerRadius
        }
implicitWidth: 510
    implicitHeight: 205
    Layout.minimumWidth: 340
    Layout.minimumHeight: 152
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property int pad: Math.max(12, Math.min(18, width * 0.035))
    readonly property bool compact: height < 190
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/brightness.py").toString().replace("file://", "")
    property var displays: []
    property bool busy: false
    property bool pendingRefresh: false
    property var queuedSet: null
    property string runningCommand: ""
    property string notice: "Connecting to KDE PowerDevil…"
    readonly property color fg: studioPalette.paint(root.studioColor("#F2F5F7"), "text")
    readonly property color muted: studioPalette.paint(root.studioColor("#B3BDC5"), "muted")

    function runCmd(command) {
        if (busy) {
            pendingRefresh = true
            return
        }
        busy = true
        runningCommand = command
        cmdWatchdog.restart()
        api.connectSource(command)
    }
    function refresh() {
        runCmd('python3 "' + scriptPath + '" list')
    }
    function setPercent(display, percent) {
        if (!display || !(display.indexOf('kde:display') === 0 || display.indexOf('backlight:') === 0)) return
        const value = Math.max(5, Math.min(100, Math.round(percent)))
        if (busy) {
            queuedSet = { "display": display, "percent": value }
            return
        }
        runCmd('python3 "' + scriptPath + '" set ' + display + ' ' + value)
        pendingRefresh = true
    }
    function handleFinish() {
        busy = false
        cmdWatchdog.stop()
        if (queuedSet !== null) {
            deferredSet.restart()
        } else if (pendingRefresh) {
            pendingRefresh = false
            delayRefresh.restart()
        }
    }
    Component.onCompleted: refresh()

    P5Support.DataSource {
        id: api
        engine: "executable"
        connectedSources: []
        onNewData: function(name, data) {
            if (name !== root.runningCommand) return
            try {
                const parsed = JSON.parse(String(data["stdout"] || "").trim())
                if (parsed.displays !== undefined) {
                    root.displays = parsed.displays
                    root.notice = parsed.displays.length ? String(parsed.notice || "LIVE MONITORS") :
                                  String(parsed.notice || "No available brightness controls")
                } else if (parsed.success === false) {
                    root.notice = String(parsed.error || "Brightness change unavailable")
                }
            } catch(e) {
                root.notice = "Brightness helper failed; run it in Konsole for details"
            }
            api.disconnectSource(name)
            root.handleFinish()
        }
    }
    Timer {
        id: cmdWatchdog; interval: 30000; repeat: false
        onTriggered: {
            if (root.runningCommand !== "") api.disconnectSource(root.runningCommand)
            root.notice = "Brightness helper timed out. Check KDE PowerDevil."
            root.handleFinish()
        }
    }
    Timer {
        id: deferredSet; interval: 100; repeat: false
        onTriggered: {
            if (root.queuedSet !== null) {
                const pending = root.queuedSet
                root.queuedSet = null
                root.setPercent(pending.display, pending.percent)
            }
        }
    }
    Timer { id: delayRefresh; interval: 800; repeat: false; onTriggered: root.refresh() }
    Timer { interval: 12000; running: true; repeat: true; onTriggered: if (!root.busy) root.refresh() }

    Rectangle {
        anchors.fill: parent; radius: 7; color: studioPalette.panel(root.studioMode === "glass" ? "transparent" : root.studioColor("#DA1B2026"))
        border.width: root.studioMode === "glass" ? 0 : 1; border.color: studioPalette.outline(root.studioColor("#657A838D"))
    }
    Rectangle { x: root.pad; y: 14; width: 3; height: 17; radius: 2; color: studioPalette.paint(root.studioColor("#D8DEE3"), "text") }
    Text {
        x: root.pad + 12; y: 14
        text: "DISPLAY / LIGHT"
        color: root.fg; font.family: root.studioFont("JetBrains Mono"); font.bold: true; font.pixelSize: Math.max(8,Math.round(13*root.studioTextScale))
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: root.pad; y: 17
        text: root.displays.length ? "● LIVE" : "○ CHECK"
        color: root.displays.length ? "#B3C7BD" : "#A8B0B8"
        font.family: root.studioFont("JetBrains Mono"); font.pixelSize: Math.max(8,Math.round(9*root.studioTextScale))
    }
    Rectangle { x: root.pad; y: 42; width: parent.width - 2*root.pad; height: 1; color: studioPalette.paint(root.studioColor("#3BFFFFFF"), "text") }

    Column {
        id: slots
        x: root.pad; y: root.compact ? 49 : 57
        width: parent.width - 2*root.pad
        spacing: root.compact ? 8 : 15
        Repeater {
            model: root.displays.slice(0, 2)
            delegate: Item {
                id: monitorRow
                required property var modelData
                width: slots.width
                height: root.compact ? 44 : 53
                readonly property int originalPercent: modelData.percent
                Rectangle {
                    anchors.fill: parent; color: studioPalette.paint(root.studioColor("#262C33"), "surface"); radius: 5
                    border.color: studioPalette.paint(root.studioColor("#304E5861"), "border"); border.width: 1
                }
                Text {
                    id: screenName
                    x: 10; y: 5; width: parent.width - 100
                    text: modelData.label
                    elide: Text.ElideRight; color: root.fg
                    font.family: root.studioFont("JetBrains Mono"); font.bold: true; font.pixelSize: root.compact ? 10 : 12
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12; y: 5
                    text: Math.round(level.value) + "%"
                    color: studioPalette.paint(root.studioColor("#EBF1F5"), "text"); font.family: root.studioFont("JetBrains Mono"); font.bold: true
                    font.pixelSize: root.compact ? 11 : 13
                }
                Controls.Slider {
                    id: level
                    x: 9; y: root.compact ? 20 : 27
                    width: parent.width - 18; height: 20
                    from: 5; to: 100; stepSize: 1
                    value: monitorRow.originalPercent
                    // Apply only on release, preventing DDC/CI hardware spam.
                    onPressedChanged: if (!pressed) root.setPercent(monitorRow.modelData.id, value)
                    onValueChanged: {} // no hardware operation until released
                }
            }
        }
    }
    Text {
        visible: root.displays.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 75; width: parent.width - 36
        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
        text: root.notice + "\nRequires a monitor supported by KDE Brightness & Colour."
        color: root.muted; font.family: root.studioFont("JetBrains Mono"); font.pixelSize: Math.max(8,Math.round(11*root.studioTextScale))
    }
    Text {
        visible: root.height >= 220
        anchors.bottom: parent.bottom; anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        text: "KDE POWERDEVIL  /  PER-DISPLAY BRIGHTNESS"
        color: studioPalette.paint(root.studioColor("#7F909C"), "muted"); font.family: root.studioFont("JetBrains Mono"); font.pixelSize: Math.max(8,Math.round(9*root.studioTextScale))
    }
}
