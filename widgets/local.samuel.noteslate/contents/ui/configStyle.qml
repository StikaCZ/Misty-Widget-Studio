import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_widgetStyle: "normal"
    property alias cfg_accentColor: accentHex.text
    property alias cfg_glassBlur: frostSlider.value
    property alias cfg_glassOpacity: glassAlpha.value
    property alias cfg_widgetOpacity: wholeOpacity.value
    property alias cfg_glassTint: glassTintField.text
    property alias cfg_cornerRadius: glassRadius.value
    property alias cfg_textScale: textScaleInput.value
    property alias cfg_lowPower: lowPowerInput.checked
    readonly property var styles: ["normal", "glass", "terminal", "minimal"]
    readonly property var colors: ["#9FB6A2", "#8FBDD1", "#D0B282", "#DDE3E2", "#D3A1B4"]

    QQC2.ComboBox {
        id: styleSelector
        Kirigami.FormData.label: i18n("Design:")
        Layout.fillWidth: true
        model: [i18n("Normal (original)"), i18n("Liquid Glass"), i18n("Terminal (Alacritty)"), i18n("Minimal")]
        currentIndex: Math.max(0, page.styles.indexOf(page.cfg_widgetStyle))
        onActivated: function(index) { page.cfg_widgetStyle = page.styles[index] }
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: page.cfg_widgetStyle === "normal" ? i18n("Original artwork and layout — no style overrides.")
            : page.cfg_widgetStyle === "glass" ? i18n("Frosted-looking, translucent panels with light-catching edges.")
            : page.cfg_widgetStyle === "terminal" ? i18n("Clean monospaced readouts inspired by an Alacritty terminal.")
            : i18n("Reduced background and text for a wallpaper-first look.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Accent preset:")
        model: [i18n("Custom"),i18n("Misty sage"),i18n("Arctic blue"),i18n("Warm amber"),i18n("Monochrome"),i18n("Rose")]
        onActivated: function(index) { if (index > 0) page.cfg_accentColor = page.colors[index - 1]; currentIndex = 0 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Accent colour:")
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 30
            onClicked: { picker.selectedColor = accentHex.text; picker.open() }
            contentItem: Rectangle { radius: 6; color: accentHex.text; border.color: "#839890"; border.width: 1 }
        }
        QQC2.TextField { id: accentHex; Layout.preferredWidth: 130; maximumLength: 9; placeholderText: "#9FB6A2" }
    }
    ColorDialog { id: picker; title: i18n("Accent colour"); onAccepted: page.cfg_accentColor = selectedColor.toString() }

    RowLayout {
        Kirigami.FormData.label: i18n("Background opacity:")
        Layout.fillWidth: true
        QQC2.Slider { id: wholeOpacity; Layout.fillWidth: true; from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(wholeOpacity.value) + "%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight }
    }
    QQC2.Label { text: i18n("Changes only panel/background transparency. Text, icons, graphs, sprites and controls remain readable."); wrapMode: Text.WordWrap; Layout.fillWidth: true }
    RowLayout {
        Kirigami.FormData.label: i18n("Glass tint:")
        enabled: page.cfg_widgetStyle === "glass"
        Layout.fillWidth: true
        QQC2.ComboBox {
            id: tintPresets; Layout.fillWidth: true
            model: [i18n("Custom"),i18n("Iridescent lilac"),i18n("Sage glass"),i18n("Crystal blue"),i18n("Silver frost"),i18n("Reference silver glass")]
            onActivated: function(i) {
                const presets = ["", "#8076CF", "#739B88", "#6699C8", "#A8ADB9", "#899EBB"]
                if (i > 0) page.cfg_glassTint = presets[i]
                currentIndex = 0
            }
        }
        QQC2.TextField { id: glassTintField; Layout.preferredWidth: 95; placeholderText: "#8076CF"; maximumLength: 9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Glass background:")
        Layout.fillWidth: true
        enabled: page.cfg_widgetStyle === "glass"
        QQC2.Slider {
            id: glassAlpha; Layout.fillWidth: true; from: 35; to: 98; stepSize: 1; snapMode: QQC2.Slider.SnapAlways
        }
        QQC2.Label { text: Math.round(glassAlpha.value) + "%"; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Frost softness:")
        Layout.fillWidth: true
        enabled: page.cfg_widgetStyle === "glass"
        QQC2.Slider { id: frostSlider; Layout.fillWidth: true; from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(frostSlider.value) + "%"; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
    }
    QQC2.Label {
        visible: page.cfg_widgetStyle === "glass"
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Softens the glass surface with frosted diffusion. It does not blur the wallpaper behind desktop widgets.")
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Corner radius:")
        Layout.fillWidth: true
        enabled: page.cfg_widgetStyle === "glass"
        QQC2.Slider { id: glassRadius; Layout.fillWidth: true; from: 4; to: 30; stepSize: 1; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(glassRadius.value) + " px"; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Text size:")
        Layout.fillWidth: true
        enabled: page.cfg_widgetStyle !== "normal"
        QQC2.Slider { id: textScaleInput; Layout.fillWidth: true; from: 75; to: 150; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(textScaleInput.value) + "%"; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
    }
    QQC2.CheckBox { id: lowPowerInput; Kirigami.FormData.label: i18n("Performance:"); text: i18n("Reduce unnecessary refreshing and animation") }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Resize: right-click the widget → Enter Edit Mode → drag its resize handle. Click Apply to save changes.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
