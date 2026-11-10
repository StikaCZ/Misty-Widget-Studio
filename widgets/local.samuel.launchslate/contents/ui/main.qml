import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
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
implicitWidth: 420
    implicitHeight: 215
    Layout.minimumWidth: 225
    Layout.minimumHeight: 155
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    readonly property int pad: Math.max(12, Math.min(18, width * 0.042))
    readonly property bool compact: width < 320 || height < 190
    readonly property string script: Qt.resolvedUrl("../scripts/launch.sh").toString().replace("file://", "")
    property string statusLine: "READY"
    readonly property var entries: [
        {name:"APPS",icon:"system-search",cmd:"search"},
        {name:"BROWSER",icon:"internet-web-browser",cmd:"browser"},
        {name:"FILES",icon:"system-file-manager",cmd:"files"},
        {name:"STEAM",icon:"steam",cmd:"steam"},
        {name:"BLENDER",icon:"blender",cmd:"blender"},
        {name:"TERMINAL",icon:"utilities-terminal",cmd:"terminal"}
    ]
    function launch(cmd) {
        root.statusLine = "OPENING " + cmd.toUpperCase()
        actions.connectSource('bash "' + root.script + '" ' + cmd)
    }
    P5Support.DataSource {
        id: actions; engine: "executable"
        onNewData: function(name, data) {
            root.statusLine = Number(data["exit code"]) === 0 ? "READY" : "APP NOT FOUND"
            disconnectSource(name)
        }
    }
    Rectangle {
        anchors.fill: parent; radius: 7; color: studioPalette.panel(root.studioMode === "glass" ? "transparent" : root.studioColor("#DA1B2026"))
        border.width: root.studioMode === "glass" ? 0 : 1; border.color: studioPalette.outline(root.studioColor("#657A838D"))
    }
    Rectangle { x: root.pad; y: 14; width: 3; height: 18; radius: 2; color: studioPalette.paint(root.studioColor("#DAE1E6"), "text") }
    Text {
        x: root.pad + 12; y: 14
        text: "APPLICATIONS / LAUNCH"
        color: studioPalette.paint(root.studioColor("#F2F4F6"), "text"); font.bold: true; font.pixelSize: compact ? 11 : 13
        font.family: root.studioFont("JetBrains Mono")
    }
    Text {
        anchors.right: parent.right; anchors.rightMargin: root.pad; y: 17
        text: root.statusLine
        color: studioPalette.paint(root.studioColor("#9CAAB4"), "muted"); font.family: root.studioFont("JetBrains Mono"); font.pixelSize: Math.max(8,Math.round(9*root.studioTextScale))
        visible: !root.compact
    }
    Rectangle { x: root.pad; y: 42; width: parent.width - 2*root.pad; height: 1; color: studioPalette.paint(root.studioColor("#3BFFFFFF"), "text") }
    Grid {
        id: grid
        x: root.pad; y: 53; width: root.width - 2*root.pad
        columns: 3
        spacing: root.compact ? 6 : 8
        readonly property real tileW: (width - spacing * (columns-1)) / columns
        readonly property real tileH: Math.max(39, (root.height - 69 - spacing) / 2)
        Repeater {
            model: root.entries
            delegate: Rectangle {
                id: tile
                required property var modelData
                width: grid.tileW; height: grid.tileH
                radius: 6; color: hover.containsMouse ? "#36414B" : "#2A3036"
                border.width: 1; border.color: hover.containsMouse ? "#A8B5BC" : "#4A59636C"
                Behavior on color { ColorAnimation { duration: 140 } }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Kirigami.Icon {
                        source: tile.modelData.icon
                        width: root.compact ? 16 : 22
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: tile.modelData.name
                        color: studioPalette.paint(root.studioColor("#EDF2F5"), "text")
                        font.family: root.studioFont("JetBrains Mono"); font.pixelSize: root.compact ? 9 : 11
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: hover; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(tile.modelData.cmd)
                }
            }
        }
    }
}
