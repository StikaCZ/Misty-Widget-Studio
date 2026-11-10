import QtQuick
import org.kde.plasma.plasmoid

// Silver glass for Plasma 6. Based on a soft, etched / beveled silver-blue material.
// This does not sample or blur the desktop wallpaper; translucency is real,
// background refraction is not possible with pure QtQuick widget content.
Item {
    ThemePalette { id: studioPalette }

    id: glass
    // This item contains only the panel glass, not the widget content.
    opacity: studioPalette.custom ? 1 : studioPalette.backgroundOpacityFactor
    property color tintColor: studioPalette.paint("#899EBB", "accent")
    property int alphaPercent: 72
    property int blurStrength: 45
    property int radiusSize: 20
    property color baseColor: studioPalette.paint("#2A364E", "surface")
    // Incoming tint and base may be set by a parent view. Apply the shared
    // palette here too so the gradient itself changes, not merely its rim.
    readonly property color themeGlassTint: studioPalette.paint(tintColor, "accent")
    readonly property color themeGlassBase: studioPalette.paint(baseColor, "surface")
    function mixedSurface(t, alpha) {
        const base = studioPalette.custom ? studioPalette.surfaceColour : glass.themeGlassBase
        const tint = studioPalette.custom ? studioPalette.accentColour : glass.themeGlassTint
        const k = Math.max(0, Math.min(1, t))
        return Qt.rgba(base.r*(1-k)+tint.r*k,
                       base.g*(1-k)+tint.g*k,
                       base.b*(1-k)+tint.b*k, alpha)
    }
    readonly property real softness: Math.max(0, Math.min(1, blurStrength / 100.0))
    readonly property real a: Math.max(0.08, Math.min(0.96, alphaPercent / 100.0))
    readonly property real curve: Math.max(3, Math.min(radiusSize, Math.min(width, height) / 2 - 2))
    clip: true

    // One exact custom panel, with no secondary gradient or alpha pass.
    Rectangle {
        anchors.fill: parent
        radius: glass.curve
        color: studioPalette.panel(studioPalette.surfaceColour)
        border.width: 1
        border.color: studioPalette.outline("#88909090")
        visible: studioPalette.custom
    }

    // Main translucent body. The shadow and bevel remain inside the widget bounds.
    Rectangle {
        visible: !studioPalette.custom
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(2, glass.curve - 1)
        antialiasing: true
        gradient: Gradient {
            GradientStop {
                position: 0.00
                color: studioPalette.custom ? glass.mixedSurface(0.46,glass.a*0.79) : Qt.rgba(0.49 + glass.themeGlassTint.r * 0.13,
                               0.54 + glass.themeGlassTint.g * 0.15,
                               0.63 + glass.themeGlassTint.b * 0.13, glass.a * 0.79)
            }
            GradientStop {
                position: 0.22
                color: studioPalette.custom ? glass.mixedSurface(0.24,glass.a*0.76) : Qt.rgba(0.32 + glass.themeGlassTint.r * 0.14,
                               0.38 + glass.themeGlassTint.g * 0.14,
                               0.49 + glass.themeGlassTint.b * 0.14, glass.a * 0.76)
            }
            GradientStop {
                position: 0.75
                color: studioPalette.custom ? glass.mixedSurface(0.12,glass.a*0.78) : Qt.rgba(0.22 + glass.themeGlassTint.r * 0.14,
                               0.28 + glass.themeGlassTint.g * 0.14,
                               0.39 + glass.themeGlassTint.b * 0.14, glass.a * 0.78)
            }
            GradientStop {
                position: 1.00
                color: studioPalette.custom ? glass.mixedSurface(0.24,glass.a*0.83) : Qt.rgba(0.33 + glass.themeGlassTint.r * 0.14,
                               0.40 + glass.themeGlassTint.g * 0.14,
                               0.53 + glass.themeGlassTint.b * 0.14, glass.a * 0.83)
            }
        }
        border.width: 1
        border.color: studioPalette.custom ? studioPalette.paint(Qt.rgba(.79,.88,.97,.68), "border") : Qt.rgba(0.79, 0.88, 0.97, 0.68)
    }

    // Subtle broad luster, not a hard horizontal glass 'header'.
    Rectangle {
        visible: !studioPalette.custom
        x: 4
        y: 4
        width: Math.max(0, parent.width - 8)
        height: Math.max(0, Math.min(parent.height * 0.32, 90))
        radius: Math.max(2, glass.curve - 3)
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.00; color: studioPalette.paint("#28F4F8FF", "text") }
            GradientStop { position: 0.35; color: studioPalette.paint("#12D4E5FF", "accent") }
            GradientStop { position: 1.00; color: studioPalette.paint("#00D4E5FF", "accent") }
        }
        opacity: 0.55 + glass.softness * 0.30
    }

    // Adjustable milky diffusion: softens the material itself, NOT the wallpaper.
    Rectangle {
        visible: !studioPalette.custom
        anchors.fill: parent
        anchors.margins: 3
        radius: Math.max(2, glass.curve - 2)
        antialiasing: true
        opacity: glass.softness * 0.68
        gradient: Gradient {
            GradientStop { position: 0.0; color: studioPalette.custom ? glass.mixedSurface(.37,glass.a*.46) : Qt.rgba(0.82, 0.89, 0.98, glass.a * 0.46) }
            GradientStop { position: 0.44; color: studioPalette.custom ? glass.mixedSurface(.26,glass.a*.29) : Qt.rgba(0.65, 0.75, 0.87, glass.a * 0.29) }
            GradientStop { position: 1.0; color: studioPalette.custom ? glass.mixedSurface(.12,glass.a*.22) : Qt.rgba(0.50, 0.59, 0.75, glass.a * 0.22) }
        }
    }

    // A single fine beveled outline, inset enough to avoid clipping at rounded corners.
    Rectangle {
        visible: !studioPalette.custom
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(2, glass.curve - 1)
        antialiasing: true
        color: "transparent"
        border.width: 1
        border.color: studioPalette.paint("#83E4EDFF", "border")
    }

    // Very small highlights at the rim (one edge glint rather than multiple bands).
    Rectangle {
        visible: !studioPalette.custom
        x: Math.max(18, Math.min(glass.width * 0.43, glass.width - 78))
        y: 2
        width: Math.max(0, Math.min(56, glass.width * 0.16))
        height: 2
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: studioPalette.paint("#00FFFFFF", "text") }
            GradientStop { position: 0.35; color: studioPalette.paint("#A0FFFFFF", "text") }
            GradientStop { position: 0.60; color: studioPalette.paint("#B0FFFFFF", "text") }
            GradientStop { position: 1.00; color: studioPalette.paint("#00FFFFFF", "text") }
        }
    }
    Rectangle {
        visible: !studioPalette.custom
        x: Math.max(18, glass.width * 0.13)
        y: Math.max(0, glass.height - 4)
        width: Math.max(0, Math.min(43, glass.width * 0.13))
        height: 1
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: studioPalette.paint("#00FFFFFF", "text") }
            GradientStop { position: 0.50; color: studioPalette.paint("#91EAF4FF", "text") }
            GradientStop { position: 1.00; color: studioPalette.paint("#00FFFFFF", "text") }
        }
        opacity: 0.5
    }
}
