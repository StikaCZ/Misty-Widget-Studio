import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// Misty Pixel Pets v4.3 — 50x40 nearest-neighbour artwork, hard pixel edges.
// All art is registered on identical canvases. Physics update independently
// of frame selection for fluid walking with crisp, unfiltered sprites.
PlasmoidItem {
    ThemePalette { id: studioPalette }

    id: root
    // Recolour only the rectangle fill; do not change Rectangle.opacity
    // because its text/Canvas/controls may be children.
    function fadeBackground(c) {
        const tint = Qt.lighter(c, 1.0)
        return Qt.rgba(tint.r, tint.g, tint.b, tint.a * Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100)))
    }
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    readonly property real mistyWholeOpacity: Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100))

    // Preserved configuration keys from existing Unified Desktop Pets.
    readonly property string selectedPet: ["penguin", "gecko", "slime"].indexOf(Plasmoid.configuration.pet) >= 0 ? Plasmoid.configuration.pet : "penguin"
    property string studioMode: Plasmoid.configuration.widgetStyle || "normal"
    property color studioAccent: studioPalette.paint(Plasmoid.configuration.accentColor || "#9FB6A2", "accent")
    property color glassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#899EBB", "accent")
    property int glassOpacity: Plasmoid.configuration.glassOpacity ?? 78
    property int glassBlur: Plasmoid.configuration.glassBlur ?? 45
    property int glassRadius: Plasmoid.configuration.cornerRadius ?? 18
    property bool lowPower: Plasmoid.configuration.lowPower === undefined ? true : Plasmoid.configuration.lowPower
    property real textScale: Math.max(.75, Math.min(1.5, Number(Plasmoid.configuration.textScale ?? 100) / 100))

    property int trackWidth: Math.max(140, Math.min(800, Number(Plasmoid.configuration.trackWidth || 260)))
    property int speedSetting: Math.max(1, Math.min(5, Number(Plasmoid.configuration.speed || 2)))
    property int sizeSetting: Math.max(50, Math.min(200, Number(Plasmoid.configuration.petSize || 100)))
    property int activityLevel: Math.max(1, Math.min(5, Number(Plasmoid.configuration.activityLevel || 3)))
    property bool allowSleep: Plasmoid.configuration.allowSleep === undefined ? true : Plasmoid.configuration.allowSleep
    property bool allowSurprises: Plasmoid.configuration.allowSurprises === undefined ? true : Plasmoid.configuration.allowSurprises
    property bool clickToPlay: Plasmoid.configuration.clickToPlay === undefined ? true : Plasmoid.configuration.clickToPlay
    property bool reactToHover: Plasmoid.configuration.reactToHover === undefined ? true : Plasmoid.configuration.reactToHover
    property bool showPetStatus: Plasmoid.configuration.showPetStatus === undefined ? true : Plasmoid.configuration.showPetStatus
    property int petHeight: Math.max(42, Math.min(250, Number(Plasmoid.configuration.petHeight || 80)))

    property color trackColor: studioPalette.paint(Plasmoid.configuration.trackColor || "#101518", "surface")
    property color outlineColor: studioPalette.paint(Plasmoid.configuration.outlineColor || "#56646A", "border")
    property color glowColor: studioPalette.paint(Plasmoid.configuration.glowColor || "#7AAFB8", "accent")
    property int trackOpacity: Math.max(0, Math.min(100, Number(Plasmoid.configuration.trackOpacity ?? 0)))
    property int outlineOpacity: Math.max(0, Math.min(100, Number(Plasmoid.configuration.outlineOpacity ?? 0)))
    property int spriteOpacity: Math.max(15, Math.min(100, Number(Plasmoid.configuration.spriteOpacity ?? 100)))
    property int trackRadius: Plasmoid.configuration.trackRadius ?? 12
    property bool showShadow: Plasmoid.configuration.showShadow === undefined ? false : Plasmoid.configuration.showShadow
    property bool showGlow: Plasmoid.configuration.showGlow === undefined ? false : Plasmoid.configuration.showGlow

    readonly property bool isTerminal: studioMode === "terminal"
    readonly property bool isGlass: studioMode === "glass"
    readonly property bool isMinimal: studioMode === "minimal"
    // The size slider changes character dimensions directly. Increase the
    // actual widget height in Edit Mode if you want a >140% character.
    // Keep the moving character inside the widget even in narrow layouts.
    // This is initialised from the configured width; the representation reports
    // real resize events when Plasma creates it. Never depend on an inner QML id
    // while constructing the root: that could make maxX undefined/NaN.
    property real stageWidth: Math.max(140, trackWidth)
    readonly property real naturalDrawWidth: (isTerminal ? 175 : 116) * sizeSetting / 100
    readonly property real drawWidth: Math.min(naturalDrawWidth, Math.max(48, stageWidth - 74))
    readonly property real drawHeight: drawWidth * (isTerminal ? .66 : .80)
    readonly property real maxX: Math.max(5, stageWidth - drawWidth - 7)

    implicitWidth: trackWidth
    implicitHeight: Math.max(petHeight, drawHeight + (isTerminal && showPetStatus ? 28 : 10))
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: 140
    Layout.minimumHeight: 60
    toolTipMainText: "Misty Living Pets · " + selectedPet
    toolTipSubText: paused ? "Paused · middle-click to resume" : action + " · left-click to play, middle-click to pause"

    property string action: "walk"
    property real elapsed: 0
    property real durationMs: 2850
    property real actorX: 6
    property int facing: 1
    property double lastClock: 0
    property double lastHoverMs: 0
    property bool paused: false
    property int cycle: 0
    property int stillActions: 0

    function clamp(x,a,b) { return Math.max(a,Math.min(b,x)) }
    function alpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    function range(a,b) { return a+Math.random()*(b-a) }
    function resetPet() {
        actorX=clamp(isFinite(actorX) ? actorX : 5, 5, maxX)
        facing=actorX>maxX*0.60?-1:1
        cycle=0
        stillActions=0
        lastClock=Date.now()
        begin("walk",3100)
    }
    Component.onCompleted: resetPet()
    onSelectedPetChanged: Qt.callLater(resetPet)
    onStudioModeChanged: Qt.callLater(resetPet)
    onSizeSettingChanged: actorX=clamp(actorX,5,maxX)
    onStageWidthChanged: {
        // After a resize, move into the valid track instead of freezing at
        // a previous boundary or leaving the sprite out of view.
        actorX = clamp(isFinite(actorX) ? actorX : 5, 5, maxX)
        if (actorX >= maxX - 2) facing = -1
        if (actorX <= 7) facing = 1
    }

    function begin(next, milliseconds) {
        if (next==="sleep" && !allowSleep) next="idle"
        if (next==="special" && !allowSurprises) next="play"
        action=next
        elapsed=0
        durationMs=Math.max(220,milliseconds)
        cycle++
        if (next==="walk" || next==="special") {
            stillActions=0
            if (actorX<14) facing=1
            if (actorX>maxX-10) facing=-1
        } else stillActions++
    }
    function chooseNext() {
        if (stillActions>=2 || cycle%3===0) {
            begin("walk",range(2300,4200))
            return
        }
        const n=Math.random()
        if (allowSurprises && n<0.15+activityLevel*0.045) begin("special",range(900,1500))
        else if (n<0.42) begin("play",range(900,1700))
        else if (n<0.64) begin("look",range(700,1400))
        else if (n<0.77) begin("blink",450)
        else if (allowSleep && cycle%11===0) begin("sleep",range(1800,3800))
        else begin("idle",range(850,1600))
    }
    function step() {
        const now=Date.now()
        const dt=lastClock?clamp(now-lastClock,0,100):40
        lastClock=now
        if (paused) return
        elapsed+=dt
        if (!isFinite(actorX)) actorX = 5
        if (action==="walk" || (action==="special" && selectedPet==="gecko")) {
            const moveSpeed=(35 + speedSetting*15) * (action==="special"?1.6:1.0)
            // Preserve velocity during the middle of the walk, with a gentle
            // ramp at the beginning and end of each action.
            const easeIn=Math.min(1,elapsed/220)
            const easeOut=Math.min(1,Math.max(0,durationMs-elapsed)/220)
            const multiplier=0.42+0.58*Math.max(0.0,Math.min(easeIn,easeOut))
            // Bounce at the edges instead of remaining pinned there.
            let candidate = actorX + facing*moveSpeed*dt/1000*multiplier
            if (candidate >= maxX) { candidate = maxX; facing = -1 }
            if (candidate <= 5) { candidate = 5; facing = 1 }
            actorX = clamp(candidate,5,maxX)
        }
        if (elapsed>=durationMs) chooseNext()
    }
    Timer {
        // One independent heartbeat for both the pet's position and its frames.
        // It does not depend on the visibility of the scene or the image loader.
        interval: root.lowPower?55:40
        repeat: true
        running: true
        onTriggered: root.step()
    }
    function touchPet(button) {
        if (button===Qt.MiddleButton) {
            paused=!paused
            lastClock=Date.now()
            if (!paused) begin("walk",2500)
            return
        }
        if (!clickToPlay) return
        paused=false
        lastClock=Date.now()
        begin("play",1300)
    }
    function hoverPet() {
        const now=Date.now()
        if (!reactToHover || paused || now-lastHoverMs<2600) return
        lastHoverMs=now
        if (action!=="play" && action!=="special") begin("look",950)
    }

    readonly property int frameCount: action==="special"?10: action==="blink"?4:action==="look"?6:8
    readonly property int frameMs: action==="walk"?100:action==="play"?105:action==="blink"?115:action==="special"?90:action==="sleep"?360:action==="idle"?240:180
    readonly property int frameIndex: Math.floor(elapsed/frameMs)%frameCount
    readonly property string frameName: action+"_"+(frameIndex<10?"0":"")+frameIndex+".png"
    readonly property string petImage: Qt.resolvedUrl("../images/"+selectedPet+"/"+frameName)

    // Terminal mode now uses a dedicated TerminalPet component.

    fullRepresentation: Item {
        id: walkingArea
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: root.trackWidth
        implicitHeight: root.implicitHeight
        Layout.minimumWidth: 140
        Layout.minimumHeight: 60
        clip: true
        Component.onCompleted: root.stageWidth = Math.max(140, width > 0 ? width : root.trackWidth)
        onWidthChanged: {
            if (width > 0) root.stageWidth = Math.max(140,width)
        }

        StudioGlass {
            anchors.fill: parent
            visible: root.isGlass
            tintColor: studioPalette.paint(root.glassTint, "accent")
            alphaPercent: root.glassOpacity
            blurStrength: root.glassBlur
            radiusSize: root.glassRadius
        }
        Rectangle {
            anchors.fill: parent
            visible: !root.isGlass
            radius: root.isTerminal?3:root.trackRadius
            color: studioPalette.panel(root.isTerminal?"#e6101719":root.isMinimal?"transparent":root.alpha(root.trackColor,root.trackOpacity/100))
            border.width: root.isTerminal?1:root.outlineOpacity>0?1:0
            border.color: studioPalette.custom ? studioPalette.outline("#3c646055") : root.isTerminal?studioPalette.paint("#3c646055","border"):root.alpha(root.outlineColor,root.outlineOpacity/100)
        }
        Text {
            visible: root.isTerminal && root.showPetStatus
            x:10; y:5; width:parent.width-20
            text:"~ "+root.selectedPet+" / "+(root.paused?"paused":root.action)
            color: studioPalette.paint("#9FB6A2", "muted")
            font.family:"JetBrains Mono"
            font.pixelSize:Math.max(8,9*root.textScale)
            elide:Text.ElideRight
        }
        Rectangle {
            visible:root.isTerminal && root.showPetStatus
            x:10; y:22; width:Math.max(0,parent.width-20); height:1; color: studioPalette.paint("#384c44", "surface")
        }
        Rectangle {
            visible:root.showShadow && !root.isTerminal
            x:petActor.x+petActor.width*.19; y:parent.height-6
            width:petActor.width*.62; height:3; radius:2
            color: studioPalette.paint("#50000000", "surface")
        }
        Item {
            id:petActor
            width:root.drawWidth
            height:root.drawHeight
            x:root.actorX
            y:Math.max(root.isTerminal && root.showPetStatus?24:0,walkingArea.height-height-2)
            Behavior on x { NumberAnimation { duration: root.lowPower ? 60 : 45; easing.type:Easing.Linear } }
            Image {
                anchors.fill:parent
                visible:!root.isTerminal
                source:root.petImage
                asynchronous:false
                cache:true
                fillMode:Image.PreserveAspectFit
                smooth:false
                mipmap:false
                mirror:root.facing<0
                opacity:root.spriteOpacity/100
            }
            TerminalPet {
                anchors.fill: parent
                visible: root.isTerminal
                species: root.selectedPet
                action: root.action
                elapsedMs: root.elapsed
                direction: root.facing
                ink: root.studioAccent
                textScale: root.textScale
            }
            MouseArea {
                anchors.fill:parent
                hoverEnabled:root.reactToHover
                acceptedButtons:Qt.LeftButton|Qt.MiddleButton
                cursorShape:Qt.PointingHandCursor
                onEntered:root.hoverPet()
                onClicked:function(mouse){root.touchPet(mouse.button)}
            }
        }
    }
}
