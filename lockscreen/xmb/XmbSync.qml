// One shared object for every monitor: the main monitor sets "black" (0 = clear, 1 = black)
// and each monitor draws a black cover at that level, so they all fade exactly together.
pragma Singleton
import QtQuick

QtObject {
    property real black: 0
}
