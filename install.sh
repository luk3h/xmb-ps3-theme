#!/usr/bin/env bash
# XMB PS3 theme for KDE Plasma 6 - installer
# https://github.com/luk3h/xmb-ps3-theme
#
# Installs (each part can be skipped):
#   login      SDDM login screen            -> /usr/share/sddm/themes/xmb-ps3
#   lock       KDE lock screen              -> /usr/local/share/xmb-lockscreen (+ auto re-apply after updates)
#   leave      Shut Down / Restart screen   -> ~/.local/share/plasma/look-and-feel/com.github.luk3h.xmbps3
#   splash     black login splash           -> same package as "leave"
#   sync       wave clock sync for the "Shader Wallpaper" plugin (desktop, lock and login waves line up)
#   displays   copy your monitor setup (resolution / refresh rate) to the login screen
#
# Run as your normal user (not root); it asks for sudo when it needs it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xmb-ps3"
STATE="$STATE_DIR/backup.conf"
LNF_ID="com.github.luk3h.xmbps3"
LNF_DIR="$HOME/.local/share/plasma/look-and-feel/$LNF_ID"
SHELL_LOCK="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen"
SDDM_THEME_DIR="/usr/share/sddm/themes/xmb-ps3"
SDDM_ZZ="/etc/sddm.conf.d/zz-xmb-ps3.conf"
WP_ID="online.knowmad.shaderwallpaper"

DO_LOGIN=1 DO_LOCK=1 DO_LEAVE=1 DO_SPLASH=1 DO_SYNC=1 DO_DISPLAYS=1
SHADER=""
ASSUME_YES=0
USE_SDDM=0
STILL_WAVE=auto
CHOOSE=0
SOUNDS=1
SOUND_DIR=""      # --sounds DIR: your own sound files instead of the built-in ones
LOCK_ME=""        # on / off: use the shared XMB lock screen for this account or not

usage() {
    cat <<EOF
Usage: ./install.sh [options]

  --no-login        don't install the SDDM login screen
  --use-sddm        if your PC uses another login manager (e.g. Plasma Login Manager on
                    Fedora 44+), install SDDM and switch to it for the XMB login screen
                    (./uninstall.sh switches back)
  --no-lock         don't install the lock screen
  --no-leave        don't install the Shut Down / Restart screen
  --no-splash       don't install the black login splash
  --no-sync         don't patch Shader Wallpaper for the shared wave clock
  --no-displays     don't copy your monitor setup to the login screen
  --shader FILE     use this compiled wave shader (.frag.qsb) instead of searching for one
  --still-wave      keep the login/lock wave still (automatic in virtual machines; saves CPU
                    on PCs without a proper graphics card)
  --moving-wave     always animate the wave, even in a virtual machine
  --no-sounds       no menu sounds on the login, lock and Shut Down screens
  --sounds DIR      use your own sounds from DIR: move, select, back, error, open
                    (.wav, or .mp3/.flac/.ogg/.m4a/.opus if ffmpeg is installed)
  --choose          ask about each part one by one (good for a second user on the same PC)
  --lock-off-for-me use KDE's normal lock screen for your account (the XMB one stays for others)
  --lock-on-for-me  use the XMB lock screen for your account again
  -y, --yes         don't ask for confirmation
  -h, --help        show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --no-login) DO_LOGIN=0 ;;
        --use-sddm) USE_SDDM=1 ;;
        --still-wave) STILL_WAVE=1 ;;
        --choose) CHOOSE=1 ;;
        --no-sounds) SOUNDS=0 ;;
        --sounds) SOUND_DIR="${2:-}"; shift ;;
        --lock-off-for-me) LOCK_ME=off ;;
        --lock-on-for-me) LOCK_ME=on ;;
        --moving-wave) STILL_WAVE=0 ;;
        --no-lock) DO_LOCK=0 ;;
        --no-leave) DO_LEAVE=0 ;;
        --no-splash) DO_SPLASH=0 ;;
        --no-sync) DO_SYNC=0 ;;
        --no-displays) DO_DISPLAYS=0 ;;
        --shader) SHADER="${2:-}"; shift ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

save_state() {   # save_state KEY VALUE  (only the first time, so a re-install keeps the real originals)
    mkdir -p "$STATE_DIR"
    touch "$STATE"
    grep -q "^$1=" "$STATE" || printf '%s=%s\n' "$1" "$2" >> "$STATE"
}

# ---------------------------------------------------------------- checks
[ "$(id -u)" -ne 0 ] || die "Run this as your normal user, not with sudo. It will ask for your password when needed."
command -v kwriteconfig6 >/dev/null || die "kwriteconfig6 not found. This theme needs KDE Plasma 6."
command -v kreadconfig6  >/dev/null || die "kreadconfig6 not found. This theme needs KDE Plasma 6."

PLASMA_VER="$(plasmashell --version 2>/dev/null | awk '{print $2}')"
case "$PLASMA_VER" in 6.*) ;; *) die "KDE Plasma 6 is required (found: ${PLASMA_VER:-none})." ;; esac

# which login manager starts at boot? (e.g. sddm.service, plasmalogin.service, gdm.service)
DM_UNIT=""
if [ -L /etc/systemd/system/display-manager.service ]; then
    DM_UNIT="$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")"
fi
SWITCH_DM=0
if [ "$DO_LOGIN" = 1 ] && [ -n "$DM_UNIT" ] && [ "$DM_UNIT" != "sddm.service" ]; then
    if [ "$USE_SDDM" = 1 ]; then
        SWITCH_DM=1
    else
        warn "Your login screen is run by ${DM_UNIT%.service}, not SDDM - skipping the login screen."
        if [ "$DM_UNIT" = "plasmalogin.service" ]; then
            warn "  (Plasma Login Manager, the default on new Fedora 44+ installs, can't load custom themes.)"
        fi
        warn "  For the XMB login screen too, run again with --use-sddm (./uninstall.sh switches back)."
        DO_LOGIN=0
    fi
fi
if [ "$DO_LOGIN" = 1 ] && [ "$SWITCH_DM" = 0 ] && ! command -v sddm-greeter-qt6 >/dev/null; then
    warn "SDDM (Qt 6 greeter) not found - skipping the login screen."
    DO_LOGIN=0
fi
if [ "$DO_LOCK" = 1 ] && [ ! -f "$SHELL_LOCK/LockScreen.qml" ]; then
    warn "KDE's lock screen file wasn't found at $SHELL_LOCK - skipping the lock screen."
    DO_LOCK=0
fi
# (find, not ls: ls fails if ANY of the paths is missing, which gave a false warning on Fedora)
if [ "$SOUNDS" = 1 ] && [ -z "$(find /usr/lib /usr/lib64 -maxdepth 4 -type d -name QtMultimedia -path '*qml*' 2>/dev/null | head -1)" ]; then
    warn "Qt Multimedia wasn't found, so the menu sounds will be silent (Fedora: sudo dnf install qt6-qtmultimedia)."
fi
if ! ls /usr/lib*/qt6/qml/QtQuick/Effects >/dev/null 2>&1 && ! ls /usr/lib/*/qt6/qml/QtQuick/Effects >/dev/null 2>&1; then
    warn "QtQuick.Effects wasn't found. Round profile pictures need it (usually in your distro's qt6 declarative package)."
fi

# ---------------------------------------------------------------- find the wave shader
# 1) --shader FILE   2) the copy bundled in this repo   3) one from the Shader Wallpaper plugin
if [ -z "$SHADER" ] && [ -f "$HERE/shaders/xmb-wave.frag.qsb" ]; then
    SHADER="$HERE/shaders/xmb-wave.frag.qsb"
fi
if [ -z "$SHADER" ]; then
    for c in \
        "$HOME/.local/share/plasma/wallpapers/$WP_ID/contents/ui/Shaders6/xmb-wave.frag.qsb" \
        "/usr/share/plasma/wallpapers/$WP_ID/contents/ui/Shaders6/xmb-wave.frag.qsb" \
        "/usr/share/sddm/themes/xmb-wave/xmb-wave.frag.qsb"; do
        if [ -f "$c" ]; then SHADER="$c"; break; fi
    done
fi
if [ -z "$SHADER" ]; then
    SHADER="$(find "$HOME/.local/share/plasma/wallpapers" /usr/share/plasma/wallpapers -iname '*xmb*.frag.qsb' 2>/dev/null | head -1 || true)"
fi
[ -n "$SHADER" ] && [ ! -f "$SHADER" ] && die "Shader file not found: $SHADER"

# ---------------------------------------------------------------- still or moving wave
VIRT=""
if [ "$STILL_WAVE" = auto ]; then
    STILL_WAVE=0
    if command -v systemd-detect-virt >/dev/null && systemd-detect-virt -q; then
        VIRT="$(systemd-detect-virt)"
        STILL_WAVE=1
    fi
fi
# a tiny marker image; the login and lock screens look for it
# the same trick for --no-sounds
mark_quiet() { [ "$SOUNDS" = 0 ] && ${2:-sudo} install -m 644 "$HERE/lockscreen/xmb/assets/sparkle.png" "$1/assets/sounds-off.png"; return 0; }
mark_still() { [ "$STILL_WAVE" = 1 ] && sudo install -m 644 "$HERE/lockscreen/xmb/assets/sparkle.png" "$1/assets/still.png"; return 0; }

# ---------------------------------------------------------------- what's already here
LOGIN_SHARED=0; [ -d "$SDDM_THEME_DIR" ] && LOGIN_SHARED=1
LOCK_SHARED=0;  [ -x /usr/local/bin/xmb-lockscreen-restore ] && LOCK_SHARED=1
WP_HOME_MAIN="$HOME/.local/share/plasma/wallpapers/$WP_ID/contents/ui/main.qml"
LOCK_OFF_FLAG="$STATE_DIR/lockscreen-off.png"     # the shared lock screen looks for this in each user's config

# ---------------------------------------------------------------- --choose: ask about each part
ask() {   # ask "question" -> yes unless the answer starts with n
    local a; read -r -p "$1 [Y/n] " a
    case "$a" in [nN]*) return 1 ;; *) return 0 ;; esac
}
if [ "$CHOOSE" = 1 ]; then
    say "Choose what to install (just press Enter for yes)"
    echo "    Shared parts are the same for everyone on this PC and need an admin password."
    echo "    Your parts only change your own account."
    echo
    if [ "$LOGIN_SHARED" = 1 ]; then
        echo "  Login screen (shared): already installed - leaving it as it is"; DO_LOGIN=0
    elif [ "$DO_LOGIN" = 1 ]; then
        ask "  Login screen (shared) - install it?" || DO_LOGIN=0
    fi
    if [ "$LOCK_SHARED" = 1 ]; then
        DO_LOCK=0
        if ask "  Lock screen (shared, already installed) - use it for YOUR account? (n = KDE's normal one)"; then LOCK_ME=on; else LOCK_ME=off; fi
    elif [ "$DO_LOCK" = 1 ]; then
        ask "  Lock screen (shared) - install it?" || DO_LOCK=0
    fi
    [ "$DO_LEAVE" = 1 ]  && { ask "  Shut Down screen (your account) - install it?" || DO_LEAVE=0; }
    [ "$DO_SPLASH" = 1 ] && { ask "  Black loading splash (your account) - install it?" || DO_SPLASH=0; }
    if [ "$DO_SYNC" = 1 ] && [ -f "$WP_HOME_MAIN" ]; then
        ask "  Line your desktop wave up with the login/lock wave (your account; changes Shader Wallpaper)?" || DO_SYNC=0
    fi
    if [ "$DO_LOGIN" = 1 ] && [ "$DO_DISPLAYS" = 1 ]; then
        ask "  Give the login screen your monitor setup (shared)?" || DO_DISPLAYS=0
    fi
    if [ "$SOUNDS" = 1 ] && { [ "$DO_LOGIN" = 1 ] || [ "$DO_LOCK" = 1 ] || [ "$DO_LEAVE" = 1 ]; }; then
        ask "  PS3-style menu sounds on the screens you're installing?" || SOUNDS=0
    fi
    echo
fi
[ "$LOCK_ME" = off ] && [ "$DO_LOCK" = 1 ] && warn "--lock-off-for-me: the lock screen is still installed for others; your account uses KDE's normal one."

if [ "$DO_LOGIN$DO_LOCK$DO_LEAVE$DO_SPLASH$DO_SYNC" = 00000 ] && [ -z "$LOCK_ME" ]; then
    echo "Nothing to install - all parts were skipped."; exit 0
fi

# ---------------------------------------------------------------- your own sounds (--sounds DIR)
# Qt can only play .wav, so other formats are converted with ffmpeg into a temporary folder.
CUSTOM_SOUNDS=""
SOUND_NAMES="move select back error open"
# no --sounds given? use the repo's custom-sounds/ folder if you've put files in it
if [ -z "$SOUND_DIR" ] && [ -d "$HERE/custom-sounds" ]; then
    for n in $SOUND_NAMES; do
        if ls "$HERE/custom-sounds/$n".* >/dev/null 2>&1; then SOUND_DIR="$HERE/custom-sounds"; break; fi
    done
fi
if [ -n "$SOUND_DIR" ] && [ "$SOUNDS" = 1 ]; then
    [ -d "$SOUND_DIR" ] || die "--sounds: folder not found: $SOUND_DIR"
    CUSTOM_SOUNDS="$(mktemp -d)"
    trap 'rm -rf "$CUSTOM_SOUNDS"' EXIT
    FOUND=""
    for n in $SOUND_NAMES; do
        src=""
        for ext in wav mp3 flac ogg m4a opus; do
            [ -f "$SOUND_DIR/$n.$ext" ] && { src="$SOUND_DIR/$n.$ext"; break; }
        done
        [ -n "$src" ] || continue
        if [ "${src##*.}" = wav ]; then
            cp "$src" "$CUSTOM_SOUNDS/$n.wav"
        elif command -v ffmpeg >/dev/null; then
            ffmpeg -loglevel error -y -i "$src" -ac 2 -ar 48000 -c:a pcm_s16le "$CUSTOM_SOUNDS/$n.wav" \
                || die "--sounds: couldn't convert $src"
        else
            die "--sounds: $src needs converting to .wav - install ffmpeg (Fedora: sudo dnf install ffmpeg-free) or convert it yourself"
        fi
        FOUND="$FOUND $n"
    done
    [ -n "$FOUND" ] || die "--sounds: no files named move/select/back/error/open found in $SOUND_DIR"
fi
# put your sounds over the built-in ones in a screen's folder (the ones you didn't provide stay)
use_custom_sounds() {   # use_custom_sounds DIR [sudo|command]
    [ -n "$CUSTOM_SOUNDS" ] || return 0
    for f in "$CUSTOM_SOUNDS"/*.wav; do ${2:-sudo} install -m 644 "$f" "$1/sounds/"; done
}

# ---------------------------------------------------------------- summary
say "XMB PS3 theme installer (Plasma $PLASMA_VER)"
echo "    Login screen ............ $([ $DO_LOGIN = 1 ] && echo yes || echo no)$([ $SWITCH_DM = 1 ] && echo " (switches from ${DM_UNIT%.service} to SDDM)")"
echo "    Lock screen ............. $([ $DO_LOCK = 1 ] && echo yes || { [ $LOCK_SHARED = 1 ] && echo "already installed (shared)" || echo no; })"
[ -n "$LOCK_ME" ] && echo "    Lock screen for you ..... $([ $LOCK_ME = on ] && echo "XMB" || echo "KDE's normal one")"
echo "    Shut Down screen ........ $([ $DO_LEAVE = 1 ] && echo yes || echo no)"
echo "    Black login splash ...... $([ $DO_SPLASH = 1 ] && echo yes || echo no)"
if [ "$DO_SYNC" = 0 ]; then
    echo "    Wave clock sync ......... no"
elif [ -f "$WP_HOME_MAIN" ]; then
    echo "    Wave clock sync ......... yes"
else
    echo "    Wave clock sync ......... skipped (Shader Wallpaper isn't installed - see the README, then run this again)"
fi
echo "    Copy monitor setup ...... $([ $DO_DISPLAYS = 1 ] && [ $DO_LOGIN = 1 ] && echo yes || echo no)"
echo "    Menu sounds ............. $([ $SOUNDS = 0 ] && echo no || { [ -n "$CUSTOM_SOUNDS" ] && echo "yours:$FOUND (from $SOUND_DIR)" || echo yes; })"
echo "    Login/lock wave ......... $([ $STILL_WAVE = 1 ] && echo "still$([ -n "$VIRT" ] && echo " (virtual machine detected: $VIRT; use --moving-wave to animate)")" || echo moving)"
if [ -n "$SHADER" ]; then
    echo "    Wave shader ............. $SHADER"
else
    echo "    Wave shader ............. none found - using the built-in wave images"
fi
if [ "$ASSUME_YES" = 0 ]; then
    read -r -p "Continue? [Y/n] " a
    case "$a" in [nN]*) echo "Cancelled."; exit 0 ;; esac
fi

# ---------------------------------------------------------------- login screen (SDDM)
if [ "$DO_LOGIN" = 1 ]; then
    say "Installing the login screen"
    if [ "$SWITCH_DM" = 1 ] && ! command -v sddm-greeter-qt6 >/dev/null; then
        say "Installing SDDM"
        if   command -v dnf     >/dev/null; then sudo dnf install -y sddm sddm-wayland-plasma || sudo dnf install -y sddm
        elif command -v apt-get >/dev/null; then sudo apt-get install -y sddm
        elif command -v pacman  >/dev/null; then sudo pacman -S --needed --noconfirm sddm
        elif command -v zypper  >/dev/null; then sudo zypper install -y sddm
        else die "Couldn't find a package manager to install SDDM. Install it yourself, then run this again."
        fi
        command -v sddm-greeter-qt6 >/dev/null || die "SDDM installed, but its Qt 6 greeter (sddm-greeter-qt6) is missing. Nothing was switched."
    fi
    sudo rm -rf "$SDDM_THEME_DIR"
    sudo cp -r "$HERE/sddm/xmb-ps3" "$SDDM_THEME_DIR"
    [ -n "$SHADER" ] && sudo install -m 644 "$SHADER" "$SDDM_THEME_DIR/xmb-wave.frag.qsb"
    mark_still "$SDDM_THEME_DIR"
    mark_quiet "$SDDM_THEME_DIR"
    use_custom_sounds "$SDDM_THEME_DIR"
    # the login screen runs as the sddm user: make sure it can read everything, whatever the
    # permissions of the files we copied from (a private file would silently fall back to the blue picture)
    sudo chmod -R u+rwX,go+rX,go-w "$SDDM_THEME_DIR"
    ok "Theme copied to $SDDM_THEME_DIR"

    # remember the current theme, then switch
    PREV_THEME="$(grep -h '^Current=' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | grep -v xmb-ps3 | tail -1 | cut -d= -f2- || true)"
    save_state sddm_theme "${PREV_THEME:-breeze}"
    KDE_SDDM="/etc/sddm.conf.d/kde_settings.conf"
    THEME_IN_ZZ=0
    if [ -f "$KDE_SDDM" ] && grep -q '^Current=' "$KDE_SDDM"; then
        sudo sed -i 's/^Current=.*/Current=xmb-ps3/' "$KDE_SDDM"     # same place System Settings uses
    else
        THEME_IN_ZZ=1
    fi

    # let the login screen read /proc/uptime (longer fade-in right after boot); keep any existing value
    EXISTING_ENV="$(grep -h '^GreeterEnvironment=' /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null | grep -v QML_XHR_ALLOW_FILE_READ | tail -1 | cut -d= -f2- || true)"
    NEW_ENV="${EXISTING_ENV:+$EXISTING_ENV,}QML_XHR_ALLOW_FILE_READ=1"
    {
        echo "# Added by the XMB PS3 theme installer - remove with ./uninstall.sh"
        echo "[General]"
        echo "GreeterEnvironment=$NEW_ENV"
        if [ "$THEME_IN_ZZ" = 1 ]; then echo; echo "[Theme]"; echo "Current=xmb-ps3"; fi
    } | sudo tee "$SDDM_ZZ" >/dev/null
    ok "Login screen set to XMB PS3"

    if [ "$DO_DISPLAYS" = 1 ] && [ -f "$HOME/.config/kwinoutputconfig.json" ]; then
        SDDM_HOME="$(getent passwd sddm | cut -d: -f6 || true)"
        if [ -n "$SDDM_HOME" ]; then
            sudo mkdir -p "$SDDM_HOME/.config"
            sudo cp "$HOME/.config/kwinoutputconfig.json" "$SDDM_HOME/.config/"
            sudo chown -R sddm:sddm "$SDDM_HOME/.config"
            ok "Monitor setup copied to the login screen (no re-sync blink when switching)"
        fi
    fi

    if [ "$SWITCH_DM" = 1 ]; then
        save_state display_manager "$DM_UNIT"
        sudo systemctl disable "$DM_UNIT"
        sudo systemctl enable sddm.service
        ok "Switched the login manager from ${DM_UNIT%.service} to SDDM (takes effect when you restart)"
    fi
fi

# ---------------------------------------------------------------- lock screen
if [ "$DO_LOCK" = 1 ]; then
    say "Installing the lock screen"
    sudo mkdir -p /usr/local/share/xmb-lockscreen
    sudo rm -rf /usr/local/share/xmb-lockscreen/xmb
    sudo cp -r "$HERE/lockscreen/xmb" /usr/local/share/xmb-lockscreen/xmb
    sudo cp "$HERE/lockscreen/LockScreen-shim.qml" /usr/local/share/xmb-lockscreen/
    [ -n "$SHADER" ] && sudo install -m 644 "$SHADER" /usr/local/share/xmb-lockscreen/xmb/xmb-wave.frag.qsb
    mark_still /usr/local/share/xmb-lockscreen/xmb
    mark_quiet /usr/local/share/xmb-lockscreen/xmb
    use_custom_sounds /usr/local/share/xmb-lockscreen/xmb
    sudo chmod -R u+rwX,go+rX,go-w /usr/local/share/xmb-lockscreen   # the lock screen runs as each user
    sudo install -m 755 "$HERE/lockscreen/xmb-lockscreen-apply" "$HERE/lockscreen/xmb-lockscreen-restore" /usr/local/bin/
    sudo install -m 644 "$HERE/lockscreen/xmb-lockscreen.path" "$HERE/lockscreen/xmb-lockscreen.service" /etc/systemd/system/
    sudo /usr/local/bin/xmb-lockscreen-apply
    sudo systemctl daemon-reload
    sudo systemctl enable --now xmb-lockscreen.path >/dev/null 2>&1
    ok "Lock screen installed (re-applied automatically after Plasma updates)"
fi

# ---------------------------------------------------------------- your own lock screen choice
if [ "$LOCK_ME" = off ]; then
    mkdir -p "$STATE_DIR"
    cp "$HERE/lockscreen/xmb/assets/sparkle.png" "$LOCK_OFF_FLAG"
    ok "Your account will use KDE's normal lock screen (undo: ./install.sh --lock-on-for-me)"
elif [ "$LOCK_ME" = on ]; then
    rm -f "$LOCK_OFF_FLAG"
    ok "Your account uses the XMB lock screen"
fi

# ---------------------------------------------------------------- Shut Down screen + splash
if [ "$DO_LEAVE" = 1 ] || [ "$DO_SPLASH" = 1 ]; then
    say "Installing the Shut Down screen / splash"
    mkdir -p "$(dirname "$LNF_DIR")"
    rm -rf "$LNF_DIR"
    cp -r "$HERE/plasma/$LNF_ID" "$LNF_DIR"
    [ "$DO_LEAVE" = 1 ]  || rm -rf "$LNF_DIR/contents/logout"
    [ "$DO_SPLASH" = 1 ] || rm -rf "$LNF_DIR/contents/splash"
    [ -d "$LNF_DIR/contents/logout" ] && mark_quiet "$LNF_DIR/contents/logout" command
    [ -d "$LNF_DIR/contents/logout" ] && use_custom_sounds "$LNF_DIR/contents/logout" command

    if [ "$DO_LEAVE" = 1 ]; then
        save_state lookandfeel "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)"
        kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$LNF_ID"
        ok "Shut Down screen installed (the rest of your desktop falls back to Breeze)"
    fi
    if [ "$DO_SPLASH" = 1 ]; then
        save_state splash_engine "$(kreadconfig6 --file ksplashrc --group KSplash --key Engine)"
        save_state splash_theme  "$(kreadconfig6 --file ksplashrc --group KSplash --key Theme)"
        kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
        kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$LNF_ID"
        ok "Black login splash enabled"
    fi
fi

# ---------------------------------------------------------------- matching desktop wallpaper
# If Shader Wallpaper is installed, give it the XMB wave too so you can pick it as your wallpaper.
WP_SHADERS="$HOME/.local/share/plasma/wallpapers/$WP_ID/contents/ui/Shaders6"
if [ -n "$SHADER" ] && [ -d "$WP_SHADERS" ] && [ ! -f "$WP_SHADERS/xmb-wave.frag.qsb" ]; then
    cp "$SHADER" "$WP_SHADERS/xmb-wave.frag.qsb"
    ok "XMB wave added to Shader Wallpaper (pick it in Desktop and Wallpaper settings)"
fi

# ---------------------------------------------------------------- Shader Wallpaper clock sync
if [ "$DO_SYNC" = 1 ]; then
    WP_MAIN="$HOME/.local/share/plasma/wallpapers/$WP_ID/contents/ui/main.qml"
    if [ -f "$WP_MAIN" ]; then
        say "Syncing the Shader Wallpaper clock"
        if grep -q 'xmb-ps3: shared clock' "$WP_MAIN"; then
            ok "Already patched"
        elif grep -q 'shader.iTime += 0.016' "$WP_MAIN" && grep -q 'secondsSinceMidnight' "$WP_MAIN"; then
            [ -f "$WP_MAIN.xmb-orig" ] || cp "$WP_MAIN" "$WP_MAIN.xmb-orig"
            sed -i 's/shader\.iTime += 0\.016 \* \(.*\);/shader.iTime = secondsSinceMidnight * \1; \/\/ xmb-ps3: shared clock/' "$WP_MAIN"
            if grep -q 'xmb-ps3: shared clock' "$WP_MAIN"; then
                ok "Patched (original saved as main.qml.xmb-orig)"
                RESTART_SHELL=1
            else
                cp "$WP_MAIN.xmb-orig" "$WP_MAIN"
                warn "Couldn't patch this version of Shader Wallpaper - left it unchanged."
            fi
        else
            warn "This version of Shader Wallpaper looks different - left it unchanged."
        fi
    else
        warn "Shader Wallpaper isn't installed in your home folder - skipping the clock sync."
    fi
fi

# ---------------------------------------------------------------- done
echo
say "Done!"
if [ "$DO_LOCK" = 1 ] || [ "$LOCK_SHARED" = 1 ]; then
    echo "    • Lock screen:  press Meta+L      (safe test: scripts/preview.sh lock)"
fi
if [ "$DO_LOGIN" = 1 ]; then
    echo "    • Login screen: log out or restart (safe test: scripts/preview.sh login)"
fi
if [ "$SWITCH_DM" = 1 ]; then
    echo "    • If the login screen ever doesn't appear after restarting: press Ctrl+Alt+F3, log in, then run"
    echo "        sudo systemctl disable sddm && sudo systemctl enable $DM_UNIT && sudo reboot"
fi
echo "    • To remove everything: ./uninstall.sh"
# other people with an account here? the shared screens are theirs already; the rest is per user
OTHERS="$(getent passwd | awk -F: -v me="$USER" '$3 >= 1000 && $3 < 60000 && $1 != me && $7 !~ /(nologin|false)$/ {print $1}' | paste -sd, - | sed 's/,/, /g')"
if [ -n "$OTHERS" ] && { [ "$DO_LOGIN" = 1 ] || [ "$DO_LOCK" = 1 ]; }; then
    echo "    • Other users ($OTHERS) already get the login and lock screens. For their own Shut Down"
    echo "      screen and splash (or to turn the XMB lock screen off for themselves), they can log in"
    echo "      and run: ./install.sh --choose"
fi
if [ "${RESTART_SHELL:-0}" = 1 ]; then
    echo "    • Restart the desktop to load the wallpaper change: plasmashell --replace &> /dev/null & disown"
fi
