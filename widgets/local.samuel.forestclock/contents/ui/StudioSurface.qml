import QtQuick
Item {
    ThemePalette { id: studioPalette }

    id: frame
    property string variant: "glass"
    property color baseColor: studioPalette.paint("#161624", "surface")
    property color accent: studioPalette.paint("#8076CF", "accent")
    property int alphaPercent: 70
    property int blurStrength: 45
    property int radiusSize: 20
    StudioGlass { anchors.fill: parent; tintColor: studioPalette.paint(frame.accent, "accent"); baseColor: frame.baseColor;
                  alphaPercent: frame.alphaPercent; radiusSize: frame.radiusSize; blurStrength: frame.blurStrength }
}
