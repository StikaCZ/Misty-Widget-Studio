import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    ThemePalette { id: studioPalette }

    id: root
    // Recolour only the rectangle fill; do not change Rectangle.opacity
    // because its text/Canvas/controls may be children.
    function fadeBackground(c) {
        const tint = Qt.lighter(c, 1.0)
        return Qt.rgba(tint.r, tint.g, tint.b, tint.a * Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100)))
    }
    clip: true

    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

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
            if (lum < 0.35) return Qt.rgba(0.08, 0.12, 0.15, Math.max(0.08, alpha * 0.35))
            if (lum < 0.67) return Qt.rgba(0.78, 0.84, 0.87, Math.max(0.18, alpha * 0.70))
            return Qt.rgba(0.96, 0.98, 1.00, Math.max(0.70, alpha))
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

    implicitWidth: 420
    implicitHeight: 330
    Layout.minimumWidth: 230
    Layout.minimumHeight: 160
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    readonly property int pad: Math.max(13, Math.min(19, width * 0.045))
    readonly property int topBandHeight: studioMode === "glass" ? 48 : 44
    readonly property int contentTop: studioMode === "glass" ? 60 : 55
    property string saveMessage: "AUTO-SAVE"

    StudioGlass {
        anchors.fill: parent
        visible: root.studioMode === "glass"
        z: 0
        tintColor: studioPalette.paint(root.mistyGlassTint, "accent")
        alphaPercent: root.studioGlassOpacity
        blurStrength: Plasmoid.configuration.glassBlur ?? 45
        radiusSize: root.studioCornerRadius
    }

    Rectangle {
        anchors.fill: parent
        visible: root.studioMode !== "glass"
        radius: 7
        color: studioPalette.panel(root.studioColor("#DA1B2026"))
        border.width: root.studioMode === "glass" ? 0 : 1; border.color: studioPalette.outline(root.studioColor("#657A838D"))
    }

    Rectangle {
        x: root.pad
        y: studioMode === "glass" ? 17 : 15
        width: 3
        height: studioMode === "glass" ? 16 : 18
        radius: 2
        color: root.studioMode === "glass" ? studioPalette.paint("#F3F8FF", "text") : root.studioColor("#DAE1E6")
        opacity: root.studioMode === "glass" ? 0.85 : 1.0
    }

    Text {
        x: root.pad + 12
        y: studioMode === "glass" ? 15 : 15
        text: "NOTES / DESK"
        color: root.studioMode === "glass" ? studioPalette.paint("#F7FBFF", "text") : root.studioColor("#F3F5F8")
        font.family: root.studioFont("JetBrains Mono")
        font.pixelSize: Math.max(8, Math.round((studioMode === "glass" ? 12 : 13) * root.studioTextScale))
        font.bold: true
        z: 2
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: studioMode === "glass" ? 17 : 18
        text: "● " + root.saveMessage
        color: root.studioMode === "glass" ? studioPalette.paint("#EEF5FF", "text") : root.studioColor("#BAC6CE")
        font.family: root.studioFont("JetBrains Mono")
        font.pixelSize: Math.max(8, Math.round(9 * root.studioTextScale))
        z: 2
    }

    Rectangle {
        x: root.pad
        y: root.topBandHeight
        width: root.width - 2 * root.pad
        height: 1
        color: root.studioMode === "glass" ? studioPalette.paint("#35FFFFFF", "border") : root.studioColor("#3BFFFFFF")
        visible: root.studioMode !== "minimal" && root.studioMode !== "glass"
    }

    Rectangle {
        x: root.pad
        y: root.contentTop
        width: root.width - 2 * root.pad
        height: Math.max(50, root.height - (root.contentTop + 36))
        radius: root.studioMode === "glass" ? Math.max(8, root.studioCornerRadius - 4) : 5
        color: root.fadeBackground(root.studioMode === "glass" ? "#1409111D" : root.studioColor("#3A10151A"))
        border.width: 1
        border.color: root.studioMode === "glass" ? "transparent" : root.studioColor("#235F707D")
        z: 1
    }

    Controls.ScrollView {
        id: scroll
        x: root.pad + 8
        y: root.contentTop + 7
        width: root.width - 2 * root.pad - 16
        height: Math.max(34, root.height - (root.contentTop + 51))
        clip: true
        z: 2
        Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
        Controls.TextArea {
            id: editor
            text: Plasmoid.configuration.noteText
            wrapMode: TextEdit.Wrap
            font.family: root.studioFont("JetBrains Mono")
            font.pixelSize: Math.max(12, Math.min(16, root.width * 0.036))
            color: root.studioMode === "glass" ? studioPalette.paint("#F1F6FF", "text") : root.studioColor("#EDF1F4")
            selectedTextColor: "#16191E"
            selectionColor: root.studioMode === "glass" ? "#A9C6FF" : "#B6C5CC"
            placeholderText: "Write something…\n\nTasks, ideas, reminders."
            placeholderTextColor: root.studioMode === "glass" ? "#B6C2D2" : undefined
            selectByMouse: true
            background: Item {}
            onTextChanged: { root.saveMessage = "EDITING"; saveDebounce.restart() }
        }
    }

    Timer {
        id: saveDebounce
        interval: 650
        repeat: false
        onTriggered: {
            if (Plasmoid.configuration.noteText !== editor.text)
                Plasmoid.configuration.noteText = editor.text
            root.saveMessage = "SAVED"
        }
    }

    Text {
        x: root.pad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: "LOCAL NOTE  /  " + editor.length + " CHARS"
        color: root.studioMode === "glass" ? studioPalette.paint("#D1DBEA", "muted") : root.studioColor("#8D9CA7")
        font.family: root.studioFont("JetBrains Mono")
        font.pixelSize: Math.max(8, Math.round(9 * root.studioTextScale))
        z: 2
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: "PRIVATE / ON DEVICE"
        color: root.studioMode === "glass" ? studioPalette.paint("#D1DBEA", "muted") : root.studioColor("#8D9CA7")
        font.family: root.studioFont("JetBrains Mono")
        font.pixelSize: Math.max(8, Math.round(9 * root.studioTextScale))
        z: 2
    }
}
