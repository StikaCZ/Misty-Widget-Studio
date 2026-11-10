import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    ThemePalette { id: studioPalette }

    // The legacy widgetOpacity setting now affects backgrounds only. Foreground stays fully visible.
    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

    id: root

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

    implicitWidth: 325
    implicitHeight: 220
    Layout.minimumWidth: 145
    Layout.minimumHeight: 100
    Layout.preferredWidth: 325
    Layout.preferredHeight: 220
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    toolTipMainText: "Pink Code Rain"
    toolTipSubText: paused ? "Paused • Click to resume" : "Click to pause • Right-click to configure"

    property string palette: Plasmoid.configuration.palette || "rose"
    property string customAccent: Plasmoid.configuration.customAccent || "#d597bd"
    property string customBackground: Plasmoid.configuration.customBackground || "#111423"
    property int backgroundOpacity: Plasmoid.configuration.backgroundOpacity === undefined ? 94 : Plasmoid.configuration.backgroundOpacity
    property int glyphOpacity: Plasmoid.configuration.glyphOpacity === undefined ? 90 : Plasmoid.configuration.glyphOpacity
    property int fontSize: Plasmoid.configuration.fontSize || 8
    property int cornerRadius: Plasmoid.configuration.cornerRadius === undefined ? 6 : Plasmoid.configuration.cornerRadius
    property bool showBorder: Plasmoid.configuration.showBorder === true
    property int speed: Plasmoid.configuration.speed || 3
    property int density: Plasmoid.configuration.density === undefined ? 85 : Plasmoid.configuration.density
    property int trailLength: Plasmoid.configuration.trailLength || 13
    property bool lowPower: Plasmoid.configuration.lowPower !== false
    property bool pauseWhenHidden: Plasmoid.configuration.pauseWhenHidden !== false
    property bool brightHeads: Plasmoid.configuration.brightHeads !== false
    property bool paused: false

    function validatedHex(value, fallback) {
        const s = String(value || "")
        return /^#[0-9a-fA-F]{6}$/.test(s) ? s : fallback
    }
    readonly property string nativeInkHex: palette === "custom" ? validatedHex(customAccent, "#d597bd")
                                       : palette === "ice" ? "#9bcadd"
                                       : palette === "violet" ? "#a7a0e9"
                                       : palette === "matrix" ? "#85d3a5"
                                       : palette === "mono" ? "#c7cbd4" : "#d597bd"
    readonly property string nativeBackgroundHex: palette === "custom" ? validatedHex(customBackground,"#111423")
                                              : palette === "ice" ? "#101c23"
                                              : palette === "violet" ? "#151320"
                                              : palette === "matrix" ? "#0b1511"
                                              : palette === "mono" ? "#14171b" : "#111423"

    readonly property string inkHex: studioPalette.custom ? studioPalette.accentColour.toString() : nativeInkHex
    readonly property string backgroundHex: studioPalette.custom ? studioPalette.surfaceColour.toString() : nativeBackgroundHex

    function rgb(hex) {
        const h = validatedHex(hex, "#d597bd").slice(1)
        return { r: parseInt(h.slice(0, 2), 16),
                 g: parseInt(h.slice(2, 4), 16),
                 b: parseInt(h.slice(4, 6), 16) }
    }
    function rgba(color, alpha) {
        return "rgba(" + color.r + "," + color.g + "," + color.b + "," + Math.max(0, Math.min(1, alpha)) + ")"
    }

    onFontSizeChanged: rainfall.reset()
    onDensityChanged: rainfall.reset()
    onTrailLengthChanged: rainfall.reset()
    onInkHexChanged: rainfall.requestPaint()
    onGlyphOpacityChanged: rainfall.requestPaint()
    onBrightHeadsChanged: rainfall.requestPaint()

    fullRepresentation: Item {

        StudioGlass {
            anchors.fill: parent
            visible: root.studioMode === "glass"
            z: 0
            tintColor: studioPalette.paint(root.mistyGlassTint, "accent")
            alphaPercent: root.studioGlassOpacity
            blurStrength: Plasmoid.configuration.glassBlur ?? 45
            radiusSize: root.studioCornerRadius
        }
id: stage
        Layout.minimumWidth: 145
        Layout.minimumHeight: 100
        Layout.preferredWidth: 325
        Layout.preferredHeight: 220

        Rectangle {
            id: back
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.studioMode === "glass" ? "transparent" : studioPalette.custom ? studioPalette.panel("#111423") : Qt.rgba(root.rgb(root.backgroundHex).r / 255,
                           root.rgb(root.backgroundHex).g / 255,
                           root.rgb(root.backgroundHex).b / 255,
                           root.backgroundOpacity * Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100)) / 100)
            border.color: root.studioMode === "glass" ? "transparent" : root.showBorder ? Qt.rgba(0.75, 0.70, 0.78, 0.20) : "transparent"
            border.width: root.studioMode === "glass" ? 0 : root.showBorder ? 1 : 0
            clip: true

            Canvas {
                id: rainfall
                anchors.fill: parent
                anchors.margins: root.showBorder ? 1 : 0
                antialiasing: false
                property var streams: []
                property int cycle: 0
                readonly property int cellWidth: Math.max(9, root.fontSize + 4)
                readonly property int cellHeight: Math.max(11, root.fontSize + 5)
                readonly property int totalCols: Math.max(1, Math.min(65, Math.floor(width / cellWidth)))
                readonly property int totalRows: Math.max(1, Math.min(55, Math.floor(height / cellHeight)))
                readonly property string letters: "0123456789ABCDEFHIJKMNOPRSTUVWXYZ@#$%&*:;?+"

                function rnd(a, b) { return a + Math.random() * (b - a) }
                function glyph() { return letters.charAt(Math.floor(Math.random() * letters.length)) }
                function reset() {
                    if (width < 10 || height < 10)
                        return
                    const result = []
                    const ratio = Math.max(0.15, Math.min(1, root.density / 100))
                    for (let c = 0; c < totalCols; c++) {
                        if (Math.random() > ratio) continue
                        const len = Math.max(4, Math.floor(root.trailLength * rnd(0.55, 1.65)))
                        const glyphs = []
                        for (let i = 0; i < Math.max(40, len + 8); i++) glyphs.push(glyph())
                        result.push({column: c, head: rnd(0, totalRows + Math.min(7, len)),
                                     length: len, pace: rnd(0.35, 0.95), glyphs: glyphs})
                    }
                    if (result.length === 0) {
                        result.push({column: Math.floor(totalCols / 2), head: totalRows / 2,
                                     length: 10, pace: 0.65, glyphs: ["A","B","0","1","X","3","4","5","6","7","8","9"]})
                    }
                    streams = result
                    requestPaint()
                }
                function advance() {
                    cycle++
                    const next = streams
                    for (let i = 0; i < next.length; i++) {
                        const c = next[i]
                        c.head += c.pace * (0.62 + root.speed * 0.18)
                        if (c.head - c.length > totalRows) {
                            c.head = rnd(-c.length - 12, -1)
                            c.length = Math.max(4, Math.floor(root.trailLength * rnd(0.55, 1.65)))
                            c.pace = rnd(0.35, 0.95)
                        }
                        // Change one letter per stream, not every glyph, to avoid harsh flickering.
                        if (cycle % 3 === i % 3) {
                            const index = Math.floor(Math.random() * c.glyphs.length)
                            c.glyphs[index] = glyph()
                        }
                    }
                    requestPaint()
                }
                onWidthChanged: reset()
                onHeightChanged: reset()
                Component.onCompleted: reset()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.font = root.fontSize + "px monospace"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "top"
                    const ink = root.rgb(root.inkHex)
                    const highlight = {
                        r: Math.round(ink.r * 0.40 + 255 * 0.60),
                        g: Math.round(ink.g * 0.40 + 255 * 0.60),
                        b: Math.round(ink.b * 0.40 + 255 * 0.60)
                    }
                    const globalOpacity = Math.max(0, Math.min(1, root.glyphOpacity / 100))
                    for (let s = 0; s < streams.length; s++) {
                        const stream = streams[s]
                        const colX = (stream.column + 0.5) * cellWidth
                        for (let j = 0; j < stream.length; j++) {
                            const y = Math.floor(stream.head) - j
                            if (y < 0 || y >= totalRows) continue
                            const fade = 1 - j / Math.max(1, stream.length)
                            const light = j === 0 && root.brightHeads
                            const alpha = globalOpacity * (light ? 0.96 : (0.13 + 0.63 * fade))
                            ctx.fillStyle = root.rgba(light ? highlight : ink, alpha)
                            ctx.fillText(stream.glyphs[(y + stream.column * 7) % stream.glyphs.length],
                                         colX, y * cellHeight)
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.paused = !root.paused
            }
        }

        Timer {
            interval: root.lowPower ? (165 - root.speed * 11) : (110 - root.speed * 11)
            running: !root.paused && (!root.pauseWhenHidden || (stage.visible && root.visible))
                     && stage.width > 20 && stage.height > 20
            repeat: true
            onTriggered: rainfall.advance()
        }
    }
}
