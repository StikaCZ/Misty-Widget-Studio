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

    QQC2.Label { Kirigami.FormData.isSection: true; text: i18n("Widget-specific appearance"); font.bold: true }

    property alias cfg_bgColor: bgColorField.text
    property alias cfg_headerColor: headerColorField.text
    property alias cfg_footerColor: footerColorField.text
    property alias cfg_textColor: textColorField.text
    property alias cfg_fishColor: fishColorField.text
    property alias cfg_plantColor: plantColorField.text
    property alias cfg_borderColor: borderColorField.text
    property alias cfg_bgOpacity: bgOpacityControl.value
    property alias cfg_borderOpacity: borderOpacityControl.value
    property alias cfg_contentOpacity: contentOpacityControl.value
    property alias cfg_widgetWidth: widgetWidthControl.value
    property alias cfg_widgetHeight: widgetHeightControl.value
    property alias cfg_fontScale: fontScaleControl.value
    property alias cfg_showHeader: showHeaderControl.checked
    property alias cfg_showStatus: showStatusControl.checked
    property alias cfg_monochromeFish: monochromeFishControl.checked
    property string selecting: ""

    function openPicker(key, value) {
        selecting = key
        colorPicker.selectedColor = value
        colorPicker.open()
    }

    ColorDialog {
        id: colorPicker
        title: i18n("Choose a colour")
        onAccepted: {
            const c = selectedColor.toString()
            switch (page.selecting) {
            case "bgColor": page.cfg_bgColor = c; break
            case "headerColor": page.cfg_headerColor = c; break
            case "footerColor": page.cfg_footerColor = c; break
            case "textColor": page.cfg_textColor = c; break
            case "accentColor": page.cfg_accentColor = c; break
            case "fishColor": page.cfg_fishColor = c; break
            case "plantColor": page.cfg_plantColor = c; break
            case "borderColor": page.cfg_borderColor = c; break
            }
        }
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Quick preset:")
        model: [i18n("Choose preset…"), i18n("Charcoal glass"), i18n("Monochrome"), i18n("Ice blue"), i18n("Forest"), i18n("Purple")]
        onActivated: function(index) {
            if (index < 1) return
            switch (index) {
            case 1:
                page.cfg_bgColor = "#101518"
                page.cfg_headerColor = "#1b2327"
                page.cfg_footerColor = "#151c20"
                page.cfg_textColor = "#c2cbd0"
                page.cfg_accentColor = "#7aafb8"
                page.cfg_fishColor = "#bddce0"
                page.cfg_plantColor = "#739d83"
                page.cfg_borderColor = "#384449"
                page.cfg_bgOpacity = 82
                page.cfg_borderOpacity = 100
                break
            case 2:
                page.cfg_bgColor = "#111315"
                page.cfg_headerColor = "#202326"
                page.cfg_footerColor = "#17191b"
                page.cfg_textColor = "#e2e4e6"
                page.cfg_accentColor = "#a1a8ae"
                page.cfg_fishColor = "#d0d4d8"
                page.cfg_plantColor = "#8a9298"
                page.cfg_borderColor = "#50565b"
                page.cfg_bgOpacity = 95
                page.cfg_monochromeFish = true
                break
            case 3:
                page.cfg_bgColor = "#0c1823"
                page.cfg_headerColor = "#152936"
                page.cfg_footerColor = "#10202d"
                page.cfg_textColor = "#d2f0f9"
                page.cfg_accentColor = "#6ec8ee"
                page.cfg_fishColor = "#9ad9ed"
                page.cfg_plantColor = "#4b9e9e"
                page.cfg_borderColor = "#3c657c"
                page.cfg_bgOpacity = 87
                page.cfg_monochromeFish = true
                break
            case 4:
                page.cfg_bgColor = "#101b19"
                page.cfg_headerColor = "#192b26"
                page.cfg_footerColor = "#14221e"
                page.cfg_textColor = "#d9e7df"
                page.cfg_accentColor = "#8ed3a5"
                page.cfg_fishColor = "#bcdbc9"
                page.cfg_plantColor = "#7bd18e"
                page.cfg_borderColor = "#456554"
                page.cfg_bgOpacity = 89
                page.cfg_monochromeFish = false
                break
            case 5:
                page.cfg_bgColor = "#171322"
                page.cfg_headerColor = "#241c33"
                page.cfg_footerColor = "#1d1729"
                page.cfg_textColor = "#e7ddf2"
                page.cfg_accentColor = "#bea1ef"
                page.cfg_fishColor = "#d3bff0"
                page.cfg_plantColor = "#9a8ac2"
                page.cfg_borderColor = "#625476"
                page.cfg_bgOpacity = 90
                page.cfg_monochromeFish = true
                break
            }
            currentIndex = 0
        }
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Colours — click the swatch or enter a HEX value")
        wrapMode: Text.WordWrap
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Background:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("bgColor", bgColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: bgColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: bgColorField
            Layout.preferredWidth: 120
            placeholderText: "#101518"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Top bar:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("headerColor", headerColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: headerColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: headerColorField
            Layout.preferredWidth: 120
            placeholderText: "#1b2327"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Bottom bar:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("footerColor", footerColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: footerColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: footerColorField
            Layout.preferredWidth: 120
            placeholderText: "#151c20"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Labels / text:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("textColor", textColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: textColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: textColorField
            Layout.preferredWidth: 120
            placeholderText: "#c2cbd0"
            maximumLength: 9
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Fish (single-colour mode):")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("fishColor", fishColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: fishColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: fishColorField
            Layout.preferredWidth: 120
            placeholderText: "#bddce0"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Seaweed:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("plantColor", plantColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: plantColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: plantColorField
            Layout.preferredWidth: 120
            placeholderText: "#739d83"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Border:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("borderColor", borderColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: borderColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: borderColorField
            Layout.preferredWidth: 120
            placeholderText: "#384449"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Background opacity %:")
        Layout.fillWidth: true
        QQC2.Slider { id: bgOpacityControl; Layout.fillWidth: true; from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(bgOpacityControl.value) + "%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Border opacity %:")
        Layout.fillWidth: true
        QQC2.Slider { id: borderOpacityControl; Layout.fillWidth: true; from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(borderOpacityControl.value) + "%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Fish / decorations opacity %:")
        Layout.fillWidth: true
        QQC2.Slider { id: contentOpacityControl; Layout.fillWidth: true; from: 20; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(contentOpacityControl.value) + "%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight }
    }
    QQC2.SpinBox {
        id: widgetWidthControl
        Kirigami.FormData.label: i18n("Preferred width px:")
        from: 240
        to: 840
        stepSize: 10
        editable: true
    }
    QQC2.SpinBox {
        id: widgetHeightControl
        Kirigami.FormData.label: i18n("Preferred height px:")
        from: 160
        to: 650
        stepSize: 10
        editable: true
    }

    QQC2.SpinBox {
        id: fontScaleControl
        Kirigami.FormData.label: i18n("ASCII / text scale %:")
        from: 65
        to: 160
        stepSize: 5
        editable: true
    }
    QQC2.CheckBox {
        id: showHeaderControl
        text: i18n("Show terminal title bar")
    }
    QQC2.CheckBox {
        id: showStatusControl
        text: i18n("Show bottom status bar")
    }
    QQC2.CheckBox {
        id: monochromeFishControl
        text: i18n("Use one custom colour for all fish")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Changes are saved by Apply. Each widget can use different colours and sizing.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

}
