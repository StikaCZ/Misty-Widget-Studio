# Dependencies & setup (v4.6.1)

## Working without user-specific credentials

| Widget | Required / optional items | Status on other computers |
| --- | --- | --- |
| Storage Vault | Python 3, Linux | Bundled `diskstats.py`; reads `/` without privileged access |
| System Pulse | Python 3, Linux `/proc`; optional `nvidia-smi` | Bundled `metrics.py`; unsupported GPU sensors display `--` |
| Network Radar | Python 3, Linux; optional `nmcli` | Bundled local-only `netstats.py` |
| Update Plant | Bash, pacman/checkupdates | Bundled helper; non-Arch distros may show unavailable |
| Weather Orbit | Internet + Open-Meteo endpoints | Bundled HTTPS script and simple original SVG planet/cloud/bolt; sends city only |
| Launch Slate | common Linux GUI apps / `xdg-open` | Bundled allowlisted launcher |
| Brightness Slate | sysfs backlight + optional `brightnessctl` | Bundled; **internal laptop backlights only**. External HDMI/DP monitors may not appear |
| CD Player | optional `playerctl` + MPRIS player | Bundled; display still works without transport controls |
| Homelab | optional SSH client, host, username, verified known-host key | Bundled SSH helper and configuration instructions inside the widget |
| Terraria Ice Watch | optional SSH to user's server | Bundled read-only helper; default shows setup required until locally configured |
| RGB Control | external OpenRGB SDK and custom `rgbctl.py` | **Not fully portable**. Hardware-specific helper deliberately not included; preserve the one already installed on your own PC |

## RGB Control

This widget expects `contents/scripts/rgbctl.py` and an OpenRGB SDK server or equivalent local helper. That file was absent from the exported source, so a public **fake driver is not shipped** and the widget will be offline until a compatible custom helper is supplied. Do not publish private OpenRGB device paths or passwords.

## Terraria Ice Watch

Create a local file on each PC (do **not** put this file into GitHub):

`~/.config/misty-widget-studio/terraria.json`

```json
{
  "host": "YOUR_DEBIAN_HOSTNAME_OR_IP",
  "user": "YOUR_SSH_USERNAME",
  "port": 22,
  "identity": "",
  "unit": "tmodloader.service"
}
```

The `identity` may be left blank to use a configured SSH agent. Connect manually once using `ssh USER@HOST` to inspect and accept the host key, then configure a public key if necessary. SSH never auto-accepts changed or unknown host keys. The Terraria widget reports **service state and host uptime**, but cannot reliably show a Terraria player count or current world without a server-specific helper; those fields remain blank.

## Homelab

Configure the Debian host and SSH user in the widget's **Debian connection** tab and use **Test connection**. It uses known-host checks and never stores a private key's contents or a password.

## Optional CachyOS packages

```bash
sudo pacman -S python openssh playerctl brightnessctl pacman-contrib
```

Install only the packages you need; this is an optional manual command, **not executed by the installer**.

**System Pulse classic artwork:** The former exported package did not include three optional hardware illustration PNG files. This release shows generic CPU/GPU text instead of blank cards on fresh installs. Existing local images remain available on PCs that already have them.
