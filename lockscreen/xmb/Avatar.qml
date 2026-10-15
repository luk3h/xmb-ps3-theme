// Round profile picture with a thin ring
import QtQuick
import QtQuick.Effects

Item {
    id: av
    property string source: ""
    property string fallback: "assets/user.png"
    property real ring: 2
    property bool usingFallback: source === "" || img.status === Image.Error

    // soft disc behind (shows behind the fallback silhouette)
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#35ffffff"
    }

    // real photo, masked to a circle
    Image {
        id: img
        anchors.fill: parent
        source: av.source
        sourceSize: Qt.size(512, 512)
        fillMode: Image.PreserveAspectCrop
        smooth: true; mipmap: true
        visible: false
        layer.enabled: true
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
        layer.smooth: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        visible: !av.usingFallback
    }

    // fallback silhouette
    Image {
        anchors.fill: parent
        anchors.margins: parent.width * 0.16
        source: av.fallback
        fillMode: Image.PreserveAspectFit
        smooth: true; mipmap: true
        visible: av.usingFallback
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: "#d8ffffff"
        border.width: av.ring
    }
}
