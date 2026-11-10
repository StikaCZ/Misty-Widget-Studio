import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    property alias cfg_city: cityField.text
    property alias cfg_transparent: transparentCheck.checked
    property alias cfg_animated: animatedCheck.checked

    QQC2.Label {
        text: "Weather location (town or city)"
    }
    QQC2.TextField {
        id: cityField
        Layout.fillWidth: true
        placeholderText: "Rickmansworth"
    }
    QQC2.CheckBox {
        id: transparentCheck
        text: "Transparent background (text and rings only)"
    }
    QQC2.CheckBox {
        id: animatedCheck
        text: "Slowly rotating orbit marker"
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Weather is supplied by Open-Meteo. Updates every 10 minutes while connected. Click the LIVE / OFFLINE label to refresh manually."
        opacity: 0.75
    }
    Item { Layout.fillHeight: true }
}
