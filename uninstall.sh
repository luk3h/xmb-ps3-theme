#!/usr/bin/env bash
# XMB PS3 theme for KDE Plasma 6 - uninstaller
# Puts back the settings saved by install.sh and removes everything it added.

set -uo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/xmb-ps3"
STATE="$STATE_DIR/backup.conf"
LNF_ID="com.github.luk3h.xmbps3"
LNF_DIR="$HOME/.local/share/plasma/look-and-feel/$LNF_ID"
WP_MAIN="$HOME/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper/contents/ui/main.qml"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "Run this as your normal user, not with sudo."; exit 1; }

# --no-login / --no-lock: leave the shared login and lock screens in place (e.g. when another user
# on this PC only wants to remove their own Shut Down screen and splash - no admin password needed)
DO_LOGIN=1 DO_LOCK=1
for a in "$@"; do
    case "$a" in
        --no-login) DO_LOGIN=0 ;;
        --no-lock)  DO_LOCK=0 ;;
        -h|--help)  echo "Usage: ./uninstall.sh [--no-login] [--no-lock]"; exit 0 ;;
        *) echo "Unknown option: $a (use --no-login and/or --no-lock)"; exit 1 ;;
    esac
done

get() { [ -f "$STATE" ] && grep -m1 "^$1=" "$STATE" | cut -d= -f2- ; }

say "Removing the XMB PS3 theme"

# the shared screens need admin rights - check first, so a non-admin isn't left half-uninstalled
NEED_ADMIN=0
[ "$DO_LOCK" = 1 ] && [ -x /usr/local/bin/xmb-lockscreen-restore ] && NEED_ADMIN=1
[ "$DO_LOGIN" = 1 ] && { [ -d /usr/share/sddm/themes/xmb-ps3 ] || [ -f /etc/sddm.conf.d/zz-xmb-ps3.conf ] || [ -n "$(get display_manager)" ]; } && NEED_ADMIN=1
if [ "$NEED_ADMIN" = 1 ] && ! sudo -v; then
    echo
    echo "Removing the shared login and lock screens needs an admin password."
    echo "To remove only your own Shut Down screen and splash, run:  ./uninstall.sh --no-login --no-lock"
    exit 1
fi

# lock screen
if [ "$DO_LOCK" = 1 ] && [ -x /usr/local/bin/xmb-lockscreen-restore ]; then
    sudo /usr/local/bin/xmb-lockscreen-restore
    sudo rm -f /etc/systemd/system/xmb-lockscreen.path /etc/systemd/system/xmb-lockscreen.service
    sudo systemctl daemon-reload
    sudo rm -f /usr/local/bin/xmb-lockscreen-apply /usr/local/bin/xmb-lockscreen-restore
    sudo rm -rf /usr/local/share/xmb-lockscreen
    ok "Lock screen restored to KDE's original"
fi

# login screen
if [ "$DO_LOGIN" = 1 ] && { [ -d /usr/share/sddm/themes/xmb-ps3 ] || [ -f /etc/sddm.conf.d/zz-xmb-ps3.conf ]; }; then
    PREV="$(get sddm_theme)"; PREV="${PREV:-breeze}"
    [ -f /etc/sddm.conf.d/kde_settings.conf ] && sudo sed -i "s/^Current=xmb-ps3\$/Current=$PREV/" /etc/sddm.conf.d/kde_settings.conf
    sudo rm -f /etc/sddm.conf.d/zz-xmb-ps3.conf
    sudo rm -rf /usr/share/sddm/themes/xmb-ps3
    ok "Login screen set back to: $PREV"
fi

# login manager: switch back if install.sh --use-sddm changed it
DM="$(get display_manager)"
if [ "$DO_LOGIN" = 1 ] && [ -n "$DM" ]; then
    sudo systemctl disable sddm.service
    sudo systemctl enable "$DM"
    ok "Login manager switched back to ${DM%.service} (takes effect when you restart; SDDM itself was left installed)"
fi

# Shut Down screen + splash
if [ -d "$LNF_DIR" ]; then
    LNF="$(get lookandfeel)"
    if [ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" = "$LNF_ID" ]; then
        if [ -n "$LNF" ] && [ "$LNF" != "$LNF_ID" ]; then
            kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "$LNF"
        else
            kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage --delete
        fi
    fi
    if [ "$(kreadconfig6 --file ksplashrc --group KSplash --key Theme)" = "$LNF_ID" ]; then
        E="$(get splash_engine)"; T="$(get splash_theme)"
        if [ -n "$E" ]; then kwriteconfig6 --file ksplashrc --group KSplash --key Engine "$E"; else kwriteconfig6 --file ksplashrc --group KSplash --key Engine --delete; fi
        if [ -n "$T" ]; then kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$T"; else kwriteconfig6 --file ksplashrc --group KSplash --key Theme --delete; fi
    fi
    rm -rf "$LNF_DIR"
    ok "Shut Down screen and splash removed"
fi

# Shader Wallpaper clock patch
if [ -f "$WP_MAIN.xmb-orig" ]; then
    mv "$WP_MAIN.xmb-orig" "$WP_MAIN"
    ok "Shader Wallpaper restored (restart the desktop or log out to reload it)"
fi

# keep the saved settings if the shared screens are still installed (needed to undo them later)
if [ "$DO_LOGIN" = 1 ] && [ "$DO_LOCK" = 1 ]; then rm -rf "$STATE_DIR"; fi
echo
say "Done. The copy of your monitor setup given to the login screen was left in place (it's harmless)."
