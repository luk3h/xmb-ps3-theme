# XMB PS3 theme for KDE Plasma 6

A PlayStation 3 XMB-style **login screen**, **lock screen** and **Shut Down screen** for KDE Plasma 6, built to feel like one continuous console UI:

- The animated XMB wave, changing colour through the day and in sync with your desktop wallpaper
- A PS3-style user column, clock, `[Tab] Options` panel and "Restart the system?" Yes/No prompts
- Smooth fades between the lock screen, login screen and desktop, across multiple monitors
- Soft PS3-style menu sounds (original, made for this theme)

> **Just want the wallpaper?** Get the live XMB wave on KDE with `./install.sh --wallpaper-only` ([how](docs/wallpaper.md)), or grab the 4K stills and videos for any OS from the [latest release](https://github.com/luk3h/xmb-ps3-theme/releases/latest).

## Screenshots

<table>
  <tr>
    <th width="50%">Login screen</th>
    <th width="50%">Login screen: Options</th>
  </tr>
  <tr>
    <td width="50%"><img src="docs/login.jpg" alt="Login screen with the user list" width="100%"></td>
    <td width="50%"><img src="docs/login-options.jpg" alt="Login screen with the Options panel open" width="100%"></td>
  </tr>
  <tr>
    <th width="50%">Lock screen</th>
    <th width="50%">Lock screen: Options</th>
  </tr>
  <tr>
    <td width="50%"><img src="docs/lock.jpg" alt="Lock screen" width="100%"></td>
    <td width="50%"><img src="docs/lock-options.jpg" alt="Lock screen with the Options panel open" width="100%"></td>
  </tr>
  <tr>
    <th width="50%">Restart confirmation</th>
    <th width="50%">Turn off confirmation</th>
  </tr>
  <tr>
    <td width="50%"><img src="docs/restart-confirm.jpg" alt="Restart the system?" width="100%"></td>
    <td width="50%"><img src="docs/turnoff-confirm.jpg" alt="Turn off the system?" width="100%"></td>
  </tr>
  <tr>
    <th width="50%">Shut Down screen (Ctrl+Alt+Del)</th>
    <th width="50%">The XMB wave on the desktop</th>
  </tr>
  <tr>
    <td width="50%"><img src="docs/power-menu.jpg" alt="Shut Down power menu" width="100%"></td>
    <td width="50%"><img src="docs/wave.jpg" alt="XMB wave wallpaper" width="100%"></td>
  </tr>
</table>

The wave changes colour through the day, like the PS3: each shot shows a different hour.

## Menu sounds

Every screen has soft PS3-style menu sounds, original ones made for this theme from plain sine tones (no Sony audio):

| Sound | Plays when |
|---|---|
| **open** | The login or lock screen appears |
| **move** | Moving between users or options |
| **select** | Signing in, unlocking, choosing an option |
| **back** | Closing a panel, choosing No |
| **error** | A wrong or empty password |

**Use your own sounds:** put files named `move`, `select`, `back`, `error` and `open` (WAV, or MP3/FLAC/OGG with `ffmpeg` installed) in the `custom-sounds/` folder and run `./install.sh`. Any you leave out keep the built-in sound. [More on sounds](docs/options.md#using-your-own-sounds)

Don't want any? Install with `--no-sounds`.

## Install

You need **KDE Plasma 6** on Wayland and **SDDM** for the login screen. On **Fedora 44+**, which uses Plasma Login Manager, add `--use-sddm` and the installer switches to SDDM for you.

```bash
git clone https://github.com/luk3h/xmb-ps3-theme.git
cd xmb-ps3-theme
./install.sh
```

Run it as your normal user; it asks for your password when it needs it. No git? Click **Code → Download ZIP**, extract it, and run `./install.sh` from that folder.

For the wave on your **desktop** too, install the free Shader Wallpaper plugin first: see [Wallpaper](docs/wallpaper.md).

**Try before you install:** `scripts/preview.sh login` (close with Ctrl+Q) or `scripts/preview.sh lock`.

### Controls

| Key | Login screen | Lock screen |
|---|---|---|
| Up / Down | Choose a user | Move between you and **Other User…** |
| Enter | Sign in | Unlock |
| Tab | Options (session, Sleep, Restart, Turn Off) | Options (Sleep, Hibernate, Restart, Turn Off) |

## Uninstall

```bash
./uninstall.sh
```

This puts back everything the installer changed: your previous login theme and login manager, the original lock screen, your Global Theme and splash, and the original Shader Wallpaper file.

## More

| Page | What's in it |
|---|---|
| [Options](docs/options.md) | Every install option, more than one user on the PC, your own sounds, previews |
| [Wallpaper](docs/wallpaper.md) | The wave on your desktop, power use, video and still alternatives |
| [How it works](docs/how-it-works.md) | What gets installed where, the lock screen and staying safe, multiple monitors |

## Credits & licence

- **How it was made:** designed, tested and maintained by **luk3h**, with the code written mostly by **Claude** (Anthropic's AI). I decided how every screen should look, behave and sound, tested each change on real hardware and in a VM, and tracked down the bugs; Claude wrote most of the QML and scripts. Bug reports and pull requests are welcome.
- **XMB wave shader** (`shaders/`): originally ["PS3 Menu effect"](https://www.shadertoy.com/view/tXy3DK) by **[int_45h](https://www.shadertoy.com/user/int_45h)**, who released it freely ("do whatever you want with this shader... if you can leave a comment or something or hit me up, that'd be dope"). Updated as ["Ps3 XMB 3.0 Background"](https://www.shadertoy.com/view/fcf3Dn) by **[llmciv](https://www.shadertoy.com/user/llmciv)** (dithering, smoother raymarching, anti-aliasing, time-of-day colours). Starfield based on xaot88's, hash function after Dave Hoskins. Converted for Qt 6 with an hourly colour palette for this theme. See [`shaders/README.md`](shaders/README.md) for the full credits and how to change the wave. Thank you, int_45h and llmciv! If you use this theme, go leave them a comment on Shadertoy.
- **Menu sounds** (`sounds/`): original, generated from sine tones for this theme (see [`sounds/README.md`](sounds/README.md)). No Sony audio is used.
- Everything else is licensed under the **GNU GPL v3 or later** (see `LICENSE`). The optional wave clock sync changes one line of **Shader Wallpaper** by @y4my4my4m (GPL-3.0); the original file is kept and restored by `uninstall.sh`.
- Inspired by the PlayStation 3 XMB. This is a fan project, **not affiliated with or endorsed by Sony Interactive Entertainment**. It contains no Sony logos or assets; "PlayStation" and "PS3" are trademarks of their owners.
