// XMB PS3-style Restart / Shut Down / Log Out screen for KDE Plasma 6
// (replaces KDE's "Leave" screen). Left/Right: choose   Enter: select   Esc: cancel
import QtQuick
import QtQuick.Window
import org.kde.plasma.private.sessions 2.0

Item {
    id: root

    // KDE listens for these
    signal logoutRequested()
    signal haltRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()
    signal haltUpdateRequested()       // Plasma 6.7+: install updates, then turn off
    signal rebootUpdateRequested()     // Plasma 6.7+: install updates, then restart

    width: (typeof screenGeometry !== "undefined") ? screenGeometry.width : 1920
    height: (typeof screenGeometry !== "undefined") ? screenGeometry.height : 1080
    readonly property real s: height / 1080
    readonly property string fontName: "Noto Sans"

    // Only the main monitor gets the menu; the others just dim.
    // "Main" = the biggest screen (your 4K), matched by name, or by position as a backup.
    readonly property int mainIndex: {
        var scr = Qt.application.screens
        if (!scr || scr.length === 0) return -1
        var best = 0, bestArea = -1
        for (var i = 0; i < scr.length; i++) {
            var a = scr[i].width * scr[i].height * scr[i].devicePixelRatio * scr[i].devicePixelRatio
            if (a > bestArea) { bestArea = a; best = i }
        }
        return best
    }
    readonly property bool isPrimary: {
        var scr = Qt.application.screens
        if (!scr || scr.length < 2) return true
        var maxArea = 0
        for (var i = 0; i < scr.length; i++) maxArea = Math.max(maxArea, scr[i].width * scr[i].height)
        // this copy's own screen size (Screen.* once known, otherwise the size KDE gave us)
        var myArea = (Screen.width > 0) ? Screen.width * Screen.height : root.width * root.height
        return myArea >= maxArea - 1
    }

    // pull keyboard focus onto the main monitor's copy
    function grabFocus() {
        ensureQuestion()
        if (!isPrimary) return
        if (Window.window) Window.window.requestActivate()
        if (confirm.open) confirm.ask(confirm.title, confirm.message, confirm.iconName, confirm.busyText)
        else keyCatcher.forceActiveFocus()
    }
    Timer { id: focusTimer1; interval: 120; running: true; onTriggered: root.grabFocus() }
    Timer { id: focusTimer2; interval: 500; running: true; onTriggered: root.grabFocus() }

    // ---- what KDE asked for ----
    function st(name, num) {
        return (typeof ShutdownType !== "undefined" && ShutdownType[name] !== undefined) ? ShutdownType[name] : num
    }
    readonly property int tDefault: st("ShutdownTypeDefault", -1)
    readonly property int tNone:    st("ShutdownTypeNone", 0)
    readonly property int tReboot:  st("ShutdownTypeReboot", 1)
    readonly property int tHalt:    st("ShutdownTypeHalt", 2)
    readonly property int type: (typeof sdtype !== "undefined") ? sdtype : tDefault
    readonly property bool showAll: type === tDefault
    readonly property bool mayShutdown: (typeof maysd !== "undefined") ? maysd : true
    readonly property bool mayLogout: (typeof canLogout !== "undefined") ? canLogout : true
    readonly property bool canSusp: (typeof spdMethods !== "undefined") && !!spdMethods.SuspendState
    readonly property bool canHib: (typeof spdMethods !== "undefined") && !!spdMethods.HibernateState

    readonly property var actions: {
        var a = []
        if (canSusp)     a.push({ label: "Sleep",           icon: "suspend",   act: "suspend" })
        if (canHib)      a.push({ label: "Hibernate",       icon: "hibernate", act: "hibernate" })
        if (mayShutdown) a.push({ label: "Restart System",  icon: "restart",   act: "reboot" })
        if (mayShutdown) a.push({ label: "Turn Off System", icon: "power",     act: "off" })
        if (mayLogout)   a.push({ label: "Log Out",         icon: "logout",    act: "logout" })
        return a
    }
    property int sel: 0
    property bool done: false

    function busyTextFor(act) {
        if (act === "reboot") return "Restarting..."
        if (act === "off") return "Turning off..."
        if (act === "logout") return "Logging out..."
        if (act === "hibernate") return "Hibernating..."
        return "Going to sleep..."
    }
    function run(act) {
        if (done) return
        done = true
        countdown.stop()
        confirm.showBusy(busyTextFor(act))
        pendingAct = act
        emitTimer.start()
    }
    property string pendingAct: ""
    Timer {
        id: emitTimer
        interval: 450
        onTriggered: {
            var a = root.pendingAct
            if (a === "reboot") root.rebootRequested()
            else if (a === "off") root.haltRequested()
            else if (a === "logout") root.logoutRequested()
            else if (a === "suspend") root.suspendRequested(2)
            else if (a === "hibernate") root.suspendRequested(4)
        }
    }
    function cancel() { if (!done) root.cancelRequested() }

    // the single action KDE asked for (e.g. you clicked "Restart" in the menu)
    readonly property string directAct: type === tReboot ? "reboot" : (type === tHalt ? "off" : "logout")

    // ---- countdown for a direct Restart / Turn Off / Log Out ----
    property int remaining: 30
    Timer {
        id: countdown
        interval: 1000; repeat: true
        running: !root.showAll && root.isPrimary && !root.done
        onTriggered: {
            root.remaining--
            if (root.remaining <= 0) root.run(root.directAct)
        }
    }

    function handleKey(event) {
        var k = event.key
        if (k === Qt.Key_Escape) { cancel(); event.accepted = true; return }
        if (!isPrimary || done) return
        if (k === Qt.Key_Left || k === Qt.Key_Up) sel = Math.max(0, sel - 1)
        else if (k === Qt.Key_Right || k === Qt.Key_Down) sel = Math.min(actions.length - 1, sel + 1)
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (actions[sel]) run(actions[sel].act) }
        else return
        event.accepted = true
    }

    // show the Yes/No question on the main monitor. Called at start AND whenever we learn which
    // monitor we're on (at the very start of boot that can arrive a moment late).
    function ensureQuestion() {
        if (showAll || !isPrimary || done || confirm.open || confirm.busy) return
        if (directAct === "reboot") confirm.ask("Restart System", "Restart the system?", "restart", "Restarting...")
        else if (directAct === "off") confirm.ask("Turn Off System", "Turn off the system?", "power", "Turning off...")
        else confirm.ask("Log Out", "Log out now?", "logout", "Logging out...")
    }
    onIsPrimaryChanged: ensureQuestion()
    Component.onCompleted: {
        // start on Restart if it's there
        for (var i = 0; i < actions.length; i++) if (actions[i].act === "reboot") { sel = i; break }
        ensureQuestion()
        if (showAll || !isPrimary) keyCatcher.forceActiveFocus()
    }

    Item {
        id: keyCatcher
        focus: true
        Keys.onPressed: (event) => root.handleKey(event)
    }

    // dim the desktop; clicking outside the band cancels
    Rectangle {
        anchors.fill: parent
        color: "#60000000"
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }
    }

    // ---- full power menu (from the "Shut Down..." / Leave button) ----
    Rectangle {
        id: band
        visible: root.isPrimary && root.showAll && !confirm.busy
        width: parent.width
        height: 330 * root.s
        anchors.verticalCenter: parent.verticalCenter
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#48000000" }
            GradientStop { position: 0.5; color: "#70000000" }
            GradientStop { position: 1.0; color: "#48000000" }
        }
        Rectangle { width: parent.width; height: Math.max(1, root.s); color: "#60ffffff" }
        Rectangle { width: parent.width; height: Math.max(1, root.s); color: "#60ffffff"; anchors.bottom: parent.bottom }
        MouseArea { anchors.fill: parent }   // clicks on the band don't cancel

        Text {
            x: parent.width * 0.24 - 56 * root.s
            y: 34 * root.s
            text: "Power"
            color: "#b0ffffff"
            font.family: root.fontName
            font.pixelSize: 22 * root.s
        }

        Row {
            x: parent.width * 0.24 - 56 * root.s
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 10 * root.s
            spacing: 40 * root.s
            Repeater {
                model: root.actions
                Item {
                    readonly property bool on: index === root.sel
                    width: 180 * root.s
                    height: 180 * root.s
                    Image {
                        anchors.centerIn: icon
                        width: 200 * root.s; height: width
                        source: "assets/glow.png"
                        opacity: parent.on ? 0.85 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Image {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 20 * root.s
                        width: (parent.on ? 100 : 76) * root.s; height: width
                        source: "assets/" + modelData.icon + ".png"
                        opacity: parent.on ? 1 : 0.6
                        smooth: true; mipmap: true
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        text: modelData.label
                        color: "white"
                        opacity: parent.on ? 1 : 0.6
                        font.family: root.fontName
                        font.pixelSize: (parent.on ? 22 : 19) * root.s
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.sel = index
                        onClicked: root.run(modelData.act)
                    }
                }
            }
        }
    }

    // ---- hints, bottom-right ----
    Row {
        visible: root.isPrimary && root.showAll && !confirm.busy
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 70 * root.s; anchors.bottomMargin: 60 * root.s
        spacing: 14 * root.s
        HintButton { s: root.s; fontName: root.fontName; keyText: "Esc"; label: "Cancel"; onClicked: root.cancel() }
        HintButton {
            s: root.s; fontName: root.fontName; keyText: "Enter"; label: "Select"
            onClicked: if (root.actions[root.sel]) root.run(root.actions[root.sel].act)
        }
    }

    // ---- Yes / No for a direct Restart / Turn Off / Log Out, and the busy screen ----
    ConfirmDialog {
        id: confirm
        s: root.s; fontName: root.fontName
        z: 100
        visible: root.isPrimary && opacity > 0     // never on the second monitor
        detail: (!root.showAll && open)
                ? (root.directAct === "reboot" ? "Restarting automatically in " :
                   root.directAct === "off" ? "Turning off automatically in " : "Logging out automatically in ")
                  + root.remaining + " seconds."
                : ""
        onAccepted: if (root.isPrimary) root.run(root.directAct)
        onRejected: root.cancel()
    }
}
