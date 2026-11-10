import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

// Weather Orbit · Forest Edition
// Responsive Plasma 6 widget. No scale-transform of the entire UI: text remains readable.
PlasmoidItem {
    ThemePalette { id: studioPalette }

    // The legacy widgetOpacity setting now affects backgrounds only. Foreground stays fully visible.
    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

    id: root
    // Recolour only the rectangle fill; do not change Rectangle.opacity
    // because its text/Canvas/controls may be children.
    function fadeBackground(c) {
        const tint = Qt.lighter(c, 1.0)
        return Qt.rgba(tint.r, tint.g, tint.b, tint.a * Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100)))
    }

    // Style Studio Complete: user styles, no network access and no extra process.
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

        StudioGlass {
            anchors.fill: parent
            visible: root.studioMode === "glass"
            z: 0
            tintColor: studioPalette.paint(root.mistyGlassTint, "accent")
            alphaPercent: root.studioGlassOpacity
            blurStrength: Plasmoid.configuration.glassBlur ?? 45
            radiusSize: root.studioCornerRadius
        }
Layout.minimumWidth: 275
    Layout.minimumHeight: 180
    Layout.preferredWidth: 890
    Layout.preferredHeight: 305
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property var weatherData: ({ "daily": [] })
    property string cityName: Plasmoid.configuration.city || "Rickmansworth"
    property bool hasWeather: weatherData.temp !== undefined && weatherData.temp !== null
    property bool isRefreshing: false
    property string loadError: ""
    readonly property string weatherKind: String(weatherData.icon || "cloud")
    readonly property bool effectsEnabled: Plasmoid.configuration.animated && root.visible

    // Geometry adjusts to the size dragged in KDE Edit Mode.
    readonly property bool wide: width >= 690 && height >= 265
    readonly property bool verySmall: width < 410 || height < 225
    readonly property real pad: verySmall ? 11 : 19
    readonly property real headerHeight: verySmall ? 32 : 39
    readonly property real dialSize: Math.max(82, Math.min(
        height - headerHeight - (verySmall ? 14 : 22),
        width * (wide ? 0.27 : (verySmall ? 0.37 : 0.32)),
        280))
    readonly property real contentTop: headerHeight + 5
    readonly property real contentHeight: Math.max(90, height - contentTop - (verySmall ? 7 : 12))
    readonly property real detailsX: pad + dialSize + (verySmall ? 9 : 22)
    readonly property real detailsWidth: Math.max(88, width - detailsX - pad)

    function degrees(value) {
        if (value === undefined || value === null || isNaN(Number(value))) return "--°"
        return String(Math.round(Number(value))) + "°"
    }
    function roundNumber(value) {
        return (value === undefined || value === null || isNaN(Number(value)))
                ? "--" : String(Math.round(Number(value)))
    }
    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }
    function fetchWeather() {
        if (weatherSource.connectedSources.length !== 0) return
        isRefreshing = true
        var cmd = "python3 \"$HOME/.local/share/plasma/plasmoids/local.samuel.weatherorbit/contents/scripts/weather.py\" --city "
                + shellQuote(cityName)
        weatherSource.connectSource(cmd)
    }

    onCityNameChanged: fetchWeather()
    onWeatherDataChanged: forecastLine.requestPaint()
    Component.onCompleted: fetchWeather()

    P5Support.DataSource {
        id: weatherSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            root.isRefreshing = false
            var raw = String(data["stdout"] || "").trim()
            try {
                var payload = JSON.parse(raw)
                if (payload.cityQuery && payload.cityQuery.toLowerCase() !== root.cityName.toLowerCase()) {
                    root.loadError = "Updating location…"
                } else {
                    root.weatherData = payload
                    root.loadError = payload.error || ""
                }
            } catch (error) {
                root.loadError = String(data["stderr"] || "Weather unavailable").slice(0, 160)
            }
            disconnectSource(sourceName)
        }
    }
    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: studioPalette.panel(root.studioMode === "glass" || Plasmoid.configuration.transparent ? "transparent" : root.studioMode === "terminal" ? "#ED0B0F11" : "#DA1B2026")
        border.color: root.studioMode === "glass" || Plasmoid.configuration.transparent ? "transparent" : studioPalette.outline("#7E94A0A9")
        border.width: Plasmoid.configuration.transparent ? 0 : 1
    }

    Text {
        x: root.pad
        y: root.verySmall ? 9 : 13
        text: root.verySmall ? "WEATHER / PLANET" : "W E A T H E R   /   P L A N E T"
        color: studioPalette.paint(root.studioColor("#F1F1F2"), "text")
        font.family: root.studioFont("Noto Sans")
        font.pixelSize: root.verySmall ? 9 : 11
        font.bold: true
        elide: Text.ElideRight
        width: Math.max(65, root.width - 125)
    }
    Rectangle {
        id: liveDot
        width: 5; height: 5; radius: 3
        anchors.right: liveLabel.left
        anchors.rightMargin: 8
        y: root.verySmall ? 13 : 18
        color: root.isRefreshing ? "#8E9299" : (root.hasWeather && !root.weatherData.stale ? "#FFFFFF" : "#666B72")
    }
    Text {
        id: liveLabel
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: root.verySmall ? 8 : 12
        font.family: root.studioFont("Noto Sans")
        font.pixelSize: root.verySmall ? 9 : 10
        font.letterSpacing: 1
        color: studioPalette.paint(root.studioColor("#D7DBDE"), "text")
        text: root.isRefreshing ? "UPDATING" : (root.hasWeather ? (root.weatherData.stale ? "CACHED ↻" : "LIVE ↻") : "RETRY ↻")
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.fetchWeather()
        }
    }
    Rectangle {
        x: root.pad
        y: root.headerHeight - 1
        width: Math.max(0, root.width - 2 * root.pad)
        height: 1
        color: studioPalette.paint(root.studioColor("#555960"), "surface")
    }

    // Weather Planet: coloured globe + condition-dependent, lightweight effects.
    // All art scales with the KDE desktop resize handle.
    Item {
        id: orbit
        x: root.pad
        y: root.contentTop + (root.contentHeight - height) / 2
        width: root.dialSize
        height: width

        readonly property bool cloudsVisible: root.weatherKind !== "clear"
        readonly property real globeSize: width * 0.88

        // Dimmer halo at night, brighter while sunny. No particle shaders.
        Rectangle {
            anchors.centerIn: globe
            width: globe.width * 1.08
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(1, orbit.width * 0.009)
            border.color: root.weatherKind === "clear" ? "#99f8ca77" : "#516db8ed"
            opacity: 0.76
        }

        Image {
            id: globe
            anchors.centerIn: parent
            width: orbit.globeSize
            height: width
            source: Qt.resolvedUrl("../images/weather-planet/planet.svg")
            sourceSize.width: 480
            sourceSize.height: 480
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Rectangle {
            anchors.centerIn: globe
            width: globe.width * 0.72
            height: width
            radius: width / 2
            color: studioPalette.paint(root.studioColor("#1404162b"), "surface")
            visible: root.weatherData.isDay === false
        }

        // White clouds drift across the edges of the planet, avoiding its centre label.
        Image {
            id: cloudUpper
            visible: orbit.cloudsVisible
            width: orbit.width * 0.46
            height: width * 0.53
            y: orbit.height * 0.13
            x: orbit.width * 0.51
            source: Qt.resolvedUrl("../images/weather-planet/cloud.svg")
            fillMode: Image.PreserveAspectFit
            opacity: root.weatherKind === "partly" ? 0.66 : 0.94
            // Smooth, reversible drift: no teleport when animation loops.
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.effectsEnabled && cloudUpper.visible
                NumberAnimation {
                    from: orbit.width * 0.51
                    to: orbit.width * 0.56
                    duration: 6800
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: orbit.width * 0.56
                    to: orbit.width * 0.51
                    duration: 6800
                    easing.type: Easing.InOutSine
                }
            }
        }
        Image {
            id: cloudLower
            visible: orbit.cloudsVisible
            width: orbit.width * 0.44
            height: width * 0.53
            y: orbit.height * 0.66
            x: orbit.width * 0.04
            source: Qt.resolvedUrl("../images/weather-planet/cloud.svg")
            fillMode: Image.PreserveAspectFit
            opacity: root.weatherKind === "partly" ? 0.50 : 0.84
            // Smooth, reversible drift: no teleport when animation loops.
            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.effectsEnabled && cloudLower.visible
                NumberAnimation {
                    from: orbit.width * 0.04
                    to: orbit.width * 0.09
                    duration: 8200
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: orbit.width * 0.09
                    to: orbit.width * 0.04
                    duration: 8200
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Drizzle and storms: a handful of short, moving raindrops.
        Item {
            id: rainLayer
            anchors.fill: parent
            visible: root.weatherKind === "rain" || root.weatherKind === "storm"
            Repeater {
                model: 7
                delegate: Rectangle {
                    width: Math.max(1.2, orbit.width * 0.007)
                    height: Math.max(5, orbit.width * 0.054)
                    radius: width / 2
                    color: studioPalette.paint(root.studioColor("#95dbff"), "accent")
                    opacity: 0.65
                    rotation: 15
                    x: orbit.width * (0.18 + index * 0.105)
                    y: orbit.height * 0.68
                    NumberAnimation on y {
                        from: orbit.height * (0.54 + (index % 3) * 0.05)
                        to: orbit.height * 0.97
                        duration: 850 + (index % 3) * 220
                        loops: Animation.Infinite
                        running: root.effectsEnabled && rainLayer.visible
                    }
                }
            }
        }

        // Snowflakes are just small antialiased dots; no expensive particles.
        Item {
            id: snowLayer
            anchors.fill: parent
            visible: root.weatherKind === "snow"
            Repeater {
                model: 9
                delegate: Rectangle {
                    width: Math.max(2, orbit.width * (index % 3 === 0 ? 0.019 : 0.012))
                    height: width
                    radius: width / 2
                    color: studioPalette.paint(root.studioColor("#f2f9ff"), "text")
                    opacity: 0.8
                    x: orbit.width * (0.12 + index * 0.091)
                    y: orbit.height * 0.3
                    NumberAnimation on y {
                        from: orbit.height * (0.12 + (index % 3) * 0.12)
                        to: orbit.height * 0.92
                        duration: 2600 + index * 170
                        loops: Animation.Infinite
                        running: root.effectsEnabled && snowLayer.visible
                    }
                }
            }
        }

        // Fog: two translucent, sliding bands.
        Item {
            id: fogLayer
            anchors.fill: parent
            visible: root.weatherKind === "fog"
            Repeater {
                model: 2
                delegate: Rectangle {
                    width: orbit.width * 0.83
                    height: Math.max(3, orbit.width * 0.055)
                    radius: height / 2
                    x: orbit.width * 0.12
                    y: orbit.height * (0.39 + index * 0.20)
                    color: studioPalette.paint(root.studioColor("#adf1f5f7"), "text")
                    opacity: 0.46
                    NumberAnimation on x {
                        from: orbit.width * 0.07
                        to: orbit.width * 0.22
                        duration: 7000 + index * 1700
                        loops: Animation.Infinite
                        easing.type: Easing.InOutSine
                        running: root.effectsEnabled && fogLayer.visible
                    }
                }
            }
        }

        Image {
            id: lightning
            visible: root.weatherKind === "storm"
            source: Qt.resolvedUrl("../images/weather-planet/bolt.svg")
            width: orbit.width * 0.11
            height: orbit.height * 0.23
            x: orbit.width * 0.74
            y: orbit.height * 0.49
            opacity: 0.7
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.effectsEnabled && lightning.visible
                NumberAnimation { to: 0.15; duration: 1800 }
                NumberAnimation { to: 0.95; duration: 140 }
                NumberAnimation { to: 0.2; duration: 240 }
                PauseAnimation { duration: 1800 }
            }
        }

        // Text stays legible over blue/green planet colours.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: orbit.height * 0.33
            width: orbit.width * 0.78
            horizontalAlignment: Text.AlignHCenter
            text: root.hasWeather ? root.degrees(root.weatherData.temp) : "--°"
            color: studioPalette.paint(root.studioColor("#FFFFFF"), "text")
            style: Text.Outline
            styleColor: "#80132037"
            font.family: root.studioFont("Noto Sans")
            font.weight: Font.DemiBold
            font.pixelSize: Math.max(24, orbit.width * 0.225)
        }
        Text { font.family: root.studioFont("Noto Sans"); 
            anchors.horizontalCenter: parent.horizontalCenter
            y: orbit.height * 0.635
            width: orbit.width * 0.65
            horizontalAlignment: Text.AlignHCenter
            text: root.hasWeather ? String(root.weatherData.condition || "").toUpperCase() : "WEATHER"
            color: studioPalette.paint(root.studioColor("#F1F8FF"), "text")
            style: Text.Outline
            styleColor: "#7612212e"
            font.pixelSize: Math.max(8, orbit.width * 0.050)
            font.letterSpacing: 0.6
            elide: Text.ElideRight
        }
        Text { font.family: root.studioFont("Noto Sans"); 
            anchors.horizontalCenter: parent.horizontalCenter
            y: orbit.height * 0.87
            text: "RAIN  " + (root.hasWeather ? root.roundNumber(root.weatherData.rain) + "%" : "--%")
            color: studioPalette.paint(root.studioColor("#D4E9F5"), "text")
            font.pixelSize: Math.max(8, orbit.width * 0.043)
            font.letterSpacing: 1
        }
    }

    // City and condition remain readable even when the widget is small.
    Item {
        id: details
        x: root.detailsX
        y: root.contentTop + (root.verySmall ? 2 : 9)
        width: root.detailsWidth
        height: Math.max(50, root.height - y - root.pad)

        Text {
            id: cityText
            width: parent.width
            text: root.weatherData.city || root.cityName
            color: studioPalette.paint(root.studioColor("#FFFFFF"), "text")
            font.family: root.studioFont("Noto Serif")
            font.pixelSize: root.wide ? Math.min(29, Math.max(21, root.width * 0.032))
                                      : (root.verySmall ? 14 : 19)
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }
        Text {
            id: conditionText
            width: parent.width
            y: cityText.y + cityText.height + 2
            text: root.hasWeather ? String(root.weatherData.condition || "Weather")
                     : (root.loadError ? "Weather unavailable" : "Loading forecast…")
            color: studioPalette.paint(root.studioColor("#BBC1C7"), "text")
            font.family: root.studioFont("Noto Sans")
            font.pixelSize: root.verySmall ? 10 : 13
            font.italic: root.wide
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // On large widgets, place the three measurements in a clean horizontal strip.
        Row {
            id: wideStats
            visible: root.wide
            x: 0
            y: Math.min(70, details.height * 0.31)
            width: parent.width
            height: 55
            spacing: 0
            Repeater {
                model: 3
                delegate: Item {
                    width: wideStats.width / 3
                    height: wideStats.height
                    property string fieldLabel: index === 0 ? "FEELS LIKE" : (index === 1 ? "WIND" : "HUMIDITY")
                    property string fieldValue: index === 0 ? root.degrees(root.weatherData.feels)
                              : (index === 1 ? root.roundNumber(root.weatherData.wind) + " km/h"
                                             : root.roundNumber(root.weatherData.humidity) + "%")
                    Text { font.family: root.studioFont("Noto Sans"); 
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        y: 0
                        text: fieldLabel
                        font.pixelSize: Math.max(8,Math.round(10*root.studioTextScale))
                        font.letterSpacing: 1.3
                        color: studioPalette.paint(root.studioColor("#AEB4BD"), "muted")
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        y: 22
                        text: fieldValue
                        color: studioPalette.paint(root.studioColor("#FFFFFF"), "text")
                        font.family: root.studioFont("Noto Sans")
                        font.pixelSize: Math.max(8,Math.round(22*root.studioTextScale))
                        elide: Text.ElideRight
                        width: parent.width - 18
                    }
                    Rectangle {
                        anchors.right: parent.right
                        width: 1; height: 55; y: 1
                        color: studioPalette.paint(root.studioColor("#50555E"), "surface")
                        visible: index < 2
                    }
                }
            }
        }

        Column {
            visible: !root.wide
            x: 0
            y: conditionText.y + conditionText.height + (root.verySmall ? 7 : 16)
            spacing: root.verySmall ? 3 : 10
            Repeater {
                model: 3
                delegate: Text { font.family: root.studioFont("Noto Sans"); 
                    width: details.width
                    text: (index === 0 ? "FEELS " + root.degrees(root.weatherData.feels)
                           : (index === 1 ? "WIND " + root.roundNumber(root.weatherData.wind) + " km/h"
                                          : "HUMIDITY " + root.roundNumber(root.weatherData.humidity) + "%"))
                    color: index === 0 ? "#FFFFFF" : "#D1D6DC"
                    font.pixelSize: root.verySmall ? 10 : 13
                    elide: Text.ElideRight
                }
            }
        }

        // Forecast is intentionally hidden in compact sizes rather than clipped.
        Item {
            id: forecast
            visible: root.wide
            x: 0
            y: Math.max(116, details.height - 76)
            width: parent.width
            height: 74
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: studioPalette.paint(root.studioColor("#52565C"), "surface")
            }
            Canvas {
                id: forecastLine
                x: 0; y: 54
                width: parent.width
                height: 19
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.lineWidth = 1.2
                    ctx.strokeStyle = "#AEB5BC"
                    ctx.beginPath()
                    ctx.moveTo(0,13)
                    ctx.bezierCurveTo(width * 0.17, 3, width * 0.2, 4, width / 3, 11)
                    ctx.bezierCurveTo(width * 0.52, 17, width * 0.57, 17, width * 2 / 3, 10)
                    ctx.bezierCurveTo(width * 0.82, 4, width * 0.9, 5, width, 11)
                    ctx.stroke()
                }
            }
            Row {
                x: 0; y: 10
                width: parent.width
                height: 41
                Repeater {
                    model: 3
                    delegate: Item {
                        width: forecast.width / 3
                        height: 41
                        property var dayWeather: (root.weatherData.daily && root.weatherData.daily.length > index)
                                                 ? root.weatherData.daily[index] : null
                        Text { font.family: root.studioFont("Noto Sans"); 
                            x: 13; y: 0
                            text: dayWeather ? dayWeather.label : (index === 0 ? "TODAY" : "--")
                            color: studioPalette.paint(root.studioColor("#BFC5CC"), "text")
                            font.pixelSize: Math.max(8,Math.round(10*root.studioTextScale))
                            font.letterSpacing: 1.3
                        }
                        Text { font.family: root.studioFont("Noto Sans"); 
                            x: 13; y: 21
                            text: dayWeather ? root.degrees(dayWeather.hi) + " / " + root.degrees(dayWeather.lo) : "-- / --"
                            color: studioPalette.paint(root.studioColor("#FFFFFF"), "text")
                            font.pixelSize: Math.max(8,Math.round(13*root.studioTextScale))
                        }
                        Rectangle {
                            anchors.right: parent.right
                            y: 7
                            height: 30; width: 1
                            color: studioPalette.paint(root.studioColor("#50555C"), "surface")
                            visible: index < 2
                        }
                    }
                }
            }
        }
    }
}
