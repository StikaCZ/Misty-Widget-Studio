import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// NETWORK RADAR / Slate edition (mostly neutral greys)
// The sweep and dots are aesthetic; readings are real interface counters,
// Wi-Fi signal (when available), and a ping to the LAN router, not the internet.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 510
    implicitHeight: 260
    Layout.minimumWidth: 260
    Layout.minimumHeight: 180


    function css(c) { return "rgba("+Math.round(c.r*255)+","+Math.round(c.g*255)+","+Math.round(c.b*255)+","+c.a+")" }
    readonly property bool compact: width < 400 || height < 225
    readonly property real margin: compact ? 11 : 18
    readonly property real headerHeight: compact ? 40 : 47
    readonly property real radarSize: Math.max(94, Math.min(body.height - 3, body.width * (compact ? 0.42 : 0.42), 205))
    readonly property string py: Qt.resolvedUrl("../scripts/netstats.py").toString().replace("file://", "")

    readonly property color blue: studioPalette.paint("#D4DBE0", "muted")
    readonly property color mint: studioPalette.paint("#BEC9C8", "muted")
    readonly property color amber: studioPalette.paint("#C7A478", "muted")
    readonly property color coral: studioPalette.paint("#C58D8D", "muted")
    readonly property color primaryText: studioPalette.paint("#F1F5F8", "text")
    readonly property color mutedText: studioPalette.paint("#9EADB8", "muted")
    readonly property real signalPercent: info.signalPercent === null || info.signalPercent === undefined ? -1 : Number(info.signalPercent)
    readonly property color signalColor: !info.online ? studioPalette.paint("#80929D", "muted")
        : (signalPercent >= 0 && signalPercent < 38) || (info.pingMs !== null && info.pingMs > 120) ? coral
        : (signalPercent >= 0 && signalPercent < 62) || (info.pingMs !== null && info.pingMs > 60) ? amber
        : studioPalette.paint("#A9BEB2", "accent")
    readonly property string signalLabel: !info.online ? "OFFLINE"
        : signalPercent < 0 ? "CONNECTED"
        : signalPercent < 38 ? "WEAK SIGNAL"
        : signalPercent < 62 ? "FAIR SIGNAL"
        : "STRONG SIGNAL"

    property var info: ({ "online": false, "iface": "--", "ssid": "CONNECTING", "downMbps": 0, "upMbps": 0,
                          "pingMs": null, "signalDbm": null, "signalPercent": null })
    property bool busy: false
    property bool received: false

    function rate(v) {
        var n = Math.max(0, Number(v || 0))
        return n >= 100 ? n.toFixed(0) : n.toFixed(1)
    }
    function refresh() {
        if (busy) return
        busy = true
        probe.connectSource('python3 "' + py + '"')
    }
    Component.onCompleted: refresh()
    P5Support.DataSource {
        id: probe
        engine: "executable"
        onNewData: function(name, data) {
            root.busy = false
            try {
                root.info = JSON.parse(String(data["stdout"] || "").trim())
                root.received = true
            } catch (e) {
                root.info = ({ "online": false, "iface": "--", "ssid": "UNAVAILABLE", "downMbps": 0,
                               "upMbps": 0, "pingMs": null, "signalDbm": null, "signalPercent": null })
            }
            disconnectSource(name)
        }
    }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refresh() }

    // Identical charcoal panel to System Pulse / Weather Planet / Homelab.
    Rectangle {
        anchors.fill: parent
        radius: 7
        color: studioPalette.panel("#DA1B2026")
        border.width: 1
        border.color: studioPalette.outline("#657A838D")
    }
    Rectangle {
        x: root.margin; y: compact ? 12 : 14
        width: 3; height: compact ? 15 : 19; radius: 2
        color: root.blue
    }
    Text {
        x: root.margin + 12
        y: compact ? 11 : 13
        text: "NETWORK / RADAR"
        color: root.primaryText
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: compact ? 12 : 15
        font.letterSpacing: compact ? 0.1 : 0.6
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: root.margin
        y: compact ? 13 : 17
        spacing: 6
        Rectangle {
            width: 7; height: 7; radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.signalColor
            SequentialAnimation on opacity {
                running: root.info.online; loops: Animation.Infinite
                NumberAnimation { to: 0.45; duration: 1700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1700; easing.type: Easing.InOutSine }
            }
        }
        Text {
            text: root.info.online ? "LIVE" : root.received ? "OFFLINE" : "WAIT"
            color: root.info.online ? root.primaryText : root.mutedText
            font.family: "JetBrains Mono"
            font.pixelSize: compact ? 9 : 10
        }
    }
    Rectangle {
        x: root.margin; y: root.headerHeight
        width: root.width - 2 * root.margin; height: 1
        color: studioPalette.paint("#384148", "surface")
    }

    Item {
        id: body
        x: root.margin
        y: root.headerHeight + 6
        width: root.width - 2 * root.margin
        height: Math.max(0, root.height - y - root.margin)

        Item {
            id: radar
            width: root.radarSize
            height: width
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: scannerFace
                anchors.fill: parent
                property string themeSignature: [studioPalette.custom,studioPalette.surfaceColour.toString(),studioPalette.edgeColour.toString()].join("|")
                onThemeSignatureChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2, r = Math.min(width, height) * 0.46
                    var bg = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
                    bg.addColorStop(0, root.css(studioPalette.paint("#30353C","surface")))
                    bg.addColorStop(.68, root.css(studioPalette.paint("#21262C","surface")))
                    bg.addColorStop(1, root.css(studioPalette.paint("#171B20","surface")))
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.fillStyle = bg; ctx.fill()
                    ctx.strokeStyle = root.css(studioPalette.paint("#78818A","border")); ctx.lineWidth = 1; ctx.stroke()
                    for (var i = 1; i <= 3; ++i) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r * i / 3, 0, Math.PI * 2)
                        ctx.lineWidth = i === 3 ? 1.1 : .85
                        ctx.strokeStyle = i === 3 ? "rgba(162,173,181,0.52)" : "rgba(132,143,153,0.45)"
                        ctx.stroke()
                    }
                    ctx.beginPath()
                    ctx.moveTo(cx - r, cy); ctx.lineTo(cx + r, cy)
                    ctx.moveTo(cx, cy - r); ctx.lineTo(cx, cy + r)
                    ctx.strokeStyle = "rgba(152,160,167,0.35)"; ctx.lineWidth = .8; ctx.stroke()
                    for (var a = 0; a < 12; ++a) {
                        var angle = a * Math.PI / 6
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(angle) * r * .93, cy + Math.sin(angle) * r * .93)
                        ctx.lineTo(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r)
                        ctx.strokeStyle = "rgba(183,191,197,0.68)"; ctx.lineWidth = 1; ctx.stroke()
                    }
                }
            }

            // Rotate a pre-painted wedge rather than repaint every animation frame.
            Item {
                anchors.fill: parent
                rotation: 0
                NumberAnimation on rotation {
                    from: 0; to: 360; duration: 10000
                    loops: Animation.Infinite; running: true
                    easing.type: Easing.Linear
                }
                Canvas {
                    anchors.fill: parent
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = width / 2, cy = height / 2, r = width * .45
                        var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
                        g.addColorStop(0, "rgba(224,232,238,0.19)")
                        g.addColorStop(1, "rgba(224,232,238,0.045)")
                        ctx.beginPath(); ctx.moveTo(cx, cy)
                        ctx.arc(cx, cy, r, -Math.PI / 2 - .75, -Math.PI / 2)
                        ctx.closePath(); ctx.fillStyle = g; ctx.fill()
                        ctx.beginPath(); ctx.moveTo(cx, cy)
                        ctx.lineTo(cx, cy - r)
                        ctx.strokeStyle = "rgba(226,234,240,0.73)"; ctx.lineWidth = 1.8; ctx.stroke()
                    }
                }
            }

            Rectangle {
                x: radar.width * .72; y: radar.height * .29
                width: Math.max(5, radar.width * .046); height: width; radius: width / 2
                color: root.signalColor
                opacity: root.info.online ? 0.95 : 0.30
                SequentialAnimation on scale {
                    running: root.info.online; loops: Animation.Infinite
                    NumberAnimation { to: 1.4; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1500; easing.type: Easing.InOutSine }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: radar.width * .56
                height: width
                radius: width / 2
                color: studioPalette.paint("#E421262C", "surface")
                border.width: 1
                border.color: studioPalette.paint("#667D858B", "border")
                Column {
                    anchors.centerIn: parent
                    spacing: -2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.signalPercent >= 0 ? Math.round(root.signalPercent) + "%" : "◉"
                        color: root.primaryText
                        font.family: "Noto Sans"
                        font.bold: true
                        font.pixelSize: root.signalPercent >= 0 ? radar.width * .19 : radar.width * .18
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.signalPercent >= 0 ? "SIGNAL" : "ONLINE"
                        color: root.signalColor
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: Math.max(8, radar.width * .058)
                        font.letterSpacing: .6
                    }
                }
            }
        }

        Column {
            id: readings
            x: radar.width + (root.compact ? 11 : 22)
            width: Math.max(90, body.width - x)
            spacing: root.compact ? 4 : 7
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: String(root.info.ssid || "NETWORK")
                color: root.primaryText
                font.bold: true
                font.family: "Noto Sans"
                font.pixelSize: root.compact ? 12 : 16
                elide: Text.ElideRight
            }
            Row {
                width: parent.width
                spacing: 5
                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.signalColor
                }
                Text {
                    width: Math.max(60, readings.width - 11)
                    text: root.signalLabel
                    color: root.signalColor
                    font.pixelSize: root.compact ? 9 : 10
                    font.family: "JetBrains Mono"
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                width: parent.width
                height: root.compact ? 30 : 47
                radius: 5
                color: studioPalette.paint("#25303943", "surface")
                border.width: 1
                border.color: studioPalette.paint("#43565E67", "border")
                Rectangle { x: 0; y: 0; width: 3; height: parent.height; radius: 2; color: root.blue }
                Column {
                    x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: -1
                    Text { text: "↓  DOWNLOAD"; color: studioPalette.paint("#CFD9DE", "text"); font.family: "JetBrains Mono"; font.pixelSize: root.compact ? 8 : 10 }
                    Text {
                        text: root.rate(root.info.downMbps) + " Mb/s"
                        color: root.primaryText; font.bold: true; font.family: "Noto Sans"
                        font.pixelSize: root.compact ? 13 : 20
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: root.compact ? 30 : 47
                radius: 5
                color: studioPalette.paint("#252B343B", "surface")
                border.width: 1
                border.color: studioPalette.paint("#43515960", "border")
                Rectangle { x: 0; y: 0; width: 3; height: parent.height; radius: 2; color: root.mint }
                Column {
                    x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: -1
                    Text { text: "↑  UPLOAD"; color: studioPalette.paint("#B9C5C8", "text"); font.family: "JetBrains Mono"; font.pixelSize: root.compact ? 8 : 10 }
                    Text {
                        text: root.rate(root.info.upMbps) + " Mb/s"
                        color: root.primaryText; font.bold: true; font.family: "Noto Sans"
                        font.pixelSize: root.compact ? 13 : 20
                    }
                }
            }
            Row {
                width: parent.width
                spacing: 6
                Text {
                    text: "ROUTER"
                    color: root.mutedText
                    font.family: "JetBrains Mono"; font.pixelSize: root.compact ? 9 : 10
                }
                Text {
                    text: root.info.pingMs === null || root.info.pingMs === undefined
                          ? "-- ms" : root.info.pingMs + " ms"
                    color: root.info.pingMs !== null && root.info.pingMs > 60 ? root.amber : root.primaryText
                    font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.compact ? 9 : 11
                }
            }
        }
    }
}
