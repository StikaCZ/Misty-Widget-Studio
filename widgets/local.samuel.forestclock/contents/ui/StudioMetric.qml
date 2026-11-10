import QtQuick
import QtQuick.Layouts
Item {
    ThemePalette { id: studioPalette }

    id: metric
    property string label: "CPU"
    property string value: "0%"
    property string subtext: ""
    property real progress: -1
    property color fg: studioPalette.paint("#E9F0EC", "text")
    property color muted: studioPalette.paint("#9BAA9F", "muted")
    property color accent: studioPalette.paint("#A7C2AC", "accent")
    property real textScale: 1.0
    implicitHeight: 65
    implicitWidth: 110
    Text {
        id: heading
        x: 0; y: 1
        width: parent.width
        text: metric.label.toUpperCase()
        color: metric.muted
        font.family: "JetBrains Mono"
        font.pixelSize: Math.max(9, Math.round(10*metric.textScale))
        elide: Text.ElideRight
    }
    Text {
        id: primary
        x: 0; y: 17; width: parent.width
        text: metric.value
        color: metric.fg
        font.family: "JetBrains Mono"
        font.weight: Font.DemiBold
        font.pixelSize: Math.max(15, Math.min(Math.round(25*metric.textScale),metric.width*0.15))
        elide: Text.ElideRight
    }
    Text {
        visible: metric.subtext.length > 0
        x: 0; y: 47; width: parent.width
        text: metric.subtext
        color: metric.muted
        font.family: "JetBrains Mono"
        font.pixelSize: Math.max(8,Math.round(9*metric.textScale))
        elide: Text.ElideRight
    }
    Rectangle {
        visible: metric.progress >= 0
        x: 0; anchors.bottom: parent.bottom
        width: parent.width; height: 3; radius: 2
        color: studioPalette.paint("#4c53605b", "muted")
        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: Math.max(0,Math.min(parent.width, parent.width * metric.progress/100.0))
            radius: parent.radius
            color: metric.accent
        }
    }
}
