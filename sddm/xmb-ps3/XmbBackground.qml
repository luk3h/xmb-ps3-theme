// Background: your desktop's XMB wave shader (same colours as your wallpaper, day/night),
// with a built-in image fallback if the shader file is missing, plus drifting sparkles.
import QtQuick

Item {
    id: bgRoot
    property int sparkleCount: 40

    // Still wave: the installer adds assets/still.png in virtual machines (or with --still-wave).
    // Without a graphics card, redrawing the whole screen 60 times a second is very heavy.
    Image { id: stillFlag; visible: false; source: "assets/still.png"; asynchronous: false }

    readonly property bool still: stillFlag.status === Image.Ready

    // ---- the same shader your desktop wallpaper uses ----
    ShaderEffect {
        id: wave
        anchors.fill: parent
        property real iTime: 0
        property vector3d iResolution: Qt.vector3d(width, height, 0.0)   // same as the desktop wallpaper
        property vector4d iDate: Qt.vector4d(0, 0, 0, 0)
        fragmentShader: Qt.resolvedUrl("xmb-wave.frag.qsb")

        // Same clock as your desktop wallpaper: seconds since midnight (times its speed setting),
        // so unlocking or logging in doesn't make the wave jump.
        property real speed: 1.0
        function secsSinceMidnight() {
            const d = new Date()
            return (d - new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0)) / 1000
        }
        Timer {
            interval: 16; running: wave.visible && !bgRoot.still; repeat: true; triggeredOnStart: true
            onTriggered: {
                const secs = wave.secsSinceMidnight()
                wave.iTime = secs * wave.speed
                wave.iDate = Qt.vector4d(0, 0, 0, secs)
            }
        }
        // still wave: draw one frame, at the right time of day
        Component.onCompleted: {
            const secs = wave.secsSinceMidnight()
            wave.iTime = secs * wave.speed
            wave.iDate = Qt.vector4d(0, 0, 0, secs)
        }
    }

    // ---- fallback if the shader can't load ----
    Item {
        id: fallback
        anchors.fill: parent
        visible: wave.status === ShaderEffect.Error
        property real t1: 0
        property real t2: 0
        SequentialAnimation on t1 {
            running: fallback.visible && !bgRoot.still; loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 17000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 17000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on t2 {
            running: fallback.visible && !bgRoot.still; loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 11000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: 0; duration: 11000; easing.type: Easing.InOutSine }
        }
        Image { anchors.fill: parent; source: "assets/background.png"; smooth: true }
        Image {
            source: "assets/wave1.png"
            width: bgRoot.width * 1.3; height: bgRoot.height * 0.75
            x: -bgRoot.width * 0.22 + fallback.t1 * bgRoot.width * 0.14
            y: bgRoot.height * 0.22 - fallback.t2 * bgRoot.height * 0.02
            smooth: true
        }
        Image {
            source: "assets/wave2.png"
            width: bgRoot.width * 1.3; height: bgRoot.height * 0.75
            x: -bgRoot.width * 0.08 - fallback.t2 * bgRoot.width * 0.12
            y: bgRoot.height * 0.20 + fallback.t1 * bgRoot.height * 0.03
            opacity: 0.8; smooth: true
        }
    }

    // ---- sparkles (only with the fallback; your shader draws its own) ----
    Repeater {
        model: (fallback.visible && !bgRoot.still) ? bgRoot.sparkleCount : 0
        Image {
            source: "assets/sparkle.png"
            readonly property real sc: bgRoot.height / 1080
            property real px: Math.random()
            property real py: 0.25 + Math.random() * 0.7
            property real drift: 0
            property real sz: (Math.random() < 0.75 ? 6 : 12) * sc + 2
            width: sz; height: sz
            x: ((px * bgRoot.width + drift) % (bgRoot.width + 20)) - 10
            y: py * bgRoot.height
            opacity: 0.3
            NumberAnimation on drift {
                from: 0; to: bgRoot.width + 20
                duration: 60000 + Math.random() * 90000
                loops: Animation.Infinite
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: Math.random() * 3000 }
                NumberAnimation { to: 0.9; duration: 1200 + Math.random() * 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.12; duration: 1200 + Math.random() * 2000; easing.type: Easing.InOutSine }
            }
        }
    }
}
