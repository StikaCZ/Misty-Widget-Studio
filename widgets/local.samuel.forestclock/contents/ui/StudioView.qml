import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    ThemePalette { id: studioPalette }

    id: root
    implicitWidth: 330
    implicitHeight: 140
    Layout.minimumWidth: 170
    Layout.minimumHeight: 100
    Layout.preferredWidth: 330
    Layout.preferredHeight: 140

    readonly property string mono: (Plasmoid.configuration.clockFontFamily || "JetBrains Mono") === "Custom" ? (Plasmoid.configuration.clockCustomFont || "sans-serif") : (Plasmoid.configuration.clockFontFamily || "JetBrains Mono")
    readonly property bool showClockDate: Plasmoid.configuration.clockShowDate !== false
    readonly property bool showClockCaption: Plasmoid.configuration.clockShowCaption !== false
    readonly property real clockFontScale: Math.max(.65,Math.min(1.8,(Plasmoid.configuration.clockScale ?? 100)/100))
    property date currentTime: new Date()
    Timer { interval: 1000; repeat: true; running: root.visible; onTriggered: root.currentTime = new Date() }
    

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
        
        
        Rectangle { anchors.fill: parent; radius: 5; color: studioPalette.panel(Qt.rgba(0.05,0.08,0.09,0.92)); border.width: 1; border.color: studioPalette.outline("#566b746b") }
        Text { x: 13; y: 9; text: "desktop  ~  $ date"; visible: root.showClockCaption; color: root.accentTint; font.family: root.mono; font.pixelSize: Math.max(8,Math.round(10*root.scaleFactor)) }
        Rectangle { x: 13; y: 29; width: Math.max(0,parent.width-26); height: 1; color: studioPalette.paint("#626D846E", "muted") }
        Text {
            x: 12; y: 30; width: parent.width-24; height: Math.max(35,parent.height-68)
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: Qt.formatTime(root.currentTime,"HH:mm")
            font.family: root.mono; font.bold: true
            font.pixelSize: Math.max(29,Math.min(63,terminal.height*0.42) * root.clockFontScale)
            fontSizeMode: Text.Fit; minimumPixelSize: 24
            color: studioPalette.paint("#D5E0D0", "text")
        }
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 11
            x: 13; width: parent.width-26
            horizontalAlignment: Text.AlignHCenter
            visible: root.showClockDate; text: Qt.formatDate(root.currentTime,"ddd dd MMM yyyy").toLowerCase()
            font.family: root.mono; font.pixelSize: Math.max(8,Math.round(11*root.scaleFactor)); color: studioPalette.paint("#94AA91", "muted")
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
            Text { text: "LOCAL / TIME"; visible: root.showClockCaption; font.family: root.mono; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#F4F8FF", "text"); Layout.fillWidth: true; elide: Text.ElideRight }
            Rectangle { Layout.preferredWidth: statusLabel.implicitWidth+17; Layout.preferredHeight: 22; radius: 11; color: studioPalette.paint("#36596d63", "muted"); border.color: studioPalette.paint("#5595b2a5", "border"); border.width: 1
                Text { id: statusLabel; anchors.centerIn: parent; text: "LOCAL"; visible: root.showClockCaption; font.family: root.mono; font.pixelSize: 9; color: root.accentTint }
            }
        }
                
        Text { Layout.fillWidth: true; text: Qt.formatTime(root.currentTime,"HH:mm"); color: studioPalette.paint("#f3f9f8", "text"); horizontalAlignment: Text.AlignHCenter; font.family: root.mono; font.bold: true; font.pixelSize: Math.max(26, Math.min(parent.width*0.17, parent.height*0.45)*root.scaleFactor*root.clockFontScale); fontSizeMode: Text.Fit; minimumPixelSize: 18 }
        Text { Layout.fillWidth: true; visible: root.showClockDate; text: Qt.formatDate(root.currentTime,"dddd · dd MMMM yyyy"); color: studioPalette.paint("#bdd0c9", "text"); horizontalAlignment: Text.AlignHCenter; font.family: root.mono; font.pixelSize: Math.max(9,Math.round(12*root.scaleFactor)); elide: Text.ElideRight }

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
      Text { Layout.fillWidth: true; text: "LOCAL / TIME"; visible: root.showClockCaption; font.family: root.mono; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: root.accentTint; elide: Text.ElideRight }
      Text { Layout.fillWidth: true; Layout.fillHeight: true; text: Qt.formatTime(root.currentTime,"HH:mm"); font.family: root.mono; font.weight: Font.DemiBold; font.pixelSize: Math.min(root.height*0.30,root.width*0.17)*root.scaleFactor*root.clockFontScale; minimumPixelSize: 18; fontSizeMode: Text.Fit; color: studioPalette.paint("#e8efeb", "text"); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
      Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: root.accentTint; opacity: 0.54 }
      Text { Layout.fillWidth: true; visible: root.showClockDate; text: Qt.formatDate(root.currentTime,"dddd, dd MMMM yyyy"); font.family: root.mono; font.pixelSize: Math.max(9,Math.round(10*root.scaleFactor)); color: studioPalette.paint("#bbc8bf", "text"); elide: Text.ElideRight }
   }
 }
}
}
