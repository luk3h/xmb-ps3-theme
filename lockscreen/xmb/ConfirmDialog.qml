// PS3-style confirmation: a dark band across the screen with a question and Yes / No,
// then a "Restarting..." style busy screen once you choose Yes.
import QtQuick

Item {
    id: dlg
    property real s: 1
    property string fontName: "Noto Sans"
    property string title: ""
    property string message: ""
    property string detail: ""          // optional smaller line, e.g. a countdown
    property string iconName: "power"
    property string busyText: ""
    property bool open: false
    property bool busy: false
    property int choice: 0               // 0 = Yes, 1 = No
    property bool escCancels: true
    signal accepted()
    signal rejected()

    anchors.fill: parent
    visible: opacity > 0
    opacity: (open || busy) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180 } }

    function ask(t, m, ic, bt) {
        title = t; message = m; iconName = ic; busyText = bt
        choice = 0; busy = false; open = true
        keys.forceActiveFocus()
    }
    function close() { open = false }
    // show "Restarting..." for a moment, fade to black, then run cb()
    property var afterFade: null
    function busyThenFade(text, cb) {
        showBusy(text)
        afterFade = cb
        fadeSeq.restart()
    }
    function unfade() {
        fadeSeq.stop()
        blackout.opacity = 0
        busy = false
    }
    SequentialAnimation {
        id: fadeSeq
        PauseAnimation { duration: 900 }
        NumberAnimation { target: blackout; property: "opacity"; to: 1; duration: 450; easing.type: Easing.InOutQuad }
        ScriptAction { script: if (dlg.afterFade) dlg.afterFade() }
    }
    function showBusy(text) {
        if (text) busyText = text
        open = false
        busy = true
    }
    function handleKey(event) {
        var k = event.key
        if (!open) { event.accepted = true; return }
        if (k === Qt.Key_Left || k === Qt.Key_Right || k === Qt.Key_Up || k === Qt.Key_Down) choice = 1 - choice
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (choice === 0) accepted(); else rejected() }
        else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Backspace || (k === Qt.Key_Escape && escCancels)) rejected()
        else return
        event.accepted = true
    }

    Item {
        id: keys
        focus: dlg.open
        Keys.onPressed: (event) => dlg.handleKey(event)
    }

    // swallow clicks behind the dialog
    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: {} }

    Rectangle { anchors.fill: parent; color: "#38000000" }

    // the band
    Rectangle {
        id: band
        width: parent.width
        height: 300 * dlg.s
        anchors.verticalCenter: parent.verticalCenter
        gradient: Gradient {
            // see-through dark band: your wallpaper's time-of-day colour shows through
            GradientStop { position: 0.0; color: "#48000000" }
            GradientStop { position: 0.5; color: "#70000000" }
            GradientStop { position: 1.0; color: "#48000000" }
        }
        Rectangle { width: parent.width; height: Math.max(1, dlg.s); color: "#60ffffff" }
        Rectangle { width: parent.width; height: Math.max(1, dlg.s); color: "#60ffffff"; anchors.bottom: parent.bottom }

        // ---- question ----
        Item {
            anchors.fill: parent
            visible: dlg.open
            Row {
                id: qRow
                x: parent.width * 0.24 - 56 * dlg.s
                y: 52 * dlg.s
                spacing: 28 * dlg.s
                Image {
                    source: "assets/" + dlg.iconName + ".png"
                    width: 92 * dlg.s; height: width
                    smooth: true; mipmap: true
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * dlg.s
                    Text { text: dlg.title; color: "#b0ffffff"; font.family: dlg.fontName; font.pixelSize: 20 * dlg.s }
                    Text { text: dlg.message; color: "white"; font.family: dlg.fontName; font.pixelSize: 30 * dlg.s }
                    Text { text: dlg.detail; visible: text !== ""; color: "#c0ffffff"; font.family: dlg.fontName; font.pixelSize: 18 * dlg.s }
                }
            }
            Row {
                x: qRow.x + 120 * dlg.s
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40 * dlg.s
                spacing: 18 * dlg.s
                Repeater {
                    model: ["Yes", "No"]
                    Rectangle {
                        width: 170 * dlg.s
                        height: 52 * dlg.s
                        radius: 6 * dlg.s
                        color: dlg.choice === index ? "#40ffffff" : (ma.containsMouse ? "#18ffffff" : "transparent")
                        border.color: dlg.choice === index ? "#e0ffffff" : "#50ffffff"
                        border.width: Math.max(1, dlg.s)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: "white"
                            font.family: dlg.fontName
                            font.pixelSize: 22 * dlg.s
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: dlg.choice = index
                            onClicked: index === 0 ? dlg.accepted() : dlg.rejected()
                        }
                    }
                }
            }
        }

        // ---- busy: "Restarting..." ----
        Row {
            anchors.centerIn: parent
            spacing: 26 * dlg.s
            visible: dlg.busy
            Image {
                id: spin
                source: "assets/spinner.png"
                width: 56 * dlg.s; height: width
                anchors.verticalCenter: parent.verticalCenter
                smooth: true; mipmap: true
                RotationAnimation on rotation { from: 0; to: 360; duration: 1200; loops: Animation.Infinite; running: dlg.busy }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dlg.busyText
                color: "white"
                font.family: dlg.fontName
                font.pixelSize: 30 * dlg.s
            }
        }
    }

    Rectangle {
        id: blackout
        anchors.fill: parent
        color: "black"
        opacity: 0
        z: 50
    }
}
