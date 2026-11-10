import QtQuick
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
implicitWidth: 390
    implicitHeight: 288
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property bool sdkOnline: false
    property string lastResult: "Checking OpenRGB..."
    property string currentPreset: ""
    property string currentHex: "#FFFFFF"
    readonly property string script: Qt.resolvedUrl("../scripts/rgbctl.py").toString().replace("file://", "")
    readonly property string commandPrefix: "python3 \"" + script + "\" "

    function sendPreset(name, color) {
        if (!sdkOnline) {
            lastResult = "Start OpenRGB → SDK Server first"
            return
        }
        lastResult = "Applying " + name + "..."
        actions.connectSource(commandPrefix + "set " + name)
    }

    Rectangle {
        anchors.fill: parent
        radius: 19
        color: studioPalette.panel(root.studioMode === "glass" ? "transparent" : root.studioColor("#E91B1C1F"))
        border.width: root.studioMode === "glass" ? 0 : 1
        border.color: studioPalette.outline(root.studioColor("#686868"))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 17
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "RGB  /  CONTROL"
                color: studioPalette.paint(root.studioColor("#FFFFFF"), "text")
                font.family: root.studioFont("monospace")
                font.bold: true
                font.pixelSize: Math.max(8,Math.round(17*root.studioTextScale))
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 9
                color: root.sdkOnline ? "#363B38" : "#493A3A"
                implicitWidth: statusText.implicitWidth + 20
                height: 25
                Text { font.family: root.studioFont("Noto Sans"); 
                    id: statusText
                    anchors.centerIn: parent
                    text: root.sdkOnline ? "CONNECTED" : "OFFLINE"
                    color: studioPalette.paint(root.studioColor("#F4F4F4"), "text")
                    font.pixelSize: Math.max(8,Math.round(10*root.studioTextScale))
                    font.bold: true
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: studioPalette.paint(root.studioColor("#505257"), "surface") }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Item {
                Layout.preferredWidth: 86
                Layout.preferredHeight: 86
                Rectangle {
                    anchors.centerIn: parent
                    width: 80
                    height: 80
                    radius: 40
                    color: studioPalette.paint(root.studioColor("#151619"), "surface")
                    border.width: 5
                    border.color: root.currentHex
                }
                Text { font.family: root.studioFont("Noto Sans"); 
                    anchors.centerIn: parent
                    text: "RGB"
                    color: studioPalette.paint(root.studioColor("#F1F1F1"), "text")
                    font.bold: true
                    font.pixelSize: Math.max(8,Math.round(18*root.studioTextScale))
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { font.family: root.studioFont("Noto Sans");  text: "MOTHERBOARD + FAN LIGHTS"; color: studioPalette.paint(root.studioColor("#ECECEC"), "text"); font.pixelSize: Math.max(8,Math.round(12*root.studioTextScale)); font.bold: true }
                Text { font.family: root.studioFont("Noto Sans");  text: "ASUS TUF A520M-PLUS WIFI"; color: studioPalette.paint(root.studioColor("#A7A9AD"), "text"); font.pixelSize: Math.max(8,Math.round(11*root.studioTextScale)) }
                Text { font.family: root.studioFont("Noto Sans");  text: root.currentPreset === "" ? "Choose a colour preset" : "Last applied: " + root.currentPreset.toUpperCase(); color: studioPalette.paint(root.studioColor("#CECECE"), "text"); font.pixelSize: Math.max(8,Math.round(11*root.studioTextScale)) }
                Text { font.family: root.studioFont("Noto Sans");  text: "Keyboard excluded"; color: studioPalette.paint(root.studioColor("#909397"), "muted"); font.pixelSize: Math.max(8,Math.round(10*root.studioTextScale)) }
            }
        }

        Text { font.family: root.studioFont("Noto Sans");  text: "COLOUR PRESETS"; color: studioPalette.paint(root.studioColor("#A8ADB3"), "text"); font.pixelSize: Math.max(8,Math.round(10*root.studioTextScale)); font.bold: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    {"name": "white", "label": "WHITE", "hex": "#FFFFFF"},
                    {"name": "ice", "label": "ICE", "hex": "#B8D9FF"},
                    {"name": "grey", "label": "GREY", "hex": "#727272"},
                    {"name": "purple", "label": "PURPLE", "hex": "#895EFF"},
                    {"name": "pink", "label": "PINK", "hex": "#FF90BA"},
                    {"name": "off", "label": "OFF", "hex": "#0B0B0B"}
                ]
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 40
                        height: 36
                        radius: 9
                        color: modelData.hex
                        border.width: root.currentPreset === modelData.name ? 3 : 1
                        border.color: root.currentPreset === modelData.name ? "#FFFFFF" : "#666666"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sendPreset(modelData.name, modelData.hex)
                        }
                    }
                    Text { font.family: root.studioFont("Noto Sans"); 
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        color: studioPalette.paint(root.studioColor("#BCBCBC"), "text")
                        font.pixelSize: Math.max(8,Math.round(9*root.studioTextScale))
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
        Text { font.family: root.studioFont("Noto Sans"); 
            Layout.fillWidth: true
            text: root.lastResult
            color: studioPalette.paint(root.studioColor("#C3C5C9"), "text")
            font.pixelSize: Math.max(8,Math.round(11*root.studioTextScale))
            elide: Text.ElideRight
        }
    }

    P5Support.DataSource {
        id: status
        engine: "executable"
        connectedSources: [root.commandPrefix + "check"]
        interval: 12000
        onNewData: (source, data) => {
            const output = (data["stdout"] || "").trim()
            root.sdkOnline = output.startsWith("ONLINE")
            if (!root.sdkOnline) root.lastResult = output || "OpenRGB SDK server unavailable"
            else if (root.lastResult.startsWith("Checking") || root.lastResult.startsWith("ERROR") || root.lastResult.startsWith("OpenRGB"))
                root.lastResult = "Ready · choose a colour"
        }
    }

    P5Support.DataSource {
        id: actions
        engine: "executable"
        interval: 1000
        onNewData: (source, data) => {
            const output = (data["stdout"] || "").trim()
            root.lastResult = output || (data["stderr"] || "No response from OpenRGB").trim()
            if (output.startsWith("APPLIED")) {
                const name = source.substring(source.lastIndexOf(" ") + 1)
                root.currentPreset = name
                if (name === "white") root.currentHex = "#FFFFFF"
                else if (name === "ice") root.currentHex = "#B8D9FF"
                else if (name === "grey") root.currentHex = "#727272"
                else if (name === "purple") root.currentHex = "#895EFF"
                else if (name === "pink") root.currentHex = "#FF90BA"
                else if (name === "off") root.currentHex = "#111111"
            }
            actions.disconnectSource(source)
        }
    }
}
