[← Back to the README](../README.md)

# Options

Add any of these after `./install.sh`, e.g. `./install.sh --no-splash --yes`:

| Option | What it does | Affects |
|---|---|---|
| `--wallpaper-only` | **Only** add the XMB waves to the Shader Wallpaper plugin, for your desktop. Nothing else is installed and no password is needed ([see Wallpaper](wallpaper.md)) | Just you |
| `--choose` | Ask about each part one by one, instead of installing everything | n/a |
| `--no-login` | Skip installing the login screen. If it's already installed, everyone still sees it | Everyone |
| `--no-lock` | Skip installing the lock screen. If it's already installed, everyone still sees it | Everyone |
| `--lock-off-for-me` | Use KDE's normal lock screen for **your account**, while others keep the XMB one | Just you |
| `--lock-on-for-me` | Use the XMB lock screen for your account again | Just you |
| `--no-leave` | Don't install the Shut Down / Restart screen | Just you |
| `--no-splash` | Keep your current loading splash | Just you |
| `--no-sync` | Don't change Shader Wallpaper (the desktop wave won't line up with the login/lock wave) | Just you |
| `--no-displays` | Don't copy your monitor setup and audio output/volume to the login screen | Everyone |
| `--use-sddm` | Switch to SDDM if your PC uses another login manager, like Plasma Login Manager on Fedora 44+, which can't load custom themes. `./uninstall.sh` switches back | Everyone |
| `--no-sounds` | No menu sounds on the login, lock and Shut Down screens | Everyone (login/lock), just you (Shut Down) |
| `--sounds DIR` | Use sound files from another folder instead of `custom-sounds/` ([see below](#using-your-own-sounds)) | Everyone (login/lock), just you (Shut Down) |
| `--still-wave` | Keep the login/lock wave still (saves CPU on PCs without a proper graphics card) | Everyone |
| `--moving-wave` | Animate the wave even in a virtual machine | Everyone |
| `--shader FILE` | Use a different compiled wave shader (`.frag.qsb`) | Everyone |
| `-y`, `--yes` | Don't ask "Continue?" | n/a |
| `-h`, `--help` | List the options | n/a |

**Virtual machines:** the installer detects them and keeps the login and lock screen wave **still**, because redrawing the full-screen wave without a graphics card can freeze the VM window (GNOME Boxes even crashes). Use `--moving-wave` to animate it anyway.

## More than one user on the PC

| Part | Shared or per user? |
|---|---|
| Login screen | **Shared.** It appears before anyone logs in, so everyone gets the same one |
| Lock screen | **Shared**, but each user can switch it off for themselves (`--lock-off-for-me`) |
| Shut Down screen, loading splash, wave sync | **Per user.** Other users keep KDE's normal ones until they choose them |

After you've installed it, any other user can log in and pick exactly what they want. No admin password is needed for their own parts:

```bash
git clone https://github.com/luk3h/xmb-ps3-theme.git
cd xmb-ps3-theme
./install.sh --choose
```

It asks one question per part, for example *"Lock screen (shared, already installed) - use it for YOUR account?"*. Answering **n** to everything leaves their account vanilla, apart from the login screen, which can't be per user.

To remove only your own parts and leave the shared screens for everyone else:

```bash
./uninstall.sh --no-login --no-lock
```

A plain `./uninstall.sh` (needs an admin password) removes the shared login and lock screens for **everyone**, plus your own parts.

## Using your own sounds

The built-in sounds are original ones made for this theme. To use your own, put the files in this repo's **`custom-sounds/`** folder, named `move`, `select`, `back`, `error` and `open` (any you leave out keep the built-in sound), then run `./install.sh`. It picks them up automatically, converting MP3/FLAC/OGG to WAV if `ffmpeg` is installed. See [`custom-sounds/README.md`](../custom-sounds/README.md) for the details.

Files you put there are ignored by git, so they stay on your PC. You can also point at any other folder with `./install.sh --sounds ~/some-folder`. Only use sounds you have the right to use: this project doesn't include or link to anyone else's.

## Previews and screenshots

Try the screens safely, without locking or logging out:

```bash
scripts/preview.sh login    # login screen preview; can't sign in or turn anything off. Close with Ctrl+Q
scripts/preview.sh lock     # lock screen preview; unlock with your password, or it closes after 60 s
```

In the previews, Other User and the power buttons only show a note instead of really switching user or restarting. The banner at the top fades after 5 seconds (move the mouse to the top to bring it back), so you can take clean screenshots with Spectacle.
