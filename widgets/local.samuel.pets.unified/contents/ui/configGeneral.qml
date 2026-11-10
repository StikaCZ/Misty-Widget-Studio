import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_pet: "penguin"
    property alias cfg_trackWidth: areaSize.value
    property alias cfg_speed: pace.value
    property alias cfg_petSize: size.value
    property alias cfg_petHeight: heightSpin.value
    property alias cfg_activityLevel: personality.value
    property alias cfg_allowSleep: sleepToggle.checked
    property alias cfg_allowSurprises: funToggle.checked
    property alias cfg_clickToPlay: clickToggle.checked
    property alias cfg_reactToHover: hoverToggle.checked
    property alias cfg_showPetStatus: statusToggle.checked
    readonly property var petIds: ["penguin", "gecko", "slime"]

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Pet:")
        Layout.fillWidth: true
        model: ["Linux Penguin", "Leopard Gecko", "Blue Slime"]
        currentIndex: Math.max(0, page.petIds.indexOf(page.cfg_pet))
        onActivated: function(i) { page.cfg_pet = page.petIds[i] }
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Movement & personality")
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Pace:")
        Layout.fillWidth: true
        QQC2.Slider { id: pace; Layout.fillWidth: true; from: 1; to: 5; stepSize: 1; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: String(Math.round(pace.value)); Layout.preferredWidth: 24 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Playfulness:")
        Layout.fillWidth: true
        QQC2.Slider { id: personality; Layout.fillWidth: true; from: 1; to: 5; stepSize: 1; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: String(Math.round(personality.value)); Layout.preferredWidth: 24 }
    }
    QQC2.CheckBox { id: sleepToggle; Kirigami.FormData.label: i18n("Behaviours:"); text: i18n("Let pets nap") }
    QQC2.CheckBox { id: funToggle; text: i18n("Play, wave, lick, bounce and dash") }
    QQC2.CheckBox { id: hoverToggle; text: i18n("React when I hover over the pet") }
    QQC2.CheckBox { id: clickToggle; text: i18n("Click to play or wake") }
    QQC2.CheckBox { id: statusToggle; text: i18n("Show status in Terminal mode") }
    QQC2.Label { Kirigami.FormData.isSection: true; text: i18n("Size & walking area") }
    RowLayout {
        Kirigami.FormData.label: i18n("Pet size:")
        Layout.fillWidth: true
        QQC2.Slider { id: size; Layout.fillWidth: true; from: 50; to: 200; stepSize: 5; snapMode: QQC2.Slider.SnapAlways }
        QQC2.Label { text: Math.round(size.value) + "%"; Layout.preferredWidth: 42 }
    }
    QQC2.SpinBox { id: areaSize; Kirigami.FormData.label: i18n("Walking width:"); from: 140; to: 560; stepSize: 20; editable: true }
    QQC2.SpinBox { id: heightSpin; Kirigami.FormData.label: i18n("Pet area height:"); from: 42; to: 180; stepSize: 2; editable: true }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Resize the pet widget taller for sizes above 150%. Left click: special action · Middle click: pause · Right click: KDE menu. The pet stays inside its widget area.")
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
