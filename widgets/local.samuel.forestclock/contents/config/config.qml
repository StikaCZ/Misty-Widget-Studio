import QtQuick
import org.kde.plasma.configuration
ConfigModel {
    ConfigCategory {
        name: i18n("Style & layout")
        icon: "preferences-desktop-theme"
        source: "configStyle.qml"
    }
    ConfigCategory { name: i18n("Clock face & font"); icon: "preferences-desktop-font"; source: "configClock.qml" }
    ConfigCategory { name: i18n("Theme colours"); icon: "color-management"; source: "configThemeColours.qml" }
}
