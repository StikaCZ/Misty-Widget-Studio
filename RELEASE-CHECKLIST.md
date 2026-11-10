Historical v4.6.1 release checks only; not a test report for v4.6.4.

# Before publishing a GitHub release

- [x] All 17 source directories and metadata files included; `Misty ...` display names and stika CZ author.
- [x] Static scans for private keys, common API tokens, absolute personal home directories and unsafe file types.
- [x] Python source compilation, Bash syntax, JSON/XML/SVG parsing, image validation and ZIP integrity tests.
- [x] Simulated clean install, repeat update, and restore into a temporary home directory.
- [x] Install and dependency documentation in the same folder.
- [ ] **Still required:** Run on a clean KDE Plasma 6 system and inspect the QML output and functionality for every widget.
- [ ] **Still required:** Validate licences and originality of any artwork beyond the included originals before non-beta commercial release.
- [ ] **Still required:** Test OpenRGB, external monitor brightness and SSH configuration on real supported hardware.
- [ ] **Still required:** Review real-world GitHub secret-scanning alerts after first commit.

Publish as **v4.6.1-beta**, not as a security-certified/stable release until the unchecked steps are complete.
