# Misty Widget Studio — Complete KDE Plasma 6 Collection

**17 custom widgets for Linux desktop panels and desktops.** Built and maintained by **stika CZ**.

> **Release candidate / public beta v4.6.9 (10 November 2026).** The source has been checked for common secrets and tested with simulated fresh installs and restores. It has **not** been tested end-to-end on a clean physical KDE Plasma 6 installation; this is not a claim that all 17 widgets are bug-free.

## The widgets

| Widget in KDE | Function |
| --- | --- |
| Misty ASCII Aquarium | Terminal-style animated aquarium |
| Misty Brightness Slate | Laptop/internal-screen backlight control (external DDC monitors vary) |
| Misty Forest Clock | Seven clock styles, custom font and time formatting |
| Misty Homelab | Read-only Linux server monitoring over opt-in SSH |
| Misty Launch Slate | Quick application shortcuts |
| Misty Living Moon | Desktop moon visualisation |
| Misty Network Radar | Linux connection and interface readout |
| Misty Notes Slate | Locally stored desktop notes |
| Misty Living Desktop Pets | Tux (penguin), gecko and slime animations, with Terminal option |
| Misty Pink Code Rain | Falling terminal-style characters |
| Misty RGB Control | OpenRGB interface (requires a **personal, external helper script**) |
| Misty Storage Vault | Root filesystem disk-usage display |
| Misty System Pulse | CPU, memory and optional NVIDIA GPU telemetry |
| Misty Terraria Ice Watch | Terraria-style server status with **optional SSH setup** |
| Misty Update Plant | **Original green leafy plant only**, with read-only pending update count |
| Misty Weather Orbit | Weather forecast and vector planet art via Open-Meteo |
| Misty CD Player | Customisable spinning CD; optional `playerctl` transport controls |

## Install or update (KDE Plasma 6)

1. Download the ZIP and **extract it**. You should see this README and `install.sh` inside **one folder**.
2. Open Konsole in the extracted folder and run:

   ```bash
   bash install.sh
   systemctl --user restart plasma-plasmashell.service
   ```

3. Open **Add Widgets** in KDE and search for **Misty**. All 17 should be available.

**Do not run `install.sh` with sudo.** The installer works for the current user only and automatically makes a dated backup of replaced widget directories. Configuration defaults are merged without overwriting your personal saved values.

### Revert the most recent installation

```bash
bash restore.sh
systemctl --user restart plasma-plasmashell.service
```

Restore reverts all 17 widgets to their previous folder contents; for a fresh install it removes those 17 newly installed widget folders. It does not erase your personal Plasma desktop arrangement or unrelated widgets. Make sure you use the restore script immediately after the update you want to undo.

## Appearance and settings

- Right-click a widget → **Configure**.
- Four appearances where available: Normal, Liquid Glass-inspired, Terminal and Minimal.
- **19 colour presets** with six custom colour roles; Olive Green uses a shared palette across the collection (specialised raster art may retain its colours).
- The **Background opacity** slider fades panels, **not** foreground text and icons.
- The original green leafy plant is the **only** plant; clicking it does not change species. The original SVG art is bundled for fresh installations.
- Clock has Classic, 24-hour, 12-hour, Seconds, Flip, Analogue and Binary faces, plus fonts.
- CD has centre label, spindle hole, material, ring count, colours, spin and optional playback buttons.

## Requirements and limitations

- KDE **Plasma 6** and Qt 6, with Plasma 5 Support (`plasma5support`) where your distribution packages it; **Linux only**.
- Python 3 and Bash for included helper scripts. Optional: `playerctl`, `nvidia-smi`, `brightnessctl`, `checkupdates` from `pacman-contrib`, and `openssh` for remote server monitoring.
- Weather: after adding the widget, its configured **city name is sent over HTTPS to Open-Meteo** during refresh. No API key or user account is needed. Cached forecasts are stored under your XDG cache directory.
- Some features are system-specific: **RGB Control requires your own OpenRGB helper** (not included), external monitor brightness requires additional setup, and Terraria/Homelab need server details and an authorised SSH key. See [DEPENDENCIES.md](DEPENDENCIES.md).
- The **separate Bix Player** is not included. Misty CD Player is an original widget in this pack.

## Security and redistribution

- Read the current [AUDIT-REPORT.md](AUDIT-REPORT.md), [SECURITY.md](SECURITY.md), and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- No passwords, private keys or tokens were detected in the release files by pattern scanning. **Static checks cannot guarantee perfect safety.** Review source before installing.
- The historic IDs `local.samuel.*` remain for compatibility and are **visible to anyone on GitHub**. This is an identifier, **not** a password, but it does contain the old username string.
- Source in this pack is provided under MIT; any third-party logos, game/OS brands or characters retain their original owners' rights.

## Share with friends / publish on GitHub

Upload **the contents of this extracted folder** to your repository (not a nested ZIP). The README will then appear on the repository home page.

```bash
# Run these inside this folder after creating an empty GitHub repository:
git init -b main
git add .
git commit -m "Release Misty Widget Studio v4.6.5 beta"
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/misty-widget-studio.git
git push -u origin main
```

For existing repositories, copy the folder contents into your existing clone, then `git add`, `git commit`, `git push`. Your friends can use **Code → Download ZIP**, extract, and run `bash install.sh`. Publish as a **beta** while you collect Plasma compatibility feedback.

Copyright © 2026 **stika CZ**. See [LICENSE](LICENSE).
