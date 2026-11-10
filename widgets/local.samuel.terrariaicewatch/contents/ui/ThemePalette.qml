import QtQuick
import org.kde.plasma.plasmoid

// Misty 4.6.4: one literal panel RGBA contract for all widgets.
// Inner decorative surfaces and graphics are deliberately *not* panel fills.
Item {
    id: palette
    visible: false
    width: 0
    height: 0
    readonly property real backgroundOpacityFactor: Math.max(0, Math.min(1, Number(Plasmoid.configuration.widgetOpacity ?? 100) / 100))
    readonly property bool custom: Plasmoid.configuration.studioUseColours === true
    readonly property color textColour: Plasmoid.configuration.studioThemeText || "#E8F0EC"
    readonly property color mutedColour: Plasmoid.configuration.studioThemeMuted || "#A7B3AD"
    readonly property color accentColour: Plasmoid.configuration.studioThemeAccent || "#93BFA7"
    readonly property color surfaceColour: Plasmoid.configuration.studioThemeSurface || "#1A2429"
    readonly property color edgeColour: Plasmoid.configuration.studioThemeBorder || "#6B8285"
    readonly property color secondaryColour: Plasmoid.configuration.studioThemeSecondary || "#92A9D7"

    function alphaOf(original) {
        if (original === undefined || original === null) return 1
        if (typeof original === "object" && original.a !== undefined) return original.a
        const s = String(original)
        if (s === "transparent") return 0
        if (/^#[0-9a-fA-F]{8}$/.test(s)) return parseInt(s.slice(1,3),16)/255
        if (/^#[0-9a-fA-F]{4}$/.test(s)) return parseInt(s.charAt(1),16)/15
        return 1
    }
    function targetFor(role) {
        if (role === "surface") return surfaceColour
        if (role === "border") return edgeColour
        if (role === "muted") return mutedColour
        if (role === "secondary") return secondaryColour
        if (role === "accent") return accentColour
        return textColour
    }
    // Decor remains independently readable (e.g. the weather planet's nighttime
    // shadow and system metric tiles). Never turn those into opaque panels.
    function paint(original, role) {
        if (role === "surface") return original
        const a = alphaOf(original)
        if (!custom || a <= 0.008) return original
        const tint = targetFor(role)
        return Qt.rgba(tint.r, tint.g, tint.b, Math.max(0,Math.min(1,a*tint.a)))
    }
    // ONLY outer visual backdrop. No inherited/legacy alpha, no second tint.
    // Its opacity is independent of text, icons, sprites and other children.
    function panel(original) {
        const oldAlpha = alphaOf(original)
        if (oldAlpha <= 0.008) return original // intentional glass/transparent frame
        const selected = custom ? surfaceColour : Qt.lighter(original, 1.0)
        const alpha = (custom ? surfaceColour.a : oldAlpha) * backgroundOpacityFactor
        return Qt.rgba(selected.r, selected.g, selected.b, Math.max(0,Math.min(1,alpha)))
    }
    function outline(original) {
        if (!custom) return original
        const tint = edgeColour
        return Qt.rgba(tint.r,tint.g,tint.b,tint.a)
    }
}
