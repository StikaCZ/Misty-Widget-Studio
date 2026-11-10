import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

Item {
    id: face
    ThemePalette { id: palette }
    property date now: new Date()
    readonly property string clockMode: Plasmoid.configuration.clockMode || "digital24"
    readonly property string selectedStyle: Plasmoid.configuration.widgetStyle || "normal"
    readonly property string fontName: (Plasmoid.configuration.clockFontFamily || "JetBrains Mono") === "Custom" ? (Plasmoid.configuration.clockCustomFont || "sans-serif") : (Plasmoid.configuration.clockFontFamily || "JetBrains Mono")
    readonly property real fontMultiplier: Math.max(.65,Math.min(1.8,(Plasmoid.configuration.clockScale ?? 100)/100))
    readonly property bool showDate: Plasmoid.configuration.clockShowDate !== false
    readonly property bool showCaption: Plasmoid.configuration.clockShowCaption !== false
    readonly property bool showSecondHand: Plasmoid.configuration.clockSecondsHand !== false
    readonly property color foreground: palette.paint(Plasmoid.configuration.clockHandsColor || "#E8F0EC","text")
    readonly property color accent: palette.paint(Plasmoid.configuration.clockSecondColor || "#94C6A9","accent")
    readonly property color background: palette.panel(Plasmoid.configuration.clockFaceColor || "#162326")
    readonly property color subdued: palette.paint("#9DAFA7","muted")
    readonly property int hour24: now.getHours()
    readonly property int minute: now.getMinutes()
    readonly property int second: now.getSeconds()
    readonly property string hh24: Qt.formatTime(now,"HH")
    readonly property string mm: Qt.formatTime(now,"mm")
    readonly property string ss: Qt.formatTime(now,"ss")
    readonly property string dayString: Qt.formatDate(now, "ddd dd MMM yyyy")
    readonly property string binaryHour: toBinary(hour24,5)
    readonly property string binaryMinute: toBinary(minute,6)
    readonly property string binarySecond: toBinary(second,6)
    function toBinary(number,width) { let s=number.toString(2); while(s.length<width)s="0"+s; return s }
    implicitWidth: 350
    implicitHeight: 180
    clip: true
    Timer { interval: 1000; repeat: true; running: face.visible; onTriggered: face.now=new Date() }
    Rectangle {
        anchors.fill: parent
        visible: face.selectedStyle !== "minimal"
        radius: face.selectedStyle === "glass" ? 20 : 8
        color: palette.custom ? palette.panel("#162326") : face.selectedStyle === "glass" ? Qt.rgba(face.background.r,face.background.g,face.background.b,.65)
             : face.selectedStyle === "terminal" ? palette.panel("#e00c1214") : face.background
        border.color: palette.outline("#62788b83")
        border.width: 1
    }
    Column {
        id: digitalColumn
        visible: face.clockMode !== "analog" && face.clockMode !== "binary" && face.clockMode !== "flip"
        anchors.fill: parent; anchors.margins: Math.max(6,Math.min(15,face.height*.07))
        spacing: 0
        Text {
            width: parent.width; height: face.showCaption ? parent.height*.17 : 0
            visible: face.showCaption
            text: face.clockMode === "digital12" ? "LOCAL TIME / AM-PM" : "LOCAL TIME"
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: face.fontName; font.pixelSize: Math.max(8,Math.min(12,face.height*.08)*face.fontMultiplier)
            color: face.subdued
        }
        Text {
            width: parent.width
            height: parent.height*(face.showDate ? .65 : .80) + (face.showCaption ? 0 : parent.height*.1)
            text: face.clockMode === "digital12" ? Qt.formatTime(face.now,"hh:mm AP") : face.clockMode === "seconds" ? Qt.formatTime(face.now,"HH:mm:ss") : Qt.formatTime(face.now,"HH:mm")
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: face.fontName; font.weight: Font.Bold
            font.pixelSize: Math.max(22,Math.min(face.height*.49, face.width*(face.clockMode==="seconds"?.16:.22))*face.fontMultiplier)
            fontSizeMode: Text.Fit; minimumPixelSize: 16
            color: face.foreground
        }
        Text {
            visible: face.showDate
            width: parent.width; height: face.showDate ? parent.height*.18 : 0
            text: face.dayString.toUpperCase()
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: face.fontName; font.pixelSize: Math.max(9,Math.min(15,face.height*.10)*face.fontMultiplier)
            fontSizeMode: Text.Fit; minimumPixelSize: 8
            color: face.subdued
        }
    }
    Item {
        id: flipClock
        visible: face.clockMode === "flip"
        anchors.fill: parent
        anchors.margins: Math.max(6,face.height*.08)
        Row {
            id: flipCards
            width: Math.min(parent.width, parent.height*2.8)
            height: parent.height*(face.showDate? .72 : .92)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(2,width*.025)
            Repeater {
                model: face.clockMode==="flip" ? [face.hh24,face.mm] : []
                Rectangle {
                    width: (flipCards.width - flipCards.spacing)/2
                    height: flipCards.height
                    radius: 9
                    color: face.selectedStyle==="minimal"? "#171c20" : palette.paint("#ef263034","surface")
                    border.width: 1; border.color: palette.paint("#6c7f8789","border")
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 2; color: palette.paint("#A24C5A5A","border") }
                    Text {
                        anchors.fill: parent
                        text: modelData
                        font.family: face.fontName; font.bold: true
                        font.pixelSize: Math.min(parent.width*.53,parent.height*.79)*face.fontMultiplier
                        fontSizeMode: Text.Fit; minimumPixelSize: 18
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        color: face.foreground
                    }
                }
            }
        }
        Text {
            visible: face.showDate; width: parent.width; anchors.bottom: parent.bottom; height: parent.height*.15
            text: face.dayString; font.family: face.fontName; color: face.subdued
            font.pixelSize: Math.max(8,Math.min(13,face.height*.08)*face.fontMultiplier)
            horizontalAlignment: Text.AlignHCenter
        }
    }
    Item {
        id: analogue
        visible: face.clockMode === "analog"
        anchors.fill: parent
        Canvas {
            id: clockCanvas
            anchors.centerIn: parent
            width: Math.min(parent.width*.96,parent.height*(face.showDate?.83:.98))
            height: width
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections { target: face; function onNowChanged() {clockCanvas.requestPaint()} }
            onPaint: {
                const ctx=getContext("2d")
                const s=width
                ctx.clearRect(0,0,s,s)
                if(s<4)return
                const c=s/2, r=s*.474
                function circle(radius,fill,stroke,line) {
                    ctx.beginPath();ctx.arc(c,c,radius,0,Math.PI*2)
                    if(fill){ctx.fillStyle=fill;ctx.fill()}
                    if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=line;ctx.stroke()}
                }
                circle(r,face.background.toString(),face.foreground.toString(),Math.max(1,s*.013))
                for(let k=0;k<60;k++){
                    const a=k*Math.PI/30-Math.PI/2
                    const major=k%5===0
                    const r1=r*(major?.79:.88),r2=r*.93
                    ctx.beginPath();ctx.moveTo(c+Math.cos(a)*r1,c+Math.sin(a)*r1)
                    ctx.lineTo(c+Math.cos(a)*r2,c+Math.sin(a)*r2)
                    ctx.lineWidth=major?Math.max(1,s*.012):Math.max(.6,s*.005)
                    ctx.strokeStyle=major?face.foreground.toString():face.subdued.toString();ctx.stroke()
                }
                function hand(a,len,w,col){
                    ctx.beginPath();ctx.moveTo(c-Math.cos(a)*r*.09,c-Math.sin(a)*r*.09)
                    ctx.lineTo(c+Math.cos(a)*r*len,c+Math.sin(a)*r*len)
                    ctx.lineCap="round";ctx.lineWidth=w;ctx.strokeStyle=col;ctx.stroke()
                }
                hand((face.hour24%12+face.minute/60)*Math.PI/6-Math.PI/2,.54,Math.max(2,s*.033),face.foreground.toString())
                hand((face.minute+face.second/60)*Math.PI/30-Math.PI/2,.74,Math.max(1.6,s*.023),face.foreground.toString())
                if(face.showSecondHand)hand(face.second*Math.PI/30-Math.PI/2,.84,Math.max(1,s*.008),face.accent.toString())
                circle(Math.max(2,s*.021),face.accent.toString(),null,0)
            }
        }
        Text {
            visible: face.showDate; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            text: face.dayString; font.family: face.fontName; color: face.subdued
            font.pixelSize: Math.max(8,Math.min(13,face.height*.085)*face.fontMultiplier)
        }
    }
    Column {
        visible: face.clockMode === "binary"
        anchors.centerIn: parent
        width: Math.min(parent.width*.94,340)
        spacing: Math.max(4,Math.min(10,face.height*.06))
        Text {
            visible: face.showCaption; width: parent.width
            text: "BINARY / " + face.hh24 + ":" + face.mm
            font.family: face.fontName; font.pixelSize: Math.max(9,Math.min(13,face.height*.1)*face.fontMultiplier)
            color: face.subdued; horizontalAlignment: Text.AlignHCenter
        }
        Repeater {
            model: [face.binaryHour,face.binaryMinute,face.binarySecond]
            delegate: Row {
                id: bitRow
                width: parent.width; height: Math.max(12,Math.min(27,face.height*.15))
                spacing: 4
                property string bits: modelData
                Text { width: 40; height: parent.height; text: ["H","M","S"][index]
                    verticalAlignment: Text.AlignVCenter; color:face.subdued; font.family:face.fontName; font.pixelSize: Math.max(10,parent.height*.57) }
                Repeater {
                    model: 6
                    Rectangle {
                        width: Math.max(8,(parent.width-70)/6-4)
                        height: parent.height*.75
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 4
                        color: (index>=6-bitRow.bits.length && bitRow.bits.charAt(index-(6-bitRow.bits.length))==="1")?face.accent:palette.paint("#38545f59","border")
                    }
                }
            }
        }
        Text {
            visible: face.showDate; width: parent.width
            text: face.dayString; color:face.subdued; font.family:face.fontName; font.pixelSize: Math.max(9,Math.min(12,face.height*.09)*face.fontMultiplier)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
