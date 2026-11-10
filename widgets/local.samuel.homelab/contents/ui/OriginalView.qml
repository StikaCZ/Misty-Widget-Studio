import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "ServerBridge.js" as Server

// Homelab · Unified Forest theme. Uses packaged SSH monitor and SSH agent.
// No background daemon. Read-only one-shot SSH checks at configured intervals.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 380
    implicitHeight: 348
    Layout.minimumWidth: 268
    Layout.minimumHeight: 254


    readonly property string mono: "JetBrains Mono"
    readonly property bool compact: width < 340 || height < 310
    readonly property color panelBg: studioPalette.panel("#DA1B2026")
    readonly property color panelStroke: studioPalette.outline("#7E94A0A9")
    readonly property color tileBg: studioPalette.paint("#75121820", "surface")
    readonly property color tileStroke: studioPalette.paint("#3569747E", "border")
    readonly property color divider: studioPalette.paint("#586B737C", "border")
    readonly property color primaryText: studioPalette.paint("#F2F4F7", "text")
    readonly property color secondaryText: studioPalette.paint("#B6C0C9", "muted")
    property var readings: ({})
    property bool online: false
    property bool checked: false
    property string lastUpdate: "--:--"

    function value(key, fallback) {
        const raw = root.readings[key];
        return raw === undefined || raw === "" ? (fallback || "--") : String(raw);
    }
    function fetchStats() {
        if (statsSource.connectedSources.length !== 0) return
        if (Plasmoid.configuration.serverEnabled === false) {
            updateFromText("STATUS  OFFLINE\nDETAIL  Monitoring is disabled in Configure")
            return
        }
        statsSource.connectSource(Server.sshCommand(
            Plasmoid.configuration.serverHost, Plasmoid.configuration.serverUser,
            Plasmoid.configuration.serverPort, Plasmoid.configuration.serverKeyPath,
            Plasmoid.configuration.serverService, false))
    }
    function updateFromText(output) {
        const next = {};
        const lines = String(output || "").split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^\s*(.+?)\s{2,}(.+?)\s*$/);
            if (match) next[match[1].trim().toUpperCase()] = match[2].trim();
        }
        root.readings = next;
        root.online = (next["STATUS"] || "").toUpperCase() === "ONLINE";
        root.checked = true;
        root.lastUpdate = Qt.formatTime(new Date(), "hh:mm");
    }
    function uptimeShort(text) {
        const s = String(text || "");
        if (!s || s === "--") return "--";
        const days = s.match(/(\d+)\s+days?/i);
        const hours = s.match(/(\d+)\s+hours?/i);
        const minutes = s.match(/(\d+)\s+minutes?/i);
        let parts = [];
        if (days) parts.push(days[1] + "d");
        if (hours) parts.push(hours[1] + "h");
        if (minutes) parts.push(minutes[1] + "m");
        return parts.length ? parts.join("  ") : s.replace(/^up\s+/i, "").slice(0, 30);
    }

    Component.onCompleted: fetchStats()
    P5Support.DataSource {
        id: statsSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            root.updateFromText(data["stdout"] || "");
            disconnectSource(sourceName);
        }
    }
    Timer {
        interval: Math.max(15, Math.min(300, Plasmoid.configuration.serverPollSeconds || 30)) * 1000
        running: root.visible
        repeat: true
        onTriggered: root.fetchStats()
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: root.panelBg
        border.width: 1
        border.color: root.panelStroke
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.compact ? 40 : 48

        Rectangle {
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 19
            radius: 1
            color: root.primaryText
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 25
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(80, parent.width - 128)
            text: "HOMELAB / DEBIAN"
            color: root.primaryText
            font.family: root.mono
            font.bold: true
            font.pixelSize: root.compact ? 13 : 16
            elide: Text.ElideRight
        }
        Rectangle {
            id: liveDot
            width: 6; height: 6; radius: 3
            anchors.right: liveText.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: root.online ? "#A8D0BB" : "#A2A6AB"
        }
        Text {
            id: liveText
            anchors.right: parent.right
            anchors.rightMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            text: root.online ? "LIVE" : (root.checked ? "OFFLINE" : "WAIT")
            color: root.secondaryText
            font.family: root.mono
            font.pixelSize: 10
        }
        Rectangle {
            height: 1
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            color: root.divider
        }
    }

    Rectangle {
        id: statusLine
        anchors.top: header.bottom
        anchors.topMargin: 9
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        height: root.compact ? 31 : 36
        radius: 5
        color: root.tileBg
        border.width: 1
        border.color: root.tileStroke
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: root.online ? "●  SERVER ONLINE" : (root.checked ? "○  SSH UNAVAILABLE · Configure → Debian connection" : "○  CONNECTING")
            elide: Text.ElideRight
            width: parent.width - 110
            color: root.online ? "#D7E9DF" : root.secondaryText
            font.family: root.mono
            font.bold: true
            font.pixelSize: root.compact ? 11 : 12
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: root.lastUpdate
            color: root.secondaryText
            font.family: root.mono
            font.pixelSize: root.compact ? 9 : 10
        }
    }

    Item {
        id: metricsArea
        anchors.top: statusLine.bottom
        anchors.topMargin: 8
        anchors.bottom: footer.top
        anchors.bottomMargin: 9
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12

        GridLayout {
            id: metricGrid
            anchors.fill: parent
            columns: 2
            columnSpacing: 7
            rowSpacing: 7
            Repeater {
                model: ["CPU TEMP", "CPU FAN", "AMBIENT", "LOAD (1m)", "RAM", "DISK"]
                delegate: Rectangle {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    Layout.preferredWidth: (metricGrid.width - metricGrid.columnSpacing) / 2
                    Layout.preferredHeight: (metricGrid.height - metricGrid.rowSpacing * 2) / 3
                    radius: 5
                    color: root.tileBg
                    border.width: 1
                    border.color: root.tileStroke
                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: root.compact ? 6 : 9
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        text: modelData
                        color: root.secondaryText
                        font.family: root.mono
                        font.pixelSize: root.compact ? 9 : 10
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.compact ? 6 : 8
                        text: root.online ? root.value(modelData, "--") : "--"
                        color: root.primaryText
                        font.family: root.mono
                        font.bold: true
                        font.pixelSize: root.compact ? 13 : 17
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Item {
        id: footer
        height: root.compact ? 61 : 72
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            height: 1
            color: root.divider
        }
        Text {
            anchors.top: parent.top
            anchors.topMargin: 9
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 10
            text: "UPTIME   " + (root.online ? root.uptimeShort(root.value("UPTIME")) : "--")
            color: root.secondaryText
            font.family: root.mono
            font.pixelSize: root.compact ? 10 : 12
            elide: Text.ElideRight
        }
        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.compact ? 11 : 14
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: "TERRARIA   " + (root.online ? root.value("TERRARIA") : "--")
            color: root.primaryText
            font.family: root.mono
            font.pixelSize: root.compact ? 10 : 12
            elide: Text.ElideRight
        }
    }
}
