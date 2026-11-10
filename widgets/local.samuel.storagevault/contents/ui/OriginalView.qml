import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// STORAGE VAULT / Slate edition (silver meter, muted warnings)
// Capacity and progress are actual usage of the '/' filesystem (not SMART health).
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 510
    implicitHeight: 260
    Layout.minimumWidth: 260
    Layout.minimumHeight: 180


    readonly property bool compact: width < 400 || height < 225
    readonly property real margin: compact ? 11 : 18
    readonly property real headerHeight: compact ? 40 : 47
    readonly property real usedPercent: Math.max(0, Math.min(100, Number(info.percent || 0)))
    readonly property real coreSize: Math.max(95, Math.min(content.height - 1, content.width * .41, 205))
    readonly property color accent: studioPalette.paint(usedPercent >= 90 ? "#C58D8D" : usedPercent >= 75 ? "#C7A478" : "#CDD6DC", "accent")
    readonly property color mint: studioPalette.paint("#C0C9CF", "muted")
    readonly property color primaryText: studioPalette.paint("#F1F5F8", "text")
    readonly property color mutedText: studioPalette.paint("#9EADB8", "muted")
    readonly property string capacityState: !info.ok ? "READING DRIVE" : usedPercent >= 90 ? "SPACE CRITICAL"
        : usedPercent >= 75 ? "GETTING FULL" : "ROOM TO SPARE"
    readonly property string py: Qt.resolvedUrl("../scripts/diskstats.py").toString().replace("file://", "")

    property var info: ({ "ok": false, "percent": 0, "usedGiB": 0, "totalGiB": 0, "availableGiB": 0 })
    property bool busy: false

    function poll() {
        if (busy) return
        busy = true
        stats.connectSource('python3 "' + py + '"')
    }
    Component.onCompleted: poll()
    P5Support.DataSource {
        id: stats
        engine: "executable"
        onNewData: function(name, data) {
            root.busy = false
            try { root.info = JSON.parse(String(data["stdout"] || "").trim()) }
            catch (e) { root.info = ({ "ok": false, "percent": 0, "usedGiB": 0, "totalGiB": 0, "availableGiB": 0 }) }
            disconnectSource(name)
        }
    }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: root.poll() }

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
        color: root.accent
        Behavior on color { ColorAnimation { duration: 450 } }
    }
    Text {
        x: root.margin + 12; y: compact ? 11 : 13
        text: "STORAGE / VAULT"
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
            color: root.info.ok ? root.mint : "#80929D"
        }
        Text {
            text: root.info.ok ? "SYSTEM /" : "WAIT"
            color: root.info.ok ? root.mint : root.mutedText
            font.family: "JetBrains Mono"
            font.pixelSize: compact ? 9 : 10
        }
    }
    Rectangle {
        x: root.margin; y: root.headerHeight
        width: root.width - root.margin * 2
        height: 1; color: studioPalette.paint("#384148", "surface")
    }

    Item {
        id: content
        x: root.margin
        y: root.headerHeight + 6
        width: root.width - root.margin * 2
        height: Math.max(0, root.height - y - root.margin)

        Item {
            id: core
            width: root.coreSize
            height: width
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            // Painted only on value or resize changes; no spinning storage animation.
            Canvas {
                id: dial
                anchors.fill: parent
                property real progress: root.usedPercent
                Behavior on progress { NumberAnimation { duration: 850; easing.type: Easing.OutCubic } }
                onProgressChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2
                    var outer = width * .46, track = width * .345
                    var bg = ctx.createRadialGradient(cx, cy, 0, cx, cy, outer)
                    bg.addColorStop(0, "#363C42")
                    bg.addColorStop(.74, "#23282E")
                    bg.addColorStop(1, "#181D23")
                    ctx.beginPath(); ctx.arc(cx, cy, outer, 0, Math.PI * 2)
                    ctx.fillStyle = bg; ctx.fill()
                    ctx.lineWidth = 1.3; ctx.strokeStyle = "#8B949C"; ctx.stroke()
                    // Machined tick marks around the vault face.
                    for (var k = 0; k < 36; ++k) {
                        var a = (k * 10 - 90) * Math.PI / 180
                        var r1 = outer * (k % 3 === 0 ? .88 : .92)
                        var r2 = outer * .97
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                        ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                        ctx.strokeStyle = "rgba(169,180,187,0.61)"; ctx.lineWidth = k % 3 === 0 ? 1.3 : .7; ctx.stroke()
                    }
                    // Subtle circular core and usage track.
                    ctx.beginPath(); ctx.arc(cx, cy, track, 0, Math.PI * 2)
                    ctx.strokeStyle = "rgba(105,115,123,0.42)"; ctx.lineWidth = Math.max(7, width * .055); ctx.stroke()
                    var start = -Math.PI / 2
                    var end = start + Math.PI * 2 * Math.max(0, Math.min(100, progress)) / 100
                    if (progress > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, track, start, end)
                        ctx.strokeStyle = String(root.accent)
                        ctx.lineWidth = Math.max(7, width * .055)
                        ctx.lineCap = "round"
                        ctx.stroke()
                        ctx.lineCap = "butt"
                    }
                    ctx.beginPath(); ctx.arc(cx, cy, width * .255, 0, Math.PI * 2)
                    ctx.fillStyle = "rgba(21,26,31,0.85)"; ctx.fill()
                    ctx.strokeStyle = "rgba(136,148,156,0.62)"; ctx.lineWidth = 1; ctx.stroke()
                    // Drive spindle detail.
                    for (var i = 0; i < 4; ++i) {
                        var angle = i * Math.PI / 2 + Math.PI / 4
                        ctx.beginPath()
                        ctx.arc(cx + Math.cos(angle) * width * .225,
                                cy + Math.sin(angle) * width * .225,
                                Math.max(1.1, width * .008), 0, 2 * Math.PI)
                        ctx.fillStyle = "#8C979F"; ctx.fill()
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: -4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.info.ok ? Math.round(root.usedPercent) + "%" : "--"
                    color: root.primaryText
                    font.family: "Noto Sans"
                    font.bold: true
                    font.pixelSize: core.width * .225
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "USED"
                    color: root.accent
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: Math.max(8, core.width * .062)
                    font.letterSpacing: 1
                }
            }
        }

        Column {
            id: readings
            x: core.width + (root.compact ? 10 : 22)
            width: Math.max(90, content.width - x)
            spacing: root.compact ? 5 : 9
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: root.capacityState
                color: root.accent
                font.family: "JetBrains Mono"
                font.pixelSize: root.compact ? 9 : 11
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.info.ok ? root.info.availableGiB + " GiB" : "-- GiB"
                color: root.primaryText
                font.family: "Noto Sans"
                font.bold: true
                font.pixelSize: root.compact ? 18 : 28
                elide: Text.ElideRight
            }
            Text {
                text: "AVAILABLE SPACE"
                color: root.mutedText
                font.family: "JetBrains Mono"
                font.pixelSize: root.compact ? 8 : 10
            }
            Rectangle {
                id: capacityTrack
                width: parent.width
                height: root.compact ? 6 : 8
                radius: 4
                color: studioPalette.paint("#3B454E", "surface")
                Rectangle {
                    height: parent.height
                    width: parent.width * root.usedPercent / 100
                    radius: parent.radius
                    color: root.accent
                    Behavior on width { NumberAnimation { duration: 850; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 500 } }
                }
            }
            Row {
                width: parent.width
                spacing: 4
                Repeater {
                    model: 14
                    Rectangle {
                        required property int index
                        width: Math.max(2, (readings.width - 13 * 4) / 14)
                        height: root.compact ? 5 : 7
                        radius: 1
                        color: index < Math.ceil(root.usedPercent * 14 / 100) ? root.accent : "#3D474F"
                        opacity: index < Math.ceil(root.usedPercent * 14 / 100) ? .9 : .65
                        Behavior on color { ColorAnimation { duration: 550 } }
                    }
                }
            }
            Text {
                width: parent.width
                text: root.info.ok ? root.info.usedGiB + " / " + root.info.totalGiB + " GiB" : "READING ROOT DRIVE"
                color: root.mutedText
                font.family: "JetBrains Mono"
                font.pixelSize: root.compact ? 9 : 11
                elide: Text.ElideRight
            }
        }
    }
}
