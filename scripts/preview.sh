#!/usr/bin/env bash
# Safe previews - nothing is changed, and the lock screen test closes itself.
case "${1:-}" in
    login) sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/xmb-ps3 ;;
    lock)  echo "Unlock with your password (closes by itself after 60 s)."
           timeout 60 /usr/libexec/kscreenlocker_greet --testing ;;
    *)     echo "Usage: scripts/preview.sh login|lock" ;;
esac
