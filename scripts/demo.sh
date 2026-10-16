#!/usr/bin/env bash
# Plays a smooth, evenly timed demo of the theme for filming: lock screen, Options, the
# Restart question, a wrong password, unlocking, the Shut Down question and the power menu.
# It presses the keys for you (with ydotool), so every move has exactly the same rhythm.
#
#   scripts/demo.sh                  # records it with GPU Screen Recorder (main monitor, with sound)
#   scripts/demo.sh --hour 16        # ...with the wave in that hour's colour (9 purple ... 16 blue)
#   scripts/demo.sh --no-record      # don't record (e.g. to film it some other way)
#   scripts/demo.sh --login          # the login screen instead (its preview - what you see after
#                                    #   booting or from Other User): users, Options, Restart? No
#
# The real lock screen can't be screen-recorded cleanly (the recorder grabs the wrong layer),
# so while recording, the lock screen part uses the lock screen preview, which looks the same.
#
# It never types your real password: when it's time to unlock, it waits for you to type it,
# then carries on by itself.
#
# Needs ydotool:  sudo dnf install ydotool     (Ubuntu/Debian: sudo apt install ydotool)
# Before running: quit GPU Screen Recorder's app (its hotkeys grab the keyboard), stop any
# Discord screen share (it steals the sounds) and turn on Do Not Disturb.

set -u

# ---- timing (seconds) - change these to make it faster or slower ----
MOVE=0.55        # between Up/Down/Left/Right presses
LOOK=1.6         # pause to let each new screen be seen
OPEN=3.0         # after the lock screen / a panel appears
WRONG="wrongpass"
SCREEN="DP-1"                                         # monitor to record (see --list-capture-options)
OUTFILE="$HOME/Videos/xmb-demo-$(date +%H%M%S).mp4"

RECORD=1 HOUR="" LOGIN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-record) RECORD=0 ;;
        --login) LOGIN=1 ;;
        --hour) HOUR="${2:-}"; shift ;;
        --screen) SCREEN="${2:-}"; shift ;;
        -o) OUTFILE="${2:-}"; shift ;;
        *) echo "Usage: scripts/demo.sh [--no-record] [--hour H] [--screen DP-1] [-o FILE]"; exit 1 ;;
    esac
    shift
done
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONF=/tmp/xmb-preview.conf

command -v ydotool >/dev/null && command -v ydotoold >/dev/null \
    || { echo "Needs ydotool: sudo dnf install ydotool"; exit 1; }
if pgrep -f gsr-global-hotkeys >/dev/null; then
    echo "GPU Screen Recorder's app is running - quit it first (its hotkeys grab the keyboard)."; exit 1
fi

# ---- start the key-press helper (it needs admin rights to create a virtual keyboard) ----
SOCK="${XDG_RUNTIME_DIR:-/tmp}/.xmb-ydotool.sock"
export YDOTOOL_SOCKET="$SOCK"
echo "Starting the virtual keyboard (asks for your password once)..."
sudo -v || exit 1
sudo ydotoold --socket-path="$SOCK" --socket-own="$(id -u):$(id -g)" >/dev/null 2>&1 &
YD=$!
# (the helper is stopped by cleanup, below)

# ---- the recorder (installed normally or as a Flatpak) ----
if command -v gpu-screen-recorder >/dev/null; then GSR=(gpu-screen-recorder)
else GSR=(flatpak run --command=gpu-screen-recorder com.dec05eba.gpu_screen_recorder); fi
if [ "$RECORD" = 1 ] && ! "${GSR[@]}" --list-capture-options >/dev/null 2>&1; then
    echo "GPU Screen Recorder not found - install it, or run with --no-record."; exit 1
fi
mkdir -p "$(dirname "$OUTFILE")"
REC=""
start_recording() {
    "${GSR[@]}" -w "$SCREEN" -f 60 -a default_output -o "$OUTFILE" >/tmp/xmb-demo-recorder.log 2>&1 &
    REC=$!
    sleep 2
    kill -0 "$REC" 2>/dev/null || { echo "The recorder didn't start - see /tmp/xmb-demo-recorder.log"; exit 1; }
}
stop_recording() {   # Ctrl+C equivalent, sent to the recorder itself (not just the Flatpak wrapper)
    [ -n "$REC" ] || return 0
    pkill -INT -f "gpu-screen-recorder.*$OUTFILE" 2>/dev/null
    wait "$REC" 2>/dev/null; REC=""
}
cleanup() { stop_recording; sudo kill "$YD" 2>/dev/null; sudo rm -f "$SOCK"; rm -f "$CONF"; }
trap cleanup EXIT
{ echo "banner=off"; [ -n "$HOUR" ] && echo "hour=$HOUR"; } > "$CONF"      # no "Preview" banner in the video
export QML_XHR_ALLOW_FILE_READ=1     # lets the lock preview read the colour
for _ in $(seq 20); do [ -S "$SOCK" ] && break; sleep 0.2; done
[ -S "$SOCK" ] || { echo "The virtual keyboard didn't start."; exit 1; }

# Linux key codes: Esc 1, Enter 28, Tab 15, Up 103, Left 105, Right 106, Down 108
key()  { ydotool key "$1:1" "$1:0" >/dev/null; }
tap()  { key "$1"; sleep "$MOVE"; }                      # tap KEY: press, then the usual gap
type_text() { ydotool type --key-delay 70 "$1" >/dev/null; }
locked() { [ "$(loginctl show-session "${XDG_SESSION_ID:-auto}" -p LockedHint --value 2>/dev/null)" = yes ]; }
prompt() { dbus-send --session --type=method_call --dest=org.kde.LogoutPrompt /LogoutPrompt "org.kde.LogoutPrompt.$1"; }

# How many Downs from Sleep to Restart in the lock screen's Options (depends on what the PC can do)
can() { busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$1" 2>/dev/null | grep -qE '"(yes|challenge)"'; }
TO_RESTART=0
can CanSuspend && TO_RESTART=$((TO_RESTART + 1))
can CanHibernate && TO_RESTART=$((TO_RESTART + 1))

echo
if [ "$RECORD" = 1 ]; then
    echo "Recording to: $OUTFILE"
    echo "Put the mouse in the bottom-right corner of $SCREEN. Starting in 5 seconds - don't touch"
else
    echo "Start filming now. The demo begins in 5 seconds - don't touch"
fi
echo "the keyboard or mouse until it asks for your password."
for i in 5 4 3 2 1; do printf '  %s\r' "$i"; sleep 1; done; echo
[ "$RECORD" = 1 ] && start_recording

# ---------------------------------------------------------------- the login screen (--login)
if [ "$LOGIN" = 1 ]; then
    command -v sddm-greeter-qt6 >/dev/null || { echo "SDDM's greeter isn't installed."; exit 1; }
    # Options lists the sessions first (starting on the current one), then Sleep, Restart, Turn Off
    SESSIONS=$(ls /usr/share/wayland-sessions/*.desktop /usr/share/xsessions/*.desktop 2>/dev/null | wc -l)
    TO_RESTART=$(( SESSIONS + 1 ))

    sleep "$LOOK"
    sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/xmb-ps3 >/dev/null 2>&1 &
    GREETER=$!
    sleep 3.5                                   # let it fade in (the banner is switched off)

    USERS=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/' | wc -l)
    for _ in $(seq $((USERS - 1))); do tap 108; done; sleep "$LOOK"   # down the user column...
    for _ in $(seq $((USERS - 1))); do tap 103; done; sleep 1         # ...and back up

    tap 15; sleep "$LOOK"                       # Tab: Options (session + power)
    for _ in $(seq "$TO_RESTART"); do tap 108; done
    sleep 1
    tap 28; sleep "$LOOK"                       # Enter: "Restart the system?"
    tap 106; sleep 1                            # Right: No
    tap 28; sleep "$LOOK"                       # Enter: back

    tap 28; sleep "$LOOK"                       # empty Enter: "Type your password first."
    sleep 1
    ydotool key 29:1 16:1 16:0 29:0 >/dev/null  # Ctrl+Q: close the preview
    wait "$GREETER" 2>/dev/null
    sleep 1
    stop_recording
    [ "$RECORD" = 1 ] && echo "Done - saved: $OUTFILE" || echo "Done - stop filming."
    exit 0
fi

# 1. desktop, then lock (the preview while recording, the real one otherwise)
sleep "$LOOK"
if [ "$RECORD" = 1 ]; then
    /usr/libexec/kscreenlocker_greet --testing >/dev/null 2>&1 &
    LOCK=$!
    locked() { kill -0 "$LOCK" 2>/dev/null; }      # the preview closes when you unlock
    sleep 3.5                                       # let it fade in (the banner is switched off)
else
    loginctl lock-session
    sleep "$OPEN"
fi

# 2. the user column: Other User and back
tap 108; sleep "$LOOK"; tap 103; sleep 1

# 3. Options panel -> Restart -> "Restart the system?" -> No -> close the panel
tap 15; sleep "$LOOK"
for _ in $(seq "$TO_RESTART"); do tap 108; done
sleep 1
tap 28; sleep "$LOOK"                    # Enter: the Restart question (Yes is selected)
tap 106; sleep 1                         # Right: No
tap 28; sleep "$LOOK"                    # Enter: back to the lock screen

# 4. empty password, then a wrong one
tap 28; sleep "$LOOK"                    # "Type your password first."
type_text "$WRONG"; sleep 0.4
tap 28; sleep 4                          # "The password is incorrect." (+ the checker's pause)

# 5. your turn: unlock
echo ">>> Type your password on the lock screen and press Enter. (The demo waits for you.)"
while locked; do sleep 0.3; done
sleep "$OPEN"

# 6. the Shut Down question (Start -> Shut Down) -> No
prompt promptShutDown; sleep "$OPEN"
tap 106; sleep 1                         # Right: No
tap 28; sleep "$LOOK"

# 7. the full power menu (Ctrl+Alt+Del): move along it, then Esc
prompt promptAll; sleep "$OPEN"
tap 105; tap 105; sleep 0.6; tap 106; tap 106; tap 106; sleep 1
tap 1; sleep "$LOOK"

if [ "$RECORD" = 1 ]; then
    stop_recording
    echo "Done - saved: $OUTFILE"
else
    echo "Done - stop filming."
fi
