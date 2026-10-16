# Your own sounds

Put your own sound files in this folder and `./install.sh` uses them automatically, instead of the
built-in sounds. Name each file after what it's for:

| File name | Plays when |
|---|---|
| `move` | Moving between users or options |
| `select` | Enter / choosing something / opening Options |
| `back` | Closing Options, choosing No, cancelling |
| `error` | An empty or wrong password |
| `open` | The login or lock screen appearing |

For example `move.wav`, `select.mp3`, `error.flac`. You don't need all five: any you leave out keep the
built-in sound.

**Formats:** `.wav` works as it is. `.mp3`, `.flac`, `.ogg`, `.m4a` and `.opus` are converted
automatically if `ffmpeg` is installed. The installer also makes quiet files louder (peak −1 dB) and pads very short ones with a little silence, so they always play (Fedora: `sudo dnf install ffmpeg-free`,
Ubuntu/Debian: `sudo apt install ffmpeg`).

**Then:**

```bash
./install.sh
```

The summary shows `Menu sounds ... yours: move select ...` when it's using them. Re-run `./install.sh`
after changing the files. To go back to the built-in sounds, empty this folder and run it again.

**Tips**

- Short sounds feel best: under half a second for `move`, `select` and `back`.
- To check a file really is audio (and not a web page saved by mistake): `file move.mp3` should say
  something like `Audio file`, not `HTML document`.
- Only use sounds you have the right to use. This project doesn't include or link to anyone else's.

Sound files in this folder are ignored by git, so they're never uploaded if you push your own copy.
