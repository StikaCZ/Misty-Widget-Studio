import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
Kirigami.FormLayout {
    id: page
    property string cfg_widgetStyle: "normal"
    property alias cfg_widgetOpacity: backgroundFade.value
    property string cfg_cdDesign: "silver"
    property string cfg_cdFrameStyle: "studio"
    property string cfg_cdCenterStyle: "label"
    property alias cfg_cdLabel: centerText.text
    property string cfg_cdFont: "JetBrains Mono"
    property alias cfg_cdDiscColor: discField.text
    property alias cfg_cdRingColor: ringField.text
    property alias cfg_cdCenterColor: centerField.text
    property alias cfg_cdTextColor: textField.text
    property alias cfg_cdSurfaceColor: surfaceField.text
    property alias cfg_cdSpin: spin.checked
    property alias cfg_cdSpinSeconds: speed.value
    property alias cfg_cdSize: discSize.value
    property alias cfg_cdCenterSize: centerSize.value
    property alias cfg_cdHoleSize: holeSize.value
    property alias cfg_cdShine: shine.value
    property alias cfg_cdRings: rings.value
    property alias cfg_cdShowControls: controls.checked
    property alias cfg_cdShowTrack: info.checked
    property alias cfg_cdShowProgress: progress.checked
    property string selectedColour: "disc"
    readonly property var styles: ["normal","glass","terminal","minimal"]
    readonly property var designs: ["silver","graphite","aurora","rose","vinyl"]
    readonly property var frames: ["studio","jewel","none"]
    readonly property var centerStyles: ["label","initials","plain","logo"]
    readonly property var fonts: ["JetBrains Mono","Noto Sans","DejaVu Sans Mono","Liberation Sans","Roboto","Inter","sans-serif","monospace"]
    RowLayout {
        Kirigami.FormData.label: i18n("Background opacity:")
        Layout.fillWidth: true
        QQC2.Slider { id: backgroundFade; from: 0; to: 100; stepSize: 5; Layout.fillWidth: true }
        QQC2.Label { text: Math.round(backgroundFade.value) + "%" }
    }
    QQC2.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Changes the panel background only. The CD, centre label, track names and playback controls stay visible.")
    }
    QQC2.Label { Kirigami.FormData.isSection: true; text: i18n("Disc appearance") }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Case style:")
        Layout.fillWidth: true
        model: [i18n("Modern studio card"),i18n("Transparent jewel-case edge"),i18n("Just the disc / no case")]
        currentIndex: Math.max(0,page.frames.indexOf(page.cfg_cdFrameStyle))
        onActivated: function(i){ page.cfg_cdFrameStyle=page.frames[i] }
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Style:")
        Layout.fillWidth: true; model: ["Normal","Liquid Glass","Terminal","Minimal"]
        currentIndex: Math.max(0,page.styles.indexOf(page.cfg_widgetStyle))
        onActivated: function(i){page.cfg_widgetStyle=page.styles[i]}
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Disc material:")
        Layout.fillWidth: true; model: ["Silver CD","Dark graphite","Aurora iridescent","Rose gold","Black vinyl"]
        currentIndex: Math.max(0,page.designs.indexOf(page.cfg_cdDesign))
        onActivated: function(i){
            page.cfg_cdDesign=page.designs[i]
            const presets = [
                ["#C1CFD0","#8FB89F","#223036"],
                ["#444E5A","#9AA9BD","#141D27"],
                ["#ACBEDB","#B0E2A2","#46557B"],
                ["#D6A8AC","#ECD4B9","#7A485B"],
                ["#21252E","#777A86","#373B43"]
            ]
            page.cfg_cdDiscColor=presets[i][0]
            page.cfg_cdRingColor=presets[i][1]
            page.cfg_cdCenterColor=presets[i][2]
        }
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Disc centre:")
        Layout.fillWidth: true; model: ["Custom label","Initials","Plain colour","Music symbol"]
        currentIndex: Math.max(0,page.centerStyles.indexOf(page.cfg_cdCenterStyle))
        onActivated: function(i){page.cfg_cdCenterStyle=page.centerStyles[i]}
    }
    QQC2.TextField { id: centerText; Kirigami.FormData.label: i18n("Centre text:"); Layout.fillWidth: true; maximumLength: 32; placeholderText: "STIKA CZ" }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Label font:")
        Layout.fillWidth: true; model: page.fonts
        currentIndex: Math.max(0,page.fonts.indexOf(page.cfg_cdFont))
        onActivated: function(i){page.cfg_cdFont=page.fonts[i]}
    }
    QQC2.Label { Kirigami.FormData.isSection: true; text: i18n("Customise the inside & rings") }
    function edit(role,value){selectedColour=role;picker.selectedColor=value;picker.open()}
    ColorDialog {
        id: picker; title: i18n("CD colour")
        onAccepted: {
            const v=selectedColor.toString()
            if(page.selectedColour==="disc")discField.text=v
            else if(page.selectedColour==="ring")ringField.text=v
            else if(page.selectedColour==="center")centerField.text=v
            else if(page.selectedColour==="text")textField.text=v
            else surfaceField.text=v
        }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Disc tint:")
        QQC2.Button { text:"●"; onClicked:page.edit("disc",discField.text) }
        QQC2.TextField { id:discField; Layout.fillWidth:true; maximumLength:9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Ring colour:")
        QQC2.Button { text:"●"; onClicked:page.edit("ring",ringField.text) }
        QQC2.TextField { id:ringField; Layout.fillWidth:true; maximumLength:9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Centre colour:")
        QQC2.Button { text:"●"; onClicked:page.edit("center",centerField.text) }
        QQC2.TextField { id:centerField; Layout.fillWidth:true; maximumLength:9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Centre text:")
        QQC2.Button { text:"●"; onClicked:page.edit("text",textField.text) }
        QQC2.TextField { id:textField; Layout.fillWidth:true; maximumLength:9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Background:")
        QQC2.Button { text:"●"; onClicked:page.edit("surface",surfaceField.text) }
        QQC2.TextField { id:surfaceField; Layout.fillWidth:true; maximumLength:9 }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Disc size:")
        QQC2.Slider { id:discSize; from:60;to:100;stepSize:2; Layout.fillWidth:true }
        QQC2.Label { text:Math.round(discSize.value)+"%" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Centre diameter:")
        QQC2.Slider { id:centerSize; from:24;to:56;stepSize:1; Layout.fillWidth:true }
        QQC2.Label { text:Math.round(centerSize.value)+"%" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Spindle hole:")
        QQC2.Slider { id:holeSize; from:6;to:22;stepSize:1; Layout.fillWidth:true }
        QQC2.Label { text:Math.round(holeSize.value)+"%" }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Groove rings:")
        QQC2.Slider { id:rings; from:0;to:14;stepSize:1; Layout.fillWidth:true }
        QQC2.Label { text:Math.round(rings.value) }
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Shine:")
        QQC2.Slider { id:shine; from:0;to:100;stepSize:5; Layout.fillWidth:true }
        QQC2.Label { text:Math.round(shine.value)+"%" }
    }
    QQC2.Label { Kirigami.FormData.isSection: true; text: i18n("Animation & controls") }
    QQC2.CheckBox { id:spin; Kirigami.FormData.label:i18n("Rotation:"); text:i18n("Spin when music is playing") }
    RowLayout {
        Kirigami.FormData.label: i18n("Seconds per turn:")
        QQC2.Slider { id:speed;from:2;to:24;stepSize:1; Layout.fillWidth:true }
        QQC2.Label {text:Math.round(speed.value)+"s"}
    }
    QQC2.CheckBox { id:controls; Kirigami.FormData.label:i18n("Music buttons:"); text:i18n("Show previous, play / pause and next") }
    QQC2.CheckBox { id:info; Kirigami.FormData.label:i18n("Track details:"); text:i18n("Show track and artist below the CD") }
    QQC2.CheckBox { id:progress; Kirigami.FormData.label:i18n("Progress:"); text:i18n("Show song progress line when supported") }
    QQC2.Label { text:i18n("Use Theme colours to override surface, text and accent colours. This widget does not save music or credentials."); Layout.fillWidth:true; wrapMode:Text.WordWrap }
}
