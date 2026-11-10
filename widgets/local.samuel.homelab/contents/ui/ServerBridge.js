.pragma library

function safeToken(value) {
    // Pure ASCII shell token: do not directly interpolate settings into a shell.
    const encoded = encodeURIComponent(String(value === undefined || value === null ? "" : value))
        .replace(/[!'()*]/g, function(c) { return "%" + c.charCodeAt(0).toString(16).toUpperCase(); });
    // Empty options still need a shell-safe argument; Python strips %20 to blank.
    return encoded.length ? encoded : "%20";
}

function sshCommand(host, user, port, keyFile, unit, testOnly) {
    const script = '/usr/bin/python3 "$HOME/.local/share/plasma/plasmoids/local.samuel.homelab/contents/scripts/homelab_stats.py"';
    const mode = testOnly ? " --test" : "";
    return script +
        " --host " + safeToken(host || "debian") +
        " --user " + safeToken(user || "") +
        " --port " + safeToken(port || 22) +
        " --identity " + safeToken(keyFile || "") +
        " --unit " + safeToken(unit || "") + mode;
}

function sshTarget(host, user, port) {
    const h = String(host || "debian").trim();
    const u = String(user || "").trim();
    const p = parseInt(port, 10) || 22;
    const target = (u ? u + "@" : "") + h;
    return "ssh " + (p === 22 ? "" : "-p " + p + " ") + target;
}

function copyIdCommand(host, user, port) {
    const h = String(host || "debian").trim();
    const u = String(user || "").trim();
    const p = parseInt(port, 10) || 22;
    return "ssh-copy-id " + (p === 22 ? "" : "-p " + p + " ") + (u ? u + "@" : "") + h;
}
