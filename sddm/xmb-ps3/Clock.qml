// PS3-style clock box
import QtQuick

Rectangle {
    id: clock
    property real s: 1
    property string fontName: "Noto Sans"
    width: clockText.implicitWidth + 50 * s
    height: 44 * s
    radius: 4 * s
    color: "#18ffffff"
    border.color: "#70ffffff"
    border.width: Math.max(1, s)
    Text {
        id: clockText
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "white"
        font.family: clock.fontName
        font.pixelSize: 24 * clock.s
        text: Qt.formatDateTime(new Date(), "d/M  HH:mm")
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "d/M  HH:mm")
        }
    }
}
