# Menu sounds

Original PS3-*style* UI sounds made for this theme. They're not recordings of Sony's sounds: each one is
generated from scratch out of plain sine tones by `make-sounds.py`, so they're free to share under the
theme's licence (GPL-3.0).

| Sound | Plays when |
|---|---|
| `move.wav` | Moving between users or options |
| `select.wav` | Enter: signing in, unlocking, choosing an option, opening the Options panel |
| `back.wav` | Closing the panel, choosing No, cancelling |
| `error.wav` | An empty or wrong password |
| `open.wav` | The login or lock screen appearing |

Copies live next to each screen (`sddm/xmb-ps3/sounds`, `lockscreen/xmb/sounds`,
`plasma/.../logout/sounds`). To change them, edit `make-sounds.py`, then:

```bash
python3 make-sounds.py                     # writes the five .wav files here (needs python3-numpy)
for d in ../sddm/xmb-ps3 ../lockscreen/xmb ../plasma/com.github.luk3h.xmbps3/contents/logout; do
    cp *.wav "$d/sounds/"
done
```

and run `./install.sh` again. Turn the sounds off with `./install.sh --no-sounds`.
