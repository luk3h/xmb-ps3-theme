// XMB PS3 - PlayStation 3 "select a user" style SDDM login theme (Qt 6)
// Up/Down: choose user   Enter: sign in   Tab / Options: session + power panel
import QtQuick
import QtQuick.Window

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#00063a"

    // Only draw the menus on the main monitor; other monitors just get the background
    readonly property bool showUi: (typeof primaryScreen === "undefined") ? true : primaryScreen
    readonly property real s: height / 1080
    readonly property bool isPrimaryForSync: showUi
    readonly property bool dialogUp: confirm.open || confirm.busy
    readonly property string fontName: "Noto Sans"

    property int userIdx: Math.max(0, (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0)
    property int sessionIdx: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool optionsOpen: false
    property int optIdx: 0
    property bool busy: false
    property string statusText: ""

    readonly property real listX: width * 0.24
    readonly property real selY: height * 0.40
    readonly property real itemGap: 92 * s
    readonly property int sessCount: sessRep.count
    readonly property int optCount: sessCount + powerModel.count

    function itemY(i, cur) {
        if (i === cur) return selY
        if (i < cur) return selY - (cur - i) * itemGap - 10 * s
        return selY + (i - cur) * itemGap + 50 * s
    }
    // get keyboard focus on the main monitor straight away, no click needed
    function grabFocus() {
        if (!showUi) return
        if (Window.window) Window.window.requestActivate()
        if (confirm.open) return
        focusRight()
    }
    Timer { interval: 100; running: true; onTriggered: root.grabFocus() }
    // at startup KDE may not hand over the keyboard straight away, so keep asking (for up to 15 s)
    property real startedAt: Date.now()
    Timer {
        id: focusRetry
        interval: 400; repeat: true
        running: root.showUi && !Window.active
        onTriggered: { if (Date.now() - root.startedAt > 15000) stop(); else root.grabFocus() }
    }
    function focusRight() {
        if (optionsOpen || !showUi) keyCatcher.forceActiveFocus()
        else password.focusInput()
    }
    function setUser(v) {
        if (userRep.count <= 0) return
        v = Math.max(0, Math.min(userRep.count - 1, v))
        if (v !== userIdx) { userIdx = v; password.clear() }
    }
    function openOptions(open) {
        optionsOpen = open
        if (open) optIdx = sessionIdx
        focusRight()
    }
    function login() {
        if (busy) return
        var u = userRep.itemAt(userIdx)
        if (!u) return
        if (password.text.length === 0) { statusText = "Type your password first."; statusTimer.restart(); password.shake(false); return }
        busy = true
        statusText = "Checking password..."
        loginWatchdog.restart()
        pendingUser = u.uName
        pendingPass = password.text
        broadcast("black")                 // both monitors fade out together...
        sendLogin.restart()                // ...then the password goes to SDDM
    }
    property string pendingUser: ""
    property string pendingPass: ""
    // preview (sddm-greeter-qt6 --test-mode / scripts/preview.sh login): SDDM ignores sign-in and
    // power buttons there, so we fade back in and say so instead of sitting on a black screen
    readonly property bool previewMode: Qt.application.arguments.indexOf("--test-mode") >= 0
    readonly property string previewNote: "Preview only - this can't sign in or turn anything off. Press Ctrl+Q to exit."
    Timer {
        id: sendLogin; interval: 220
        onTriggered: {
            if (root.previewMode) { root.pendingPass = ""; previewBack.start(); return }
            sddm.login(root.pendingUser, root.pendingPass, root.sessionIdx); root.pendingPass = ""
        }
    }
    Timer {
        id: previewBack; interval: 1200
        onTriggered: {
            loginWatchdog.stop()
            root.busy = false
            if (root.showUi) root.broadcast("clear")
            password.clear()
            root.statusText = root.previewNote
            statusTimer.interval = 8000; statusTimer.restart()
            root.focusRight()
        }
    }
    function activateOption() {
        if (optIdx < sessCount) { sessionIdx = optIdx; openOptions(false); return }
        var a = powerModel.get(optIdx - sessCount).act
        optionsOpen = false
        askPower(a)
    }
    function askPower(act) {
        confirm.pendingAct = act
        if (act === "reboot") confirm.ask("Restart System", "Restart the system?", "restart", "Restarting...")
        else if (act === "off") confirm.ask("Turn Off System", "Turn off the system?", "power", "Turning off...")
        else if (act === "suspend") confirm.ask("Sleep", "Put the system to sleep?", "suspend", "Going to sleep...")
        else if (act === "hibernate") confirm.ask("Hibernate", "Hibernate the system?", "hibernate", "Hibernating...")
    }
    function doPower(act) {
        if (act === "reboot") sddm.reboot()
        else if (act === "off") sddm.powerOff()
        else if (act === "suspend") sddm.suspend()
    }
    function afterDialog() { focusRight() }
    function handleKey(event) {
        var k = event.key
        if (optionsOpen) {
            if (k === Qt.Key_Up) optIdx = Math.max(0, optIdx - 1)
            else if (k === Qt.Key_Down) optIdx = Math.min(optCount - 1, optIdx + 1)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) activateOption()
            else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Escape || k === Qt.Key_Left || k === Qt.Key_Backspace) openOptions(false)
            else return
            event.accepted = true
            return
        }
        if (k === Qt.Key_Up) { setUser(userIdx - 1); event.accepted = true }
        else if (k === Qt.Key_Down) { setUser(userIdx + 1); event.accepted = true }
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { login(); event.accepted = true }
        else if (k === Qt.Key_Tab || k === Qt.Key_Backtab || k === Qt.Key_Menu || k === Qt.Key_Escape) { openOptions(true); event.accepted = true }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            loginWatchdog.stop()
            if (root.showUi) root.broadcast("clear")    // wrong password: both monitors fade back in
            busy = false
            password.clear()
            statusText = "The password is incorrect."
            statusTimer.restart()
            password.shake(true)
            focusRight()
        }
        function onLoginSucceeded() {
            statusText = "Signing in..."
        }
    }
    Timer { id: statusTimer; interval: 3500; onTriggered: { interval = 3500; if (!busy) statusText = "" } }
    // safety net: if signing in never answers (e.g. in test mode), let you try again
    Timer {
        id: loginWatchdog
        interval: 30000
        onTriggered: {
            if (!busy) return
            busy = false
            if (root.showUi) root.broadcast("clear")
            password.clear()
            statusText = "Please try again."
            statusTimer.restart()
            focusRight()
        }
    }

    ListModel {
        id: powerModel
        ListElement { label: "Sleep";           icon: "suspend"; act: "suspend" }
        ListElement { label: "Restart System";  icon: "restart"; act: "reboot" }
        ListElement { label: "Turn Off System"; icon: "power";   act: "off" }
    }

    XmbBackground { anchors.fill: parent }

    Item {
        id: ui
        anchors.fill: parent
        visible: root.showUi
        opacity: 0
        Component.onCompleted: { fadeIn.start(); root.focusRight() }
        NumberAnimation { id: fadeIn; target: ui; property: "opacity"; to: 1; duration: 900; easing.type: Easing.OutCubic }

        Item {
            id: keyCatcher
            focus: true
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
            text: "Select a user."
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

        // ----- user column -----
        Item {
            anchors.fill: parent
            opacity: root.dialogUp ? 0 : (root.optionsOpen ? 0.45 : 1)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Repeater {
                id: userRep
                model: (typeof userModel !== "undefined") ? userModel : 0
                XmbItem {
                    s: root.s; baseX: root.listX; fontName: root.fontName
                    property string uName: model.name
                    selected: index === root.userIdx
                    iconSource: model.icon ? model.icon : ""
                    label: (model.realName && model.realName !== "") ? model.realName : model.name
                    y: root.itemY(index, root.userIdx)
                    onClicked: { root.setUser(index); root.focusRight() }
                }
            }

            PasswordBox {
                id: password
                s: root.s; fontName: root.fontName
                busy: root.busy
                x: root.listX + 80 * root.s
                y: root.selY + 62 * root.s
                onKeyPressed: (event) => root.handleKey(event)
            }
        }

        // ----- bottom-right hints -----
        Row {
            anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.rightMargin: 70 * root.s; anchors.bottomMargin: 60 * root.s
            spacing: 14 * root.s
            opacity: (root.dialogUp || root.optionsOpen) ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            HintButton {
                s: root.s; fontName: root.fontName
                keyText: "Tab"; label: root.optionsOpen ? "Back" : "Options"
                onClicked: root.openOptions(!root.optionsOpen)
            }
            HintButton {
                s: root.s; fontName: root.fontName
                keyText: "Enter"; label: root.optionsOpen ? "Select" : "Sign In"
                onClicked: root.optionsOpen ? root.activateOption() : root.login()
            }
        }

        Text {
            anchors.left: parent.left; anchors.bottom: parent.bottom
            anchors.leftMargin: 70 * root.s; anchors.bottomMargin: 72 * root.s
            color: "#b0ffffff"
            font.family: root.fontName; font.pixelSize: 18 * root.s
            text: {
                var it = sessRep.itemAt(root.sessionIdx)
                return it ? "Session: " + it.label : ""
            }
        }

        // ----- Options panel (slides in from the right, like the PS3 triangle menu) -----
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
                HintButton { s: root.s; fontName: root.fontName; keyText: "Enter"; label: "Select"; onClicked: root.activateOption() }
            }

            Column {
                id: optCol
                x: 50 * root.s
                y: root.height * 0.28
                width: parent.width - 80 * root.s
                spacing: 4 * root.s

                Text { text: "Session"; color: "#90ffffff"; font.family: root.fontName; font.pixelSize: 18 * root.s; bottomPadding: 6 * root.s }
                Repeater {
                    id: sessRep
                    model: (typeof sessionModel !== "undefined") ? sessionModel : 0
                    OptionRow {
                        property string label: model.name
                        s: root.s; fontName: root.fontName
                        width: optCol.width
                        text: model.name
                        iconSource: index === root.sessionIdx ? "assets/check.png" : ""
                        highlighted: root.optionsOpen && root.optIdx === index
                        onClicked: { root.optIdx = index; root.activateOption() }
                    }
                }
                Item { width: 1; height: 26 * root.s }
                Text { text: "Power"; color: "#90ffffff"; font.family: root.fontName; font.pixelSize: 18 * root.s; bottomPadding: 6 * root.s }
                Repeater {
                    model: powerModel
                    OptionRow {
                        s: root.s; fontName: root.fontName
                        width: optCol.width
                        text: model.label
                        iconSource: "assets/" + model.icon + ".png"
                        highlighted: root.optionsOpen && root.optIdx === root.sessCount + index
                        onClicked: { root.optIdx = root.sessCount + index; root.activateOption() }
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
                if (root.previewMode) { previewPower.start(); return }
                root.doPower(a)
                if (a === "suspend" || a === "hibernate") wakeTimer.start()   // bring the screen back after waking
                else busyFailsafe.start()
            })
        }
        onRejected: { close(); root.afterDialog() }
    }
    // if the system doesn't go down (e.g. blocked), give the screen back
    // Timers don't count while the PC is asleep, so this fires shortly after it wakes up
    Timer {
        id: previewPower; interval: 1000
        onTriggered: {
            confirm.unfade()
            root.statusText = root.previewNote
            statusTimer.interval = 8000; statusTimer.restart()
            root.afterDialog()
        }
    }
    Timer { id: wakeTimer; interval: 2500; onTriggered: { confirm.unfade(); root.afterDialog() } }
    Timer {
        id: busyFailsafe; interval: 20000
        onTriggered: {
            confirm.unfade()
            root.statusText = "The system did not respond. Please try again."
            statusTimer.interval = 15000; statusTimer.restart()
            root.afterDialog()
        }
    }
    }


    Rectangle {
        id: leaveCover
        anchors.fill: parent
        color: "black"
        z: 1001
        opacity: 0
        NumberAnimation on opacity { id: leaveFade; running: false; to: 1; duration: 250; easing.type: Easing.InQuad }
    }

    // ---- fades shared by every monitor ----
    // SDDM gives each monitor its own separate copy of this screen. They all live in one program,
    // so the main copy "broadcasts" by changing the program's display name (harmless; nothing shows it),
    // and every copy reacts to that.
    function broadcast(cmd) { Qt.application.displayName = "xmb:" + cmd + ":" + Date.now() }
    // main monitor: once it's drawn, tell every monitor to fade in together.
    // Straight after a restart the monitors are still waking up, so wait longer then.
    property int arriveDelay: 300
    Timer { id: arriveTimer; interval: root.arriveDelay; onTriggered: root.broadcast("arrive") }
    function checkUptime() {
        // /proc/uptime = seconds since the PC started (needs QML_XHR_ALLOW_FILE_READ=1 for SDDM)
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            var up = parseFloat(("" + xhr.responseText).split(" ")[0])
            if (root.arriveStarted) return                        // fallback already went
            root.arriveStarted = true
            if (!isNaN(up) && up < 90) root.arriveDelay = 2500     // just booted: give the second monitor time to wake from standby
            arriveTimer.restart()
        }
        try {
            xhr.open("GET", "file:///proc/uptime")
            xhr.send()
        } catch (e) {
            root.arriveStarted = true
            arriveTimer.restart()
        }
    }
    // if reading the file is blocked or never answers, carry on with the normal timing
    property bool arriveStarted: false
    Timer { id: uptimeFallback; interval: 250; onTriggered: if (!root.arriveStarted) { root.arriveStarted = true; arriveTimer.restart() } }
    // a monitor that started after the signal catches up straight away; and nobody stays black forever
    Component.onCompleted: {
        if (root.showUi) { checkUptime(); uptimeFallback.start() }
        var parts = ("" + Qt.application.displayName).split(":")
        if (parts[0] === "xmb" && parts[1] === "arrive" && Date.now() - Number(parts[2]) < 3000) sharedCover.opacity = 0
    }
    Timer {
        interval: 4500; running: true
        onTriggered: if (sharedCover.opacity > 0.99 && !root.busy && !confirm.busy) { sharedFade.pause = 0; sharedFade.to = 0; sharedFade.dur = 350; sharedFade.restart() }
    }
    Connections {
        target: Qt.application
        function onDisplayNameChanged() {
            var parts = ("" + Qt.application.displayName).split(":")
            if (parts[0] !== "xmb") return
            var cmd = parts[1]
            if (cmd === "quit") { root.closePreviewWindow(); return }
            sharedFade.stop()
            if (cmd === "black")      { sharedFade.pause = 0;   sharedFade.to = 1; sharedFade.dur = 200 }
            else if (cmd === "power") { sharedFade.pause = 900; sharedFade.to = 1; sharedFade.dur = 450 }
            else if (cmd === "clear") { sharedFade.pause = 0;   sharedFade.to = 0; sharedFade.dur = 250 }
            else if (cmd === "arrive") { sharedFade.pause = 0;  sharedFade.to = 0; sharedFade.dur = 350 }
            else return
            sharedFade.restart()
        }
    }
    Rectangle {
        id: sharedCover
        anchors.fill: parent
        color: "black"
        z: 2000
        opacity: 1          // start black; fade in when the main monitor says "arrive"
    }
    SequentialAnimation {
        id: sharedFade
        property int pause: 0
        property real to: 1
        property int dur: 200
        PauseAnimation { duration: sharedFade.pause }
        NumberAnimation { target: sharedCover; property: "opacity"; to: sharedFade.to; duration: sharedFade.dur; easing.type: Easing.InOutQuad }
    }
    Connections {
        target: confirm
        function onBusyChanged() {
            if (!root.showUi) return
            root.broadcast(confirm.busy ? "power" : "clear")
        }
    }

    // ---- preview only: an always-visible way out, even while the screen is faded to black ----
    // SDDM's preview ignores Qt.quit(), but closing the windows ends it (like Alt+F4).
    // Every monitor has its own window, so tell them all to close.
    function exitPreview() { if (root.previewMode) root.broadcast("quit") }
    function closePreviewWindow() { if (root.previewMode && root.Window.window) root.Window.window.close() }
    Shortcut { sequence: "Ctrl+Q"; enabled: root.previewMode; onActivated: root.exitPreview() }
    HintButton {
        visible: root.previewMode
        z: 5000
        s: root.s; fontName: root.fontName
        keyText: "Ctrl+Q"; label: "Exit preview"
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 24 * root.s
        onClicked: root.exitPreview()
    }
}
