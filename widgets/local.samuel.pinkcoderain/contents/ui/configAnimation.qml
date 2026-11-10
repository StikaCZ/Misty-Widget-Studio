import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_speed: speed.value
    property alias cfg_density: density.value
    property alias cfg_trailLength: trail.value
    property alias cfg_lowPower: lowPower.checked
    property alias cfg_pauseWhenHidden: pauseHidden.checked
    property alias cfg_brightHeads: highlights.checked

    QQC2.SpinBox {
        id: speed
        Kirigami.FormData.label: i18n("Falling speed:")
        from: 1; to: 5; stepSize: 1; value: 3
    }
    QQC2.SpinBox {
        id: density
        Kirigami.FormData.label: i18n("Column density (%):")
        from: 15; to: 100; stepSize: 5; editable: true; value: 85
    }
    QQC2.SpinBox {
        id: trail
        Kirigami.FormData.label: i18n("Trail length (characters):")
        from: 4; to: 28; stepSize: 1; editable: true; value: 13
    }
    QQC2.CheckBox {
        id: highlights
        text: i18n("Brighten the front of each column")
        checked: true
    }
    QQC2.CheckBox {
        id: lowPower
        text: i18n("Low-power mode (recommended)")
        checked: true
    }
    QQC2.CheckBox {
        id: pauseHidden
        text: i18n("Pause when widget is hidden")
        checked: true
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Uses one Canvas and one timer; no Python, terminal emulator or background service. Click the widget to pause/resume.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
