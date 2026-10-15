// One row in the user column: round picture + name, bigger when selected
import QtQuick

Item {
    id: item
    property bool selected: false
    property string iconSource: ""
    property string label: ""
    property real s: 1
    property real baseX: 0
    property string fontName: "Noto Sans"
    signal clicked()

    x: baseX - (selected ? 56 : 38) * s
    width: 700 * s
    height: (selected ? 112 : 76) * s
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Image {
        anchors.centerIn: pic
        width: pic.width * 2; height: width
        source: "assets/glow.png"
        opacity: item.selected ? 0.55 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Avatar {
        id: pic
        width: (item.selected ? 112 : 76) * item.s
        height: width
        ring: Math.max(1.5, 2 * item.s)
        source: item.iconSource
        opacity: item.selected ? 1 : 0.6
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Text {
        anchors.left: pic.right
        anchors.leftMargin: 24 * item.s
        anchors.top: item.selected ? pic.top : undefined
        anchors.topMargin: item.selected ? 10 * item.s : 0
        anchors.verticalCenter: item.selected ? undefined : pic.verticalCenter
        text: item.label
        color: "white"
        font.family: item.fontName
        font.pixelSize: (item.selected ? 28 : 22) * item.s
        opacity: item.selected ? 1 : 0.7
        style: Text.Raised
        styleColor: "#40002040"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: item.clicked()
    }
}
