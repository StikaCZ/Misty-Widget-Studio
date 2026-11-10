import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_trackColor: trackColorField.text
    property alias cfg_outlineColor: outlineColorField.text
    property alias cfg_glowColor: glowColorField.text
    property alias cfg_trackOpacity: trackOpacityControl.value
    property alias cfg_outlineOpacity: outlineOpacityControl.value
    property alias cfg_spriteOpacity: spriteOpacityControl.value
    property alias cfg_trackRadius: trackRadiusControl.value
    property alias cfg_petHeight: petHeightControl.value
    property alias cfg_showGlow: showGlowControl.checked
    property alias cfg_showShadow: showShadowControl.checked
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
            case "trackColor": page.cfg_trackColor = c; break
            case "outlineColor": page.cfg_outlineColor = c; break
            case "glowColor": page.cfg_glowColor = c; break
            }
        }
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Quick preset:")
        model: [i18n("Choose preset…"), i18n("Transparent (original)"), i18n("Charcoal glass"), i18n("Ice glow"), i18n("Forest glow"), i18n("Purple glow")]
        onActivated: function(index) {
            if (index < 1) return
            switch (index) {
            case 1:
                page.cfg_trackColor = "#101518"
                page.cfg_outlineColor = "#56646a"
                page.cfg_glowColor = "#7aafb8"
                page.cfg_trackOpacity = 0
                page.cfg_outlineOpacity = 0
                page.cfg_spriteOpacity = 100
                page.cfg_showGlow = false
                break
            case 2:
                page.cfg_trackColor = "#101518"
                page.cfg_outlineColor = "#4d5962"
                page.cfg_glowColor = "#9cb7cb"
                page.cfg_trackOpacity = 70
                page.cfg_outlineOpacity = 80
                page.cfg_spriteOpacity = 100
                page.cfg_showGlow = false
                break
            case 3:
                page.cfg_trackColor = "#11212c"
                page.cfg_outlineColor = "#5282a2"
                page.cfg_glowColor = "#69c9f2"
                page.cfg_trackOpacity = 58
                page.cfg_outlineOpacity = 70
                page.cfg_spriteOpacity = 100
                page.cfg_showGlow = true
                break
            case 4:
                page.cfg_trackColor = "#15231c"
                page.cfg_outlineColor = "#4c755d"
                page.cfg_glowColor = "#8fd5a1"
                page.cfg_trackOpacity = 66
                page.cfg_outlineOpacity = 76
                page.cfg_spriteOpacity = 100
                page.cfg_showGlow = true
                break
            case 5:
                page.cfg_trackColor = "#1b1328"
                page.cfg_outlineColor = "#82659e"
                page.cfg_glowColor = "#c9a3ff"
                page.cfg_trackOpacity = 68
                page.cfg_outlineOpacity = 70
                page.cfg_spriteOpacity = 100
                page.cfg_showGlow = true
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
        Kirigami.FormData.label: i18n("Walking area:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("trackColor", trackColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: trackColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: trackColorField
            Layout.preferredWidth: 120
            placeholderText: "#101518"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Border:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("outlineColor", outlineColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: outlineColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: outlineColorField
            Layout.preferredWidth: 120
            placeholderText: "#56646a"
            maximumLength: 9
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Glow highlight:")
        QQC2.Button {
            width: 34; implicitWidth: 38; implicitHeight: 28
            onClicked: page.openPicker("glowColor", glowColorField.text)
            contentItem: Rectangle {
                radius: 5
                color: glowColorField.text
                border.color: "#8799a4"
                border.width: 1
            }
        }
        QQC2.TextField {
            id: glowColorField
            Layout.preferredWidth: 120
            placeholderText: "#7aafb8"
            maximumLength: 9
        }
    }
    QQC2.SpinBox {
        id: trackOpacityControl
        Kirigami.FormData.label: i18n("Walking area opacity %:")
        from: 0
        to: 100
        stepSize: 5
        editable: true
    }
    QQC2.SpinBox {
        id: outlineOpacityControl
        Kirigami.FormData.label: i18n("Border opacity %:")
        from: 0
        to: 100
        stepSize: 5
        editable: true
    }
    QQC2.SpinBox {
        id: spriteOpacityControl
        Kirigami.FormData.label: i18n("Pet opacity %:")
        from: 10
        to: 100
        stepSize: 5
        editable: true
    }
    QQC2.SpinBox {
        id: trackRadiusControl
        Kirigami.FormData.label: i18n("Corner roundness px:")
        from: 0
        to: 32
        stepSize: 2
        editable: true
    }
    QQC2.SpinBox {
        id: petHeightControl
        Kirigami.FormData.label: i18n("Pet area height px:")
        from: 32
        to: 110
        stepSize: 2
        editable: true
    }
    QQC2.CheckBox {
        id: showGlowControl
        text: i18n("Show subtle coloured glow")
    }
    QQC2.CheckBox {
        id: showShadowControl
        text: i18n("Show tiny ground shadow")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Changes are saved by Apply. Each widget can use different colours and sizing.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
