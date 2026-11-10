import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_studioUseColours: enable.checked
    property alias cfg_studioThemeText: primaryField.text
    property alias cfg_studioThemeMuted: mutedField.text
    property alias cfg_studioThemeAccent: accentField.text
    property alias cfg_studioThemeSurface: surfaceField.text
    property alias cfg_studioThemeBorder: borderField.text
    property alias cfg_studioThemeSecondary: secondField.text
    property string editingRole: ""

    readonly property var palettePresets: [
        ["#E8F0EC", "#A7B3AD", "#93BFA7", "#1A2429", "#6B8285", "#92A9D7"],
        ["#E8F5E9", "#A8C6B3", "#58C17C", "#14271C", "#476D53", "#B0E2A2"],
        ["#E8FFF2", "#A1D6BA", "#16B77C", "#092C23", "#397E63", "#7DE3BD"],
        ["#DFFFDE", "#89C997", "#65F26A", "#091710", "#295A36", "#A1FFAC"],
        ["#F1F2DF", "#B6B99B", "#A2BA62", "#252B1D", "#65704B", "#DAE5A0"],
        ["#F0F4DE", "#B5C49E", "#87B76E", "#202D21", "#536D50", "#BCD896"],
        ["#DFFAF4", "#9BD4C9", "#3DBAB5", "#09272C", "#3E7278", "#85E0DC"],
        ["#E4F0FA", "#A1BDD0", "#7DBCE8", "#152633", "#67869F", "#D8EFFF"],
        ["#E5F3FF", "#94BCD9", "#4D98D4", "#102A44", "#315F88", "#87D2F5"],
        ["#E1E9FF", "#9BAFD8", "#7B91D9", "#131A30", "#3A4B77", "#A0C7FF"],
        ["#E3FDFF", "#8BD4DF", "#3DDAED", "#102C35", "#3E8894", "#A1F8FF"],
        ["#F2E9FF", "#C1B0DE", "#B597ED", "#231A37", "#806CA3", "#E7B9FF"],
        ["#F1E6FF", "#C2A4DA", "#A267E3", "#2B173B", "#664486", "#D9ACFF"],
        ["#FFE9F2", "#DFABC1", "#ED83B1", "#371B2A", "#87506A", "#FFC5DB"],
        ["#FFF0EF", "#D6A9A6", "#E16C67", "#30191B", "#89504F", "#FFB1A2"],
        ["#F4E7D5", "#D4B99C", "#E7B56D", "#2A231C", "#9B7957", "#DCC8A3"],
        ["#FFF0E3", "#D9B59D", "#F09D58", "#2D1C1D", "#936447", "#FFCC83"],
        ["#F0F0F0", "#AAAAAA", "#D2D2D2", "#1B1B1B", "#737373", "#D0D0D0"],
        ["#25382F", "#566E60", "#278764", "#F5F5EC", "#9BB0A1", "#B06D49"]
    ]
    readonly property var presetNames: ["Misty sage", "Forest green", "Emerald green", "Matrix green", "Olive green", "Moss green", "Teal", "Glacier blue", "Ocean blue", "Midnight blue", "Cyan", "Lilac", "Amethyst purple", "Rose pink", "Crimson red", "Warm amber", "Sunset orange", "Monochrome", "Ivory light"]


    function choosePreset(i) {
        if (i < 1) return
        const a = palettePresets[i - 1]
        page.cfg_studioThemeText = a[0]
        page.cfg_studioThemeMuted = a[1]
        page.cfg_studioThemeAccent = a[2]
        page.cfg_studioThemeSurface = a[3]
        page.cfg_studioThemeBorder = a[4]
        page.cfg_studioThemeSecondary = a[5]
        page.cfg_studioUseColours = true
    }
    function showColourPicker(role, value) {
        editingRole = role
        picker.selectedColor = value
        picker.open()
    }
    function setColour(role, value) {
        switch (role) {
        case "text": page.cfg_studioThemeText = value; break
        case "muted": page.cfg_studioThemeMuted = value; break
        case "accent": page.cfg_studioThemeAccent = value; break
        case "surface": page.cfg_studioThemeSurface = value; break
        case "border": page.cfg_studioThemeBorder = value; break
        case "secondary": page.cfg_studioThemeSecondary = value; break
        }
    }
    ColorDialog {
        id: picker
        title: i18n("Widget colour")
        onAccepted: page.setColour(page.editingRole, selectedColor.toString())
    }
    QQC2.CheckBox {
        id: enable
        Kirigami.FormData.label: i18n("Custom theme:")
        text: i18n("Use my colours in every appearance")
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Select a palette, click Apply, and set Style & layout → Background opacity. The Background swatch controls the outer panel; labels and artwork stay opaque. A transparent backdrop shows wallpaper through it.")
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Preset:")
        // Even when custom colours are off, selecting a preset turns them on.
        Layout.fillWidth: true
        model: [i18n("Choose preset…")].concat(page.presetNames)
        onActivated: function(index) { page.choosePreset(index); currentIndex = 0 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Current palette:")
        spacing: 5
        Repeater {
            model: [primaryField.text, mutedField.text, accentField.text, secondField.text, surfaceField.text, borderField.text]
            delegate: Rectangle {
                width: 28
                height: 20
                radius: 4
                color: modelData
                border.color: "#858585"
                border.width: 1
            }
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Main text:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("text", primaryField.text)
            contentItem: Rectangle { radius: 5; color: primaryField.text; border.color: "#808080"; border.width: 1 }
        }
        QQC2.TextField { id: primaryField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#E8F0EC" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Secondary text:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("muted", mutedField.text)
            contentItem: Rectangle { radius: 5; color: mutedField.text; border.color: "#808080"; border.width: 1 }
        }
        QQC2.TextField { id: mutedField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#A7B3AD" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Accent / data:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("accent", accentField.text)
            contentItem: Rectangle { radius: 5; color: accentField.text; border.color: "#808080"; border.width: 1 }
        }
        QQC2.TextField { id: accentField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#93BFA7" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Second accent:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("secondary", secondField.text)
            contentItem: Rectangle { radius: 5; color: secondField.text; border.color: "#808080"; border.width: 1 }
        }
        QQC2.TextField { id: secondField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#92A9D7" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Background:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("surface", surfaceField.text)
            contentItem: Rectangle { radius: 5; color: surfaceField.text; border.color: "#808080"; border.width: 1 }
        }
        QQC2.TextField { id: surfaceField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#1A2429" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Borders / lines:")
        enabled: page.cfg_studioUseColours
        QQC2.Button {
            implicitWidth: 35; implicitHeight: 29
            onClicked: page.showColourPicker("border", borderField.text)
            contentItem: Rectangle { radius: 5; color: borderField.text; border.width: 1; border.color: "#808080" }
        }
        QQC2.TextField { id: borderField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#6B8285" }
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Select any preset (it automatically enables custom colours), then Apply to save. Transparent areas stay transparent; moon artwork, device LED colours and individual pet sprite pixels are not automatically recoloured. Plants, fish and pet accents retain their own extra settings.")
    }
}
