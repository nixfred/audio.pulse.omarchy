import QtQuick
import "Model.js" as Model

// A speaker, not a processor die. Magnet and cone on the left, sound arcs
// and a live waveform on the right. Headphones, HDMI and Bluetooth swap the
// mark; mute slashes it. Colour still uses the Pulse ramp, but loudness
// (not headroom) drives it from the panel.
Item {
    id: root
    property string kind: 'speaker'   // 'speaker' | 'headphones' | 'hdmi' | 'bluetooth' | 'none'
    property real level: 0            // 0–1 output volume
    property real activity: 0         // 0–1 peak, drives waveform motion
    property bool muted: false
    property bool animate: true
    property bool compact: false
    property color tint: "#43f2a1"
    property real phase: 0
    property real shownLevel: level
    implicitWidth: compact ? 34 : 160
    implicitHeight: compact ? 25 : 160
    Behavior on shownLevel { NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    Behavior on tint { ColorAnimation { duration: 1100 } }
    NumberAnimation on phase { from: 0; to: 1; duration: 5800; loops: Animation.Infinite; running: root.animate }
    onPhaseChanged: canvas.requestPaint()
    onTintChanged: canvas.requestPaint()
    onShownLevelChanged: canvas.requestPaint()
    onKindChanged: canvas.requestPaint()
    onActivityChanged: canvas.requestPaint()
    onMutedChanged: canvas.requestPaint()
    onAnimateChanged: canvas.requestPaint()
    Canvas {
        id: canvas
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var c = getContext('2d'), w = width, h = height
            c.reset(); c.clearRect(0,0,w,h)
            if (w <= 0 || h <= 0) return
            var cx=w/2, cy=h/2, size=Math.min(w,h)
            var t=root.phase*Math.PI*2
            var lvl=Model.clamp(root.shownLevel,0,1)
            var act=Model.clamp(root.muted ? 0 : root.activity,0,1)
            var live=root.muted ? 0 : lvl
            var aura=c.createRadialGradient(cx,cy,size*0.08,cx,cy,size*0.55)
            aura.addColorStop(0,Qt.alpha(root.tint,0.38+0.28*live)); aura.addColorStop(0.62,Qt.alpha(root.tint,0.16+0.08*Math.sin(t))); aura.addColorStop(1,'transparent')
            c.fillStyle=aura; c.fillRect(0,0,w,h)
            if (!root.compact) {
                for(var ring=0;ring<3;ring++) {
                    var rad=size*(0.34+ring*0.10)
                    c.beginPath(); c.strokeStyle=Qt.alpha(root.tint,0.10+ring*0.04); c.lineWidth=1
                    c.arc(cx,cy,rad,0,Math.PI*2); c.stroke()
                    c.beginPath(); c.strokeStyle=Qt.alpha(root.tint,0.55+0.2*live); c.lineWidth=2; c.lineCap='round'
                    var ang=t*(1+act*2)*(ring%2===0?1:-1)+ring*1.7
                    c.arc(cx,cy,rad,ang,ang+0.55);c.stroke()
                }
            }
            var s=size*(root.compact?0.92:0.62)
            if (root.kind === 'headphones') {
                c.strokeStyle=root.tint; c.fillStyle=root.tint; c.lineWidth=root.compact?1.8:3.2; c.lineCap='round'
                c.shadowColor=root.tint; c.shadowBlur=root.compact?5:12
                c.beginPath(); c.arc(cx, cy-s*0.06, s*0.34, Math.PI*1.12, Math.PI*1.88); c.stroke()
                var cupW=s*(root.compact?0.16:0.14), cupH=s*(root.compact?0.34:0.32)
                c.fillRect(cx-s*0.38, cy-s*0.02, cupW, cupH)
                c.fillRect(cx+s*0.38-cupW, cy-s*0.02, cupW, cupH)
                c.shadowBlur=0
                var arcs=3
                for(var a=1;a<=arcs;a++){
                    var lit=live*arcs>=a-0.35, pulse=(lit && a===Math.min(arcs,Math.max(1,Math.ceil(live*arcs))))?0.65+0.35*Math.sin(t*2):1
                    c.beginPath(); c.strokeStyle=Qt.alpha(root.tint,lit?0.9*pulse:0.16); c.lineWidth=(root.compact?1.2:2.2)*(lit?1:0.7); c.lineCap='round'
                    c.arc(cx, cy+s*0.08, s*0.18*a, 0.15, Math.PI-0.15); c.stroke()
                }
            } else if (root.kind === 'hdmi') {
                var dw=s*0.46, dh=s*0.30, dx=cx-dw/2, dy=cy-s*0.28
                c.strokeStyle=root.tint; c.fillStyle=root.tint; c.lineWidth=root.compact?1.4:2.4
                c.shadowColor=root.tint; c.shadowBlur=root.compact?5:12
                c.strokeRect(dx,dy,dw,dh)
                c.beginPath(); c.moveTo(cx-s*0.07,dy+dh); c.lineTo(cx+s*0.07,dy+dh); c.lineTo(cx+s*0.12,dy+dh+s*0.10); c.lineTo(cx-s*0.12,dy+dh+s*0.10); c.closePath(); c.fill()
                c.shadowBlur=0
                var bars=root.compact?4:7, barW=s/(bars*3.2), base=cy+s*0.42
                for(var i=0;i<bars;i++){
                    var envelope=Math.sin(Math.PI*(i+1)/(bars+1))
                    var wobble=root.animate?0.62+0.38*Math.abs(Math.sin(t*(1.4+act)+i*0.9)):1
                    var bh=s*0.28*live*envelope*wobble*(0.55+0.45*act)
                    var bx=cx-s*0.28+s*0.56*(i+0.5)/bars
                    c.fillStyle=Qt.alpha(root.tint,0.35+0.55*live)
                    c.fillRect(bx-barW/2,base-bh,barW,Math.max(root.compact?1.5:2.5,bh))
                }
            } else if (root.kind === 'none') {
                c.strokeStyle=Qt.alpha(root.tint,0.75); c.lineWidth=root.compact?1.4:2.6; c.setLineDash([s*0.08,s*0.08])
                c.beginPath(); c.arc(cx,cy,s*0.28,0,Math.PI*2); c.stroke(); c.setLineDash([])
            } else {
                var ox=cx-(root.compact?s*0.08:s*0.12), oy=cy
                var magW=s*0.18, magH=s*0.30, magX=ox-s*0.48, magY=oy-magH/2
                c.fillStyle=root.tint; c.shadowColor=root.tint; c.shadowBlur=root.muted?0:(root.compact?6:14)
                c.beginPath()
                c.moveTo(magX, magY+magH*0.18)
                c.quadraticCurveTo(magX-s*0.04, magY+magH*0.18, magX-s*0.04, magY+magH*0.32)
                c.lineTo(magX-s*0.04, magY+magH*0.68)
                c.quadraticCurveTo(magX-s*0.04, magY+magH*0.82, magX, magY+magH*0.82)
                c.lineTo(magX+magW, magY+magH*0.82)
                c.lineTo(ox, oy+s*0.42)
                c.quadraticCurveTo(ox+s*0.10, oy+s*0.44, ox+s*0.10, oy+s*0.30)
                c.lineTo(ox+s*0.10, oy-s*0.30)
                c.quadraticCurveTo(ox+s*0.10, oy-s*0.44, ox, oy-s*0.42)
                c.lineTo(magX+magW, magY+magH*0.18)
                c.closePath()
                c.fill()
                c.shadowBlur=0
                var extra=root.kind==='bluetooth'?4:3
                for(var a=1;a<=extra;a++){
                    var lit=live*extra>=a-0.35, pulse=(lit && a===Math.min(extra,Math.max(1,Math.ceil(live*extra))))?0.65+0.35*Math.sin(t*2):1
                    c.beginPath(); c.strokeStyle=Qt.alpha(root.tint,lit?0.95*pulse:0.16); c.lineWidth=(root.compact?1.5:2.8)*(lit?1:0.7); c.lineCap='round'
                    c.arc(ox+s*0.08, oy, s*0.20*a, -0.88, 0.88); c.stroke()
                }
            }
            if (!root.compact && root.kind !== 'headphones' && root.kind !== 'none') {
                var bars=9, barW=s/22, base=cy+s*0.48, left=cx-s*0.42
                for(var i=0;i<bars;i++){
                    var envelope=Math.sin(Math.PI*(i+1)/(bars+1))
                    var wobble=root.animate?0.58+0.42*Math.abs(Math.sin(t*(1.5+act)+i*0.85)):1
                    var bh=s*0.22*live*envelope*wobble*(0.5+0.5*act)
                    var bx=left+s*0.84*(i+0.5)/bars
                    c.fillStyle=Qt.alpha(root.tint,0.30+0.60*live)
                    c.fillRect(bx-barW/2,base-bh,barW,Math.max(2,bh))
                }
            }
            if (root.muted || root.kind === 'none') {
                c.strokeStyle=Qt.alpha(root.tint,0.95); c.lineWidth=root.compact?2:3.2; c.lineCap='round'
                c.beginPath(); c.moveTo(cx-s*0.32, cy-s*0.32); c.lineTo(cx+s*0.32, cy+s*0.32); c.stroke()
            }
        }
    }
}
