// XMB PS3 splash: plain black on every monitor while Plasma builds your desktop.
// KDE then fades the whole thing away at once, so both monitors' desktops appear together
// (straight on from the login screen's fade to black).
import QtQuick

Rectangle {
    id: root
    color: "black"
    property int stage      // KDE sets this as the desktop loads; nothing to show here
}
