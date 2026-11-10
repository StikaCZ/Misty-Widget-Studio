import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// Stika CD 2.0 — a clean, scalable desktop music deck.
// Foreground disc/text/buttons never inherit panel opacity.
PlasmoidItem {
    id: widget
    ThemePalette { id: palette }
    implicitWidth: 300
    implicitHeight: 385
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: 165
    Layout.minimumHeight: 220
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property string styleName: Plasmoid.configuration.widgetStyle || "normal"
    readonly property string design: Plasmoid.configuration.cdDesign || "silver"
    readonly property string frameStyle: Plasmoid.configuration.cdFrameStyle || "studio"
    readonly property string centreStyle: Plasmoid.configuration.cdCenterStyle || "label"
    readonly property color discColor: palette.paint(Plasmoid.configuration.cdDiscColor || "#C1CFD0", "secondary")
    readonly property color ringColor: palette.paint(Plasmoid.configuration.cdRingColor || "#8FB89F", "accent")
    readonly property color centreColor: palette.paint(Plasmoid.configuration.cdCenterColor || "#223036", "surface")
    readonly property color ink: palette.paint(Plasmoid.configuration.cdTextColor || "#F0F5F2", "text")
    readonly property color background: palette.panel(Plasmoid.configuration.cdSurfaceColor || "#111C22")
    readonly property color muted: palette.paint("#9BACB2", "muted")
    readonly property color edge: palette.outline("#8298A5")
    readonly property string labelText: Plasmoid.configuration.cdLabel || "STIKA CZ"
    readonly property string labelFont: Plasmoid.configuration.cdFont || "JetBrains Mono"
    readonly property bool controlsVisible: Plasmoid.configuration.cdShowControls !== false
    readonly property bool infoVisible: Plasmoid.configuration.cdShowTrack !== false
    readonly property bool progressVisible: Plasmoid.configuration.cdShowProgress !== false
    readonly property int centrePercent: Math.max(24,Math.min(56,Plasmoid.configuration.cdCenterSize ?? 38))
    readonly property int holePercent: Math.max(6,Math.min(22,Plasmoid.configuration.cdHoleSize ?? 10))
    readonly property int discPercent: Math.max(60,Math.min(100,Plasmoid.configuration.cdSize ?? 92))
    readonly property real shine: Math.max(0,Math.min(1,(Plasmoid.configuration.cdShine ?? 60)/100))
    readonly property int rings: Math.max(0,Math.min(14,Plasmoid.configuration.cdRings ?? 5))
    readonly property bool spinning: Plasmoid.configuration.cdSpin !== false
    readonly property int spinMs: Math.max(2,Math.min(24,Plasmoid.configuration.cdSpinSeconds ?? 8))*1000
    readonly property bool isPlaying: mediaState === "Playing"
    property string mediaState: "No media player"
    property string mediaTitle: "No music playing"
    property string mediaArtist: ""
    property real mediaPosition: 0
    property real mediaDuration: 0
    readonly property real mediaProgress: mediaDuration > 0 ? Math.max(0,Math.min(1,mediaPosition / mediaDuration)) : 0

    function css(c, alpha) {
        const a=alpha === undefined ? c.a : alpha
        return "rgba("+Math.round(c.r*255)+","+Math.round(c.g*255)+","+Math.round(c.b*255)+","+a+")"
    }
    function command(kind) {
        if (["status","play-pause","previous","next"].indexOf(kind) < 0) return
        // Executable and arguments are fixed; no user text or media metadata goes to the shell.
        const exe = '$HOME/.local/share/plasma/plasmoids/local.stikacz.cdplayer/contents/scripts/mediactl.py'
        dataSource.connectSource('/bin/bash -c \'exec "'+exe+'" '+kind+'\'')
    }
    P5Support.DataSource {
        id: dataSource
        engine: "executable"
        connectedSources: []
        onNewData: function(name, data) {
            try {
                const m=JSON.parse(String(data["stdout"] || "{}"))
                widget.mediaState=String(m.status || "No media player")
                widget.mediaTitle=String(m.title || "No music playing")
                widget.mediaArtist=String(m.artist || "")
                widget.mediaPosition=Number(m.position || 0)
                widget.mediaDuration=Number(m.duration || 0)
            } catch(e) {
                widget.mediaState="Media helper unavailable"
                widget.mediaTitle="Check playerctl"
                widget.mediaArtist=""
                widget.mediaPosition=0
                widget.mediaDuration=0
            }
            disconnectSource(name)
        }
    }
    Timer { interval: 4500; running: widget.visible; repeat: true; onTriggered: widget.command("status") }
    Component.onCompleted: command("status")

    fullRepresentation: Item {
        id: body
        implicitWidth: widget.implicitWidth
        implicitHeight: widget.implicitHeight
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Rectangle {
            anchors.fill: parent
            visible: widget.frameStyle !== "none" && widget.styleName !== "minimal"
            radius: widget.frameStyle === "jewel" ? 8 : widget.styleName === "glass" ? 24 : 16
            color: widget.styleName === "glass" && !palette.custom
                 ? Qt.rgba(widget.background.r,widget.background.g,widget.background.b, widget.background.a*.65)
                 : widget.background
            border.width: widget.frameStyle === "jewel" ? 2 : 1
            border.color: widget.edge
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 12
            color: "transparent"
            border.color: palette.paint("#2BFFFFFF","border")
            border.width: 1
            visible: widget.frameStyle === "jewel" && widget.styleName !== "minimal"
        }
        ColumnLayout {
            id: stack
            anchors.fill: parent
            anchors.margins: Math.max(8, Math.min(15,body.width*.045))
            spacing: Math.max(3,Math.min(10,body.height*.022))

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 25
                spacing: 6
                Rectangle { Layout.preferredWidth: 3; Layout.preferredHeight: 18; radius: 2; color:widget.ringColor }
                Text {
                    Layout.fillWidth: true
                    text: "STIKA / DISC"
                    font.family: widget.labelFont
                    font.pixelSize: Math.max(9,Math.min(12,body.width*.040))
                    font.bold: true
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                    color: widget.ink
                }
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: widget.isPlaying ? widget.ringColor : widget.muted
                }
                Text {
                    text: widget.isPlaying ? "PLAYING" : widget.mediaState === "Paused" ? "PAUSED" : "IDLE"
                    font.family: widget.labelFont
                    font.pixelSize: Math.max(8,Math.min(10,body.width*.032))
                    color: widget.muted
                }
            }

            Item {
                id: discSlot
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 90
                Layout.preferredHeight: 205
                clip: false
                Rectangle {
                    width: Math.min(discSlot.width,discSlot.height)*widget.discPercent/100 + 8
                    height: width; radius: width/2
                    anchors.centerIn: parent
                    color: palette.paint("#36000000","surface")
                    visible: widget.frameStyle !== "none"
                }
                Item {
                    id: disc
                    width: Math.max(60,Math.min(discSlot.width,discSlot.height)*widget.discPercent/100)
                    height: width
                    anchors.centerIn: parent
                    NumberAnimation on rotation {
                        from: 0; to: 360
                        duration: widget.spinMs
                        loops: Animation.Infinite
                        running: widget.spinning && widget.isPlaying && widget.visible
                        easing.type: Easing.Linear
                    }
                    Canvas {
                        id: discPaint
                        anchors.fill: parent
                        property string paintSignature: [widget.design,widget.discColor.toString(),widget.ringColor.toString(),widget.shine,widget.rings,palette.custom].join("|")
                        onPaintSignatureChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPaint: {
                            const ctx=getContext("2d")
                            const w=width, h=height, cx=w*.5, cy=h*.5, r=Math.min(w,h)*.485
                            ctx.clearRect(0,0,w,h)
                            if (r < 10) return
                            ctx.save()
                            ctx.beginPath();ctx.arc(cx,cy,r,0,2*Math.PI);ctx.clip()
                            const base=widget.discColor
                            const accent=widget.ringColor
                            const pal=palette.custom
                            const mat=widget.design
                            const steel=(mat==="graphite"||mat==="vinyl")
                            const g=ctx.createLinearGradient(w*.08,0,w*.92,h)
                            g.addColorStop(0,steel ? widget.css(base,.84) : widget.css(base,.93))
                            g.addColorStop(.13,pal ? widget.css(palette.secondaryColour,.9) : steel ? "#343C46" : "#E1EBEF")
                            g.addColorStop(.32,widget.css(base,.96))
                            g.addColorStop(.49,pal ? widget.css(palette.mutedColour,.86) : steel ? "#171C25" : mat==="rose" ? "#EECED0" : "#87969F")
                            g.addColorStop(.64,pal ? widget.css(palette.accentColour,.87) : steel ? "#45505A" : "#E9EEF0")
                            g.addColorStop(.82,widget.css(base,.97))
                            g.addColorStop(1,pal ? widget.css(palette.surfaceColour,.9) : steel ? "#20262E" : "#9CAAB0")
                            ctx.fillStyle=g;ctx.fillRect(0,0,w,h)
                            // Fine concentric tracks: enough to look like a real optical disc.
                            for(let i=0;i<Math.max(4,widget.rings*3);i++){
                                const rad=r*(.56+.425*i/Math.max(1,widget.rings*3))
                                ctx.beginPath();ctx.arc(cx,cy,rad,0,2*Math.PI)
                                ctx.strokeStyle=i%3===0 ? widget.css(accent,.34) : "rgba(255,255,255,0.16)"
                                ctx.lineWidth=Math.max(.5,w*.0025)
                                ctx.stroke()
                            }
                            if(widget.shine>0) {
                                for(let i=0;i<4;i++){
                                    ctx.beginPath();ctx.moveTo(cx,cy)
                                    const a=(-1.1+i*1.61)
                                    ctx.arc(cx,cy,r*.98,a,a+.27)
                                    ctx.closePath()
                                    ctx.fillStyle="rgba(255,255,255,"+(.09*widget.shine)+")"
                                    ctx.fill()
                                }
                            }
                            ctx.restore()
                            ctx.beginPath();ctx.arc(cx,cy,r,0,2*Math.PI)
                            ctx.strokeStyle=widget.css(accent,.76)
                            ctx.lineWidth=Math.max(1,w*.011)
                            ctx.stroke()
                            ctx.beginPath();ctx.arc(cx,cy,r*.954,0,2*Math.PI)
                            ctx.strokeStyle="rgba(255,255,255,.38)"
                            ctx.lineWidth=1;ctx.stroke()
                        }
                    }
                    Rectangle {
                        id: labelDisc
                        anchors.centerIn: parent
                        width: parent.width*widget.centrePercent/100
                        height: width
                        radius: width/2
                        color: widget.centreColor
                        border.color: widget.ringColor
                        border.width: Math.max(1.4,width*.025)
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: width/2
                            color: "transparent"
                            border.color: palette.paint("#44FFFFFF","border")
                            border.width: 1
                        }
                        Text {
                            visible: widget.centreStyle !== "plain"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height*.17
                            width: parent.width*.85
                            height: parent.height*.30
                            font.family: widget.labelFont
                            font.pixelSize: Math.max(8,Math.min(16,parent.width*.21))
                            font.bold: true
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 6
                            text: widget.centreStyle === "logo" ? "♫" : widget.centreStyle === "initials"
                                ? widget.labelText.slice(0,2).toUpperCase() : widget.labelText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: widget.ink
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: widget.centreStyle === "label"
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height*.74
                            width: parent.width*.78
                            height: parent.height*.12
                            text: "M I S T Y   /   C D"
                            font.family: widget.labelFont
                            font.pixelSize: Math.max(5,Math.min(8,parent.width*.083))
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 5
                            horizontalAlignment: Text.AlignHCenter
                            color: widget.muted
                        }
                    }
                    Rectangle {
                        width: parent.width*widget.holePercent/100
                        height: width; radius: width/2
                        anchors.centerIn: parent
                        color: palette.paint("#0C1118","surface")
                        border.width: Math.max(1,disc.width*.009)
                        border.color:widget.ringColor
                    }
                    Rectangle {
                        width: Math.max(2,disc.width*.016)
                        height: width; radius:width/2
                        anchors.centerIn: parent
                        color: palette.paint("#8EA5A5","border")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: widget.infoVisible ? 45 : 0
                visible: widget.infoVisible
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: widget.mediaTitle
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.family: widget.labelFont
                    font.bold: true
                    font.pixelSize: Math.max(10,Math.min(15,body.width*.050))
                    color: widget.ink
                }
                Text {
                    Layout.fillWidth: true
                    text: widget.mediaArtist || widget.mediaState
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.family: widget.labelFont
                    font.pixelSize: Math.max(9,Math.min(12,body.width*.039))
                    color: widget.muted
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: widget.progressVisible ? 8 : 0
                visible: widget.progressVisible
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 3; radius: 2
                    color: palette.paint("#56738081","border")
                    Rectangle {
                        width: Math.max(0,Math.min(parent.width,parent.width*widget.mediaProgress))
                        height: parent.height
                        radius: parent.radius
                        color: widget.ringColor
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: widget.controlsVisible ? 42 : 0
                visible: widget.controlsVisible
                spacing: Math.max(9,body.width*.04)
                Item { Layout.fillWidth: true }
                Repeater {
                    model: ["previous","play-pause","next"]
                    delegate: Rectangle {
                        readonly property string actionName: modelData
                        Layout.preferredWidth: actionName === "play-pause" ? 52 : 43
                        Layout.preferredHeight: 39
                        radius: 12
                        color: actionName === "play-pause" ? palette.paint("#324A4B","surface") : palette.paint("#1F3032","surface")
                        border.color: widget.edge
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: actionName === "previous" ? "⏮" : actionName === "next" ? "⏭" : widget.isPlaying ? "⏸" : "▶"
                            color: actionName === "play-pause" ? widget.ringColor : widget.ink
                            font.family: "Noto Sans Symbols 2"
                            font.pixelSize: 19
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: widget.command(actionName)
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
