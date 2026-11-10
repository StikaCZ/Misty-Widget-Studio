import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// TERRARIA / ICE WATCH — custom procedural pixel art, no image downloads.
// Server observations use read-only key-based SSH. No remote start/stop actions.
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
implicitWidth: 620
    implicitHeight: 325
    Layout.minimumWidth: 300
    Layout.minimumHeight: 215
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property bool compact: width < 455 || height < 275
    readonly property real pad: compact ? 11 : 15
    readonly property real headH: compact ? 39 : 46
    readonly property real footH: compact ? 65 : 71
    readonly property color fg: studioPalette.paint(root.studioColor("#F0F4F7"), "text")
    readonly property color secondary: studioPalette.paint(root.studioColor("#AAB5BE"), "muted")
    readonly property color ice: studioPalette.paint(root.studioColor("#BDDDEC"), "muted")
    readonly property string mono: "JetBrains Mono"
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/serverstats.py").toString().replace("file://", "")

    property var stats: ({ "reachable": false, "service": "unknown", "world": "—",
                           "players": null, "serviceUptime": "—", "hostUptime": "—",
                           "ramMiB": null, "error": "" })
    property bool received: false
    property bool busy: false
    readonly property bool serverOnline: stats.reachable && stats.service === "active"
    readonly property string serverLabel: !received ? "CONNECTING"
        : !stats.reachable ? "SSH OFFLINE"
        : serverOnline ? "ONLINE" : "TERRARIA OFF"

    function refresh() {
        if (busy) return
        busy = true
        monitor.connectSource('python3 "' + scriptPath + '"')
    }
    Component.onCompleted: refresh()
    onServerOnlineChanged: icePainting.requestPaint()

    P5Support.DataSource {
        id: monitor
        engine: "executable"
        onNewData: function(sourceName, data) {
            root.busy = false
            root.received = true
            try {
                root.stats = JSON.parse(String(data["stdout"] || "").trim())
            } catch (e) {
                root.stats = ({ "reachable": false, "service": "unknown", "world": "—",
                                "serviceUptime": "—", "hostUptime": "—", "ramMiB": null,
                                "players": null, "error": "Invalid status response" })
            }
            disconnectSource(sourceName)
        }
    }
    Timer { interval: 20000; repeat: true; running: true; onTriggered: root.refresh() }

    // Matches Homelab, System Pulse and Weather Planet translucent panels.
    Rectangle {
        anchors.fill: parent
        radius: 7
        color: studioPalette.panel(root.studioMode === "glass" ? "transparent" : root.studioColor("#DA1B2026"))
        border.width: root.studioMode === "glass" ? 0 : 1; border.color: studioPalette.outline(root.studioColor("#657A838D"))
    }

    Rectangle {
        x: root.pad
        anchors.verticalCenter: topHeader.verticalCenter
        width: 3
        height: compact ? 15 : 19
        radius: 1.5
        color: root.ice
    }
    Item {
        id: topHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headH
        Text {
            x: root.pad + 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(110, parent.width - 186)
            text: "TERRARIA / ICE WATCH"
            color: root.fg
            font.family: root.studioFont(root.mono)
            font.bold: true
            font.pixelSize: root.compact ? 11 : 14
            font.letterSpacing: 0.5
            elide: Text.ElideRight
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: refreshBox.left
            anchors.rightMargin: 11
            spacing: 6
            Rectangle {
                width: 7; height: 7; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: root.serverOnline ? "#9AC7B5" : (root.received ? "#A4AEB5" : "#829AA6")
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.serverOnline
                    NumberAnimation { to: 0.45; duration: 1300; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1300; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: root.serverLabel
                color: root.serverOnline ? "#D4E8E2" : root.secondary
                font.family: root.studioFont(root.mono)
                font.pixelSize: root.compact ? 8 : 10
            }
        }
        Rectangle {
            id: refreshBox
            width: 24; height: 24
            radius: 5
            anchors.right: parent.right
            anchors.rightMargin: root.pad
            anchors.verticalCenter: parent.verticalCenter
            color: refreshArea.containsMouse ? "#39444D" : "#243039"
            border.width: 1
            border.color: studioPalette.paint(root.studioColor("#63707B"), "border")
            Text { font.family: root.studioFont("Noto Sans"); 
                anchors.centerIn: parent
                text: "↻"
                color: root.ice
                font.pixelSize: Math.max(8,Math.round(17*root.studioTextScale))
            }
            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refresh()
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            height: 1
            color: studioPalette.paint(root.studioColor("#53636D77"), "muted")
        }
    }

    Item {
        id: scene
        x: root.pad
        y: root.headH + 8
        width: Math.max(0, root.width - root.pad * 2)
        height: Math.max(50, root.height - y - root.footH - 13)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: studioPalette.paint(root.studioColor("#1B2E3B"), "surface")
        }

        Canvas {
            id: icePainting
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var c = getContext("2d")
                var w = width, h = height
                if (w <= 0 || h <= 0) return
                c.clearRect(0, 0, w, h)
                var awake = root.serverOnline
                var sky = c.createLinearGradient(0, 0, 0, h)
                if (awake) {
                    sky.addColorStop(0, "#263D51")
                    sky.addColorStop(0.65, "#36566A")
                    sky.addColorStop(1, "#6D97A6")
                } else {
                    sky.addColorStop(0, "#16212B")
                    sky.addColorStop(1, "#334653")
                }
                c.fillStyle = sky; c.fillRect(0, 0, w, h)

                // Winter moon and distant frozen haze (behind the mountains).
                var mx = w * 0.77, my = h * 0.22, moon = Math.min(17, h * .11)
                c.fillStyle = awake ? "#C7D9E0" : "#899CA9"
                c.beginPath(); c.arc(mx, my, moon, 0, Math.PI * 2); c.fill()
                c.fillStyle = awake ? "#DBE9EE" : "#A3AFB8"
                c.beginPath(); c.arc(mx - moon * .18, my - moon * .15, moon * .78, 0, Math.PI * 2); c.fill()

                function polygon(points, color) {
                    c.fillStyle = color
                    c.beginPath(); c.moveTo(points[0][0] * w, points[0][1] * h)
                    for (var p = 1; p < points.length; p++) c.lineTo(points[p][0] * w, points[p][1] * h)
                    c.closePath(); c.fill()
                }
                polygon([[0,.60],[.13,.24],[.26,.58],[.38,.30],[.52,.66],[.72,.35],[.87,.63],[1,.40],[1,1],[0,1]], awake ? "#526E7C" : "#344854")
                polygon([[0,.78],[.18,.48],[.29,.68],[.47,.40],[.66,.74],[.85,.49],[1,.72],[1,1],[0,1]], awake ? "#72939F" : "#455A66")
                polygon([[.065,.41],[.13,.24],[.19,.40],[.15,.37],[.13,.33],[.107,.38]], "#CADFE8")
                polygon([[.31,.46],[.38,.30],[.45,.47],[.40,.42],[.38,.37],[.355,.43]], "#C4DCE6")
                polygon([[.66,.46],[.72,.35],[.77,.47],[.73,.43],[.72,.39],[.69,.43]], "#B7D3DF")
                polygon([[.945,.54],[1,.40],[1,.51],[.987,.51]], "#CADDE6")

                // Frozen water, ice fractures, and foreground snow drifts.
                polygon([[0,.81],[.26,.75],[.50,.80],[.73,.74],[1,.79],[1,1],[0,1]], awake ? "#94C2CF" : "#678B99")
                c.fillStyle = awake ? "#B4DFE6" : "#779FAC"
                for (var s=0; s<10; ++s) {
                    var xx = (s * 83 + 24) % Math.max(1,w)
                    var yy = h * (.84 + (s%3)*.044)
                    c.fillRect(xx, yy, Math.max(9,w*.052), Math.max(1.5,h*.012))
                }
                polygon([[0,.88],[.07,.86],[.13,.91],[.21,.88],[.30,.92],[.41,.87],[.52,.91],[.62,.86],[.71,.9],[.85,.87],[1,.90],[1,1],[0,1]], "#D1E9EC")
                polygon([[0,.94],[.08,.93],[.15,.96],[.23,.94],[.34,.98],[.48,.93],[.63,.96],[.76,.94],[.88,.97],[1,.93],[1,1],[0,1]], "#EAF3F4")

                // Chunky Terraria-inspired pine trees, generated with pixel rectangles.
                function pine(cx, baseline, scale) {
                    var px = Math.max(2, Math.floor(scale * Math.min(h / 155, 1.3)))
                    var tx = cx*w, ty = baseline*h
                    c.fillStyle = "#4C4242"
                    c.fillRect(tx - px, ty - px*11, px*2, px*11)
                    for (var j = 0; j < 5; j++) {
                        var cw = px * (5.5 - j * .75)
                        var cy = ty - px * (4.3 + j * 3.8)
                        c.fillStyle = j%2 ? "#1D4955" : "#1E5663"
                        c.fillRect(tx-cw, cy, cw*2, px*3)
                        c.fillStyle = "#BDD4DC"
                        c.fillRect(tx-cw+px, cy, cw*1.7, px*.8)
                    }
                }
                pine(.08,.85,2.0)
                pine(.22,.90,2.7)
                pine(.42,.84,1.8)
                pine(.90,.85,2.4)
                pine(.97,.89,1.5)

                // Colourful but restrained ice crystals on the snow.
                function crystal(x,y,sc) {
                    var z = Math.min(h/8, 15)*sc
                    polygon([[x-z/w,y],[x,y-z*2/h],[x+z/w,y],[x,y+z*.6/h]], awake ? "#91C7D7" : "#668F9D")
                    polygon([[x-z*.1/w,y],[x,y-z*2/h],[x+z/w,y],[x,y+z*.6/h]], "#C1E3E8")
                }
                crystal(.34, h*.87, .72)
                crystal(.60, h*.87, .58)
                crystal(.82, h*.91, .48)

                // Campfire logs are permanent; animated fire is overlaid in QML.
                var fx = w*.71, fy = h*.86
                c.fillStyle = "#514A48"
                c.fillRect(fx-11, fy-2, 24, 5)
                c.fillStyle = "#937560"
                c.fillRect(fx-9, fy-4, 18, 3)
            }
        }

        // On/off indicator also controls light and creatures, never remote services.
        Rectangle {
            x: scene.width * .71 - width/2
            y: scene.height * .86 - height - 1
            width: 12; height: 18
            visible: root.serverOnline
            radius: 5
            gradient: Gradient {
                GradientStop { position: 0.0; color: studioPalette.paint(root.studioColor("#FFDEA2"), "accent") }
                GradientStop { position: 0.6; color: studioPalette.paint(root.studioColor("#E9A56C"), "accent") }
                GradientStop { position: 1.0; color: studioPalette.paint(root.studioColor("#B8734C"), "accent") }
            }
            SequentialAnimation on opacity {
                running: root.serverOnline; loops: Animation.Infinite
                NumberAnimation { to: 0.62; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 660; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale {
                running: root.serverOnline; loops: Animation.Infinite
                NumberAnimation { to: 1.12; duration: 390; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.94; duration: 590; easing.type: Easing.InOutSine }
            }
        }

        // Snow is reintroduced beyond the top edge; no visible snapping.
        Repeater {
            model: root.serverOnline ? (root.compact ? 15 : 23) : 0
            Rectangle {
                readonly property int seed: index
                width: index%5 === 0 ? 3 : 2
                height: width
                radius: width/2
                x: scene.width * ((index * 43 + 17)%101) / 101
                color: studioPalette.paint(root.studioColor("#ECF5F8"), "text")
                opacity: 0.25 + (index%5)*.11
                NumberAnimation on y {
                    from: -30 - ((index * 17)%130)
                    to: scene.height + 10
                    duration: 3600 + ((index * 719)%3900)
                    running: root.serverOnline
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }
            }
        }

        // Tiny ice slime with slow idle hop; always stays within scene.
        Item {
            id: slime
            width: Math.max(21, Math.min(34, scene.height*.23))
            height: width
            x: scene.width * .55
            property real hop: 0
            y: scene.height * .88 - height + hop
            visible: root.serverOnline
            SequentialAnimation on hop {
                running: root.serverOnline
                loops: Animation.Infinite
                PauseAnimation { duration: 850 }
                NumberAnimation { to: -9; duration: 370; easing.type: Easing.OutCubic }
                NumberAnimation { to: 0; duration: 400; easing.type: Easing.InCubic }
                PauseAnimation { duration: 1100 }
            }
            Canvas {
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var c=getContext("2d"), z=Math.max(1,Math.floor(width/14))
                    var left=(width-z*14)/2, top=(height-z*14)/2
                    c.clearRect(0,0,width,height)
                    function pix(x,y,w,h,color) {
                        c.fillStyle=color
                        c.fillRect(left+x*z,top+y*z,w*z,h*z)
                    }
                    pix(4,1,6,2,"#9DE5F0")
                    pix(2,3,10,2,"#78CDE5")
                    pix(1,5,12,6,"#4BAACF")
                    pix(2,11,10,2,"#468DAE")
                    pix(4,13,6,1,"#3D7B98")
                    pix(3,5,5,2,"#B5EDF0")
                    pix(4,8,2,2,"#17323F")
                    pix(9,8,2,2,"#17323F")
                    pix(6,11,3,1,"#24465B")
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: studioPalette.paint(root.studioColor("#55111A23"), "surface")
            radius: 5
            visible: root.received && !root.serverOnline
        }
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 9
            color: studioPalette.paint(root.studioColor("#99141F27"), "surface")
            border.color: studioPalette.paint(root.studioColor("#4D7B8E98"), "border")
            border.width: 1
            radius: 3
            width: zoneLabel.implicitWidth + 14
            height: zoneLabel.implicitHeight + 9
            Text {
                id: zoneLabel
                anchors.centerIn: parent
                text: "FROZEN  /  INFERNUM"
                color: studioPalette.paint(root.studioColor("#E3EFF3"), "text")
                font.family: root.studioFont(root.mono)
                font.pixelSize: root.compact ? 8 : 10
                font.bold: true
                font.letterSpacing: .6
            }
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            text: root.serverOnline ? "❄ SNOWFALL" : "FROZEN / STANDBY"
            color: studioPalette.paint(root.studioColor("#DAF0F5"), "text")
            font.family: root.studioFont(root.mono)
            font.pixelSize: root.compact ? 8 : 9
            font.bold: true
        }
    }

    Item {
        id: footer
        x: root.pad
        y: root.height - root.footH - 5
        width: root.width - root.pad*2
        height: root.footH

        Row {
            id: statTiles
            anchors.fill: parent
            spacing: compact ? 4 : 8
            Repeater {
                model: [
                    { "label": "WORLD", "value": root.stats.world || "—" },
                    { "label": "PLAYERS", "value": "—" },
                    { "label": "UPTIME", "value": root.stats.serviceUptime || "—" },
                    { "label": "TML RAM", "value": root.stats.ramMiB === null || root.stats.ramMiB === undefined ? "—" : (Number(root.stats.ramMiB) / 1024).toFixed(1) + " GiB" }
                ]
                Rectangle {
                    required property var modelData
                    width: Math.max(0, (footer.width - statTiles.spacing*3)/4)
                    height: footer.height - 3
                    radius: 5
                    color: studioPalette.paint(root.studioColor("#77171D23"), "surface")
                    border.width: 1
                    border.color: studioPalette.paint(root.studioColor("#3A697780"), "border")
                    Rectangle {
                        x: 9; y: 11; width: 3; height: 3; radius: 1
                        color: root.ice
                        opacity: .65
                    }
                    Text {
                        x: 17; y: 8
                        width: parent.width-20
                        text: modelData.label
                        color: root.secondary
                        font.family: root.studioFont(root.mono)
                        font.pixelSize: root.compact ? 8 : 9
                        font.letterSpacing: 0.4
                        elide: Text.ElideRight
                    }
                    Text {
                        x: 9; y: 27
                        width: parent.width - 16
                        text: modelData.value
                        color: root.fg
                        font.family: root.studioFont(root.mono)
                        font.bold: true
                        font.pixelSize: root.compact ? 11 : 14
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
