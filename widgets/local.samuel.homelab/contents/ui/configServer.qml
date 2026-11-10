import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import "ServerBridge.js" as Server

Kirigami.FormLayout {
    id: page
    property alias cfg_serverHost: hostField.text
    property alias cfg_serverUser: userField.text
    property alias cfg_serverPort: portField.value
    property alias cfg_serverKeyPath: keyField.text
    property alias cfg_serverService: unitField.text
    property alias cfg_serverPollSeconds: refreshField.value
    property alias cfg_serverEnabled: enabledField.checked
    property bool testing: false
    property string testMessage: i18n("Not tested yet. Enter the details and select Test connection.")
    property bool testPassed: false

    function testConnection() {
        if (testing) return
        testing = true
        testPassed = false
        testMessage = i18n("Checking SSH connection…")
        testSource.connectSource(Server.sshCommand(
            page.cfg_serverHost, page.cfg_serverUser, page.cfg_serverPort,
            page.cfg_serverKeyPath, page.cfg_serverService, true))
    }

    QQC2.CheckBox {
        id: enabledField
        Kirigami.FormData.label: i18n("Monitoring:")
        text: i18n("Enable Debian server monitoring")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("1 · Your Debian server")
    }
    QQC2.Label {
        text: i18n("Enter the hostname or LAN IP and the SSH login you normally use. No passwords are stored.")
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    QQC2.TextField {
        id: hostField
        Kirigami.FormData.label: i18n("Server address:")
        Layout.fillWidth: true
        placeholderText: i18n("debian or 192.168.1.50")
    }
    QQC2.TextField {
        id: userField
        Kirigami.FormData.label: i18n("SSH username:")
        Layout.fillWidth: true
        placeholderText: i18n("Leave empty to use your Linux username")
    }
    QQC2.SpinBox {
        id: portField
        Kirigami.FormData.label: i18n("SSH port:")
        from: 1
        to: 65535
        editable: true
    }
    QQC2.TextField {
        id: keyField
        Kirigami.FormData.label: i18n("SSH private key (optional):")
        Layout.fillWidth: true
        placeholderText: i18n("Leave empty for the SSH agent / default key")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("2 · Set up secure SSH (once)")
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("On Debian, install and start SSH. Run these commands directly on Debian:")
    }
    QQC2.TextField {
        Kirigami.FormData.label: i18n("Debian Konsole:")
        Layout.fillWidth: true
        readOnly: true
        selectByMouse: true
        text: "sudo apt install openssh-server && sudo systemctl enable --now ssh"
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.text: i18n("Select and copy this command")
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("On your CachyOS PC, run the commands below. The first SSH login lets you verify and trust Debian's host fingerprint. When asked, enter the server password in Konsole, not here. Then copy your public key so monitoring works without prompts.")
    }
    QQC2.TextField {
        Kirigami.FormData.label: i18n("First login:")
        Layout.fillWidth: true
        readOnly: true
        selectByMouse: true
        text: Server.sshTarget(hostField.text, userField.text, portField.value)
    }
    QQC2.TextField {
        Kirigami.FormData.label: i18n("Create a key (if needed):")
        Layout.fillWidth: true
        readOnly: true
        selectByMouse: true
        text: "ssh-keygen -t ed25519"
    }
    QQC2.TextField {
        Kirigami.FormData.label: i18n("Authorise your key:")
        Layout.fillWidth: true
        readOnly: true
        selectByMouse: true
        text: Server.copyIdCommand(hostField.text, userField.text, portField.value)
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Tip: use ssh-copy-id after you've verified the first connection. If you use a passphrase-protected key, unlock it in your desktop SSH agent first. These instructions never disable SSH host-key verification.")
    }
    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: i18n("3 · Test and save")
    }
    QQC2.Button {
        text: page.testing ? i18n("Testing…") : i18n("Test connection")
        icon.name: "network-connect"
        enabled: !page.testing && hostField.text.trim().length > 0
        onClicked: page.testConnection()
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: page.testMessage
        color: page.testPassed ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("If the test says ONLINE, click Apply to save. The widget then refreshes itself; there is no separate Conky script to install.")
    }
    QQC2.TextField {
        id: unitField
        Kirigami.FormData.label: i18n("Terraria service (optional):")
        Layout.fillWidth: true
        placeholderText: "tmodloader.service"
    }
    QQC2.SpinBox {
        id: refreshField
        Kirigami.FormData.label: i18n("Refresh every (seconds):")
        from: 15
        to: 300
        stepSize: 15
        editable: true
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("CPU temperature and fan speed only appear when Debian exposes those sensors. Missing sensors show --, not invented readings.")
    }

    P5Support.DataSource {
        id: testSource
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            const raw = String(data["stdout"] || "")
            const status = /^STATUS\s{2,}ONLINE$/m.test(raw)
            const detail = raw.match(/^DETAIL\s{2,}(.+)$/m)
            page.testPassed = status
            page.testMessage = (status ? "✓ ONLINE — " : "○ OFFLINE — ") +
                (detail ? detail[1] : i18n("No response. Verify the address, key, and SSH setup."))
            page.testing = false
            disconnectSource(sourceName)
        }
    }
}
