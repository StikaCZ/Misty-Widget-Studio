import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_palette: "rose"
    property alias cfg_customAccent: accentText.text
    property alias cfg_customBackground: backgroundText.text
    property alias cfg_backgroundOpacity: opacity.value
    property alias cfg_glyphOpacity: glyphOpacity.value
    property alias cfg_fontSize: fontSize.value
    property alias cfg_cornerRadius: corners.value
    property alias cfg_showBorder: borderCheck.checked

    readonly property var paletteIds: ["rose", "ice", "violet", "matrix", "mono", "custom"]
    function paletteIndex(name) { return Math.max(0, paletteIds.indexOf(name)) }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Colour preset:")
        model: [i18n("Dusty pink (reference)"), i18n("Icy blue"), i18n("Lavender"),
                i18n("Classic green"), i18n("Monochrome"), i18n("Custom colours")]
        currentIndex: page.paletteIndex(page.cfg_palette)
        onActivated: function(index) { page.cfg_palette = page.paletteIds[index] }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Custom code colour:")
        QQC2.TextField {
            id: accentText
            text: "#d597bd"
            placeholderText: "#d597bd"
            maximumLength: 7
            Layout.preferredWidth: 125
            validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
            onEditingFinished: page.cfg_palette = "custom"
        }
        Rectangle {
            Layout.preferredWidth: 24; Layout.preferredHeight: 24
            radius: 4; color: accentText.acceptableInput ? accentText.text : "#d597bd"
            border.color: "#767676"
        }
        QQC2.Button {
            text: i18n("Choose…")
            onClicked: { accentPicker.selectedColor = accentText.acceptableInput ? accentText.text : "#d597bd"; accentPicker.open() }
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Custom background:")
        QQC2.TextField {
            id: backgroundText
            text: "#111423"
            placeholderText: "#111423"
            maximumLength: 7
            Layout.preferredWidth: 125
            validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
            onEditingFinished: page.cfg_palette = "custom"
        }
        Rectangle {
            Layout.preferredWidth: 24; Layout.preferredHeight: 24
            radius: 4; color: backgroundText.acceptableInput ? backgroundText.text : "#111423"
            border.color: "#767676"
        }
        QQC2.Button {
            text: i18n("Choose…")
            onClicked: { backgroundPicker.selectedColor = backgroundText.acceptableInput ? backgroundText.text : "#111423"; backgroundPicker.open() }
        }
    }

    Dialogs.ColorDialog {
        id: accentPicker
        title: i18n("Choose the falling-code colour")
        onAccepted: { accentText.text = selectedColor.toString(); page.cfg_palette = "custom" }
    }
    Dialogs.ColorDialog {
        id: backgroundPicker
        title: i18n("Choose the background colour")
        onAccepted: { backgroundText.text = selectedColor.toString(); page.cfg_palette = "custom" }
    }

    QQC2.SpinBox {
        id: opacity
        Kirigami.FormData.label: i18n("Background opacity (%):")
        from: 0; to: 100; stepSize: 5; editable: true; value: 94
    }
    QQC2.SpinBox {
        id: glyphOpacity
        Kirigami.FormData.label: i18n("Text opacity (%):")
        from: 20; to: 100; stepSize: 5; editable: true; value: 90
    }
    QQC2.SpinBox {
        id: fontSize
        Kirigami.FormData.label: i18n("Character size (px):")
        from: 7; to: 16; stepSize: 1; editable: true; value: 8
    }
    QQC2.SpinBox {
        id: corners
        Kirigami.FormData.label: i18n("Corner radius (px):")
        from: 0; to: 24; stepSize: 2; editable: true; value: 6
    }
    QQC2.CheckBox { id: borderCheck; text: i18n("Draw a subtle border"); checked: false }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Choose Custom colours after editing HEX values, or use one of the ready-made presets.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
