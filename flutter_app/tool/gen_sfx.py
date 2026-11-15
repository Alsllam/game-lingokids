"""Generates the app's original sound effects as small WAV files.

Run:  python3 tool/gen_sfx.py
Every sound is synthesised from sine waves here, so nothing is copied from
any other product. Replace the files in assets/audio/ with studio recordings
whenever you like - keep the same file names.
"""
import math
import os
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def tone(freq, dur, vol=0.5, attack=0.005, release=0.08, harmonics=(1.0, 0.25, 0.1)):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * min(1.0, (dur - t) / release)
        s = sum(a * math.sin(2 * math.pi * freq * (k + 1) * t) for k, a in enumerate(harmonics))
        out.append(vol * env * s / sum(harmonics))
    return out


def sweep(f0, f1, dur, vol=0.5):
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        phase += 2 * math.pi * f / RATE
        env = min(1.0, i / (0.01 * RATE)) * (1 - t) ** 1.5
        out.append(vol * env * math.sin(phase))
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(a, b, offset=0.0):
    start = int(offset * RATE)
    out = list(a) + [0.0] * max(0, start + len(b) - len(a))
    for i, s in enumerate(b):
        out[start + i] += s
    return out


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


C5, E5, G5, C6, E6 = 523.25, 659.25, 783.99, 1046.5, 1318.5

save("tap.wav", tone(880, 0.07, 0.5, release=0.05))
save("flip.wav", sweep(400, 900, 0.12, 0.45))
save("correct.wav", mix(tone(E5, 0.14, 0.5), tone(C6, 0.28, 0.5, release=0.2), 0.11))
save("wrong.wav", mix(tone(220, 0.16, 0.45, harmonics=(1.0, 0.5, 0.3)), tone(175, 0.26, 0.45, harmonics=(1.0, 0.5, 0.3), release=0.18), 0.13))
win = []
for i, f in enumerate((C5, E5, G5, C6)):
    win = mix(win, tone(f, 0.2, 0.5, release=0.12), i * 0.13)
win = mix(win, mix(tone(C6, 0.7, 0.4, release=0.5), tone(E6, 0.7, 0.3, release=0.5)), 0.55)
save("win.wav", win)
save("star.wav", mix(tone(C6, 0.1, 0.45), tone(E6, 0.22, 0.45, release=0.16), 0.07))
print("sound effects written to", os.path.abspath(OUT))
