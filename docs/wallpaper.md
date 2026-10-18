[← Back to the README](../README.md)

# Wallpaper

There are three ways to get the XMB wave on your desktop:

| | What it is | Works on |
|---|---|---|
| **[Live wave](#the-live-wave-shader-wallpaper)** | Drawn in real time: changes colour through the day and stays in sync with the login and lock screens | KDE Plasma 6 |
| **[Video loop](#video-loops)** | Seamless 4K videos, smooth and lighter on power | KDE, Windows, anything that plays video wallpapers |
| **Still image** | 4K PNGs, one per colour, from the [latest release](https://github.com/luk3h/xmb-ps3-theme/releases/latest) | Anything |

## The live wave (Shader Wallpaper)

The login and lock screens bring their own copy of the wave. For the **desktop**, you need the free **Shader Wallpaper** plugin by y4my4my4m:

1. Right-click the desktop → **Desktop and Wallpaper** → **Get New Plugins…**
2. Search **Shader Wallpaper** ("Shader Wallpaper for Plasma6 by y4my4my4m") and click **Install**.
3. It asks you to *Pick Your Installation Option*. Choose the newest, **`kde-shader-wallpaper-3.0.3-plasma6.zip`**. (The ⚠ icons are normal.)
4. Run `./install.sh` (again, if you already ran it). It should say **XMB wave added to Shader Wallpaper** and **Syncing the Shader Wallpaper clock... Patched**.
   **Just want the wallpaper, not the rest of the theme?** Run `./install.sh --wallpaper-only` instead. It only copies the waves into Shader Wallpaper.
5. In Desktop and Wallpaper, set **Wallpaper type** to **Shader Wallpaper** and pick **xmb-wave** from its list. It changes colour through the day like the login and lock screens. For a wave that **stays one colour**, pick one of `xmb-wave-blue`, `-purple`, `-pink`, `-red`, `-gold`, `-green`, `-teal` or `-grey` instead.

**Shader Wallpaper version 4** (built from source on [GitHub](https://github.com/y4my4my4m/kde-shader-wallpaper), not on the KDE Store) works differently, so the installer can't add the wave to it. Use its **Import** button instead and choose `shaders/xmb-wave.frag` from this repo. The clock sync isn't available there.

**In a virtual machine**, keep a normal image wallpaper. The installer makes the login and lock wave still in VMs, but the desktop wallpaper always animates, and without a graphics card that makes the whole VM sluggish.

What the installer changes in the plugin is listed in [How it works](how-it-works.md#shader-wallpaper).

## Power use

The live wave is drawn by your graphics card many times a second, so it uses more power than a still wallpaper. Measured on a Radeon RX 9070 XT (4K 240 Hz + 1440p monitors, idle desktop, no windows open):

| Desktop wallpaper | Graphics card power | Extra over a still image |
|---|---|---|
| Still image | ~38 W | |
| Video loop (Smart Video Wallpaper Reborn) | ~46 W | ~8 W |
| Live wave (Shader Wallpaper) | ~56 W | ~18 W |

- **Live wave:** the best looking. It follows the time of day and stays in sync across monitors and with the login and lock screens.
- **Video loop:** smooth, at about half the extra power, because your graphics card plays video with a separate, low-power decoder.
- **Still image:** no extra power at all.

Shader Wallpaper already pauses the live wave while a window is maximised or full screen, so it costs nothing while you're gaming. Its settings have stricter options, like pausing whenever a window is open.

## Video loops

1. Download `xmb-wave-loop-4k.mp4` (all colours) or `xmb-wave-colour-loops-4k.zip` (one colour each; unzip it) from the [latest release](https://github.com/luk3h/xmb-ps3-theme/releases/latest).
2. Right-click the desktop → **Desktop and Wallpaper** → **Get New Plugins...**, search **Smart Video Wallpaper Reborn** and click **Install**.
3. Set **Wallpaper type** to **Smart Video Wallpaper Reborn**. On its **Videos** tab, click **Pick a file...**, choose your video and click **Apply**.

**More than one monitor?** Use the same **single-colour** video on each screen. The all-colours loop starts at a different point on each monitor, so the colours won't match.

On Fedora, MP4 playback may need `sudo dnf install gstreamer1-plugin-openh264`.

On **Windows**, the same videos work with Wallpaper Engine or the free Lively Wallpaper (drag the video into Lively to add it).
