// Password field with Caps Lock warning and a "wrong password" shake
import QtQuick

Item {
    id: box
    property real s: 1
    property string fontName: "Noto Sans"
    property bool busy: false
    property alias text: input.text
    signal keyPressed(var event)

    // Caps Lock: SDDM's own detection doesn't work on Wayland, so we work it out
    // from the letters you type (capital without Shift, or small with Shift = Caps on)
    property bool capsGuess: false
    readonly property bool capsOn: capsGuess || ((typeof keyboard !== "undefined") && keyboard !== null && keyboard.capsLock === true)

    function clear() { input.text = "" }
    // ignore repeat requests while one shake is still fresh
    property real lastShake: 0
    function shake() {
        var now = Date.now()
        if (now - lastShake < 1500) return
        lastShake = now
        shakeAnim.restart()
    }
    function focusInput() { input.forceActiveFocus() }
    function updateCaps(event) {
        if (event.key === Qt.Key_CapsLock) { capsGuess = !capsGuess; return }
        var t = event.text
        if (t.length === 1 && t.toLowerCase() !== t.toUpperCase()) {
            var upper = (t === t.toUpperCase())
            var shift = (event.modifiers & Qt.ShiftModifier) !== 0
            capsGuess = (upper !== shift)
        }
    }

    width: 380 * s
    height: 46 * s

    Rectangle {
        id: frame
        width: parent.width
        height: parent.height
        radius: 6 * box.s
        color: "#30ffffff"
        border.color: input.activeFocus ? "#c8ffffff" : "#60ffffff"
        border.width: Math.max(1, box.s)
        opacity: box.busy ? 0.5 : 1
        property real shakeX: 0
        transform: Translate { x: frame.shakeX }
        SequentialAnimation {
            id: shakeAnim
            // one quick left-right shake
            NumberAnimation { target: frame; property: "shakeX"; to: 12 * box.s; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: frame; property: "shakeX"; to: -12 * box.s; duration: 110; easing.type: Easing.InOutQuad }
            NumberAnimation { target: frame; property: "shakeX"; to: 0; duration: 80; easing.type: Easing.InQuad }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 16 * box.s
            anchors.rightMargin: 16 * box.s
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            color: "white"
            selectionColor: "#5080c0ff"
            font.family: box.fontName
            font.pixelSize: 22 * box.s
            clip: true
            enabled: !box.busy
            Keys.onPressed: (event) => { box.updateCaps(event); box.keyPressed(event) }
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "Password"
                color: "#a0ffffff"
                font: input.font
                visible: input.text.length === 0
            }
        }
    }

    // Caps Lock warning under the box
    Row {
        anchors.left: frame.left
        anchors.top: frame.bottom
        anchors.topMargin: 8 * box.s
        spacing: 8 * box.s
        visible: box.capsOn
        Rectangle {
            width: 22 * box.s; height: 22 * box.s; radius: 4 * box.s
            color: "#ffd27a"
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "A"; color: "#1a2a40"; font.bold: true
                font.family: box.fontName; font.pixelSize: 14 * box.s
            }
        }
        Text {
            height: 22 * box.s
            verticalAlignment: Text.AlignVCenter
            text: "Caps Lock is on"
            color: "#ffd27a"
            font.family: box.fontName
            font.pixelSize: 17 * box.s
        }
    }
}
