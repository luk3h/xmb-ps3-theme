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

get() { [ -f "$STATE" ] && grep -m1 "^$1=" "$STATE" | cut -d= -f2- ; }

say "Removing the XMB PS3 theme"

# lock screen
if [ -x /usr/local/bin/xmb-lockscreen-restore ]; then
    sudo /usr/local/bin/xmb-lockscreen-restore
    sudo rm -f /etc/systemd/system/xmb-lockscreen.path /etc/systemd/system/xmb-lockscreen.service
    sudo systemctl daemon-reload
    sudo rm -f /usr/local/bin/xmb-lockscreen-apply /usr/local/bin/xmb-lockscreen-restore
    sudo rm -rf /usr/local/share/xmb-lockscreen
    ok "Lock screen restored to KDE's original"
fi

# login screen
if [ -d /usr/share/sddm/themes/xmb-ps3 ] || [ -f /etc/sddm.conf.d/zz-xmb-ps3.conf ]; then
    PREV="$(get sddm_theme)"; PREV="${PREV:-breeze}"
    [ -f /etc/sddm.conf.d/kde_settings.conf ] && sudo sed -i "s/^Current=xmb-ps3\$/Current=$PREV/" /etc/sddm.conf.d/kde_settings.conf
    sudo rm -f /etc/sddm.conf.d/zz-xmb-ps3.conf
    sudo rm -rf /usr/share/sddm/themes/xmb-ps3
    ok "Login screen set back to: $PREV"
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

rm -rf "$STATE_DIR"
echo
say "Done. The copy of your monitor setup given to the login screen was left in place (it's harmless)."
