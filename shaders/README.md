# XMB wave shader

`xmb-wave.frag.qsb` is the animated PS3 XMB wave used by the login screen, the lock screen and (via the
Shader Wallpaper plugin) the desktop. It's a compiled Qt 6 shader. The source code is next to it:

| File | What it is |
|---|---|
| `xmb-wave.frag` | Source of the shipped `xmb-wave.frag.qsb`. The background drifts through a palette of colours, one per hour, and is dimmer at night |
| `xmb-wave-daynight.frag` | llmciv's original colours: dark grey at night, the classic XMB blue by day |
| `xmb-wave.frag.qsb` | The compiled shader the theme uses |
| `colours/xmb-wave-<colour>.frag.qsb` | Single-colour versions for your desktop (blue, purple, pink, red, gold, green, teal, grey). They stay one colour all day, at full brightness |
| `make-colours.sh` | Rebuilds `colours/` from `xmb-wave.frag` (needs `qsb`, see below) |

## Credits

The wave has been passed along and improved by several people on Shadertoy:

1. **[int_45h](https://www.shadertoy.com/user/int_45h)**: the original, "PS3 Menu effect",
   https://www.shadertoy.com/view/tXy3DK (forked from "waves pt 2"). int_45h's note:
   > I'm too lazy to copy the MIT license so like just do whatever you want with this shader
   > but like if you can leave a comment or something or hit me up, that'd be dope. thxxx
2. **[llmciv](https://www.shadertoy.com/user/llmciv)**: "Ps3 XMB 3.0 Background",
   https://www.shadertoy.com/view/fcf3Dn. Added dithering, smoothed raymarching, anti-aliasing, and
   the dark grey to blue time-of-day colours.
3. **xaot88**: the starfield the sparkles are based on, https://www.shadertoy.com/view/Md2SR3
4. **Dave Hoskins**: the "Hash without Sine" random-number function pattern used here.
5. This theme: converted for Qt 6 / KDE Shader Wallpaper, plus the hourly colour palette.

Thank you all! 🌊 If you use this, go leave int_45h and llmciv a comment on Shadertoy.

## Changing the wave

Edit a `.frag` file (for example the palette colours near the top of `xmb-wave.frag`, or
`HOURS_PER_COLOUR`), then compile it with Qt's `qsb` tool:

```bash
sudo dnf install qt6-qtshadertools          # Fedora; on other distros look for "qt6 shadertools"
/usr/lib64/qt6/bin/qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o xmb-wave.frag.qsb xmb-wave.frag
```

| Part | Meaning |
|---|---|
| `qsb` | Qt's shader compiler. Qt 6 only loads shaders in its own `.qsb` format |
| `--glsl "100 es,120,150"` | Include versions for the OpenGL variants Qt can use |
| `--hlsl 50` / `--msl 12` | Versions for Direct3D and Metal, which Linux doesn't need but keep the file complete |
| `-o xmb-wave.frag.qsb` | The output file |
| `xmb-wave.frag` | The source to compile |

Then run `./install.sh` again so the login screen, lock screen and Shader Wallpaper get the new version.
If you changed the palette, also run `shaders/make-colours.sh` to rebuild the single-colour versions.
Only want the wave on your desktop, without the rest of the theme? Install Shader Wallpaper, then copy
`xmb-wave.frag.qsb` and/or any file from `colours/` into
`~/.local/share/plasma/wallpapers/online.knowmad.shaderwallpaper/contents/ui/Shaders6/`.
(The path to `qsb` may differ: `rpm -ql qt6-qtshadertools | grep bin/qsb` shows where it is.)
