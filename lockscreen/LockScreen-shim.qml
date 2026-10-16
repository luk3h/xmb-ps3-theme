// XMB-LOCKSCREEN-SHIM
// Installed by /usr/local/bin/xmb-lockscreen-apply. KDE's original is saved next to this as LockScreen.breeze.qml.
// To undo: sudo /usr/local/bin/xmb-lockscreen-restore
//
// The lock screen runs as whoever is locked, so each user can opt out:
// ./install.sh --lock-off-for-me creates ~/.config/xmb-ps3/lockscreen-off.png and they get KDE's normal one.
import QtQuick
import QtCore

Item {
    id: shim
    // KDE sets these two on the lock screen's top item; pass them on to whichever lock screen is shown
    property bool viewVisible: false
    property bool locked: false

    Image {
        id: optOut
        visible: false
        asynchronous: false
        source: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/xmb-ps3/lockscreen-off.png"
    }
    readonly property bool useKde: optOut.status === Image.Ready

    Loader {
        id: loader
        anchors.fill: parent
        focus: true
        source: shim.useKde ? "LockScreen.breeze.qml" : "xmb/XmbLockScreen.qml"
    }
    Binding {
        target: loader.item
        property: "viewVisible"
        value: shim.viewVisible
        when: loader.item !== null && loader.item.hasOwnProperty("viewVisible")
    }
    Binding {
        target: loader.item
        property: "locked"
        value: shim.locked
        when: loader.item !== null && loader.item.hasOwnProperty("locked")
    }
}
