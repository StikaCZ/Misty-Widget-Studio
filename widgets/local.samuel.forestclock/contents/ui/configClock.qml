import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_clockMode: "classic"
    property string cfg_clockFontFamily: "JetBrains Mono"
    property alias cfg_clockCustomFont: customName.text
    property alias cfg_clockScale: scaleSlider.value
    property alias cfg_clockShowDate: dateToggle.checked
    property alias cfg_clockShowCaption: captionToggle.checked
    property alias cfg_clockSecondsHand: secondsToggle.checked
    property alias cfg_clockFaceColor: faceField.text
    property alias cfg_clockHandsColor: handsField.text
    property alias cfg_clockSecondColor: secondField.text
    property string colourTarget: ""
    readonly property var modes: ["classic","digital24","digital12","seconds","flip","analog","binary"]
    readonly property var fonts: ["JetBrains Mono","Noto Sans","DejaVu Sans Mono","Liberation Sans","Roboto","Inter","sans-serif","monospace","Custom"]
    readonly property var modesNames: ["Classic (current style)","Digital · 24-hour","Digital · AM/PM","Digital · with seconds","Flip clock","Analogue clock","Binary clock"]
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Clock type:")
        Layout.fillWidth: true
        model: page.modesNames
        currentIndex: Math.max(0,page.modes.indexOf(page.cfg_clockMode))
        onActivated: function(i) { page.cfg_clockMode = page.modes[i] }
    }
    QQC2.Label {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: i18n("Classic keeps the chosen Normal, Glass, Terminal or Minimal layout. Other clock types use the same colour theme and can be resized on your desktop.")
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Clock font:")
        Layout.fillWidth: true
        model: page.fonts
        currentIndex: Math.max(0,page.fonts.indexOf(page.cfg_clockFontFamily))
        onActivated: function(i) { page.cfg_clockFontFamily = page.fonts[i] }
    }
    QQC2.TextField {
        id: customName
        Kirigami.FormData.label: i18n("Custom font name:")
        Layout.fillWidth: true
        enabled: page.cfg_clockFontFamily === "Custom"
        placeholderText: i18n("Installed font family")
    }
    QQC2.Label {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: i18n("Fonts must already be installed on your computer. Unknown fonts fall back to the system font.")
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Font size:")
        QQC2.Slider { id: scaleSlider; Layout.fillWidth: true; from: 65; to: 180; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(scaleSlider.value)+"%"; Layout.preferredWidth: 46 }
    }
    QQC2.CheckBox { id: dateToggle; Kirigami.FormData.label: i18n("Date:"); text: i18n("Display date") }
    QQC2.CheckBox { id: captionToggle; Kirigami.FormData.label: i18n("Caption:"); text: i18n("Display title / timezone label") }
    QQC2.CheckBox { id: secondsToggle; Kirigami.FormData.label: i18n("Analogue:"); text: i18n("Show second hand") }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Analogue clock colours")
    }
    function editColour(target,current) { colourTarget=target; colourPicker.selectedColor=current; colourPicker.open() }
    ColorDialog {
        id: colourPicker
        title: i18n("Clock colour")
        onAccepted: {
            const value=selectedColor.toString()
            if (page.colourTarget==="face") faceField.text=value
            else if (page.colourTarget==="hands") handsField.text=value
            else secondField.text=value
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Clock face:")
        QQC2.Button { text: "●"; onClicked: page.editColour("face",faceField.text) }
        QQC2.TextField { id: faceField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#162326" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Hands / numerals:")
        QQC2.Button { text: "●"; onClicked: page.editColour("hands",handsField.text) }
        QQC2.TextField { id: handsField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#E8F0EC" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Second hand:")
        QQC2.Button { text: "●"; onClicked: page.editColour("seconds",secondField.text) }
        QQC2.TextField { id: secondField; Layout.fillWidth: true; maximumLength: 9; placeholderText: "#94C6A9" }
    }
    QQC2.Label {
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        text: i18n("The global Theme colours override can replace the clock colours. Turn it off for these individual colour values.")
    }
}
