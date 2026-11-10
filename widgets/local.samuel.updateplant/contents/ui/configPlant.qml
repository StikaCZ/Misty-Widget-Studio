import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_illustratedSize: plantSize.value

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("Original plant")
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("The original green plant is now the only plant. Its appearance changes with the number of pending updates; clicking it no longer changes the species.")
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Flower size:")
        Layout.fillWidth: true
        QQC2.Slider {
            id: plantSize
            from: 65
            to: 150
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
            Layout.fillWidth: true
        }
        QQC2.Label {
            text: Math.round(plantSize.value) + "%"
            Layout.preferredWidth: 44
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("The widget uses your installed original SVG art if available. On a fresh install, a simple bundled flower is displayed instead. Middle-click the plant to refresh pending updates.")
    }
}
