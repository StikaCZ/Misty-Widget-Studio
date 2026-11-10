import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    ThemePalette { id: studioPalette }

    id: root

    // KDE's desktop resize handle controls the item. No fixed width/height.
    implicitWidth: 425
    implicitHeight: 180
    Layout.preferredWidth: 425
    Layout.preferredHeight: 180
    Layout.minimumWidth: 118
    Layout.minimumHeight: 68


    // Your original two appearance options are retained by the installer.
    property bool showSoftBackground: false
    property bool showSecondsBar: true

    property date currentTime: new Date()
    readonly property string chosenClockFont: (Plasmoid.configuration.clockFontFamily || "JetBrains Mono") === "Custom" ? (Plasmoid.configuration.clockCustomFont || "sans-serif") : (Plasmoid.configuration.clockFontFamily || "JetBrains Mono")
    readonly property real clockFontScale: Math.max(.65, Math.min(1.8, (Plasmoid.configuration.clockScale ?? 100)/100))
    readonly property bool showClockDate: Plasmoid.configuration.clockShowDate !== false
    readonly property bool showClockCaption: Plasmoid.configuration.clockShowCaption !== false

    // Switch layouts instead of shrinking every text element by a fixed factor.
    readonly property bool compactLayout: width < 250 || height < 135
    readonly property bool tinyLayout: width < 175 || height < 95
    readonly property int marginSize: Math.max(4, Math.min(14, Math.round(Math.min(width, height) * 0.06)))
    readonly property real usableHeight: Math.max(1, height - 2 * marginSize)
    readonly property bool captionVisible: !compactLayout && showClockCaption
    readonly property bool barVisible: showSecondsBar && !tinyLayout
    readonly property real captionHeight: captionVisible ? usableHeight * 0.14 : 0
    readonly property real clockHeight: usableHeight * (tinyLayout ? 0.76 : compactLayout ? 0.71 : 0.58)
    readonly property real barHeight: barVisible ? usableHeight * (compactLayout ? 0.06 : 0.075) : 0
    readonly property real dateHeight: showClockDate ? Math.max(0, usableHeight - captionHeight - clockHeight - barHeight) : 0

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentTime = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: studioPalette.panel("#88131518")
        border.color: studioPalette.outline("#507D858B")
        border.width: 1
        visible: root.showSoftBackground
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.marginSize
        spacing: 0

        Item {
            width: parent.width
            height: root.captionHeight
            visible: root.captionVisible

            Text {
                anchors.fill: parent
                text: "L O C A L   /   T I M E"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.chosenClockFont
                font.weight: Font.DemiBold
                font.pixelSize: Math.max(11, Math.round(parent.height * 0.67))
                fontSizeMode: Text.Fit
                minimumPixelSize: 8
                color: studioPalette.paint("#F3F4F5", "text")
                style: Text.Outline
                styleColor: "#A5181B1F"
            }
        }

        Item {
            width: parent.width
            height: root.clockHeight

            Text {
                anchors.fill: parent
                text: Qt.formatTime(root.currentTime, "HH:mm")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.chosenClockFont
                font.weight: Font.Bold
                font.pixelSize: Math.max(28, Math.round(parent.height * 0.98 * root.clockFontScale))
                fontSizeMode: Text.Fit
                minimumPixelSize: 16
                font.letterSpacing: -1
                color: studioPalette.paint("#FFFFFF", "text")
                style: Text.Outline
                styleColor: "#B5181B1F"
            }
        }

        Item {
            width: parent.width
            height: root.barHeight
            visible: root.barVisible

            Rectangle {
                width: parent.width * 0.66
                height: Math.max(1, Math.min(3, parent.height * 0.35))
                radius: 1
                color: studioPalette.paint("#66545A60", "surface")
                anchors.centerIn: parent

                Rectangle {
                    width: parent.width * root.currentTime.getSeconds() / 60
                    height: parent.height
                    radius: parent.radius
                    color: studioPalette.paint("#F3F4F5", "text")
                }
            }
        }

        Item {
            width: parent.width
            height: root.dateHeight
            visible: root.showClockDate

            Text {
                anchors.fill: parent
                text: root.tinyLayout
                      ? Qt.formatDate(root.currentTime, "dd MMM").toUpperCase()
                      : root.compactLayout
                        ? Qt.formatDate(root.currentTime, "ddd  dd MMM").toUpperCase()
                        : Qt.formatDate(root.currentTime, "dddd").toUpperCase()
                          + "   /   " + Qt.formatDate(root.currentTime, "dd MMM yyyy").toUpperCase()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.chosenClockFont
                font.weight: Font.DemiBold
                font.pixelSize: Math.max(12, Math.round(parent.height * 0.78))
                fontSizeMode: Text.Fit
                minimumPixelSize: 8
                color: studioPalette.paint("#E6E8EA", "text")
                style: Text.Outline
                styleColor: "#B5181B1F"
                elide: Text.ElideRight
            }
        }
    }
}
