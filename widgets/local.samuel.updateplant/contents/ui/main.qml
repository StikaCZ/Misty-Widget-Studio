import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    ThemePalette { id: studioPalette }

    // The legacy widgetOpacity setting now affects backgrounds only. Foreground stays fully visible.
    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

    id: root

    // Style Studio Complete: user styles, no network access and no extra process.

    // The original SVG flower is the only plant. Saved settings from older
    // multi-plant versions are deliberately ignored so updates cannot switch it.
    property int illustratedSize: Math.max(65,Math.min(150,Plasmoid.configuration.illustratedSize ?? 100))
    readonly property bool showOriginal: true
    readonly property bool showIllustrated: true

    property string studioMode: Plasmoid.configuration.widgetStyle || "normal"
    property color studioAccent: studioPalette.paint(Plasmoid.configuration.accentColor || "#9FB6A2", "accent")
    property int studioGlassOpacity: Math.max(25, Math.min(98, Plasmoid.configuration.glassOpacity ?? 78))
    property int studioCornerRadius: Math.max(4, Math.min(30, Plasmoid.configuration.cornerRadius ?? 18))
    property real studioTextScale: Math.max(0.75, Math.min(1.5, (Plasmoid.configuration.textScale ?? 100) / 100.0))
    property bool studioLowPower: Plasmoid.configuration.lowPower === undefined ? true : Plasmoid.configuration.lowPower

    function studioColor(hex) {
        if (studioMode === "normal") return hex
        const text = String(hex).replace("#", "")
        if (text.length !== 6 && text.length !== 8) return hex
        let alpha = 1.0, v = text
        if (text.length === 8) { alpha = parseInt(text.slice(0,2),16)/255; v = text.slice(2) }
        const r = parseInt(v.slice(0,2),16)/255, g = parseInt(v.slice(2,4),16)/255, b = parseInt(v.slice(4,6),16)/255
        const lum = 0.2126*r + 0.7152*g + 0.0722*b
        if (studioMode === "glass") {
            if (lum < 0.35) return Qt.rgba(0.10, 0.16, 0.17, Math.max(0.1, alpha * studioGlassOpacity/100.0))
            if (lum < 0.67) return Qt.rgba(0.57, 0.71, 0.67, Math.max(0.25, alpha*0.72))
            return Qt.rgba(0.93,0.96,0.96,Math.max(0.55,alpha))
        }
        if (studioMode === "terminal") {
            if (lum < 0.35) return Qt.rgba(0.06,0.09,0.08,Math.max(0.35,alpha*0.96))
            if (lum < 0.67) return Qt.rgba(studioAccent.r*0.72,studioAccent.g*0.72,studioAccent.b*0.72,Math.max(0.4,alpha))
            return Qt.rgba(0.82,0.88,0.80,Math.max(0.64,alpha))
        }
        if (lum < 0.35) return Qt.rgba(0.10,0.12,0.12,Math.min(0.25,alpha*0.3))
        if (lum < 0.67) return Qt.rgba(0.60,0.67,0.63,Math.max(0.45,alpha))
        return Qt.rgba(0.87,0.91,0.88,Math.max(0.6,alpha))
    }
    function studioFont(original) { return studioMode === "terminal" ? "JetBrains Mono" : studioMode === "glass" ? "Noto Sans" : original }


    // Smaller, freely resizable desktop widget with a portrait plant silhouette.
    implicitWidth: 188
    implicitHeight: 224
    Layout.minimumWidth: 64
    Layout.minimumHeight: 72
    Layout.preferredWidth: 188
    Layout.preferredHeight: 224

    // No panel background or card. The SVG layers are truly transparent.
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property int pendingUpdates: -1
    property string checkState: "checking"
    property string lastChecked: ""
    property bool requestRunning: false
    property string updateSource: ""
    property string checkNote: ""
    readonly property string updatesScriptPath: Qt.resolvedUrl("../scripts/check-updates.py").toString().replace("file://", "")

    // 100 or more pending repository package updates -> fully decayed.
    readonly property int plantStage: {
        if (pendingUpdates < 0) return 2
        if (pendingUpdates === 0) return 0
        if (pendingUpdates <= 9) return 1
        if (pendingUpdates <= 24) return 2
        if (pendingUpdates <= 49) return 3
        if (pendingUpdates <= 74) return 4
        if (pendingUpdates <= 99) return 5
        return 6
    }

    readonly property string plantName: [
        "BLOOMING", "THRIVING", "HEALTHY", "STRESSED",
        "DROOPING", "WITHERED", "DECAYED"
    ][plantStage]

    readonly property string plantMessage: [
        "Everything is up to date", "Looking fresh", "Growing steadily",
        "Could use some care", "Needs attention", "Time for an update",
        "100+ updates waiting"
    ][plantStage]

    readonly property int vitality: pendingUpdates < 0 ? 0 : Math.max(0, 100 - Math.min(100, pendingUpdates))

    // Original plant is never switched; click or middle-click to refresh.
    function refreshUpdates() {
        if (requestRunning) return
        requestRunning = true
        checkState = "checking"
        updateWatchdog.restart()
        updateSource = 'python3 "' + updatesScriptPath + '"'
        source.connectSource(updateSource)
    }

    P5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            if (sourceName !== root.updateSource) return
            updateWatchdog.stop()
            try {
                const parsed = JSON.parse(String(data["stdout"] || "").trim())
                root.checkNote = String(parsed.note || "")
                if (parsed.ok && Number.isFinite(Number(parsed.count)) && Number(parsed.count) >= 0) {
                    root.pendingUpdates = Math.floor(Number(parsed.count))
                    root.checkState = parsed.source === "fresh" ? "ok" : "cached"
                    root.lastChecked = Qt.formatTime(new Date(), "hh:mm")
                } else {
                    root.checkState = root.pendingUpdates >= 0 ? "stale" : "error"
                }
            } catch (e) {
                root.checkNote = "Cannot run the update-checking helper"
                root.checkState = root.pendingUpdates >= 0 ? "stale" : "error"
            }
            root.requestRunning = false
            source.disconnectSource(sourceName)
        }
    }

    Timer {
        id: updateWatchdog
        interval: 32000
        repeat: false
        onTriggered: {
            root.requestRunning = false
            root.checkNote = "Update checker did not respond"
            root.checkState = root.pendingUpdates >= 0 ? "stale" : "error"
            if (root.updateSource !== "") source.disconnectSource(root.updateSource)
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refreshUpdates()
    }

    Component.onCompleted: root.refreshUpdates()

    readonly property string details: {
        if (checkState === "checking") return "Misty Plant • checking package updates…"
        if (checkState === "error") return "Misty Plant • cannot check updates\n" + checkNote
            + "\nTry: python3 ~/.local/share/plasma/plasmoids/local.samuel.updateplant/contents/scripts/check-updates.py"
        const status = checkState === "cached" ? "(CACHED, not a fresh repository check)" :
                       checkState === "stale" ? "(LAST KNOWN VALUE, check failed)" : "(fresh)"
        return "CachyOS • " + pendingUpdates + " pending package updates " + status
            + "\n" + plantName + " • " + plantMessage
            + "\nChecked " + lastChecked + " • Every 30 minutes"
            + (checkNote ? "\n" + checkNote : "")
            + "\nClick to refresh."
    }

    // Only the standalone plant and pot are visible on the desktop.
    // All updates and error details are available by hovering over it.

    fullRepresentation: Item {

        StudioGlass {
            anchors.fill: parent
            visible: root.studioMode === "glass"
            z: 0
            tintColor: studioPalette.paint(root.mistyGlassTint, "accent")
            alphaPercent: root.studioGlassOpacity
            blurStrength: Plasmoid.configuration.glassBlur ?? 45
            radiusSize: root.studioCornerRadius
        }
id: face
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Scale the cropped SVG art to fill the available widget space without distortion.
        Item {
            id: drawing
            width: Math.max(0, Math.min(face.width, face.height * 188 / 224))
            height: width * 224 / 188
            anchors.centerIn: parent
            // Scale the complete artwork INCLUDING the pot, update number and label.
            // The base is anchored low so size changes do not pull roots off the pot.
            transformOrigin: Item.Bottom
            scale: root.illustratedSize / 100.0
            readonly property bool originalArtworkLoaded: foliage.status === Image.Ready && pot.status === Image.Ready

            // The separate foliage layer sways without moving the pot.
            Image {
                id: foliage
                visible: drawing.originalArtworkLoaded
                anchors.fill: parent
                source: Qt.resolvedUrl("../images/foliage-" + root.plantStage + ".svg")
                fillMode: Image.Stretch
                sourceSize.width: 376
                sourceSize.height: 448
                smooth: true
                asynchronous: false
                transform: Rotation {
                    id: foliageSway
                    origin.x: foliage.width / 2
                    origin.y: foliage.height * 0.66
                    angle: 0
                }
                SequentialAnimation {
                    running: !root.studioLowPower && (root.checkState === "ok" || root.checkState === "cached") && root.plantStage <= 2
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: foliageSway
                        property: "angle"
                        from: -1.1
                        to: 1.1
                        duration: 2400
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: foliageSway
                        property: "angle"
                        from: 1.1
                        to: -1.1
                        duration: 2400
                        easing.type: Easing.InOutSine
                    }
                    onRunningChanged: if (!running) foliageSway.angle = 0
                }
            }

            Image {
                id: pot
                visible: drawing.originalArtworkLoaded
                anchors.fill: parent
                source: Qt.resolvedUrl("../images/pot-" + root.plantStage + ".svg")
                fillMode: Image.Stretch
                sourceSize.width: 376
                sourceSize.height: 448
                smooth: true
                asynchronous: false
            }


            // Bundled flower fallback only when the legacy SVG assets are absent.
            // Never substitute another plant species.
            Image {
                id: fallbackFlower
                visible: !drawing.originalArtworkLoaded
                anchors.fill: parent
                source: Qt.resolvedUrl("../images/original-flower-fallback-" + root.plantStage + ".svg")
                fillMode: Image.Stretch
                sourceSize.width: 376
                sourceSize.height: 448
                smooth: true
                asynchronous: false
            }
            Image {
                id: fallbackPot
                visible: !drawing.originalArtworkLoaded
                anchors.fill: parent
                source: Qt.resolvedUrl("../images/original-pot-fallback.svg")
                fillMode: Image.Stretch
                sourceSize.width: 376
                sourceSize.height: 448
                smooth: true
                asynchronous: false
            }

            // Update count is printed directly on the pot, not beneath it.
            Text {
                width: parent.width * 0.45
                height: parent.height * 0.095
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.778
                visible: true
                text: root.pendingUpdates < 0 ? "···" : String(root.pendingUpdates)
                color: "#F4F4F4"
                font.family: root.studioFont("Noto Sans")
                font.pixelSize: Math.max(6, Math.min(24, drawing.height * 0.077 * root.studioTextScale))
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            Text {
                width: parent.width * 0.45
                height: parent.height * 0.064
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.874
                visible: true
                text: (root.checkState === "ok" ? "UPDATES" :
                       root.checkState === "cached" ? "CACHED" :
                       root.checkState === "stale" ? "STALE" :
                       root.checkState === "checking" ? "CHECKING" : "CHECK FAILED")
                color: "#E7E8E6"
                font.family: root.studioFont("Noto Sans")
                font.pixelSize: Math.max(5, Math.min(15, drawing.height * 0.039 * root.studioTextScale))
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            MouseArea {
                id: plantInteraction
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor
                onClicked: root.refreshUpdates()

                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.delay: 600
                QQC2.ToolTip.text: root.details + (!drawing.originalArtworkLoaded
                    ? "\nOriginal SVGs unavailable; showing bundled single-flower fallback." : "")
            }
        }
    }
}
