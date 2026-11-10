import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// System Pulse | v4.6.9: artwork selects itself from detected CPU/GPU identity.
// Zero extra daemons: the same metrics.py runs every 3s as before.
Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 750
    implicitHeight: 410
    Layout.minimumWidth: 350
    Layout.minimumHeight: 235


    readonly property bool compact: width < 700 || height < 400
    readonly property bool narrow: width < 535
    readonly property string mono: "JetBrains Mono"
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/metrics.py").toString().replace(/^file:\/\//, "")


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

    function clamp(v) { return Math.max(0, Math.min(100, Number(v) || 0)); }
    function numeric(v) {
        if (v === "--" || v === undefined || v === null || v === "") return -1;
        const n = Number(v);
        return isFinite(n) ? n : -1;
    }
    function niceTemp(v) { return v < 0 ? "--°" : Math.round(v) + "°C"; }
    function niceClock(v) { return v < 0 ? "--" : v.toFixed(2); }
    function niceRam(v) { return Number(v || 0).toFixed(1); }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: studioPalette.panel("#DA1B2026")
        border.width: 1
        border.color: studioPalette.outline("#7E94A0A9")
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.narrow ? 35 : (root.compact ? 40 : 49)

        Rectangle {
            x: 12
            width: 3
            radius: 1
            height: root.narrow ? 17 : 22
            anchors.verticalCenter: parent.verticalCenter
            color: studioPalette.paint("#EDF0F2", "text")
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "SYSTEM  /  PULSE"
            font.family: root.mono
            font.bold: true
            font.pixelSize: root.narrow ? 13 : (root.compact ? 16 : 19)
            color: studioPalette.paint("#F0F2F3", "text")
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: root.receivedData ? "● LIVE" : "○ WAIT"
            font.family: root.mono
            font.pixelSize: root.narrow ? 9 : 10
            color: studioPalette.paint("#BBC6CE", "text")
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            height: 1
            color: studioPalette.paint("#54656E75", "muted")
        }
    }

    Row {
        id: cards
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.narrow ? 7 : 10
        spacing: root.narrow ? 7 : 10

        Repeater {
            model: 2
            delegate: Rectangle {
                id: tile
                required property int index
                readonly property bool cpu: index === 0
                readonly property real usage: cpu ? root.cpuUsage : root.gpuUsage
                readonly property real temp: cpu ? root.cpuTemp : root.gpuTemp
                readonly property real clock: cpu ? root.cpuClock : root.gpuClock
                readonly property var history: cpu ? root.cpuHistory : root.gpuHistory
                readonly property int pad: root.narrow ? 6 : 11
                width: (cards.width - cards.spacing) / 2
                height: cards.height
                radius: 5
                color: studioPalette.paint("#E51C2227", "surface")
                border.width: 1
                border.color: studioPalette.paint("#647C858E", "border")

                Column {
                    id: titleBlock
                    anchors.top: parent.top
                    anchors.topMargin: root.narrow ? 5 : 7
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: tile.pad
                    anchors.rightMargin: tile.pad
                    spacing: 1

                    Text {
                        width: parent.width
                        height: root.narrow ? 23 : (root.compact ? 26 : 31)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: tile.cpu ? "CPU" : "GPU"
                        font.family: root.mono
                        font.bold: true
                        font.pixelSize: root.narrow ? 19 : (root.compact ? 22 : 27)
                        color: studioPalette.paint("#FFFFFF", "text")
                    }
                    Text {
                        width: parent.width
                        height: 15
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: tile.cpu ? root.cpuModel : root.shortGpuName()
                        font.family: root.mono
                        font.pixelSize: root.narrow ? 10 : 11
                        color: studioPalette.paint("#CDD4D9", "text")
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: metrics
                    anchors.top: titleBlock.bottom
                    anchors.topMargin: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: tile.pad
                    anchors.rightMargin: tile.pad
                    height: root.narrow ? 50 : (root.compact ? 56 : 69)

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: studioPalette.paint("#57656E", "muted")
                    }
                    Row {
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        spacing: 0
                        readonly property real third: width / 3
                        Item {
                            width: parent.third
                            height: parent.height
                            Text {
                                width: parent.width
                                text: "USAGE"
                                font.family: root.mono
                                font.pixelSize: root.narrow ? 8 : 10
                                horizontalAlignment: Text.AlignHCenter
                                color: studioPalette.paint("#BBC5CB", "text")
                            }
                            Item {
                                width: root.narrow ? 30 : (root.compact ? 38 : 51)
                                height: width
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                Canvas {
                                    id: gauge
                                    anchors.fill: parent
                                    antialiasing: true
                                    onPaint: {
                                        const ctx = getContext('2d');
                                        ctx.clearRect(0, 0, width, height);
                                        const lw = root.narrow ? 3.5 : (root.compact ? 4.5 : 6);
                                        const rad = (width - lw) / 2 - 0.5;
                                        ctx.lineWidth = lw;
                                        ctx.strokeStyle = '#48535C';
                                        ctx.beginPath();
                                        ctx.arc(width/2, height/2, rad, -Math.PI/2, Math.PI*1.5);
                                        ctx.stroke();
                                        ctx.strokeStyle = '#ECEFF2';
                                        ctx.beginPath();
                                        ctx.arc(width/2, height/2, rad, -Math.PI/2,
                                                -Math.PI/2 + Math.PI*2*root.clamp(tile.usage)/100);
                                        ctx.stroke();
                                    }
                                    Connections {
                                        target: tile
                                        function onUsageChanged() { gauge.requestPaint(); }
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(root.clamp(tile.usage)) + '%'
                                    font.family: root.mono
                                    font.bold: true
                                    font.pixelSize: root.narrow ? 11 : (root.compact ? 13 : 17)
                                    color: '#FFFFFF'
                                }
                            }
                        }
                        Item {
                            width: parent.third
                            height: parent.height
                            Text {
                                width: parent.width
                                text: "TEMP"
                                font.family: root.mono
                                font.pixelSize: root.narrow ? 8 : 10
                                horizontalAlignment: Text.AlignHCenter
                                color: studioPalette.paint("#BBC5CB", "text")
                            }
                            Text {
                                anchors.fill: parent
                                anchors.topMargin: 15
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: root.niceTemp(tile.temp)
                                font.family: root.mono
                                font.bold: true
                                font.pixelSize: root.narrow ? 17 : (root.compact ? 20 : 25)
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 12
                                color: '#F2F4F5'
                            }
                        }
                        Item {
                            width: parent.third
                            height: parent.height
                            Text {
                                width: parent.width
                                text: "CLOCK"
                                font.family: root.mono
                                font.pixelSize: root.narrow ? 8 : 10
                                horizontalAlignment: Text.AlignHCenter
                                color: studioPalette.paint("#BBC5CB", "text")
                            }
                            Text {
                                anchors.fill: parent
                                anchors.topMargin: 15
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: root.niceClock(tile.clock) + " GHz"
                                font.family: root.mono
                                font.bold: true
                                font.pixelSize: root.narrow ? 11 : (root.compact ? 13 : 17)
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 10
                                color: '#F2F4F5'
                            }
                        }
                    }
                }

                Column {
                    id: bottom
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.narrow ? 5 : 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: tile.pad
                    anchors.rightMargin: tile.pad
                    spacing: 2
                    Text {
                        width: parent.width
                        height: root.narrow ? 14 : 17
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: tile.cpu ? (root.cpuCores > 0 ? root.cpuCores + " CORES  /  " + root.cpuThreads + " THREADS" : "CPU DETECTING")
                                       : root.gpuFan < 0 ? "GPU FAN: NOT REPORTED"
                                       : root.gpuFan === 0 ? "GPU FAN: IDLE"
                                       : "GPU FAN: " + Math.round(root.gpuFan) + "%"
                        font.family: root.mono
                        font.pixelSize: root.narrow ? 9 : 11
                        color: '#CCD4D9'
                        elide: Text.ElideRight
                    }
                    Canvas {
                        id: spark
                        width: parent.width
                        height: 20
                        visible: tile.height > 345 && !root.compact
                        antialiasing: true
                        onPaint: {
                            const ctx = getContext('2d');
                            ctx.clearRect(0, 0, width, height);
                            const a = tile.history;
                            if (!a || a.length < 2) return;
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = '#C8D2D8';
                            ctx.beginPath();
                            for (let i = 0; i < a.length; i++) {
                                const x = i * width / (a.length - 1);
                                const y = 2 + (height-4) * (1-root.clamp(a[i])/100);
                                if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }
                        Connections {
                            target: tile
                            function onHistoryChanged() { spark.requestPaint(); }
                        }
                    }
                }

                // Artwork consumes all space left between metrics and footnote.
                // Models have transparent margins INSIDE the PNG, so nothing hits edges.
                Item {
                    id: art
                    anchors.top: metrics.bottom
                    anchors.bottom: bottom.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: tile.pad + 3
                    anchors.rightMargin: tile.pad + 3
                    anchors.topMargin: 2
                    anchors.bottomMargin: 1

                    Item {
                        id: chipArea
                        visible: tile.cpu
                        anchors.centerIn: parent
                        width: Math.max(0, Math.min(art.width - 4, art.height - 2))
                        height: width
                        Rectangle {
                            id: cpuHalo
                            anchors.centerIn: parent
                            width: parent.width * 0.91
                            height: parent.height * 0.91
                            radius: 12
                            color: 'transparent'
                            border.width: 2
                            border.color: '#A2B9C7'
                            opacity: root.cpuUsage > 6 ? 0.25 : 0.05
                            SequentialAnimation on opacity {
                                running: tile.cpu && root.cpuUsage > 8 && chipArea.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.1; to: 0.45; duration: 1200; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.45; to: 0.1; duration: 1200; easing.type: Easing.InOutSine }
                            }
                        }
                        Image {
                            id: cpuIllustration
                            anchors.fill: parent
                            source: root.exactRyzen5700X ? '../images/cpu-complete.png' : '../images/cpu-unbranded.png'
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            mipmap: true
                        }
                        Column {
                            visible: !root.exactRyzen5700X && cpuIllustration.status === Image.Ready
                            anchors.centerIn: parent
                            width: parent.width * 0.73
                            spacing: Math.max(1, parent.height * 0.014)
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignHCenter
                                text: root.cpuVendor === "amd" ? "AMD" : root.cpuVendor === "intel" ? "INTEL" : "CPU"
                                font.family: root.mono; font.bold: true
                                font.pixelSize: Math.max(8, chipArea.height * 0.11)
                                color: "#30373D"
                            }
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignHCenter
                                text: root.cpuFamily(); elide: Text.ElideRight
                                font.family: root.mono; font.bold: true
                                fontSizeMode: Text.Fit; minimumPixelSize: 7
                                font.pixelSize: Math.max(12, chipArea.height * 0.18)
                                color: "#30373D"
                            }
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignHCenter
                                text: root.cpuChipLabel(); elide: Text.ElideRight
                                font.family: root.mono; font.bold: true
                                fontSizeMode: Text.Fit; minimumPixelSize: 6
                                font.pixelSize: Math.max(9, chipArea.height * 0.105)
                                color: "#30373D"
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: cpuIllustration.status === Image.Error || cpuIllustration.status === Image.Null
                            text: "▣ CPU"
                            font.family: root.mono
                            font.pixelSize: Math.max(13, Math.min(25, chipArea.width * .20))
                            font.bold: true
                            color: studioPalette.paint("#CDD6DC", "text")
                        }
                    }

                    Item {
                        id: gpuArea
                        visible: !tile.cpu
                        anchors.centerIn: parent
                        readonly property real aspect: 840 / 340
                        width: Math.max(0, Math.min(art.width - 4, (art.height - 2) * aspect))
                        height: width / aspect
                        Image {
                            id: gpuIllustration
                            anchors.fill: parent
                            source: root.hasRtxArtwork ? '../images/gpu-complete-body.png' : '../images/gpu-unbranded.png'
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            mipmap: true
                        }
                        Text {
                            visible: !root.hasRtxArtwork && gpuIllustration.status === Image.Ready
                            anchors.centerIn: parent
                            width: parent.width * 0.26
                            horizontalAlignment: Text.AlignHCenter
                            text: root.gpuBadge()
                            font.family: root.mono; font.bold: true
                            fontSizeMode: Text.Fit; minimumPixelSize: 5
                            font.pixelSize: Math.max(8, gpuArea.height * 0.18)
                            color: "#D6DFE3"
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: gpuIllustration.status === Image.Error || gpuIllustration.status === Image.Null
                            text: "GPU / GRAPHICS"
                            font.family: root.mono
                            font.pixelSize: Math.max(10, Math.min(18, gpuArea.width * .08))
                            font.bold: true
                            color: studioPalette.paint("#CDD6DC", "text")
                        }
                        Repeater {
                            model: 2
                            delegate: Image {
                                required property int index
                                visible: gpuIllustration.status === Image.Ready
                                source: '../images/gpu-fan-round.png'
                                width: gpuArea.width * (228 / 840)
                                height: gpuArea.height * (228 / 340)
                                x: gpuArea.width * (((index === 0 ? 235 : 609) - 114) / 840)
                                y: gpuArea.height * ((170 - 114) / 340)
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                transformOrigin: Item.Center
                                RotationAnimation on rotation {
                                    running: !tile.cpu && root.gpuFan > 0 && gpuArea.visible
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: Math.max(430, 2350 - Math.min(100, root.gpuFan) * 17)
                                    easing.type: Easing.Linear
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.narrow ? 26 : (root.compact ? 30 : 37)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            height: 1
            color: '#58656E'
        }
        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: 'RAM ' + root.niceRam(root.ramUsed) + '/' + root.niceRam(root.ramTotal)
                  + ' GiB  |  VRAM ' + (root.nvidiaAvailable
                  ? root.niceRam(root.vramUsed) + '/' + root.niceRam(root.vramTotal) + ' GiB' : '--')
            color: '#CBD4D9'
            font.family: root.mono
            font.pixelSize: root.narrow ? 10 : (root.compact ? 11 : 13)
            fontSizeMode: Text.Fit
            minimumPixelSize: 9
        }
    }

    P5Support.DataSource {
        id: collector
        engine: 'executable'
        connectedSources: ['/usr/bin/python3 ' + root.scriptPath]
        interval: 3000
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
}
