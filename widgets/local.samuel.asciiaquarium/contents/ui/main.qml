import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

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

    Layout.minimumWidth: 240
    Layout.minimumHeight: 160
    Layout.preferredWidth: root.widgetWidth
    Layout.preferredHeight: root.widgetHeight
    toolTipMainText: "ASCII Aquarium"
    toolTipSubText: "Left-click to pause or resume. Configure to adjust the aquarium."

    property int fishCount: Plasmoid.configuration.fishCount || 5
    property int motionSpeed: Plasmoid.configuration.motionSpeed || 2
    property string palette: Plasmoid.configuration.palette || "subtle"
    property bool showBubbles: Plasmoid.configuration.showBubbles === undefined ? true : Plasmoid.configuration.showBubbles
    property bool showSeaweed: Plasmoid.configuration.showSeaweed === undefined ? true : Plasmoid.configuration.showSeaweed
    property bool showWaves: Plasmoid.configuration.showWaves === undefined ? true : Plasmoid.configuration.showWaves
    property bool showJellyfish: Plasmoid.configuration.showJellyfish === undefined ? true : Plasmoid.configuration.showJellyfish
    property bool glassBackground: Plasmoid.configuration.glassBackground === undefined ? false : Plasmoid.configuration.glassBackground

    // Appearance. Separate colour channels are individually configurable.
    property color bgColor: studioPalette.paint(Plasmoid.configuration.bgColor || "#101518", "surface")
    property color headerColor: studioPalette.paint(Plasmoid.configuration.headerColor || "#1b2327", "muted")
    property color footerColor: studioPalette.paint(Plasmoid.configuration.footerColor || "#151c20", "muted")
    property color textColor: studioPalette.paint(Plasmoid.configuration.textColor || "#c2cbd0", "text")
    property color accentColor: studioPalette.paint(Plasmoid.configuration.accentColor || "#7aafb8", "accent")
    property color fishColor: studioPalette.paint(Plasmoid.configuration.fishColor || "#bddce0", "accent")
    property color plantColor: studioPalette.paint(Plasmoid.configuration.plantColor || "#739d83", "accent")
    property color borderColor: studioPalette.paint(Plasmoid.configuration.borderColor || "#384449", "border")
    property int bgOpacity: Math.max(0, Math.min(100, Plasmoid.configuration.bgOpacity ?? 100))
    property int borderOpacity: Math.max(0, Math.min(100, Plasmoid.configuration.borderOpacity ?? 100))
    property int contentOpacity: Math.max(0, Math.min(100, Plasmoid.configuration.contentOpacity ?? 100))
    property int widgetWidth: Math.max(240, Plasmoid.configuration.widgetWidth || 390)
    property int widgetHeight: Math.max(160, Plasmoid.configuration.widgetHeight || 255)
    property int cornerRadius: Math.max(0, Plasmoid.configuration.cornerRadius ?? 12)
    property int fontScale: Math.max(65, Math.min(160, Plasmoid.configuration.fontScale || 100))
    property bool showHeader: Plasmoid.configuration.showHeader === undefined ? true : Plasmoid.configuration.showHeader
    property bool showStatus: Plasmoid.configuration.showStatus === undefined ? true : Plasmoid.configuration.showStatus
    property bool monochromeFish: Plasmoid.configuration.monochromeFish === undefined ? false : Plasmoid.configuration.monochromeFish

    function alphaColour(c, percent) { return Qt.rgba(c.r, c.g, c.b, percent / 100.0) }
    readonly property color mainInk: studioPalette.paint(root.textColor, "muted")
    readonly property color dimInk: studioPalette.paint(palette === "mono" ? "#9caaad" : "#748b90", "muted")
    readonly property color accentInk: studioPalette.paint(root.accentColor, "accent")
    readonly property color weedInk: studioPalette.paint(root.plantColor, "muted")
    property var fishStates: []
    property var bubbleStates: []
    property int tickCount: 0
    property int viewportWidth: 350
    property int viewportHeight: 173
    property bool paused: false

    function rand(minimum, maximum) {
        return minimum + Math.random() * (maximum - minimum)
    }
    function fishText(kind, direction) {
        const goingRight = ["><(((o>", "><>", ">==o>", "><((((o>", ">-o>"]
        const goingLeft = ["<o)))><", "<><", "<o==<", "<o))))><", "<o-<"]
        return (direction > 0 ? goingRight : goingLeft)[kind % goingRight.length]
    }
    function fishInk(index) {
        if (studioPalette.custom) return root.fishColor
        if (monochromeFish) return fishColor
        if (palette === "mono")
            return index % 3 === 0 ? "#e0e3e5" : "#929b9f"
        if (palette === "classic")
            return ["#92d6b2", "#d5b78b", "#a1c8e4", "#b7bbdd", "#d09b9e"][index % 5]
        return ["#bddce0", "#a9b5b8", "#7ca4a8", "#c0c9bd", "#d0b4a4"][index % 5]
    }
    function seedFish() {
        let next = []
        const count = Math.max(1, Math.min(9, fishCount))
        for (let i = 0; i < count; i++) {
            next.push({
                x: rand(-10, Math.max(60, viewportWidth - 30)),
                depth: rand(0.12, 0.76),
                direction: Math.random() < 0.5 ? -1 : 1,
                kind: i % 5,
                pace: rand(0.65, 1.15),
                phase: rand(0, 6.28)
            })
        }
        fishStates = next
    }
    function seedBubbles() {
        let next = []
        for (let i = 0; i < 12; i++) {
            next.push({
                x: rand(8, Math.max(12, viewportWidth - 8)),
                y: rand(4, Math.max(20, viewportHeight - 10)),
                pace: rand(0.4, 0.9),
                phase: rand(0, 6.28)
            })
        }
        bubbleStates = next
    }
    function moveScene() {
        tickCount += 1
        const scale = motionSpeed === 1 ? 0.58 : (motionSpeed === 3 ? 1.52 : 1.0)
        let nextFish = []
        for (let i = 0; i < fishStates.length; i++) {
            const f = fishStates[i]
            let x = f.x + f.direction * f.pace * scale
            // Travel beyond the visible edge, then swim in again from the other side.
            if (x > viewportWidth + 14) x = -85
            if (x < -90) x = viewportWidth + 8
            nextFish.push({x: x, depth: f.depth, direction: f.direction,
                           kind: f.kind, pace: f.pace, phase: f.phase})
        }
        fishStates = nextFish
        if (showBubbles) {
            let nextBubbles = []
            for (let j = 0; j < bubbleStates.length; j++) {
                const b = bubbleStates[j]
                let y = b.y - b.pace * scale * 1.4
                let x = b.x
                if (y < -10) { y = viewportHeight + rand(0, 30); x = rand(8, Math.max(12, viewportWidth - 8)) }
                nextBubbles.push({x: x, y: y, pace: b.pace, phase: b.phase})
            }
            bubbleStates = nextBubbles
        }
    }
    onFishCountChanged: seedFish()
    Component.onCompleted: { seedFish(); seedBubbles() }

    // Plasma 6 root PlasmoidItem: do not set preferredRepresentation on a Rectangle.
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
id: panel
        Layout.minimumWidth: 240
        Layout.minimumHeight: 160
        Layout.preferredWidth: root.widgetWidth
        Layout.preferredHeight: root.widgetHeight

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: studioPalette.panel(root.studioMode === "glass" ? "transparent" : root.studioMode === "terminal" ? Qt.rgba(.035,.053,.048,.95) : root.alphaColour(root.bgColor, root.glassBackground ? Math.min(root.bgOpacity, 86) : root.bgOpacity))
            border.color: root.studioMode === "glass" ? "transparent" : studioPalette.outline(root.alphaColour(root.borderColor, root.borderOpacity))
            border.width: root.studioMode === "glass" ? 0 : 1
            clip: true

            Rectangle {
                id: topbar
                height: root.showHeader ? 31 : 0
                visible: root.showHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                color: studioPalette.custom ? "transparent" : root.fadeBackground(root.studioMode === "glass" ? "transparent" : root.alphaColour(root.headerColor, root.bgOpacity))
                radius: root.cornerRadius
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 12
                    color: parent.color
                }
                Row {
                    x: 13
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 7; height: 7; radius: 4
                            color: studioPalette.paint(index === 0 ? "#5b686d" : (index === 1 ? "#405055" : "#66777b"), "border")
                        }
                    }
                }
                Text {
                    x: 53
                    anchors.verticalCenter: parent.verticalCenter
                    text: "$ asciiquarium"
                    color: root.textColor
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 12 * root.fontScale / 100
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.paused ? "II  PAUSED" : ">  LIVE"
                    color: root.paused ? studioPalette.paint("#a3afb3", "muted") : root.accentInk
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 10 * root.fontScale / 100
                    font.bold: true
                }
            }

            Item {
                id: water
                anchors.top: topbar.bottom
                anchors.bottom: status.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 5
                anchors.bottomMargin: 3
                clip: true
                opacity: root.contentOpacity / 100.0
                onWidthChanged: root.viewportWidth = Math.max(40, width)
                onHeightChanged: root.viewportHeight = Math.max(40, height)

                Text {
                    visible: root.showWaves && root.studioMode !== "glass"
                    x: -20 + (root.tickCount % 9)
                    y: 0
                    text: "~~~  ~~~~~  ~~~  ~~~~~  ~~~  ~~~~~  ~~~  ~~~~~  ~~~  ~~~~~  ~~~~"
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 11 * root.fontScale / 100
                    color: root.accentInk
                    opacity: 0.52
                }

                Repeater {
                    model: root.showBubbles ? root.bubbleStates.length : 0
                    Text {
                        readonly property var bubble: root.bubbleStates[index] || ({x: 0, y: 0, phase: 0})
                        x: bubble.x + Math.sin(root.tickCount * 0.11 + bubble.phase) * 2
                        y: bubble.y
                        text: index % 4 === 0 ? "o" : "."
                        color: root.accentInk
                        opacity: index % 3 === 0 ? 0.45 : 0.26
                        font.family: root.studioFont("monospace")
                        font.pixelSize: (index % 4 === 0 ? 11 : 10) * root.fontScale / 100
                    }
                }

                Repeater {
                    model: root.fishStates.length
                    Text {
                        readonly property var fish: root.fishStates[index] || ({x: 0, depth: 0.3, direction: 1, kind: 0, phase: 0})
                        x: fish.x
                        y: Math.max(15, Math.min(water.height - 23,
                            13 + fish.depth * Math.max(20, water.height - 36)
                            + Math.sin(root.tickCount * 0.11 + fish.phase) * 2))
                        text: root.fishText(fish.kind, fish.direction)
                        textFormat: Text.PlainText
                        font.family: root.studioFont("monospace")
                        font.pixelSize: (fish.kind === 3 ? 14 : 13) * root.fontScale / 100
                        font.bold: fish.kind === 3
                        color: root.fishInk(index)
                        opacity: 0.93
                    }
                }

                Text {
                    visible: root.showJellyfish && water.width > 225 && water.height > 100
                    x: water.width * 0.78 + Math.sin(root.tickCount * 0.026) * 16
                    y: water.height * 0.22 + Math.sin(root.tickCount * 0.06) * 8
                    text: " .-.\n( o )\n )|( "
                    color: root.mainInk
                    opacity: 0.68
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 11 * root.fontScale / 100
                    lineHeight: 0.82
                }

                Text {
                    visible: root.showSeaweed
                    x: 22 + Math.sin(root.tickCount * 0.045) * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    text: "  (\n  )\n  (\n  )\n  ("
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 12 * root.fontScale / 100
                    lineHeight: 0.8
                    color: root.weedInk
                    opacity: 0.75
                }
                Text {
                    visible: root.showSeaweed && water.width > 290
                    x: water.width * 0.56 + Math.sin(root.tickCount * 0.038 + 1.2) * 2
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    text: " (\n )\n (\n )"
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 12 * root.fontScale / 100
                    lineHeight: 0.84
                    color: root.weedInk
                    opacity: 0.55
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    text: "_..__..__..._..____..._..___...___..__..__...___.._"
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 10 * root.fontScale / 100
                    color: root.dimInk
                    opacity: 0.43
                }
                Text {
                    visible: water.width > 260
                    x: water.width - width - 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    text: " /\\_\n[____]"
                    color: root.dimInk
                    opacity: 0.55
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 11 * root.fontScale / 100
                    lineHeight: 0.84
                }
            }

            Rectangle {
                id: status
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.showStatus ? 24 : 0
                visible: root.showStatus
                color: studioPalette.custom ? "transparent" : root.fadeBackground(root.studioMode === "glass" ? "transparent" : root.alphaColour(root.footerColor, root.bgOpacity))
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: "fish: " + (root.fishCount < 10 ? "0" : "") + root.fishCount +
                          "    bubbles: " + (root.showBubbles ? "on" : "off")
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 10 * root.fontScale / 100
                    color: root.dimInk
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "[click: pause]"
                    font.family: root.studioFont("monospace")
                    font.pixelSize: 10 * root.fontScale / 100
                    color: root.dimInk
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: false
                onClicked: root.paused = !root.paused
            }
        }
        Timer {
            interval: root.motionSpeed === 1 ? 220 : (root.motionSpeed === 3 ? 100 : 150)
            running: panel.visible && root.visible && !root.paused
            repeat: true
            onTriggered: root.moveScene()
        }
    }
}
