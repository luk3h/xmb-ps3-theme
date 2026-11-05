// XMB-LOGOUT-SHIM
// Installed by /usr/local/bin/xmb-logout-apply. KDE's original is saved next to this as Logout.breeze.qml.
// To undo: sudo /usr/local/bin/xmb-logout-restore
//
// From Plasma 6.8 the Shut Down screen is loaded from the desktop shell, not from your look-and-feel,
// so it's shared by every user. This loader keeps it per user: if you installed the XMB Shut Down
// screen (it lives in your own look-and-feel folder), you get that; everyone else gets KDE's.
import QtQuick
import QtCore

Item {
    id: shim

    // the greeter connects to these on the top item; pass them on from whichever screen is shown
    signal logoutRequested()
    signal haltRequested()
    signal haltUpdateRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal rebootUpdateRequested()
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()

    readonly property url xmbScreen: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
        + "/plasma/look-and-feel/com.github.luk3h.xmbps3/contents/logout/Logout.qml"
    property bool useKde: false

    Loader {
        id: loader
        anchors.fill: parent
        focus: true
        source: shim.useKde ? "Logout.breeze.qml" : shim.xmbScreen
        // not installed for this user (or it failed to load): fall back to KDE's
        onStatusChanged: if (status === Loader.Error && !shim.useKde) shim.useKde = true
    }

    Connections {
        target: loader.item
        ignoreUnknownSignals: true
        function onLogoutRequested() { shim.logoutRequested() }
        function onHaltRequested() { shim.haltRequested() }
        function onHaltUpdateRequested() { shim.haltUpdateRequested() }
        function onSuspendRequested(spdMethod) { shim.suspendRequested(spdMethod) }
        function onRebootRequested() { shim.rebootRequested() }
        function onRebootRequested2(opt) { shim.rebootRequested2(opt) }
        function onRebootUpdateRequested() { shim.rebootUpdateRequested() }
        function onCancelRequested() { shim.cancelRequested() }
        function onLockScreenRequested() { shim.lockScreenRequested() }
        function onCancelSoftwareUpdateRequested() { shim.cancelSoftwareUpdateRequested() }
    }
}
