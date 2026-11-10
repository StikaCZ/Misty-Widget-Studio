import QtQuick
import "TerminalFrames.js" as Art

// All characters are genuine monospaced text glyphs, not raster images.
// Pupils belong to the artwork's fifth colour layer and animate with the eyes.
Item {
    id: pet
    ThemePalette { id: studioPalette }
    property string species: "penguin"
    property string action: "idle"
    property real elapsedMs: 0
    property int direction: 1
    property color ink: "#A7BEAD"
    property real textScale: 1.0
    clip: true

    readonly property var speciesFrames: Art.artBook[species] || Art.artBook.penguin
    readonly property var activeFrames: speciesFrames[action] || speciesFrames.idle
    readonly property real frameMs: action === "walk" ? 125
        : action === "special" ? 160 : action === "play" ? 160
        : action === "blink" ? 145 : action === "look" ? 240
        : action === "sleep" ? 550 : 300
    readonly property int frameNo: Math.floor(Math.max(0, elapsedMs) / frameMs) % Math.max(1, activeFrames.length)
    readonly property var picture: activeFrames[frameNo]
    // Fixed glyph grid, same scale and baseline for every character and action.
    readonly property real fontPx: Math.max(4, Math.floor(Math.min(16, width / 11.2, height / 9.9) * textScale))
    readonly property real artWidth: 18 * fontPx * 0.61
    readonly property real artHeight: 9 * fontPx * 1.0
    readonly property real artX: Math.max(0, (width - artWidth) / 2)
    readonly property real artY: Math.max(0, (height - artHeight) / 2)

    readonly property var palette: studioPalette.custom
        // Keep the pupil dark and legible even when custom colours are used.
        ? [studioPalette.mutedColour, studioPalette.accentColour,
           studioPalette.textColour, studioPalette.secondaryColour, "#11171A"]
        : species === "penguin"
        ? ["#323C44", "#ABBAC0", "#ECF0E9", "#E6AC4D", "#161B20"]
        : species === "gecko"
        ? ["#836E4C", "#CBB784", "#F2E8CE", "#E69AAA", "#1F2522"]
        : species === "slime"
        ? ["#3974A3", "#64BEDD", "#C3EDF0", "#F4C7A5", "#223952"]
        : ["#A66376", "#F2EEEA", "#8EAECF", "#FFFFFF", "#1A2331"]

    Repeater {
        model: 5
        delegate: Text {
            // All five layers share the exact same dimensions and origin.
            x: pet.artX
            y: pet.artY
            width: pet.artWidth
            height: pet.artHeight
            text: pet.picture && pet.picture[index] ? pet.picture[index] : ""
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            font.family: "DejaVu Sans Mono"
            font.pixelSize: pet.fontPx
            font.kerning: false
            font.hintingPreference: Font.PreferFullHinting
            lineHeight: 1.0
            lineHeightMode: Text.ProportionalHeight
            color: pet.palette[index]
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
        }
    }
}
