import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// Misty Meadow: network facts instead of decorative radar sweep.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 420
    implicitHeight: 175
    Layout.minimumWidth: 280
    Layout.minimumHeight: 140

    readonly property string mono: "JetBrains Mono"
    readonly property color bg: studioPalette.paint("#D813191A", "surface")
    readonly property color borderCol: studioPalette.paint("#4E7D9082", "border")
    readonly property color accent: studioPalette.paint("#A9BEA2", "accent")
    readonly property color fg: studioPalette.paint("#EBEEE9", "text")
    readonly property color muted: studioPalette.paint("#9CA9A1", "muted")
    readonly property string py: Qt.resolvedUrl("../scripts/netstats.py").toString().replace("file://", "")
    property var info: ({ "online": false, "iface": "--", "ssid": "CONNECTING", "downMbps": 0, "upMbps": 0, "pingMs": null, "signalDbm": null, "signalPercent": null })
    property bool busy: false
    property bool received: false
    function rate(v) { var n = Math.max(0, Number(v || 0)); return n >= 100 ? n.toFixed(0) : n.toFixed(1) }
    function refresh() { if (busy) return; busy = true; probe.connectSource('python3 "' + py + '"') }
    Component.onCompleted: refresh()
    P5Support.DataSource {
        id: probe; engine: "executable"
        onNewData: function(name, data) {
            root.busy = false
            try { root.info = JSON.parse(String(data["stdout"] || "").trim()); root.received = true; root.rxHistory = root.rxHistory.slice(-39).concat([Math.max(0,Number(root.info.downMbps)||0)]); root.txHistory = root.txHistory.slice(-39).concat([Math.max(0,Number(root.info.upMbps)||0)]) }
            catch (e) { root.info = ({ "online": false, "iface": "--", "ssid": "UNAVAILABLE", "downMbps": 0, "upMbps": 0, "pingMs": null, "signalDbm": null, "signalPercent": null }) }
            disconnectSource(name)
        }
    }
    Timer { interval: root.lowPower ? 15000 : 7000; repeat: true; running: root.visible; onTriggered: root.refresh() }

    property var rxHistory: []
    property var txHistory: []
    function plot(history, cells) {
        var glyphs="▁▂▃▄▅▆▇█"
        var out=""; var recent=history.slice(-cells)
        var peak=1; for (var j=0;j<recent.length;++j) peak=Math.max(peak,Number(recent[j])||0)
        while (out.length+recent.length<cells) out+="·"
        for (var i=0;i<recent.length;++i) out+=glyphs.charAt(Math.min(7,Math.floor(Math.max(0,recent[i])*8/(peak+0.001))))
        return out
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
            text: "network@local  ~/net  " + (root.info.iface || "--")
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
            elide: Text.ElideRight
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 13; y: 9
            text: root.info.online ? "● online" : "○ offline"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
        }
        Text {
            x: 13; y: 40; width: parent.width-26
            font.family: root.mono; font.pixelSize: Math.max(10, Math.min(12,terminal.width/37))
            lineHeight: 1.3; lineHeightMode: Text.ProportionalHeight
            color: studioPalette.paint("#D2DCD0", "text")
            text: "RX  ↓ " + root.rate(root.info.downMbps).padStart(7," ") + " Mbit/s\n" +
                  "    " + root.plot(root.rxHistory,37) + "\n" +
                  "TX  ↑ " + root.rate(root.info.upMbps).padStart(7," ") + " Mbit/s\n" +
                  "    " + root.plot(root.txHistory,37)
        }
        Rectangle { x: 13; anchors.bottom: footer.top; anchors.bottomMargin: 7; width: Math.max(0,parent.width-26); height: 1; color: studioPalette.paint("#526A755F", "muted") }
        Text {
            id: footer
            x: 13; width: parent.width-26; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
            text: "ssid " + (root.info.ssid || "--").slice(0,18) +
                  "  /  ping " + (root.info.pingMs === null || root.info.pingMs === undefined ? "--" : Math.round(Number(root.info.pingMs))) + "ms"
            elide: Text.ElideRight; font.family: root.mono; font.pixelSize: Math.max(8,Math.round(9*root.scaleFactor)); color: studioPalette.paint("#8C9B90", "muted")
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
            Text { text: "NETWORK / RADAR"; font.family: "Noto Sans"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#F4F8FF", "text"); Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { Layout.preferredWidth: statusLabel.implicitWidth+17; Layout.preferredHeight: 22; radius: 11; color: studioPalette.paint("#36596d63", "muted"); border.color: studioPalette.paint("#5595b2a5", "border"); border.width: 1
                Text { id: statusLabel; anchors.centerIn: parent; text: root.info.online ? "ONLINE" : "OFFLINE"; font.family: "Noto Sans"; font.pixelSize: 9; color: root.accentTint }
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
            label: "DOWNLOAD"
            value: root.rate(root.info.downMbps) + " Mb/s"
            subtext: root.info.iface || "--"
            progress: -1
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "UPLOAD"
            value: root.rate(root.info.upMbps) + " Mb/s"
            subtext: root.info.ssid || "--"
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
      Text { Layout.fillWidth: true; text: "NETWORK / RADAR"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: root.accentTint; elide: Text.ElideRight }
      Text { Layout.fillWidth: true; Layout.fillHeight: true; text: root.rate(root.info.downMbps) + " Mb/s"; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: Math.min(root.height*0.30,root.width*0.17)*root.scaleFactor; minimumPixelSize: 18; fontSizeMode: Text.Fit; color: studioPalette.paint("#e8efeb", "text"); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: root.accentTint; opacity: 0.54 }
      Text { Layout.fillWidth: true; text: "↑ " + root.rate(root.info.upMbps) + " Mb/s    interface " + (root.info.iface || "--"); font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#bbc8bf", "text"); elide: Text.ElideRight }
   }
 }
}
}
