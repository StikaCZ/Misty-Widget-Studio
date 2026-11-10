import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "ServerBridge.js" as Server

// Misty Meadow: one read-only Debian SSH check at configured intervals.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 420
    implicitHeight: 208
    Layout.minimumWidth: 290
    Layout.minimumHeight: 160

    readonly property string mono: "JetBrains Mono"
    readonly property color bg: studioPalette.paint("#D813191A", "surface")
    readonly property color borderCol: studioPalette.paint("#4E7D9082", "border")
    readonly property color accent: studioPalette.paint("#A9BEA2", "accent")
    readonly property color fg: studioPalette.paint("#EBEEE9", "text")
    readonly property color muted: studioPalette.paint("#9CA9A1", "muted")
    property var readings: ({})
    property bool online: false
    property bool checked: false
    property string lastUpdate: "--:--"
    function value(key, fallback) { const raw = root.readings[key]; return raw === undefined || raw === "" ? (fallback || "--") : String(raw) }
    function fetchStats() {
        if (statsSource.connectedSources.length !== 0) return
        if (Plasmoid.configuration.serverEnabled === false) {
            updateFromText("STATUS  OFFLINE\nDETAIL  Monitoring disabled")
            return
        }
        statsSource.connectSource(Server.sshCommand(
            Plasmoid.configuration.serverHost, Plasmoid.configuration.serverUser,
            Plasmoid.configuration.serverPort, Plasmoid.configuration.serverKeyPath,
            Plasmoid.configuration.serverService, false))
    }
    function updateFromText(output) {
        const next = {}
        const lines = String(output || "").split(/\r?\n/)
        for (let i=0; i<lines.length; i++) {
            const match = lines[i].match(/^\s*(.+?)\s{2,}(.+?)\s*$/)
            if (match) next[match[1].trim().toUpperCase()] = match[2].trim()
        }
        root.readings = next
        root.online = (next["STATUS"] || "").toUpperCase() === "ONLINE"
        root.checked = true
        root.lastUpdate = Qt.formatTime(new Date(), "hh:mm")
    }
    function uptimeShort(text) {
        const s = String(text || ""); if (!s || s === "--") return "--"
        const days=s.match(/(\d+)\s+days?/i), hours=s.match(/(\d+)\s+hours?/i), minutes=s.match(/(\d+)\s+minutes?/i)
        let parts=[]; if (days) parts.push(days[1]+"d"); if (hours) parts.push(hours[1]+"h"); if (minutes) parts.push(minutes[1]+"m")
        return parts.length ? parts.join("  ") : s.replace(/^up\s+/i, "").slice(0,30)
    }
    Component.onCompleted: fetchStats()
    P5Support.DataSource {
        id: statsSource; engine: "executable"; connectedSources: []
        onNewData: function(sourceName,data) { root.updateFromText(data["stdout"] || ""); disconnectSource(sourceName) }
    }
    Timer {
        interval: Math.max(15, Math.min(300, Plasmoid.configuration.serverPollSeconds || 30)) * 1000
        running: root.visible
        repeat: true
        onTriggered: root.fetchStats()
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
            text: (Plasmoid.configuration.serverUser || "user") + "@" + (Plasmoid.configuration.serverHost || "debian") + " ~ / monitor"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
            elide: Text.ElideRight
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 13; y: 9
            text: root.online ? "● ssh reachable" : "○ disconnected"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
        }
        Text {
            x: 13; y: 40; width: parent.width-26
            text: "status    " + (root.checked ? (root.online ? "ONLINE" : "OFFLINE") : "CHECKING") + "\n" +
                  "host      " + (Plasmoid.configuration.serverHost || "debian") + "\n" +
                  "cpu temp  " + (root.online ? root.value("CPU TEMP") : "--") + "\n" +
                  "ram       " + (root.online ? root.value("RAM") : "--") + "\n" +
                  "disk      " + (root.online ? root.value("DISK") : "--") + "\n" +
                  "load 1m   " + (root.online ? root.value("LOAD (1m)") : "--")
            color: studioPalette.paint("#D2DCD0", "text"); font.family: root.mono
            font.pixelSize: Math.max(10,Math.min(12,terminal.width/37)); lineHeight: 1.26; lineHeightMode: Text.ProportionalHeight
        }
        Rectangle { x: 13; anchors.bottom: footer.top; anchors.bottomMargin: 7; width: Math.max(0,parent.width-26); height: 1; color: studioPalette.paint("#526A755F", "muted") }
        Text {
            id: footer
            x: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 9; width: parent.width-26
            text: "up " + (root.online ? root.uptimeShort(root.value("UPTIME")) : "--") +
                  "  |  terraria " + (root.online ? root.value("TERRARIA") : "--")
            color: studioPalette.paint("#8C9B90", "muted"); font.family: root.mono; font.pixelSize: Math.max(8,Math.round(9*root.scaleFactor)); elide: Text.ElideRight
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
            Text { text: "DEBIAN / HOMELAB"; font.family: "Noto Sans"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#F4F8FF", "text"); Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { Layout.preferredWidth: statusLabel.implicitWidth+17; Layout.preferredHeight: 22; radius: 11; color: studioPalette.paint("#36596d63", "muted"); border.color: studioPalette.paint("#5595b2a5", "border"); border.width: 1
                Text { id: statusLabel; anchors.centerIn: parent; text: root.online ? "CONNECTED" : root.checked ? "OFFLINE" : "CONNECTING"; font.family: "Noto Sans"; font.pixelSize: 9; color: root.accentTint }
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
            label: "CPU TEMP"
            value: root.online ? root.value("CPU TEMP") : "--"
            subtext: "Debian"
            progress: -1
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "MEMORY"
            value: root.online ? root.value("RAM") : "--"
            subtext: "Memory"
            progress: -1
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "DISK"
            value: root.online ? root.value("DISK") : "--"
            subtext: "Filesystem"
            progress: -1
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "LOAD 1M"
            value: root.online ? root.value("LOAD (1m)") : "--"
            subtext: "Server load"
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
      Text { Layout.fillWidth: true; text: "DEBIAN / HOMELAB"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: root.accentTint; elide: Text.ElideRight }
      Text { Layout.fillWidth: true; Layout.fillHeight: true; text: root.online ? root.value("CPU TEMP") : "OFFLINE"; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: Math.min(root.height*0.30,root.width*0.17)*root.scaleFactor; minimumPixelSize: 18; fontSizeMode: Text.Fit; color: studioPalette.paint("#e8efeb", "text"); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: root.accentTint; opacity: 0.54 }
      Text { Layout.fillWidth: true; text: "UP " + (root.online ? root.uptimeShort(root.value("UPTIME")) : "--") + "   TERRARIA " + (root.online ? root.value("TERRARIA") : "--"); font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#bbc8bf", "text"); elide: Text.ElideRight }
   }
 }
}
}
