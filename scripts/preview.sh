#!/usr/bin/env bash
# Safe previews - nothing is changed, and the lock screen test closes itself.
# lets the previews read /tmp/xmb-preview.conf (used by scripts/screenshots.sh)
export QML_XHR_ALLOW_FILE_READ=1
case "${1:-}" in
    login) echo "Exit the preview with Ctrl+Q or its Exit preview button (or press Ctrl+C here). Signing in and power buttons do nothing in it."
           sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/xmb-ps3 ;;
    lock)  echo "Unlock with your password (closes by itself after 60 s). Other User and the power buttons only show a note in the preview."
           timeout 60 /usr/libexec/kscreenlocker_greet --testing ;;
    *)     echo "Usage: scripts/preview.sh login|lock" ;;
esac
