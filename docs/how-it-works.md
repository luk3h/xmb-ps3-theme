[← Back to the README](../README.md)

# How it works

## What gets installed

| Part | What it replaces | Installed to |
|---|---|---|
| **Login screen** | SDDM theme | `/usr/share/sddm/themes/xmb-ps3` |
| **Lock screen** | Plasma's lock screen (Meta+L) | `/usr/local/share/xmb-lockscreen`, swapped into Plasma's lock screen folder |
| **Shut Down screen** | The Restart / Shut Down / Log Out screen | `~/.local/share/plasma/look-and-feel/com.github.luk3h.xmbps3` |
| **Login splash** | The splash while your desktop loads (a plain black one, so the desktop fades in on every monitor at once) | same package as above |
| **Wave clock sync** *(optional)* | One line in the Shader Wallpaper plugin, so the desktop, lock and login waves line up | your Shader Wallpaper plugin folder |

The installer saves your previous settings in `~/.config/xmb-ps3/`, so `./uninstall.sh` can put them back.

### Requirements in detail

- **KDE Plasma 6** (tested on Plasma 6.7, Fedora 44) on Wayland
- **SDDM** with the Qt 6 greeter, for the login screen. Fedora 44+ uses Plasma Login Manager, which can't load custom themes; `--use-sddm` switches to SDDM and `./uninstall.sh` switches back
- `QtQuick.Effects` (part of Qt 6 declarative; installed with Plasma on most distros), for the round profile pictures
- *For the menu sounds:* Qt Multimedia (`qt6-qtmultimedia` on Fedora; usually already installed with Plasma). Without it everything works, just silently
- The wave shader is included in `shaders/`. The login and lock screens use it automatically; `--shader FILE` uses a different one

### Shader Wallpaper

What the installer changes in the plugin (`~/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper/`):

| File | Change | Undone by `./uninstall.sh`? |
|---|---|---|
| `contents/ui/Shaders6/xmb-wave.frag.qsb` | The XMB wave added to the plugin's shader list | No, on purpose: it may be your wallpaper. Delete it yourself if you like |
| `contents/ui/Shaders6/xmb-wave-*.frag.qsb` | The 8 single-colour versions (from `shaders/colours/`) | No, same reason |
| `contents/ui/main.qml` | One line, so the desktop wave uses the same clock as the login/lock wave (no jump when you unlock). Original saved as `main.qml.xmb-orig` | Yes |

## Controls

| Key | Login screen | Lock screen |
|---|---|---|
| Up / Down | Choose a user | Move between you and **Other User…** |
| Enter | Sign in | Unlock (or go to the login screen on **Other User…**) |
| Tab | Options (session, Sleep, Restart, Turn Off) | Options (Sleep, Hibernate, Restart, Turn Off) |
| Esc | Options | *Turns the monitors off (a built-in KDE shortcut)* |

## The lock screen (and staying safe)

Since Plasma 6.1, the lock screen isn't part of any theme. Plasma always loads one fixed file, `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreen.qml`. The installer saves the original as `LockScreen.breeze.qml` and puts a small loader in its place. A systemd path unit (`xmb-lockscreen.path`) re-applies it automatically if a Plasma update replaces the file.

- If the XMB lock screen ever fails to load, Plasma shows its own basic fallback lock, and your password still works.
- If you're ever stuck on a lock screen: press **Ctrl+Alt+F3**, log in, run `loginctl unlock-sessions`, then `sudo /usr/local/bin/xmb-lockscreen-restore`.

## Multiple monitors

If one monitor blinks or arrives late when switching between the lock screen, login screen and desktop, it's usually re-syncing because of a different refresh rate in each place:

1. **Give the login screen your display setup.** The installer copies it for you (`--no-displays` to skip). You can also use System Settings → Colours & Themes → Login Screen (SDDM) → **Apply Plasma Settings…**. Do this again after changing resolution or refresh rate.
2. **Use the same mode from the moment you boot** (optional). Find your connectors with
   `for p in /sys/class/drm/card*-*; do echo "$(basename $p): $(cat $p/status)"; done`
   and add for example `video=DP-1:3840x2160@240 video=DP-2:2560x1440@144` to your kernel options (`sudo grubby --update-kernel=ALL --args="…"`). If your GRUB has `GRUB_ENABLE_BLSCFG=false`, also run `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`.
3. **Monitor menu:** turning off *input auto-switch / auto source* and *resolution notice* makes monitors come back from a signal change faster.
4. **Desktop icons jumping between monitors at login:** use the **Desktop** layout (not Folder View) on every monitor except your main one.
