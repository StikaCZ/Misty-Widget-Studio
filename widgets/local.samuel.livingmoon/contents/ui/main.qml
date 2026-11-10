import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 270
    implicitHeight: 230
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Approximate moon phase from a known new moon (UTC), no network or scripts.
    // This is a visual lunar calendar, not an astronomical ephemeris.
    property date currentTime: new Date()
    readonly property real synodicMonth: 29.530588853
    readonly property real elapsedDays: (currentTime.getTime() - Date.UTC(2000, 0, 6, 18, 14)) / 86400000.0
    readonly property real phase: (((elapsedDays / synodicMonth) % 1) + 1) % 1
    readonly property real moonAge: phase * synodicMonth
    readonly property int illuminationPercent: Math.round(50 * (1 - Math.cos(2 * Math.PI * phase)))
    readonly property var phaseNames: ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
                                       "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"]
    readonly property string phaseName: phaseNames[Math.floor(phase * 8 + 0.5) % 8]
    readonly property bool wide: width > height * 1.32
    readonly property real moonSize: Math.max(30, Math.min(wide ? height * 0.74 : width * 0.60,
                                                           wide ? width * 0.45 : height * 0.57))

    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: root.currentTime = new Date()
    }

    // A tiny silver orbit around the globe; transparent like Update Plant.
    Item {
        id: moonArea
        width: root.moonSize + 32
        height: width
        x: root.wide ? Math.max(4, root.width * 0.085 - 16) : (root.width - width) / 2
        y: root.wide ? (root.height - height) / 2 : Math.max(0, root.height * 0.035)

        Rectangle {
            anchors.centerIn: parent
            width: moonFace.width + 20
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: studioPalette.paint("#284A6575", "border")
        }
        Rectangle {
            anchors.centerIn: parent
            width: moonFace.width + 35
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: studioPalette.paint("#124A6575", "border")
        }

        Canvas {
            id: moonFace
            width: root.moonSize
            height: width
            anchors.centerIn: parent
            renderTarget: Canvas.Image
            onPaint: {
                var ctx = getContext("2d");
                var w = width;
                var x = w / 2;
                var y = w / 2;
                var r = w * 0.485;
                ctx.clearRect(0, 0, w, w);
                if (r <= 0) return;

                // Pale grey moon texture. The terminator below masks the unlit portion.
                ctx.save();
                ctx.beginPath();
                ctx.arc(x, y, r, 0, 2 * Math.PI, false);
                ctx.clip();
                var surface = ctx.createRadialGradient(x - r * 0.28, y - r * 0.34, 2,
                                                       x + r * 0.10, y + r * 0.12, r * 1.50);
                surface.addColorStop(0, "#F2F4F6");
                surface.addColorStop(0.58, "#CAD0D5");
                surface.addColorStop(1, "#808E99");
                ctx.fillStyle = surface;
                ctx.fillRect(0, 0, w, w);

                // Subtle fixed crater texture, in the same silver palette.
                var craters = [
                    [-0.34,-0.28,0.16], [0.24,-0.42,0.12], [-0.04,0.12,0.19],
                    [0.39,0.29,0.11], [-0.47,0.36,0.10], [0.03,-0.58,0.08],
                    [0.51,-0.13,0.07], [-0.16,0.58,0.09]
                ];
                for (var i = 0; i < craters.length; ++i) {
                    var c = craters[i];
                    var cr = c[2] * r;
                    var cx = x + c[0] * r;
                    var cy = y + c[1] * r;
                    ctx.beginPath();
                    ctx.arc(cx, cy, cr, 0, 2 * Math.PI, false);
                    ctx.fillStyle = "rgba(82,99,115,0.15)";
                    ctx.fill();
                    ctx.beginPath();
                    ctx.arc(cx - cr * 0.15, cy - cr * 0.20, cr * 0.69, 0, 2 * Math.PI, false);
                    ctx.fillStyle = "rgba(255,255,255,0.14)";
                    ctx.fill();
                }

                // Shadow is exactly the region outside the lit crescent/gibbous.
                // The terminator is elliptical, not a sliding full circle.
                var terminator = Math.cos(2 * Math.PI * root.phase);
                ctx.fillStyle = "rgba(8,14,21,0.955)";
                var step = Math.max(0.60, r / 145);
                for (var yy = -r; yy < r; yy += step) {
                    var off = Math.max(-r, Math.min(r, yy + step / 2));
                    var edge = Math.sqrt(Math.max(0, r * r - off * off));
                    var left, right;
                    if (root.phase < 0.5) {
                        left = -edge;
                        right = terminator * edge;
                    } else {
                        left = -terminator * edge;
                        right = edge;
                    }
                    ctx.fillRect(x + left, y + yy, Math.max(0, right - left), step + 0.45);
                }
                ctx.restore();
                ctx.beginPath();
                ctx.arc(x, y, r - 0.5, 0, 2 * Math.PI, false);
                ctx.lineWidth = 1.0;
                ctx.strokeStyle = "rgba(225,236,243,0.44)";
                ctx.stroke();
            }
        }

        // A few gentle, original stars; only slow opacity animation.
        Repeater {
            model: [ {x:0.10,y:0.18,s:2}, {x:0.87,y:0.21,s:3}, {x:0.92,y:0.78,s:2}, {x:0.13,y:0.82,s:2} ]
            delegate: Rectangle {
                required property var modelData
                x: moonArea.width * modelData.x
                y: moonArea.height * modelData.y
                width: modelData.s
                height: width
                radius: width / 2
                color: studioPalette.paint("#DDE5EC", "text")
                opacity: 0.5
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.20; duration: 2400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.65; duration: 2400; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    Connections {
        target: root
        function onPhaseChanged() { moonFace.requestPaint(); }
    }

    Item {
        id: readings
        x: root.wide ? root.width * 0.51 : 7
        y: root.wide ? root.height * 0.16 : moonArea.y + moonArea.height - 1
        width: root.wide ? Math.max(60, root.width - x - 8) : root.width - 14
        height: root.wide ? root.height * 0.70 : Math.max(36, root.height - y)

        Text {
            id: title
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: root.wide ? Text.AlignLeft : Text.AlignHCenter
            text: "LUNAR / PHASE"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: root.wide ? Math.max(10, Math.min(13, root.height * 0.055)) : 10
            color: studioPalette.paint("#B7C2CC", "text")
            elide: Text.ElideRight
        }
        Text {
            id: phaseLabel
            anchors.top: title.bottom
            anchors.topMargin: root.wide ? 11 : 4
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: root.wide ? Text.AlignLeft : Text.AlignHCenter
            text: root.phaseName
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: root.wide ? Math.max(14, Math.min(21, root.height * 0.10)) : Math.max(12, Math.min(16, root.width * 0.065))
            color: studioPalette.paint("#F0F3F6", "text")
            elide: Text.ElideRight
        }
        Rectangle {
            id: divider
            anchors.top: phaseLabel.bottom
            anchors.topMargin: root.wide ? 10 : 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.wide ? parent.width : parent.width * 0.68
            height: 1
            color: studioPalette.paint("#4A738390", "muted")
        }
        Text {
            anchors.top: divider.bottom
            anchors.topMargin: root.wide ? 10 : 5
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: root.wide ? Text.AlignLeft : Text.AlignHCenter
            text: "LIGHT " + root.illuminationPercent + "%  ·  AGE " + root.moonAge.toFixed(1) + "D"
            font.family: "JetBrains Mono"
            font.pixelSize: root.wide ? Math.max(9, Math.min(12, root.height * 0.055)) : 10
            color: studioPalette.paint("#D4DDE5", "text")
            elide: Text.ElideRight
        }
    }
}
