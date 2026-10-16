# Original UI sounds for the XMB PS3 theme - generated from scratch (sine tones + envelopes).
import numpy as np, wave, sys
SR = 48000
def env(n, attack=0.004, decay=8.0):
    t = np.arange(n) / SR
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-decay * t)
def tone(freq, dur, decay, harm=(1.0,), detune=0.0, sweep=0.0):
    n = int(SR * dur); t = np.arange(n) / SR
    f = freq * (1 + sweep * t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = sum(a * np.sin((i + 1) * ph + i) for i, a in enumerate(harm))
    if detune: s += 0.5 * np.sin(ph * (1 + detune))
    return s * env(n, decay=decay)
def mix(*parts):
    n = max(len(p) for _, p in parts); out = np.zeros(n)
    for off, p in parts:
        o = int(off * SR); out[o:o+len(p)] += p[:max(0, n-o)]
    return out
def save(name, s, peak):
    s = s / (np.max(np.abs(s)) + 1e-9) * peak
    fade = int(0.003 * SR); s[-fade:] *= np.linspace(1, 0, fade)
    # pad with silence to at least 0.3 s: Qt drops sounds shorter than one audio buffer
    s = np.concatenate([s, np.zeros(max(0, int(0.3 * SR) - len(s)))])
    pcm = (s * 32767).astype('<i2')
    with wave.open(name, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    print(name, f"{len(s)/SR*1000:.0f} ms")
# soft glassy tick for moving between items
save("move.wav",   tone(2400, 0.06, 70, harm=(1, .25, .08)), 0.35)
# brighter two-note select
save("select.wav", mix((0, tone(1320, .18, 26, harm=(1,.3,.1))), (.045, tone(1980, .2, 22, harm=(1,.25)))), 0.45)
# lower, falling back/cancel
save("back.wav",   tone(900, 0.12, 30, harm=(1, .3), sweep=-0.35), 0.4)
# soft double low note for errors
save("error.wav",  mix((0, tone(300, .12, 28, harm=(1,.5,.25))), (.12, tone(240, .16, 24, harm=(1,.5,.25)))), 0.5)
# gentle airy chime when a screen appears
save("open.wav",   mix((0, tone(660, 1.1, 3.2, harm=(1,.2), detune=.003)),
                       (.07, tone(990, 1.0, 3.5, harm=(1,.15), detune=.003)),
                       (.14, tone(1320, .9, 4.0, harm=(1,.1), detune=.003))), 0.35)
