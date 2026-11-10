import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_fishCount: fishCount.value
    property alias cfg_motionSpeed: speed.value
    property string cfg_palette: "subtle"
    property alias cfg_showBubbles: bubbles.checked
    property alias cfg_showSeaweed: seaweed.checked
    property alias cfg_showWaves: waves.checked
    property alias cfg_showJellyfish: jellyfish.checked
    property alias cfg_glassBackground: glass.checked
    readonly property var paletteIds: ["subtle", "mono", "classic"]

    QQC2.SpinBox {
        id: fishCount
        Kirigami.FormData.label: i18n("Number of fish:")
        from: 1
        to: 9
        stepSize: 1
    }
    QQC2.SpinBox {
        id: speed
        Kirigami.FormData.label: i18n("Swimming speed:")
        from: 1
        to: 3
        stepSize: 1
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Colour style:")
        model: [i18n("Subtle cyan and grey"), i18n("Monochrome"), i18n("Classic terminal colours")]
        currentIndex: Math.max(0, page.paletteIds.indexOf(page.cfg_palette))
        onActivated: function(index) { page.cfg_palette = page.paletteIds[index] }
    }
    QQC2.CheckBox {
        id: bubbles
        Kirigami.FormData.label: i18n("Details:")
        text: i18n("Floating bubbles")
    }
    QQC2.CheckBox { id: seaweed; text: i18n("Swaying seaweed") }
    QQC2.CheckBox { id: waves; text: i18n("Water surface") }
    QQC2.CheckBox { id: jellyfish; text: i18n("Floating jellyfish") }
    QQC2.CheckBox { id: glass; text: i18n("Slightly transparent background") }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Click the aquarium to pause or resume. Animation runs only while the widget is visible and not paused.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
