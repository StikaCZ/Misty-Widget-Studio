import QtQuick
import org.kde.plasma.configuration
ConfigModel {
    ConfigCategory { name: i18n("Settings"); icon: "configure"; source: "configGeneral.qml" }
    ConfigCategory { name: i18n("Style & layout"); icon: "preferences-desktop-theme"; source: "configStyle.qml" }
    ConfigCategory { name: i18n("Theme colours"); icon: "color-management"; source: "configThemeColours.qml" }
}
