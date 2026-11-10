import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// Misty Meadow: genuine filesystem usage, restrained horizontal meter.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 420
    implicitHeight: 156
    Layout.minimumWidth: 265
    Layout.minimumHeight: 120

    readonly property string mono: "JetBrains Mono"
    readonly property color bg: studioPalette.paint("#D813191A", "surface")
    readonly property color borderCol: studioPalette.paint("#4E7D9082", "border")
    readonly property color accent: studioPalette.paint(usedPercent > 90 ? "#C99A86" : "#A9BEA2", "accent")
    readonly property color fg: studioPalette.paint("#EBEEE9", "text")
    readonly property color muted: studioPalette.paint("#9CA9A1", "muted")
    readonly property real usedPercent: Math.max(0, Math.min(100, Number(info.percent || 0)))
    readonly property string py: Qt.resolvedUrl("../scripts/diskstats.py").toString().replace("file://", "")
    property var info: ({ "ok": false, "percent": 0, "usedGiB": 0, "totalGiB": 0, "availableGiB": 0 })
    property bool busy: false
    function poll() { if (busy) return; busy = true; stats.connectSource('python3 "' + py + '"') }
    Component.onCompleted: poll()
    P5Support.DataSource {
        id: stats; engine: "executable"
        onNewData: function(name, data) {
            root.busy = false
            try { root.info = JSON.parse(String(data["stdout"] || "").trim()) }
            catch (e) { root.info = ({ "ok": false, "percent": 0, "usedGiB": 0, "totalGiB": 0, "availableGiB": 0 }) }
            disconnectSource(name)
        }
    }
    Timer { interval: root.lowPower ? 300000 : 120000; repeat: true; running: root.visible; onTriggered: root.poll() }
    function meter(value, cells) {
        var n=Math.max(1,Math.round(value/100*cells))
        return "█".repeat(root.usedPercent <= 0 ? 0 : n) + "·".repeat(cells-(root.usedPercent <= 0 ? 0 : n))
    }
    

    property string selectedStyle: Plasmoid.configuration.widgetStyle || "terminal"
    property color accentTint: studioPalette.paint(Plasmoid.configuration.accentColor || "#9FB6A2", "accent")
    property color glassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")
    property int glassOpacity: Math.max(25,Math.min(98,Plasmoid.configuration.glassOpacity ?? 78))
    property int glassBlur: Math.max(0,Math.min(100,Plasmoid.configuration.glassBlur ?? 45))
    property int cornerRadius: Math.max(4,Math.min(30,Plasmoid.configuration.cornerRadius ?? 18))
    property real scaleFactor: Math.max(0.75,Math.min(1.5,(Plasmoid.configuration.textScale ?? 100)/100.0))
    property bool lowPower: Plasmoid.configuration.lowPower === undefined ? true : Plasmoid.configuration.lowPower

    Loader { anchors.fill: parent; sourceComponent: root.selectedStyle === "glass" ? glassView : root.selectedStyle === "minimal" ? minimalView : terminalView }
    Component { id: terminalView;
Item {
        anchors.fill: parent
        id: terminal
        
        
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        clip: true
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: studioPalette.panel(Qt.rgba(0.05,0.08,0.09,0.92))
            border.width: 1
            border.color: studioPalette.outline("#566b746b")
        }
        Rectangle { x: 12; y: 29; width: Math.max(0,parent.width-24); height: 1; color: studioPalette.paint("#626D846E", "border") }
        Text {
            x: 13; y: 9; width: parent.width-100
            text: "user@cachyos  ~/mnt/root"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
            elide: Text.ElideRight
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 13; y: 9
            text: root.info.ok ? "● mounted" : "○ waiting"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
        }
        Text {
            x: 13; y: 42; width: parent.width-26
            text: "rootfs  /  " + (root.info.ok ? Math.round(root.usedPercent) + "% used" : "reading...")
            font.family: root.mono; font.pixelSize: Math.max(8,Math.round(15*root.scaleFactor)); color: studioPalette.paint("#D2DCD0", "text")
        }
        Text {
            x: 13; y: 77; width: parent.width-26
            text: "[" + root.meter(root.usedPercent,31) + "]"
            font.family: root.mono; font.pixelSize: Math.max(9,Math.min(12,terminal.width/38)); color: root.usedPercent >= 90 ? "#CBB18D" : "#A4B6A2"
        }
        Text {
            x: 13; y: 102; width: parent.width-26; elide: Text.ElideRight
            text: root.info.ok ? "used " + root.info.usedGiB + "G     free " + root.info.availableGiB + "G     total " + root.info.totalGiB + "G" : "awaiting filesystem statistics"
            font.family: root.mono; font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#96A49A", "muted")
        }
    }
    }
Component {
 id: glassView
 Item {
    id: glass
    anchors.fill: parent
    clip: true
    StudioSurface { anchors.fill: parent; variant: "glass"; baseColor: "#142022"; accent: studioPalette.paint(root.glassTint, "accent"); alphaPercent: root.glassOpacity; radiusSize: root.cornerRadius; blurStrength: root.glassBlur }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.width < 320 ? 12 : 18
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Text { text: "STORAGE / ROOT"; font.family: "Noto Sans"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#F4F8FF", "text"); Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { Layout.preferredWidth: statusLabel.implicitWidth+17; Layout.preferredHeight: 22; radius: 11; color: studioPalette.paint("#36596d63", "muted"); border.color: studioPalette.paint("#5595b2a5", "border"); border.width: 1
                Text { id: statusLabel; anchors.centerIn: parent; text: root.info.ok ? "MOUNTED" : "READING"; font.family: "Noto Sans"; font.pixelSize: 9; color: root.accentTint }
            }
        }
                GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: root.width < 320 ? 10 : 24
            rowSpacing: 8
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "USED"
            value: Math.round(root.usedPercent) + "%"
            subtext: root.info.ok ? root.info.usedGiB + " GiB used" : "reading disk"
            progress: root.usedPercent
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "AVAILABLE"
            value: root.info.ok ? root.info.availableGiB + " GiB" : "--"
            subtext: root.info.ok ? root.info.totalGiB + " GiB total" : "--"
            progress: -1
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        }

    }
 }
}
Component {
 id: minimalView
 Item {
   id: minimal
   anchors.fill: parent
   clip: true
   Rectangle { anchors.fill: parent; radius: 7; visible: studioPalette.custom;
               color: studioPalette.panel("#DA1B2026"); border.width: 1;
               border.color: studioPalette.outline("#657A838D") }
   ColumnLayout {
      anchors.fill: parent
      anchors.margins: root.width < 310 ? 8 : 13
      spacing: 4
      Text { Layout.fillWidth: true; text: "STORAGE / ROOT"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: root.accentTint; elide: Text.ElideRight }
      Text { Layout.fillWidth: true; Layout.fillHeight: true; text: Math.round(root.usedPercent) + "%"; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: Math.min(root.height*0.30,root.width*0.17)*root.scaleFactor; minimumPixelSize: 18; fontSizeMode: Text.Fit; color: studioPalette.paint("#e8efeb", "text"); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: root.accentTint; opacity: 0.54 }
      Text { Layout.fillWidth: true; text: "Available " + (root.info.availableGiB || "--") + " GiB    Total " + (root.info.totalGiB || "--") + " GiB"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#bbc8bf", "text"); elide: Text.ElideRight }
   }
 }
}
}
