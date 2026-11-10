import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// Misty Meadow: actual monitoring, flat rows, no decorative hardware artwork.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 420
    implicitHeight: 192
    Layout.minimumWidth: 290
    Layout.minimumHeight: 150


    readonly property string mono: "JetBrains Mono"
    readonly property color bg: studioPalette.paint("#D813191A", "surface")
    readonly property color borderCol: studioPalette.paint("#4E7D9082", "border")
    readonly property color accent: studioPalette.paint("#A9BEA2", "accent")
    readonly property color fg: studioPalette.paint("#EBEEE9", "text")
    readonly property color muted: studioPalette.paint("#9CA9A1", "muted")
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/metrics.py").toString().replace("file://", "")


    // Identity comes from this computer (metrics.py), not from saved widget defaults.
    property string cpuVendor: "generic"
    property string cpuModel: "Detecting CPU…"
    property int cpuCores: 0
    property int cpuThreads: 0
    property string gpuVendor: "generic"
    property string gpuModel: "Detecting GPU…"
    readonly property bool exactRyzen5700X: cpuVendor === "amd" && /\bRyzen\s+7\s+5700X\b/i.test(cpuModel)
    readonly property bool hasRtxArtwork: gpuVendor === "nvidia" && /\bRTX\b/i.test(gpuModel)
    function cpuFamily() {
        const n = cpuModel.toLowerCase();
        if (n.indexOf("ryzen") >= 0) return "RYZEN";
        if (n.indexOf("epyc") >= 0) return "EPYC";
        if (n.indexOf("core") >= 0) return "CORE";
        if (n.indexOf("xeon") >= 0) return "XEON";
        return "PROCESSOR";
    }
    function cpuChipLabel() {
        if (cpuVendor === "amd" && cpuFamily() === "RYZEN") return cpuModel.replace(/^.*?Ryzen\s*/i, "").replace(/\s+\d+-Core.*/i, "").trim();
        if (cpuVendor === "intel") {
            const match = cpuModel.match(/\bi[3579][- ]?[a-z0-9-]+/i);
            if (match) return match[0];
        }
        return cpuModel.replace(/\s*\([^)]*\)/g, "").replace(/^(AMD|Intel)\s+/i, "").slice(0, 36);
    }
    function gpuBadge() {
        if (gpuVendor === "amd") return "RADEON";
        if (gpuVendor === "intel") return /\bArc\b/i.test(gpuModel) ? "INTEL ARC" : "INTEL";
        if (gpuVendor === "nvidia") return /\bGTX\b/i.test(gpuModel) ? "GEFORCE GTX" : "NVIDIA";
        return "GPU";
    }
    function shortGpuName() {
        return gpuModel.replace(/^.*?((?:GeForce\s+)?(?:RTX|GTX)\s*\d+[a-z0-9]*).*$/i, "$1")
                       .replace(/^(?:Advanced Micro Devices, Inc\.?|NVIDIA Corporation)\s*[:\[]?\s*/i, "")
                       .slice(0, 46);
    }

    property real cpuUsage: 0
    property real cpuTemp: -1
    property real cpuClock: -1
    property real gpuUsage: 0
    property real gpuTemp: -1
    property real gpuClock: -1
    property real gpuFan: -1
    property real ramUsed: 0
    property real ramTotal: 0
    property real vramUsed: 0
    property real vramTotal: 0
    property bool receivedData: false
    property bool nvidiaAvailable: false
    property var cpuHistory: []
    property var gpuHistory: []

    function clamp(v) { return Math.max(0, Math.min(100, Number(v) || 0)) }
    function numeric(v) { if (v === "--" || v === undefined || v === null || v === "") return -1; const n = Number(v); return isFinite(n) ? n : -1 }
    function niceTemp(v) { return v < 0 ? "--°" : Math.round(v) + "°" }
    function niceClock(v) { return v < 0 ? "--" : v.toFixed(2) }
    function niceRam(v) { return Number(v || 0).toFixed(1) }

    function meter(value, cells) {
        var total = Math.max(2, cells)
        var full = Math.round(clamp(value) / 100 * total)
        return "█".repeat(full) + "·".repeat(total - full)
    }
    function spark(values, count) {
        if (!values || values.length === 0) return "·".repeat(count)
        var glyphs = "▁▂▃▄▅▆▇█"
        var out = ""
        var recent = values.slice(-count)
        while (out.length + recent.length < count) out += "·"
        for (var i=0; i<recent.length; ++i) {
            var v = Math.max(0,Math.min(100,Number(recent[i]) || 0))
            out += glyphs.charAt(Math.min(7,Math.floor(v*8/101)))
        }
        return out
    }
    function usedRamPercent() { return ramTotal > 0 ? clamp(ramUsed/ramTotal*100) : 0 }
    function usedVramPercent() { return vramTotal > 0 ? clamp(vramUsed/vramTotal*100) : 0 }
    
    P5Support.DataSource {
        id: collector
        engine: 'executable'
        connectedSources: ['/usr/bin/python3 ' + root.scriptPath]
        interval: root.lowPower ? 10000 : 5000
        onNewData: (sourceName, data) => {
            const output = (data['stdout'] || '').trim();
            if (!output) return;
            let values = {};
            output.split(/\r?\n/).forEach(function(line) {
                const eq = line.indexOf('=');
                if (eq > 0) values[line.slice(0, eq)] = line.slice(eq + 1).trim();
            });
            if (values.CPU_USAGE === undefined) return;
            if (values.CPU_VENDOR !== undefined) root.cpuVendor = values.CPU_VENDOR;
            if (values.CPU_MODEL !== undefined) root.cpuModel = values.CPU_MODEL;
            if (values.CPU_CORES !== undefined) root.cpuCores = Number(values.CPU_CORES) || 0;
            if (values.CPU_THREADS !== undefined) root.cpuThreads = Number(values.CPU_THREADS) || 0;
            if (values.GPU_VENDOR !== undefined) root.gpuVendor = values.GPU_VENDOR;
            if (values.GPU_MODEL !== undefined) root.gpuModel = values.GPU_MODEL;
            root.cpuUsage = root.clamp(values.CPU_USAGE);
            root.cpuTemp = root.numeric(values.CPU_TEMP);
            root.cpuClock = root.numeric(values.CPU_CLOCK);
            root.gpuUsage = root.clamp(values.GPU_USAGE);
            root.gpuTemp = root.numeric(values.GPU_TEMP);
            root.gpuClock = root.numeric(values.GPU_CLOCK);
            root.gpuFan = root.numeric(values.GPU_FAN);
            root.nvidiaAvailable = values.GPU_USAGE !== '--' && values.GPU_USAGE !== undefined;
            root.ramUsed = Number(values.RAM_USED) || 0;
            root.ramTotal = Number(values.RAM_TOTAL) || 0;
            root.vramUsed = Number(values.VRAM_USED) || 0;
            root.vramTotal = Number(values.VRAM_TOTAL) || 0;
            root.cpuHistory = root.cpuHistory.slice(-39).concat([root.cpuUsage]);
            root.gpuHistory = root.gpuHistory.slice(-39).concat([root.gpuUsage]);
            root.receivedData = true;
        }
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
            text: "system@local  ~/" + (root.cpuVendor === "generic" ? "monitor" : root.cpuVendor)
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
            elide: Text.ElideRight
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 13; y: 9
            text: root.receivedData ? "● live" : "○ waiting"
            font.family: root.mono
            font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor))
            color: root.accentTint
        }
        Text {
            id: dataLines
            x: 13; y: 39; width: parent.width-26
            font.family: root.mono
            font.pixelSize: Math.max(9,Math.min(12,terminal.width/37))
            lineHeight: 1.3; lineHeightMode: Text.ProportionalHeight
            color: studioPalette.paint("#D2DCD0", "text")
            text: "CPU  " + String(Math.round(root.cpuUsage)).padStart(3," ") + "%  [" + root.meter(root.cpuUsage,16) + "]  " + root.niceTemp(root.cpuTemp) + "\n" +
                  "     " + root.spark(root.cpuHistory,36) + "\n" +
                  "GPU  " + (root.nvidiaAvailable ? String(Math.round(root.gpuUsage)).padStart(3," ") + "%" : " --%") + "  [" + root.meter(root.gpuUsage,16) + "]  " + root.niceTemp(root.gpuTemp) + "\n" +
                  "     " + root.spark(root.gpuHistory,36) + "\n" +
                  "RAM  " + root.niceRam(root.ramUsed).padStart(4," ") + "/" + root.niceRam(root.ramTotal) + "G [" + root.meter(root.usedRamPercent(),13) + "]\n" +
                  "VRAM " + (root.nvidiaAvailable ? root.niceRam(root.vramUsed) + "/" + root.niceRam(root.vramTotal) + "G [" + root.meter(root.usedVramPercent(),13) + "]" : "GPU data unavailable")
        }
        Rectangle { x: 13; anchors.bottom: footer.top; anchors.bottomMargin: 7; width: Math.max(0,parent.width-26); height: 1; color: studioPalette.paint("#526A755F", "muted") }
        Text {
            id: footer
            x: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: parent.width-26
            text: "cpu " + root.niceClock(root.cpuClock) + " GHz    gpu " + root.niceClock(root.gpuClock) + " GHz    refresh 5s"
            font.family: root.mono; font.pixelSize: Math.max(8,Math.round(9*root.scaleFactor))
            color: studioPalette.paint("#8C9B90", "muted"); elide: Text.ElideRight
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
            Text { text: "SYSTEM / PULSE"; font.family: "Noto Sans"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#F4F8FF", "text"); Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { Layout.preferredWidth: statusLabel.implicitWidth+17; Layout.preferredHeight: 22; radius: 11; color: studioPalette.paint("#36596d63", "muted"); border.color: studioPalette.paint("#5595b2a5", "border"); border.width: 1
                Text { id: statusLabel; anchors.centerIn: parent; text: root.receivedData ? "LIVE" : "READING"; font.family: "Noto Sans"; font.pixelSize: 9; color: root.accentTint }
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
            label: "CPU"
            value: Math.round(root.cpuUsage) + "%"
            subtext: root.niceTemp(root.cpuTemp)
            progress: root.cpuUsage
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "GPU"
            value: root.nvidiaAvailable ? Math.round(root.gpuUsage) + "%" : "--"
            subtext: root.niceTemp(root.gpuTemp)
            progress: root.gpuUsage
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "RAM"
            value: root.niceRam(root.ramUsed) + " GiB"
            subtext: root.niceRam(root.ramTotal) + " GiB total"
            progress: root.usedRamPercent()
            accent: studioPalette.paint(root.accentTint, "accent")
            textScale: root.scaleFactor
        }
        StudioMetric {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.preferredHeight: root.height < 205 ? 52 : 68
            label: "VRAM"
            value: root.nvidiaAvailable ? root.niceRam(root.vramUsed) + " GiB" : "--"
            subtext: root.niceRam(root.vramTotal) + " GiB total"
            progress: root.usedVramPercent()
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
      Text { Layout.fillWidth: true; text: "SYSTEM / PULSE"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: root.accentTint; elide: Text.ElideRight }
      Text { Layout.fillWidth: true; Layout.fillHeight: true; text: Math.round(root.cpuUsage) + "%"; font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: Math.min(root.height*0.30,root.width*0.17)*root.scaleFactor; minimumPixelSize: 18; fontSizeMode: Text.Fit; color: studioPalette.paint("#e8efeb", "text"); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: root.accentTint; opacity: 0.54 }
      Text { Layout.fillWidth: true; text: "CPU " + root.niceTemp(root.cpuTemp) + "    GPU " + root.niceTemp(root.gpuTemp) + "    RAM " + root.niceRam(root.ramUsed) + "G"; font.family: "JetBrains Mono"; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#bbc8bf", "text"); elide: Text.ElideRight }
   }
 }
}
}
