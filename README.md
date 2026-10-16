# XMB PS3 theme for KDE Plasma 6

A PlayStation 3 XMB-style **login screen**, **lock screen** and **Shut Down screen** for KDE Plasma 6, built to feel like one continuous console UI:

- The animated XMB wave, in the same day/night colours as your desktop wallpaper, and in sync with it
- A PS3-style user column with round profile pictures
- A clock box, `[Tab] Options` / `[Enter] Sign In` key hints and a slide-in Options panel
- "Restart the system?" Yes/No confirmations, then "Restarting..." and a fade to black
- Smooth fades between the lock screen, login screen and desktop, across multiple monitors


## Screenshots

| Login screen | Login screen: Options |
|---|---|
| ![Login screen with the user list](docs/login.jpg) | ![Login screen with the Options panel open](docs/login-options.jpg) |
| **Lock screen** | **Lock screen: Options** |
| ![Lock screen](docs/lock.jpg) | ![Lock screen with the Options panel open](docs/lock-options.jpg) |
| **Restart confirmation** | **Turn off confirmation** |
| ![Restart the system?](docs/restart-confirm.jpg) | ![Turn off the system?](docs/turnoff-confirm.jpg) |
| **Shut Down screen (Ctrl+Alt+Del)** | **The XMB wave on the desktop** |
| ![Shut Down power menu](docs/power-menu.jpg) | ![XMB wave wallpaper](docs/wave.jpg) |

The wave changes colour through the day, like the PS3. These shots were taken at night.

---

## What's included

| Part | What it replaces | Installed to |
|---|---|---|
| **Login screen** | SDDM theme | `/usr/share/sddm/themes/xmb-ps3` |
| **Lock screen** | Plasma's lock screen (Meta+L) | `/usr/local/share/xmb-lockscreen`, swapped into Plasma's lock screen folder |
| **Shut Down screen** | The Restart / Shut Down / Log Out screen | `~/.local/share/plasma/look-and-feel/com.github.luk3h.xmbps3` |
| **Login splash** | The splash while your desktop loads (a plain black one, so the desktop fades in on every monitor at once) | same package as above |
| **Wave clock sync** *(optional)* | One line in the Shader Wallpaper plugin, so the desktop, lock and login waves line up | your Shader Wallpaper plugin folder |

### Controls

| Key | Login screen | Lock screen |
|---|---|---|
| Up / Down | Choose a user | Move between you and **Other User…** |
| Enter | Sign in | Unlock (or go to the login screen on **Other User…**) |
| Tab | Options (session, Sleep, Restart, Turn Off) | Options (Sleep, Hibernate, Restart, Turn Off) |
| Esc | Options | *Turns the monitors off (a built-in KDE shortcut)* |

---

## Requirements

- **KDE Plasma 6** (tested on Plasma 6.7, Fedora 44) on Wayland
- **SDDM** with the Qt 6 greeter (for the login screen). See [Fedora 44+ and Plasma Login Manager](#fedora-44-and-plasma-login-manager) if your distro uses something else.
- `QtQuick.Effects` (part of Qt 6 declarative; installed with Plasma on most distros)
- *Optional, recommended:* the **Shader Wallpaper** plugin, so your **desktop** gets the same animated XMB wave. **Install it before running `./install.sh`** (or just run `./install.sh` again afterwards): right-click the desktop → Desktop and Wallpaper → Get New Plugins… → search "Shader Wallpaper". The installer then adds the wave to the plugin for you; pick **Shader Wallpaper** → **xmb-wave** in Desktop and Wallpaper settings.

> The animated XMB wave shader is included in `shaders/` (see Credits). The login and lock screens use it automatically. Use `--shader FILE` to use a different one.

---

## Install

You need `git` to download it. Fedora: `sudo dnf install git` · Ubuntu/Debian: `sudo apt install git` · Arch: `sudo pacman -S git`.
(No git? Click **Code → Download ZIP** at the top of this page, extract it, and run `./install.sh` from the extracted folder.)

```bash
git clone https://github.com/luk3h/xmb-ps3-theme.git
cd xmb-ps3-theme
./install.sh
```

Run it as your normal user. It asks for your password when it needs `sudo`. Skip any part with:

```
--no-login  --no-lock  --no-leave  --no-splash  --no-sync  --no-displays  --shader FILE  --yes
```

and add `--use-sddm` to switch to SDDM if your PC uses a different login manager (see below).

### Fedora 44+ and Plasma Login Manager

New installs of Fedora 44 KDE (and possibly other distros later) use KDE's new **Plasma Login Manager** instead of SDDM. It can't load custom themes, so the installer **skips the login screen** there; the lock screen, Shut Down screen and everything else still install. (PCs upgraded from an older Fedora keep SDDM and get everything.)

To get the XMB login screen as well, switch to SDDM:

```bash
./install.sh --use-sddm
```

This installs SDDM if needed and makes it the login manager from your next restart. `./uninstall.sh` switches back to Plasma Login Manager. If the login screen ever doesn't appear after restarting, press **Ctrl+Alt+F3**, log in, and run `sudo systemctl disable sddm && sudo systemctl enable plasmalogin && sudo reboot`.

**Test safely before relying on it:**

```bash
scripts/preview.sh login    # login screen in a window; can't actually log you in
scripts/preview.sh lock     # test lock screen; unlock with your password, or it closes after 60 s
```

## Uninstall

```bash
./uninstall.sh
```

This puts back your previous login theme (and your previous login manager, if you used `--use-sddm`), the original lock screen, your Global Theme and splash settings, and the original Shader Wallpaper file. The installer saved them in `~/.config/xmb-ps3/`.

---

## How the lock screen works (and staying safe)

Since Plasma 6.1, the lock screen isn't part of any theme. Plasma always loads one fixed file, `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreen.qml`. The installer saves the original as `LockScreen.breeze.qml` and puts a small loader in its place. A systemd path unit (`xmb-lockscreen.path`) re-applies it automatically if a Plasma update replaces the file.

- If the XMB lock screen ever fails to load, Plasma shows its own basic fallback lock, and your password still works.
- If you're ever stuck on a lock screen: press **Ctrl+Alt+F3**, log in, run `loginctl unlock-sessions`, then `sudo /usr/local/bin/xmb-lockscreen-restore`.

---

## Tips for multiple monitors

If one monitor blinks or arrives late when switching between the lock screen, login screen and desktop, it's usually re-syncing because of a different refresh rate in each place:

1. **Give the login screen your display setup.** The installer copies it for you (`--no-displays` to skip). You can also use System Settings → Colours & Themes → Login Screen (SDDM) → **Apply Plasma Settings…**. Do this again after changing resolution or refresh rate.
2. **Use the same mode from the moment you boot** (optional). Find your connectors with
   `for p in /sys/class/drm/card*-*; do echo "$(basename $p): $(cat $p/status)"; done`
   and add for example `video=DP-1:3840x2160@240 video=DP-2:2560x1440@144` to your kernel options (`sudo grubby --update-kernel=ALL --args="…"`). If your GRUB has `GRUB_ENABLE_BLSCFG=false`, also run `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`.
3. **Monitor menu:** turning off *input auto-switch / auto source* and *resolution notice* makes monitors come back from a signal change faster.
4. **Desktop icons jumping between monitors at login:** use the **Desktop** layout (not Folder View) on every monitor except your main one.

---

## Credits & licence

- **XMB wave shader** (`shaders/xmb-wave.frag.qsb`) by **[llmciv](https://www.shadertoy.com/user/llmciv)**, from [their Shadertoy shader](https://www.shadertoy.com/view/fcf3Dn). They released it freely ("do whatever you want with this shader", MIT-style) and asked for a shout-out, so thank you, llmciv! If you use this theme, go leave them a comment on Shadertoy.
- Everything else is licensed under the **GNU GPL v3 or later** (see `LICENSE`).
- The optional wave clock sync changes one line of **Shader Wallpaper** by @y4my4my4m (GPL-3.0); the original file is kept and restored by `uninstall.sh`.
- Inspired by the PlayStation 3 XMB. This is a fan project, **not affiliated with or endorsed by Sony Interactive Entertainment**. It contains no Sony logos or assets; "PlayStation" and "PS3" are trademarks of their owners.
