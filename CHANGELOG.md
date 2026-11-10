## v4.6.8 — System / Pulse original CPU and GPU illustrations restored (2026-11-10)
- Bundle the three original PNG assets referenced by OriginalView.qml: CPU chip, GPU body and GPU fan.
- Prevent missing-image placeholders after installation; preserve GPU fan animation.
- No change to the other 16 widget folders, existing configurations, or System / Pulse QML scripts.

## v4.6.6 — Plant, Updates & Brightness reliability
- Fix original plant update polling path and add update-check fallback.
- Use KDE per-display brightness D-Bus instead of sysfs-only external-monitor detection.
- Keep all other widgets, existing original plant art and removed eyeball unchanged.

## v4.6.5 — Original plant restored, removed pet fully excluded (2026-11-10)
- Restored all 14 original green leafy plant/pot SVGs from the earlier Update Plant easy-resize package; no changes to plant runtime code or animations.
- Removed the outdated Terminal Pet preview that still pictured the Eye pet. The pet selector, runtime fallback, terminal art and shipped sprites include only penguin, gecko and slime.
- Left all other 17 widget runtime files unchanged from v4.6.4, including Weather / Planet and background styling.

## v4.6.4 — Direct background panel binding / weather restoration

# Changelog

## v4.6.1 — GitHub and friends beta release (2026-11-10)
- All **17 widgets** in one folder, with author metadata set to **stika CZ** and display names prefixed **Misty**.
- Consolidated documentation, installation, security report and known limitations.
- Bundled previously missing local helpers for Storage Vault, System Pulse, Launch Slate, laptop backlight control, Weather Orbit and optional Terraria read-only SSH integration.
- Added original SVG planet, cloud and lightning icons for Weather Orbit.
- Preserved the existing 17-widget update/backup/restore installer. No automatic installation of dependencies.
- RGB helper remains intentionally absent, as it depends on user hardware and was not in the export.

## v4.6 — Widget name cleanup
- Display names unified as `Misty ...` (internal IDs unchanged for compatibility).

## v4.5 — Terminal pet polish
- Four Terminal pets, consistent text grid and pupils in artwork, 208 action frames.

## v4.4 — Pet refinement
- Pixel eyeball animations redrawn and Terminal pupils repaired.

## v4.3 — Original flower only
- Other species and click-to-cycle options removed; single original SVG flower (fallback for fresh installs).

## v4.2 — Shared colours, CD and Wi-Fi repair
- Unified 19-preset palettes, updated CD visualisation, Network Radar local helper and style correction.

## v4.1 — Background-only opacity
- Opacity now affects surfaces rather than text or icons.

## v4.0 — Clock + CD
- Seven clock faces, custom fonts, and a separate configurable CD player.

- Replaced machine-specific CPU/GPU model labels in System Pulse with generic labels and added text fallbacks when optional hardware illustrations are missing.
