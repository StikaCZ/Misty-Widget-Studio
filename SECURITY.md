# Security and privacy

## Publishing and installation

- No root permission is requested by `install.sh`; it writes to `$HOME/.local/share/plasma/plasmoids` and `$HOME/.local/state/stikacz-misty-collection` only.
- No installer downloads, contacts a cloud service, reads browser secrets, copies SSH keys, or invokes `sudo`.
- Each update makes a timestamped backup before replacing widget files. Use `restore.sh` promptly if needed.
- **Do not publish** your `~/.config/plasma-org.kde.plasma.desktop-appletsrc`, server credentials, local machine configuration, SSH key material, `.env` files, token files, or logs.
- Old `local.samuel.*` IDs are visible in the release source. They are retained for compatibility; they can reveal a historical name despite no credentials being present.

## Runtime access and data

- **Weather Orbit** sends the configured city name to Open-Meteo over HTTPS and caches the result in the local XDG cache directory. Do not use it if you prefer not to make this external request.
- **Update Plant** runs `checkupdates` or `pacman -Qu`, which may reach configured package mirrors; no system updates are installed.
- **Homelab and Terraria** contact the **server you explicitly configure** using standard SSH; strict host-key verification and public-key authentication are used. Hostnames, usernames and optional key **paths** are local settings, never bundled in the public pack.
- **CD Player** interacts with locally installed `playerctl`/MPRIS. **RGB Control** needs an external hardware helper; not included here.
- **Launch Slate** opens an external website only if the Browser shortcut is clicked. Other shortcuts start local applications.
- Most other widgets are offline-only, reading local files, operating-system interfaces or stored widget settings.

## Limits

This is a **static code and asset audit plus simulated install tests**, not a penetration test or a real Plasma 6 device test. No safety review can guarantee absence of defects or vulnerabilities. Treat this as a **beta** until tested on several clean desktops.

For security reports: open an issue on the project's GitHub repository without posting private credentials. Remove or rotate any accidentally published keys immediately.
