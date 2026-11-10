import QtQuick
import org.kde.plasma.configuration
ConfigModel {
    ConfigCategory { name: i18n("CD look & inside"); icon: "media-optical"; source: "configDisc.qml" }
    ConfigCategory { name: i18n("Playback help"); icon: "help-about"; source: "configPlayback.qml" }
    ConfigCategory { name: i18n("Theme colours"); icon: "color-management"; source: "configThemeColours.qml" }
}
