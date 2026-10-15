// One row in the Options panel
import QtQuick

Rectangle {
    id: row
    property real s: 1
    property string fontName: "Noto Sans"
    property string text: ""
    property string iconSource: ""
    property bool highlighted: false
    signal clicked()

    height: 52 * s
    radius: 4 * s
    color: highlighted ? "#40a0d0ff" : (mouse.containsMouse ? "#20ffffff" : "transparent")
    border.color: highlighted ? "#90c0e8ff" : "transparent"
    border.width: Math.max(1, s)
    Behavior on color { ColorAnimation { duration: 120 } }

    Image {
        id: ic
        x: 14 * row.s
        anchors.verticalCenter: parent.verticalCenter
        width: 28 * row.s; height: width
        source: row.iconSource
        visible: row.iconSource !== ""
        smooth: true; mipmap: true
    }
    Text {
        x: 58 * row.s
        anchors.verticalCenter: parent.verticalCenter
        text: row.text
        color: "white"
        font.family: row.fontName
        font.pixelSize: 21 * row.s
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: row.clicked() }
}
