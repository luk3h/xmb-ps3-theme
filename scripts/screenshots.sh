#!/usr/bin/env bash
# Takes the README screenshots automatically, each in a different hour's wave colour,
# and saves them into docs/ (1920 px wide JPEGs with no hidden metadata).
#
#   scripts/screenshots.sh            # all of them
#   scripts/screenshots.sh lock       # just the ones whose name contains "lock"
#
# Needs: the theme installed (./install.sh), spectacle (KDE's screenshot tool) and ffmpeg.
# Keep the mouse still on your main monitor while it runs - that's the monitor it captures.
# The Shut Down power menu (docs/power-menu.jpg) has no wave colour, so it isn't retaken.

set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/docs"
CONF=/tmp/xmb-preview.conf
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" "$CONF"' EXIT
export QML_XHR_ALLOW_FILE_READ=1     # lets the previews read $CONF

for c in spectacle ffmpeg sddm-greeter-qt6; do
    command -v "$c" >/dev/null || { echo "Missing: $c (install it first)"; exit 1; }
done
[ -d /usr/share/sddm/themes/xmb-ps3 ] || { echo "Install the theme first: ./install.sh"; exit 1; }

# name : which screen : hour (picks the colour) : what to open
# colours by hour: 9 purple, 10 magenta, 11 crimson, 12 gold, 13 green, 14 teal, 15 silver, 16 blue
SHOTS="
login:login:16:
login-options:login:9:options
restart-confirm:login:12:restart
turnoff-confirm:login:14:off
lock:lock:11:
lock-options:lock:13:options
wave:login:10:wave
"

shoot() {   # shoot NAME SCREEN HOUR SHOW
    local name=$1 screen=$2 hour=$3 show=$4 pid
    printf 'hour=%s\nshow=%s\n' "$hour" "$show" > "$CONF"
    if [ "$screen" = login ]; then
        sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/xmb-ps3 >/dev/null 2>&1 &
    else
        /usr/libexec/kscreenlocker_greet --testing >/dev/null 2>&1 &
    fi
    pid=$!
    sleep 8                                   # let it fade in, open the panel, and the banner fade out
    spectacle -b -n -m -o "$TMP/$name.png" </dev/null    # background, no notification, monitor under the mouse
    sleep 1
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    if [ -f "$TMP/$name.png" ]; then
        ffmpeg -nostdin -loglevel error -y -i "$TMP/$name.png" -vf "scale=1920:-2" -map_metadata -1 -q:v 3 "$OUT/$name.jpg" \
            && echo "  ✓ docs/$name.jpg (hour $hour)"
    else
        echo "  ! $name: no screenshot taken"
    fi
    sleep 2
}

echo "Taking screenshots - don't touch the mouse or keyboard (about $(( $(echo "$SHOTS" | grep -c :) * 11 )) seconds)..."
echo "$SHOTS" | while IFS=: read -r name screen hour show; do
    [ -n "$name" ] || continue
    case "$name" in *"${1:-}"*) shoot "$name" "$screen" "$hour" "$show" ;; esac
done
echo "Done. Check them in docs/, then: git add docs && git commit -m 'New screenshots' && git push"
