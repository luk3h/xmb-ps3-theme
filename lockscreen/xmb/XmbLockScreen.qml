// XMB PS3 lock screen for KDE Plasma 6 — matches the XMB PS3 login screen.
// Enter: unlock   Down: Other User   Tab: Options (Sleep / Hibernate / Restart / Turn Off)
import QtQuick
import QtQuick.Window
import org.kde.plasma.private.sessions

Item {
    id: root
    readonly property real s: height / 1080
    readonly property bool dialogUp: confirm.open || confirm.busy
    readonly property bool isPrimaryForSync: isPrimary
    // Only the main (biggest) monitor shows the login box. KDE copies every key press to all
    // monitors, so typing still reaches it wherever the keyboard focus happens to be.
    readonly property bool isPrimary: {
        var scr = Qt.application.screens
        if (!scr || scr.length < 2) return true
        var maxArea = 0
        for (var i = 0; i < scr.length; i++) maxArea = Math.max(maxArea, scr[i].width * scr[i].height)
        var myArea = (Screen.width > 0) ? Screen.width * Screen.height : root.width * root.height
        return myArea >= maxArea - 1
    }
    readonly property string fontName: "Noto Sans"
    readonly property real listX: width * 0.24
    readonly property real selY: height * 0.40
    property bool busy: false
    property string statusText: ""
    property bool optionsOpen: false
    // user column: 0 = you, 1 = "Other User..." (goes to the login screen's full user list)
    property int userSel: 0
    readonly property bool hasOther: sm.canSwitchUser
    readonly property real itemGap: 92 * s
    function itemY(i, cur) {
        if (i === cur) return selY
        if (i < cur) return selY - (cur - i) * itemGap - 10 * s
        return selY + (i - cur) * itemGap + 50 * s
    }
    function setUserSel(v) {
        if (!hasOther) v = 0
        userSel = Math.max(0, Math.min(1, v))
        if (userSel === 0) password.focusInput()
        else keyCatcher.forceActiveFocus()
    }
    property int optIdx: 0

    readonly property string userName: (typeof kscreenlocker_userName !== "undefined") ? kscreenlocker_userName : ""
    readonly property string userImage: (typeof kscreenlocker_userImage !== "undefined") ? ("" + kscreenlocker_userImage) : ""

    // KDE's session controls (the same object KDE's own lock screen uses)
    SessionManagement { id: sm }

    // Options shown in the panel, only the ones your system allows
    readonly property var actions: {
        var a = []
        if (sm.canSuspend)    a.push({ label: "Sleep",           icon: "suspend",   act: "suspend",   section: "power" })
        if (sm.canHibernate)  a.push({ label: "Hibernate",       icon: "hibernate", act: "hibernate", section: "power" })
        if (sm.canReboot)     a.push({ label: "Restart System",  icon: "restart",   act: "reboot",    section: "power" })
        if (sm.canShutdown)   a.push({ label: "Turn Off System", icon: "power",     act: "off",       section: "power" })
        return a
    }
    // the session you're in (shown greyed out: it can only be changed from the login screen)
    readonly property string sessionName: Qt.platform.pluginName === "xcb" ? "Plasma (X11)" : "Plasma (Wayland)"

    // PAM (KDE's password checker) only accepts a password after it has asked for one.
    // After a wrong password it pauses briefly, so we hold the password until it's ready.
    property bool pamReady: true      // ready at first; after a failure we wait for a new prompt
    property int retries: 0
    property string pending: ""
    property bool hasPending: false

    // get keyboard focus on the main monitor straight away, no click needed
    function grabFocus() {
        startAuth()
        if (!isPrimary) return
        if (Window.window) Window.window.requestActivate()
        if (confirm.open) return
        if (optionsOpen || userSel === 1) keyCatcher.forceActiveFocus()
        else password.focusInput()
    }
    Timer { interval: 100; running: true; onTriggered: root.grabFocus() }
    Timer { interval: 600; running: true; onTriggered: root.grabFocus() }
    // fade to black, then hand over to the login screen; fade back in when you return
    // every monitor fades (key presses reach all of them); only the main one does the switch
    function goOtherUser() {
        if (!isPrimary) return
        if (!switchFade.running) switchFade.restart()
    }

    // start KDE's password checker on the main monitor - as soon as we know we ARE the main monitor
    property bool authStarted: false
    function startAuth() {
        if (!isPrimary || authStarted) return
        authStarted = true
        authenticator.startAuthenticating()
    }
    onIsPrimaryChanged: startAuth()

    function unlock() {
        if (!isPrimary) return
        if (!authStarted) { startAuth(); pamReady = false }   // checker wasn't running: start it, send when it asks
        if (busy) return
        if (password.text.length === 0) { statusText = "Type your password first."; statusTimer.restart(); password.shake(false); return }
        busy = true
        statusText = "Checking password..."
        pending = password.text
        hasPending = true
        retries = 0
        watchdog.restart()
        quickRetry.restart()
        sendPending()
    }
    function sendPending() {
        if (!hasPending || !pamReady) return
        hasPending = false
        pamReady = false
        authenticator.respond(pending)
        pending = ""
    }
    function resetAuth() {
        busy = false
        hasPending = false
        pending = ""
        pamReady = false
        authenticator.startAuthenticating()
        if (!optionsOpen) password.focusInput()
    }
    function openOptions(open) {
        if (open && actions.length === 0) return
        optionsOpen = open
        optIdx = 0
        if (!open) password.focusInput()
        else keyCatcher.forceActiveFocus()
    }
    function runAction(i) {
        if (!isPrimary) return
        var a = actions[i]
        if (!a) return
        openOptions(false)
        if (a.act === "switch") sm.switchUser()
        else root.askPower(a.act)
    }
    function askPower(act) {
        confirm.pendingAct = act
        if (act === "reboot") confirm.ask("Restart System", "Restart the system?", "restart", "Restarting...")
        else if (act === "off") confirm.ask("Turn Off System", "Turn off the system?", "power", "Turning off...")
        else if (act === "suspend") confirm.ask("Sleep", "Put the system to sleep?", "suspend", "Going to sleep...")
        else if (act === "hibernate") confirm.ask("Hibernate", "Hibernate the system?", "hibernate", "Hibernating...")
    }
    function doPower(act) {
        if (!isPrimary) return
        if (act === "reboot") sm.requestReboot(0)      // 0 = skip KDE's own confirmation
        else if (act === "off") sm.requestShutdown(0)
        else if (act === "suspend") sm.suspend()
        else if (act === "hibernate") sm.hibernate()
    }
    function afterDialog() { password.focusInput() }
    function handleKey(event) {
        var k = event.key
        if (optionsOpen) {
            if (k === Qt.Key_Up) optIdx = Math.max(0, optIdx - 1)
            else if (k === Qt.Key_Down) optIdx = Math.min(actions.length - 1, optIdx + 1)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) runAction(optIdx)
            else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Escape || k === Qt.Key_Left || k === Qt.Key_Backspace) openOptions(false)
            else return
            event.accepted = true
            return
        }
        if (k === Qt.Key_Up) { setUserSel(userSel - 1); event.accepted = true }
        else if (k === Qt.Key_Down) { setUserSel(userSel + 1); event.accepted = true }
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (userSel === 1) { root.goOtherUser() }
            else unlock()
            event.accepted = true
        }
        else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Menu) { openOptions(true); event.accepted = true }
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind !== 0) return            // ignore fingerprint/smartcard noise
            watchdog.stop()
            busy = false
            hasPending = false
            pending = ""
            pamReady = false
            password.clear()
            statusText = "The password is incorrect."
            password.shake(true)
            statusTimer.restart()
            restartTimer.restart()
        }
        function onSucceeded() { unlockFade.start() }
        function onPromptForSecretChanged() {
            pamReady = true
            if (hasPending) sendPending()
            else if (!root.optionsOpen) password.focusInput()
        }
    }
    Timer { id: statusTimer; interval: 3500; onTriggered: if (!busy) statusText = "" }
    // ask PAM for a new password prompt after a failure
    Timer { id: restartTimer; interval: 3000; onTriggered: if (root.isPrimary) authenticator.startAuthenticating() }
    // password still waiting to be sent after 5 s? ask KDE's checker to start again; it sends when ready
    Timer {
        id: quickRetry
        interval: 5000
        onTriggered: if (root.busy && root.hasPending) { root.authStarted = true; authenticator.startAuthenticating() }
    }
    // safety net: if nothing happens, reset so you can always type again
    Timer {
        id: watchdog
        interval: 30000
        onTriggered: {
            if (!busy) return
            if (hasPending && retries < 1) {
                // password never got sent: ask PAM to prompt again, then it sends automatically
                retries++
                authenticator.startAuthenticating()
                watchdog.restart()
                return
            }
            statusText = "Please try again."
            statusTimer.restart()
            password.clear()
            resetAuth()
        }
    }

    Component.onCompleted: {
        // KDE's own wallpaper doesn't animate on the lock screen, so we draw the wave ourselves
        // and hide KDE's copy underneath to save GPU time.
        if (typeof wallpaper !== "undefined" && wallpaper) wallpaper.visible = false
        startAuth()
        password.focusInput()
    }

    XmbBackground { anchors.fill: parent }

    // second monitor: just the wave and a clock
    Clock {
        visible: !root.isPrimary
        s: root.s; fontName: root.fontName
        anchors.right: parent.right; anchors.top: parent.top
        anchors.rightMargin: 70 * root.s; anchors.topMargin: 60 * root.s
    }

    Item {
        id: ui
        anchors.fill: parent
        visible: root.isPrimary
        opacity: 0
        Component.onCompleted: fadeIn.start()
        NumberAnimation { id: fadeIn; target: ui; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }

        Item {
            id: keyCatcher
            Keys.onPressed: (event) => root.handleKey(event)
        }

        Clock {
            s: root.s; fontName: root.fontName
            anchors.right: parent.right; anchors.top: parent.top
            anchors.rightMargin: 70 * root.s; anchors.topMargin: 60 * root.s
        }

        Text {
            x: root.listX - 56 * root.s
            y: 64 * root.s
            text: "Locked"
            color: "white"; opacity: root.dialogUp ? 0 : 0.9
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.family: root.fontName; font.pixelSize: 26 * root.s
        }
        Text {
            x: root.listX - 56 * root.s
            y: 110 * root.s
            color: "white"
            opacity: text === "" ? 0 : 0.9
            Behavior on opacity { NumberAnimation { duration: 250 } }
            font.family: root.fontName; font.pixelSize: 22 * root.s
            text: root.statusText
        }

        Item {
            anchors.fill: parent
            opacity: root.dialogUp ? 0 : (root.optionsOpen ? 0.45 : 1)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            XmbItem {
                s: root.s; baseX: root.listX; fontName: root.fontName
                selected: root.userSel === 0
                iconSource: root.userImage
                label: root.userName
                y: root.itemY(0, root.userSel)
                onClicked: { root.openOptions(false); root.setUserSel(0) }
            }
            XmbItem {
                visible: root.hasOther
                s: root.s; baseX: root.listX; fontName: root.fontName
                selected: root.userSel === 1
                iconSource: ""
                label: "Other User..."
                y: root.itemY(1, root.userSel)
                onClicked: { if (root.userSel === 1) { root.goOtherUser() } else root.setUserSel(1) }
            }
            Text {
                visible: root.userSel === 1
                x: root.listX + 80 * root.s
                y: root.selY + 68 * root.s
                text: "Press Enter to choose another user."
                color: "#d0ffffff"
                font.family: root.fontName; font.pixelSize: 20 * root.s
            }

            PasswordBox {
                id: password
                visible: root.userSel === 0
                s: root.s; fontName: root.fontName
                busy: root.busy
                x: root.listX + 80 * root.s
                y: root.selY + 62 * root.s
                onKeyPressed: (event) => root.handleKey(event)
            }
        }

        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.rightMargin: 70 * root.s; anchors.bottomMargin: 60 * root.s
            spacing: 14 * root.s
            opacity: (root.dialogUp || root.optionsOpen) ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            HintButton {
                s: root.s; fontName: root.fontName
                visible: root.actions.length > 0
                keyText: "Tab"; label: root.optionsOpen ? "Back" : "Options"
                onClicked: root.openOptions(!root.optionsOpen)
            }
            HintButton {
                s: root.s; fontName: root.fontName
                keyText: "Enter"; label: root.optionsOpen ? "Select" : (root.userSel === 1 ? "Choose User" : "Unlock")
                onClicked: root.optionsOpen ? root.runAction(root.optIdx) : (root.userSel === 1 ? root.goOtherUser() : root.unlock())
            }
        }

        // Options panel, slides in from the right like the PS3 triangle menu
        Rectangle {
            id: panel
            width: 520 * root.s
            height: parent.height
            x: root.optionsOpen ? parent.width - width : parent.width + 10
            // only drawn while open or sliding; no slide animation during startup
            visible: root.optionsOpen || x < parent.width
            property bool ready: false
            Timer { interval: 500; running: true; onTriggered: panel.ready = true }
            Behavior on x { enabled: panel.ready; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#b0000818" }
                GradientStop { position: 1.0; color: "#e0000818" }
            }
            Rectangle { width: Math.max(1, root.s); height: parent.height; color: "#50ffffff" }

            // the panel's own hints (the main ones fade out while it's open)
            Row {
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.rightMargin: 70 * root.s; anchors.bottomMargin: 60 * root.s
                spacing: 14 * root.s
                HintButton { s: root.s; fontName: root.fontName; keyText: "Tab"; label: "Back"; onClicked: root.openOptions(false) }
                HintButton { s: root.s; fontName: root.fontName; keyText: "Enter"; label: "Select"; onClicked: root.runAction(root.optIdx) }
            }
            Column {
                id: optCol
                x: 50 * root.s
                y: root.height * 0.32
                width: parent.width - 80 * root.s
                spacing: 4 * root.s
                Text { text: "Session"; color: "#90ffffff"; font.family: root.fontName; font.pixelSize: 18 * root.s; bottomPadding: 6 * root.s }
                OptionRow {
                    s: root.s; fontName: root.fontName
                    width: optCol.width
                    text: root.sessionName
                    iconSource: "assets/check.png"
                    enabled: false
                    opacity: 0.5
                }
                Repeater {
                    model: root.actions
                    Column {
                        width: optCol.width
                        spacing: 4 * root.s
                        readonly property bool firstPower: modelData.section === "power" &&
                            (index === 0 || root.actions[index - 1].section !== "power")
                        Item { width: 1; height: 22 * root.s; visible: parent.firstPower }
                        Text {
                            visible: parent.firstPower
                            text: "Power"; color: "#90ffffff"
                            font.family: root.fontName; font.pixelSize: 18 * root.s; bottomPadding: 6 * root.s
                        }
                        OptionRow {
                            s: root.s; fontName: root.fontName
                            width: optCol.width
                            text: modelData.label
                            iconSource: "assets/" + modelData.icon + ".png"
                            highlighted: root.optionsOpen && root.optIdx === index
                            onClicked: root.runAction(index)
                        }
                    }
                }
            }
        }
    
    // PS3-style "Restart the system?" box, then "Restarting..."
    ConfirmDialog {
        id: confirm
        s: root.s; fontName: root.fontName
        z: 100
        property string pendingAct: ""
        onAccepted: {
            busyThenFade("", function() {
                var a = confirm.pendingAct
                root.doPower(a)
                if (a === "suspend" || a === "hibernate") wakeTimer.start()   // bring the screen back after waking
                else busyFailsafe.start()
            })
        }
        onRejected: { close(); root.afterDialog() }
    }
    // if the system doesn't go down (e.g. blocked), give the screen back
    // Timers don't count while the PC is asleep, so this fires shortly after it wakes up
    Timer { id: wakeTimer; interval: 2500; onTriggered: { confirm.unfade(); root.afterDialog() } }
    Timer {
        id: busyFailsafe; interval: 20000
        onTriggered: {
            confirm.unfade()
            root.statusText = "An app is waiting \u2014 unlock to see it."
            statusTimer.interval = 15000; statusTimer.restart()
            root.afterDialog()
        }
    }
    }

    // PS3-style exit: box fades out, screen dims, then the desktop appears
    Rectangle {
        id: fadeCover
        anchors.fill: parent
        color: "black"
        opacity: 0
        z: 1000
    }
    SequentialAnimation {
        id: unlockFade
        NumberAnimation { target: ui; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InQuad }
        NumberAnimation { target: XmbSync; property: "black"; to: 1; duration: 320; easing.type: Easing.InOutQuad }
        ScriptAction { script: Qt.quit() }
    }
    // never let the fade stop you getting in
    Timer { running: unlockFade.running; interval: 1500; onTriggered: Qt.quit() }

    SequentialAnimation {
        id: switchFade
        NumberAnimation { target: XmbSync; property: "black"; to: 1; duration: 200; easing.type: Easing.InQuad }
        ScriptAction { script: { if (root.isPrimary) { root.awayAt = Date.now(); root.away = true; sm.switchUser(); returnFallback.restart() } } }
    }
    // stay black while you're on the login screen; fade back in when this screen is shown again
    property bool away: false
    property real awayAt: 0
    property bool winActive: Window.active
    onWinActiveChanged: {
        if (!isPrimary || !away) return
        if (!winActive) { returnFallback.stop(); return }      // we've really left
        if (Date.now() - awayAt < 400) return                   // still the moment of leaving
        comeBack()
    }
    function comeBack() {
        away = false
        returnFallback.stop()
        fadeBackIn.restart()
        grabFocus()
    }
    SequentialAnimation {
        id: fadeBackIn
        PauseAnimation { duration: 900 }    // if you're logging straight back in, KDE unlocks during this and you go black -> desktop
        NumberAnimation { target: XmbSync; property: "black"; to: 0; duration: 450; easing.type: Easing.InOutQuad }
    }
    // if the switch never happened, don't leave you on a black screen
    Timer { id: returnFallback; interval: 6000; onTriggered: if (root.away) root.comeBack() }

    // ---- shared fade, followed by every monitor ----
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: 2000
        opacity: XmbSync.black
    }
    // restart / sleep: wait while "Restarting..." shows, then fade everything to black
    SequentialAnimation {
        id: powerFadeShared
        PauseAnimation { duration: 900 }
        NumberAnimation { target: XmbSync; property: "black"; to: 1; duration: 450; easing.type: Easing.InOutQuad }
    }
    Connections {
        target: confirm
        function onBusyChanged() {
            if (!root.isPrimaryForSync) return
            if (confirm.busy) powerFadeShared.restart()
            else { powerFadeShared.stop(); XmbSync.black = 0 }
        }
    }
}
