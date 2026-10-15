// Bottom-right hint, e.g. [Enter] Sign In — keycap + label, centred properly
import QtQuick

Rectangle {
    id: hint
    property real s: 1
    property string fontName: "Noto Sans"
    property string keyText: "Enter"
    property string label: ""
    signal clicked()

    readonly property real pad: 16 * s
    width: keycap.width + labelText.implicitWidth + pad * 3
    height: 48 * s
    radius: height / 2
    color: mouse.containsMouse ? "#38ffffff" : "#30001030"
    border.color: "#50ffffff"
    border.width: Math.max(1, s)
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        id: keycap
        x: hint.pad
        anchors.verticalCenter: parent.verticalCenter
        height: 28 * hint.s
        width: Math.max(height, keyLabel.implicitWidth + 16 * hint.s)
        radius: 5 * hint.s
        color: "#e8ffffff"
        Text {
            id: keyLabel
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: hint.keyText
            color: "#10284a"
            font.family: hint.fontName
            font.pixelSize: 15 * hint.s
            font.bold: true
        }
    }
    Text {
        id: labelText
        anchors.left: keycap.right
        anchors.leftMargin: hint.pad * 0.75
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: hint.label
        color: "white"
        font.family: hint.fontName
        font.pixelSize: 19 * hint.s
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: hint.clicked() }
}
