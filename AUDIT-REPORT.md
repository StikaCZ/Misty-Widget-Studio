Historical v4.6.1 release checks only; not a test report for v4.6.4.

# Release security & compatibility audit — 10 November 2026

**Release:** Misty Widget Studio v4.6.1-beta  
**Author metadata:** `stika CZ` on all **17** widgets.  
**Scope:** the release **folder only**, not your private desktop settings, external RGB helper, SSH configuration, or installed original artwork.

## Results

| Test | Result |
| --- | --- |
| 17 widget folders, IDs, `Misty ...` names and author metadata | **PASS** |
| Metadata JSON and 17 KConfig XML files | **PASS** |
| 132 QML files checked for duplicate `id` declarations | **PASS** |
| 10 Python scripts compiled and 5 Bash scripts syntax-checked | **PASS** |
| 238 PNG image files validated and checked for embedded metadata | **PASS** (none contained metadata) |
| 11 SVG graphics parsed as XML | **PASS** |
| Scan for common API keys, GitHub/AWS/OpenAI/Slack tokens, PEM private keys, password assignments, personal absolute home paths | **NO MATCHES DETECTED** |
| No source symlinks and no `.env`, `.ssh`, key or credentials files | **PASS** |
| Sample helper outputs and launcher action allowlist | **PASS** |
| Install into temporary empty user home and restore | **PASS** |
| Upgrade over existing 17 widget directories and restore their previous files | **PASS** |
| Full GUI rendering and functionality on real KDE Plasma 6 | **NOT TESTED** |
| External RGB hardware, remote SSH server, external monitor brightness, Open-Meteo live network | **NOT TESTED** |

**33/33 automated static/isolated checks passed.** No claim is made that this guarantees the widgets are free of security issues or runtime bugs.

## Privacy considerations found

- **Historical public IDs:** Sixteen widgets retain `local.samuel.*` directory/plugin IDs for compatibility. This string is visible in any public GitHub repository and may disclose an old username. It is **not a credential**. Changing IDs later requires desktop layout migration.
- **Weather:** The optional Open-Meteo widget transmits the configured city name to `geocoding-api.open-meteo.com` and `api.open-meteo.com` over HTTPS; it uses an XDG-cache directory. No API key is used.
- **Linux update count:** `checkupdates` may query the OS's configured package mirrors; it does **not** install updates.
- **Homelab/Terraria:** The SSH helper connects **only** to an explicitly configured host and requires an authorised key and verified known-host fingerprint. Key contents and passwords are not shipped.
- **CD:** Uses local `playerctl` commands, not Spotify/other API keys.
- **Launcher:** The Browser shortcut opens a website only on explicit click.
- **RGB:** The external hardware-specific `rgbctl.py` was absent from exports and is **not bundled**. It can be added separately after reviewing it.
- **No secret files:** Neither an `.env` nor any SSH private key, known-host database, browser profile, personal desktop configuration, or local `.config` folder was included in the release.

## Safety limitations and release recommendation

- The installer is user-local and creates backups; however **installing any QML package runs locally executable code**, including helper scripts if configured, so recipients should inspect the source and run it only if they trust it.
- Legacy imported widget source and artwork origins cannot be independently authenticated by a static scan. Source code is labelled MIT, but trademarked third-party characters and brands retain their rights; see `THIRD_PARTY_NOTICES.md`.
- **Known incomplete features:** RGB hardware control requires an external script. External HDMI/DP brightness, server player counts, and optional original flower SVG art vary by computer. The package now includes lightweight scripts for the other previously missing general-purpose helpers.
- Because real-world Plasma and hardware tests remain incomplete, **publish as a beta/release candidate (`v4.6.1-beta`)**, not as a security-certified stable release.
