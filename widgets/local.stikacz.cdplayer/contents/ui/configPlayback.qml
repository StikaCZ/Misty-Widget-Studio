import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: page
    QQC2.Label { Kirigami.FormData.isSection:true; text:i18n("Connect your music player") }
    QQC2.Label {
        Layout.fillWidth: true; wrapMode:Text.WordWrap
        text:i18n("The CD reads the currently playing track from MPRIS (supported by Spotify, Elisa, VLC, Firefox and many Linux music players). It uses the local playerctl tool and does not use an API key.")
    }
    QQC2.Label { Layout.fillWidth:true;wrapMode:Text.WordWrap; text:i18n("1. Open Konsole and install the optional dependency:
    sudo pacman -S playerctl") }
    QQC2.Label { Layout.fillWidth:true;wrapMode:Text.WordWrap; text:i18n("2. Play a track in a supported music app.
3. The CD shows the title and controls automatically.
4. Music playback is handled by your music app, not by this widget.") }
    QQC2.Label { Kirigami.FormData.isSection:true;text:i18n("Troubleshooting") }
    QQC2.Label { Layout.fillWidth:true;wrapMode:Text.WordWrap; text:i18n("Run playerctl status in Konsole. If it says No players found, start a supported media player and play something.") }
    QQC2.Label { Layout.fillWidth:true;wrapMode:Text.WordWrap; text:i18n("The disc only spins when playback is active. You can customise its centre and materials even when no music is playing.") }
}
