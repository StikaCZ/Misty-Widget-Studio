import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
PlasmoidItem {
    ThemePalette { id: studioPalette }

    // The legacy widgetOpacity setting now affects backgrounds only. Foreground stays fully visible.
    property real mistyWholeOpacity: Math.max(0, Math.min(1, (Plasmoid.configuration.widgetOpacity ?? 100) / 100.0))
    property color mistyGlassTint: studioPalette.paint(Plasmoid.configuration.glassTint || "#8076CF", "accent")

    id: widget
    implicitWidth: 425
    implicitHeight: 180
    Layout.preferredWidth: 425
    Layout.preferredHeight: 180
    Layout.minimumWidth: 175
    Layout.minimumHeight: 94
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    property string selectedStyle: Plasmoid.configuration.widgetStyle || "normal"
    readonly property string clockMode: Plasmoid.configuration.clockMode || "classic"
    fullRepresentation: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: widget.implicitWidth
        implicitHeight: widget.implicitHeight
        Loader {
            id: contentLoader
            anchors.fill: parent
            asynchronous: false
            source: widget.clockMode !== "classic" ? "ClockModes.qml" : widget.selectedStyle === "normal" ? "OriginalView.qml" : "StudioView.qml"
        }
        Rectangle { anchors.fill: parent; radius: 8; color: studioPalette.paint("#e0151c1c", "surface"); visible: contentLoader.status === Loader.Error }
        Text {
            anchors.centerIn: parent; width: Math.max(100,parent.width-20)
            visible: contentLoader.status === Loader.Error
            color: studioPalette.paint("#e3eee8", "text"); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            font.family: "monospace"; font.pixelSize: 12
            text: "STYLE ERROR\nSwitch to Normal in Configure → Appearance"
        }
    }
}
