import QtQuick
import org.kde.plasma.configuration
ConfigModel {
    ConfigCategory { name: i18n("Appearance & colour"); icon: "color-management"; source: "configAppearance.qml" }
    ConfigCategory { name: i18n("Animation"); icon: "media-playback-start"; source: "configAnimation.qml" }
    ConfigCategory { name: i18n("Style & layout"); icon: "preferences-desktop-theme"; source: "configStyle.qml" }
    ConfigCategory { name: i18n("Theme colours"); icon: "color-management"; source: "configThemeColours.qml" }
}
