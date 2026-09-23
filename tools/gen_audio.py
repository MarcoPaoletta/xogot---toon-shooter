#!/usr/bin/env python3
"""Synthesises every SFX and music loop for Container Yard as 16 bit mono WAV files.

Standard library only, deterministic (fixed seeds). No samples, no square or pulse
waves, no bit crushing: instruments are sines, saws, Karplus-Strong plucks and
filtered noise with envelopes and a feedback delay reverb.

Usage:
    python3 tools/gen_audio.py            writes assets/audio/sfx/*.wav and assets/audio/music/*.wav
    python3 tools/gen_audio.py --verify   checks the three audio rules of GDD section 10 on the files
"""
import math, os, random, struct, sys, wave

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
SFX_DIR = os.path.join(ROOT, "sfx")
MUSIC_DIR = os.path.join(ROOT, "music")
TAU = 2.0 * math.pi


# ---------------------------------------------------------------- helpers

def zeros(seconds):
    return [0.0] * int(seconds * SR)


def mix(dst, src, at=0.0, gain=1.0):
    o = int(at * SR)
    n = min(len(src), len(dst) - o)
    for i in range(max(0, n)):
        dst[o + i] += src[i] * gain
    return dst


def normalize(s, peak=0.9):
    m = max(1e-9, max(abs(x) for x in s))
    k = peak / m
    return [x * k for x in s]


def write(path, s):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in s))


def read(path):
    with wave.open(path, "rb") as w:
        n = w.getnframes()
        raw = w.readframes(n)
    return [v / 32767.0 for v in struct.unpack("<%dh" % n, raw)]


def lowpass(s, cutoff):
    a = 1.0 - math.exp(-TAU * cutoff / SR)
    y = 0.0
    out = []
    for x in s:
        y += a * (x - y)
        out.append(y)
    return out


def lowpass_sweep(s, c0, c1):
    n = len(s)
    y = 0.0
    out = []
    for i, x in enumerate(s):
        c = c0 * (c1 / c0) ** (i / max(1, n - 1))
        a = 1.0 - math.exp(-TAU * c / SR)
        y += a * (x - y)
        out.append(y)
    return out


def highpass(s, cutoff):
    lp = lowpass(s, cutoff)
    return [x - l for x, l in zip(s, lp)]


def noise(seconds, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(int(seconds * SR))]


def env_exp(n, attack, decay):
    """Attack in seconds (linear), then exponential decay with time constant `decay`."""
    a = max(1, int(attack * SR))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            out.append(math.exp(-(i - a) / (decay * SR)))
    return out


def apply(s, e):
    return [x * g for x, g in zip(s, e)]


def sine_sweep(seconds, f0, f1, decay, attack=0.001):
    n = int(seconds * SR)
    ph = 0.0
    out = []
    for i in range(n):
        f = f0 * (f1 / f0) ** (i / max(1, n - 1))
        ph += TAU * f / SR
        g = (i / (attack * SR)) if i < attack * SR else math.exp(-(i - attack * SR) / (decay * SR))
        out.append(math.sin(ph) * g)
    return out


def saw(freq, seconds, detune=0.0):
    n = int(seconds * SR)
    out = []
    p = random.random()
    f = freq * (1.0 + detune)
    for i in range(n):
        p += f / SR
        p -= math.floor(p)
        out.append(2.0 * p - 1.0)
    return out


def reverb(s, amount=0.25, delays=(0.029, 0.037, 0.041, 0.053), fb=0.55, tail=0.6):
    out = s + [0.0] * int(tail * SR)
    wet = [0.0] * len(out)
    for d in delays:
        dl = int(d * SR)
        buf = [0.0] * len(out)
        for i in range(len(out)):
            x = out[i] if i < len(s) else 0.0
            y = x + (buf[i - dl] * fb if i >= dl else 0.0)
            buf[i] = y
            wet[i] += y
    k = amount / len(delays)
    return [o + w * k for o, w in zip(out, wet)]


def pluck(freq, seconds, rng, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string."""
    period = max(2, int(SR / freq))
    buf = [rng.uniform(-1, 1) for _ in range(period)]
    buf = lowpass(buf, 2000 + 8000 * bright)
    out = []
    idx = 0
    n = int(seconds * SR)
    for _ in range(n):
        a = buf[idx]
        b = buf[(idx + 1) % period]
        v = decay * 0.5 * (a + b)
        buf[idx] = v
        out.append(a)
        idx = (idx + 1) % period
    return out


def click(rng, length=0.004, gain=1.0):
    n = int(length * SR)
    return [rng.uniform(-1, 1) * gain * (1 - i / n) for i in range(n)]


def thump(freq, seconds, decay):
    return sine_sweep(seconds, freq * 1.6, freq, decay)


# ---------------------------------------------------------------- SFX

def gunshot(rng, dur, f_hi, f_lo, thump_f, thump_gain, tail_decay, body_decay, metal=0.15, rev=0.15):
    n = noise(dur, rng)
    n = lowpass_sweep(n, f_hi, f_lo)
    n = apply(n, env_exp(len(n), 0.0008, body_decay))
    hiss = apply(highpass(noise(dur, rng), 2500), env_exp(int(dur * SR), 0.0005, 0.012))
    t = thump(thump_f, dur, tail_decay)
    s = zeros(dur)
    mix(s, n, 0, 1.0)
    mix(s, hiss, 0, 0.6)
    mix(s, t, 0, thump_gain)
    if metal > 0:
        ring = [math.sin(TAU * 2750 * i / SR) * math.exp(-i / (0.03 * SR)) for i in range(int(dur * SR))]
        mix(s, ring, 0.002, metal)
    return normalize(reverb(s, rev, tail=min(0.3, dur)), 0.95)


def swish(rng, dur, f0, f1):
    n = noise(dur, rng)
    out = []
    y = 0.0
    N = len(n)
    for i, x in enumerate(n):
        c = f0 * (f1 / f0) ** (i / N)
        a = 1 - math.exp(-TAU * c / SR)
        y += a * (x - y)
        g = math.sin(math.pi * i / N) ** 2
        out.append(y * g)
    s = zeros(dur)
    mix(s, click(rng, 0.003, 0.3))
    mix(s, out)
    mix(s, thump(90, dur * 0.5, 0.03), 0, 0.25)
    return normalize(s, 0.85)


def chime(notes, step, dur, rng, bright=0.6):
    s = zeros(dur)
    for k, f in enumerate(notes):
        tone = []
        for i in range(int((dur - k * step) * SR)):
            e = math.exp(-i / (0.35 * SR))
            tone.append((math.sin(TAU * f * i / SR) + 0.3 * math.sin(TAU * 2 * f * i / SR) * bright + 0.12 * math.sin(TAU * 3.01 * f * i / SR)) * e)
        mix(s, tone, k * step, 0.6)
        mix(s, click(rng, 0.002, 0.4), k * step)
    mix(s, thump(110, 0.2, 0.05), 0, 0.3)
    return normalize(reverb(s, 0.3), 0.85)


def horn(freqs, dur, rng, swell=0.5, rel=0.4):
    s = zeros(dur)
    n = int(dur * SR)
    for f in freqs:
        for det in (-0.006, 0.0, 0.007):
            w = saw(f, dur, det)
            mix(s, w, 0, 0.25)
    env = []
    for i in range(n):
        t = i / SR
        g = min(1.0, 0.35 + t / swell) if t < swell else 1.0
        if t > dur - rel:
            g *= max(0.0, (dur - t) / rel)
        env.append(g)
    s = apply(lowpass_sweep(s, 500, 3500), env)
    mix(s, click(rng, 0.004, 0.8))
    mix(s, thump(freqs[0] / 2, 0.4, 0.15), 0, 0.5)
    return normalize(reverb(s, 0.35), 0.85)


def make_sfx():
    rng = random.Random(7)
    out = {}
    out["blaster"] = gunshot(rng, 0.09, 4000, 400, 120, 0.9, 0.05, 0.025, metal=0.18)
    out["pistol"] = gunshot(rng, 0.07, 5000, 700, 150, 0.6, 0.03, 0.015, metal=0.1)
    out["bandit_pistol"] = gunshot(rng, 0.06, 4200, 800, 160, 0.45, 0.025, 0.012, metal=0.08, rev=0.08)
    out["revolver"] = gunshot(rng, 0.30, 3500, 250, 90, 1.0, 0.12, 0.05, metal=0.2, rev=0.3)
    out["revolver_small"] = gunshot(rng, 0.08, 6000, 900, 170, 0.5, 0.03, 0.012, metal=0.12)
    out["smg"] = gunshot(rng, 0.055, 5500, 1200, 140, 0.5, 0.02, 0.01, metal=0.06, rev=0.05)
    out["shotgun"] = gunshot(rng, 0.35, 3000, 150, 70, 1.2, 0.15, 0.07, metal=0.1, rev=0.3)
    out["short_cannon"] = gunshot(rng, 0.40, 2600, 120, 60, 1.3, 0.18, 0.09, metal=0.08, rev=0.35)
    out["sniper"] = gunshot(rng, 0.55, 6000, 300, 80, 1.1, 0.2, 0.04, metal=0.25, rev=0.5)
    out["sniper_2"] = gunshot(rng, 0.35, 6000, 350, 90, 0.9, 0.12, 0.035, metal=0.2, rev=0.35)
    gl = zeros(0.25)
    mix(gl, thump(70, 0.25, 0.08), 0, 1.0)
    mix(gl, apply(lowpass(noise(0.25, rng), 900), env_exp(int(0.25 * SR), 0.001, 0.04)), 0, 0.6)
    mix(gl, apply(highpass(noise(0.03, rng), 3000), env_exp(int(0.03 * SR), 0.0005, 0.008)), 0, 0.4)
    out["grenade_launcher"] = normalize(reverb(gl, 0.2), 0.9)
    rk = zeros(0.8)
    mix(rk, gunshot(rng, 0.2, 3000, 300, 80, 1.0, 0.1, 0.05, metal=0.0), 0, 0.8)
    roar = apply(lowpass_sweep(noise(0.8, rng), 3000, 700), [min(1, i / (0.05 * SR)) * math.exp(-i / (0.35 * SR)) for i in range(int(0.8 * SR))])
    mix(rk, roar, 0.02, 0.7)
    out["rocket"] = normalize(rk, 0.9)
    out["knife_swish_1"] = swish(rng, 0.22, 800, 5000)
    out["knife_swish_2"] = swish(rng, 0.18, 1200, 6500)
    kh = zeros(0.2)
    mix(kh, thump(130, 0.2, 0.04), 0, 1.0)
    mix(kh, apply(lowpass(noise(0.2, rng), 1800), env_exp(int(0.2 * SR), 0.001, 0.03)), 0, 0.7)
    mix(kh, apply(highpass(noise(0.02, rng), 3000), env_exp(int(0.02 * SR), 0.0005, 0.006)), 0, 0.5)
    out["knife_hit"] = normalize(kh, 0.9)
    out["shovel_swish"] = swish(rng, 0.32, 500, 3500)
    sc = zeros(0.6)
    for f, g in ((620, 0.6), (1375, 0.4), (2290, 0.3), (3470, 0.2)):
        mix(sc, [math.sin(TAU * f * i / SR) * math.exp(-i / (0.18 * SR)) for i in range(int(0.6 * SR))], 0.001, g)
    mix(sc, thump(100, 0.2, 0.05), 0, 0.6)
    mix(sc, click(rng, 0.004, 0.9))
    out["shovel_clang"] = normalize(sc, 0.9)
    ex = zeros(1.0)
    mix(ex, thump(45, 1.0, 0.35), 0, 1.2)
    mix(ex, apply(lowpass_sweep(noise(1.0, rng), 4000, 200), env_exp(SR, 0.001, 0.25)), 0, 1.0)
    for k in range(18):
        t = 0.05 + rng.random() * 0.6
        mix(ex, apply(highpass(noise(0.015, rng), 2500), env_exp(int(0.015 * SR), 0.0005, 0.004)), t, 0.3 * (1 - t))
    out["explosion"] = normalize(reverb(ex, 0.35, tail=0.4), 0.95)
    gb = zeros(0.12)
    mix(gb, [math.sin(TAU * 1900 * i / SR) * math.exp(-i / (0.02 * SR)) for i in range(int(0.12 * SR))], 0, 0.6)
    mix(gb, thump(180, 0.12, 0.02), 0, 0.6)
    mix(gb, click(rng, 0.002, 0.8))
    out["grenade_bounce"] = normalize(gb, 0.8)
    ec = zeros(0.08)
    mix(ec, click(rng, 0.003, 1.0))
    mix(ec, [math.sin(TAU * 3200 * i / SR) * math.exp(-i / (0.006 * SR)) for i in range(int(0.08 * SR))], 0, 0.4)
    mix(ec, thump(200, 0.08, 0.01), 0, 0.3)
    out["empty_click"] = normalize(ec, 0.7)
    ws = zeros(0.18)
    mix(ws, click(rng, 0.004, 1.0))
    mix(ws, thump(160, 0.1, 0.02), 0, 0.5)
    mix(ws, click(rng, 0.003, 0.8), 0.09)
    mix(ws, [math.sin(TAU * 2400 * i / SR) * math.exp(-i / (0.01 * SR)) for i in range(int(0.08 * SR))], 0.09, 0.3)
    mix(ws, thump(140, 0.08, 0.02), 0.09, 0.4)
    out["weapon_switch"] = normalize(ws, 0.75)
    out["crate_pickup"] = chime([523.25, 659.25, 783.99], 0.08, 0.7, rng, bright=0.8)
    out["health_pickup"] = chime([587.33, 880.0], 0.1, 0.45, rng, bright=0.4)
    for name, fc, dec, ring_f in (("impact_metal", 3000, 0.02, 2100), ("impact_wood", 1500, 0.025, 0), ("impact_sand", 900, 0.03, 0)):
        s = zeros(0.18)
        mix(s, click(rng, 0.002, 0.8))
        mix(s, apply(lowpass(noise(0.18, rng), fc), env_exp(int(0.18 * SR), 0.0008, dec)), 0, 0.8)
        mix(s, thump(140 if ring_f else 110, 0.1, 0.02), 0, 0.4)
        if ring_f:
            mix(s, [math.sin(TAU * ring_f * i / SR) * math.exp(-i / (0.04 * SR)) for i in range(int(0.15 * SR))], 0, 0.3)
        mix(s, apply(highpass(noise(0.02, rng), 2500), env_exp(int(0.02 * SR), 0.0005, 0.005)), 0, 0.3)
        out[name] = normalize(s, 0.7)
    hb = zeros(0.2)
    mix(hb, thump(95, 0.2, 0.05), 0, 1.0)
    mix(hb, apply(highpass(noise(0.03, rng), 3000), env_exp(int(0.03 * SR), 0.0005, 0.006)), 0, 0.6)
    out["hit_bandit"] = normalize(hb, 0.8)
    ph = zeros(0.35)
    mix(ph, thump(70, 0.35, 0.12), 0, 1.0)
    mix(ph, apply(lowpass(noise(0.35, rng), 700), env_exp(int(0.35 * SR), 0.001, 0.08)), 0, 0.6)
    mix(ph, apply(highpass(noise(0.02, rng), 2200), env_exp(int(0.02 * SR), 0.0005, 0.005)), 0, 0.35)
    out["player_hit"] = normalize(ph, 0.9)
    hbt = zeros(0.6)
    for t, g in ((0.0, 1.0), (0.22, 0.7)):
        mix(hbt, thump(55, 0.3, 0.07), t, g)
        mix(hbt, apply(highpass(noise(0.02, rng), 2500), env_exp(int(0.02 * SR), 0.0005, 0.005)), t, 0.35)
    out["heartbeat"] = normalize(hbt, 0.8)
    bd = zeros(0.7)
    for k, (f0, f1) in enumerate(((330, 260), (250, 170))):
        tone = []
        ph_ = 0.0
        N = int(0.25 * SR)
        for i in range(N):
            f = f0 * (f1 / f0) ** (i / N)
            ph_ += TAU * f / SR
            tone.append((math.sin(ph_) + 0.4 * math.sin(2 * ph_) + 0.2 * math.sin(3 * ph_)) * math.sin(math.pi * i / N))
        mix(bd, lowpass(tone, 1500), k * 0.18, 0.5)
    mix(bd, thump(60, 0.3, 0.08), 0.38, 1.0)
    mix(bd, click(rng, 0.003, 0.7))
    mix(bd, apply(highpass(noise(0.02, rng), 2500), env_exp(int(0.02 * SR), 0.0005, 0.005)), 0, 0.3)
    out["bandit_death"] = normalize(bd, 0.85)
    out["wave_start"] = horn([146.83, 220.0, 293.66], 1.2, rng, swell=0.5, rel=0.4)
    wc = zeros(1.0)
    for k, f in enumerate((392.0, 493.88, 587.33)):
        mix(wc, horn([f, f * 1.5], 0.45 if k < 2 else 0.6, rng, swell=0.05, rel=0.2), k * 0.17, 0.6)
    out["wave_cleared"] = normalize(wc, 0.85)
    yh = zeros(5.0)
    mix(yh, horn([196.0, 246.94, 293.66], 1.4, rng, swell=0.3, rel=0.5), 0, 0.7)
    mix(yh, horn([261.63, 329.63, 392.0], 1.4, rng, swell=0.2, rel=0.5), 1.2, 0.7)
    mix(yh, horn([293.66, 392.0, 493.88, 587.33], 2.4, rng, swell=0.3, rel=1.4), 2.4, 0.8)
    mix(yh, thump(49, 1.0, 0.5), 2.4, 0.6)
    out["yard_held"] = normalize(yh, 0.9)
    ov = zeros(3.0)
    for k, f in enumerate((293.66, 261.63, 233.08, 196.0)):
        mix(ov, horn([f, f * 1.19], 0.9 if k < 3 else 1.6, rng, swell=0.08, rel=0.4), k * 0.45, 0.6)
    mix(ov, thump(41, 1.2, 0.5), 1.35, 0.7)
    out["overrun"] = normalize(ov, 0.9)
    for k in range(4):
        st = zeros(0.14)
        mix(st, click(rng, 0.002, 0.5))
        mix(st, apply(lowpass(noise(0.14, rng), 1200 + 400 * k), env_exp(int(0.14 * SR), 0.001, 0.025)), 0, 0.8)
        mix(st, thump(80 + 10 * k, 0.1, 0.02), 0, 0.5)
        mix(st, apply(highpass(noise(0.02, rng), 2500), env_exp(int(0.02 * SR), 0.0005, 0.004)), 0.005, 0.25)
        out["step_%d" % (k + 1)] = normalize(st, 0.5)
    for name, f in (("ui_click", 1800), ("ui_hover", 2600)):
        u = zeros(0.09)
        mix(u, click(rng, 0.002, 0.8))
        mix(u, [math.sin(TAU * f * i / SR) * math.exp(-i / (0.012 * SR)) for i in range(int(0.09 * SR))], 0, 0.5)
        mix(u, thump(150, 0.06, 0.012), 0, 0.4)
        out[name] = normalize(u, 0.6 if name == "ui_click" else 0.35)
    return out


# ---------------------------------------------------------------- music

def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def kick(rng, g=1.0):
    s = zeros(0.4)
    mix(s, sine_sweep(0.4, 140, 42, 0.12), 0, g)
    mix(s, click(rng, 0.003, 0.4 * g))
    return s


def tom(freq, rng, g=1.0):
    s = zeros(0.45)
    mix(s, sine_sweep(0.45, freq * 1.5, freq, 0.14), 0, g)
    mix(s, apply(lowpass(noise(0.45, rng), 1500), env_exp(int(0.45 * SR), 0.001, 0.05)), 0, 0.25 * g)
    return s


def brush(rng, g=1.0, length=0.12, fc=5000):
    return apply(highpass(noise(length, rng), fc), env_exp(int(length * SR), 0.002, length / 3.0))


def pad_chord(notes, dur, rng, cutoff=1400, level=0.12):
    s = zeros(dur)
    for n in notes:
        for det in (-0.004, 0.0035):
            mix(s, saw(midi(n), dur, det), 0, level)
    s = lowpass(lowpass(s, cutoff), cutoff * 1.3)
    n = len(s)
    att = int(0.6 * SR)
    rel = int(0.6 * SR)
    return [x * min(1.0, i / att, (n - i) / rel) for i, x in enumerate(s)]


def render_loop(bars, bar_len, fill_bar, tail=2.0):
    length = bars * bar_len
    buf = zeros(length + tail)
    for b in range(bars):
        fill_bar(buf, b, b * bar_len + 0.005)   # 5 ms in: sample 0 holds only the wrapped tail, so the seam is continuous
    buf = reverb(buf, 0.18, tail=0.0)
    L = int(length * SR)
    out = buf[:L]
    for i in range(len(buf) - L):
        out[i] += buf[L + i]
    return normalize(out, 0.8)


def make_menu():
    rng = random.Random(88)
    bpm = 88.0
    beat = 60.0 / bpm
    bar_len = beat * 4
    bars = 22                       # 22 x 2.727 s = 60.0 s
    prog = [[50, 53, 57, 60], [46, 50, 53, 57], [48, 52, 55, 59], [45, 49, 52, 57],
            [50, 53, 57, 62], [43, 47, 50, 55], [46, 50, 53, 58], [45, 48, 52, 57]]
    scale = [62, 64, 65, 67, 69, 70, 72, 74, 76, 77]

    def fill(buf, b, t0):
        ch = prog[(b * 3 + b // 8) % len(prog)]
        mix(buf, pad_chord(ch[1:], bar_len + 0.5, rng, 1100 + 150 * (b % 4), 0.07), t0)
        root = ch[0] - 12
        for k, off in enumerate((0, 1.5, 2, 3)):
            nn = root + (7 if k == 2 else 0) + (12 if (b + k) % 5 == 0 else 0)
            mix(buf, lowpass(pluck(midi(nn), beat * 1.4, rng, 0.3, 0.997), 900), t0 + off * beat + rng.uniform(0, 0.01), 0.55)
        for k in range(8):
            if rng.random() < 0.8:
                mix(buf, brush(rng, 1.0, 0.1 if k % 2 else 0.16), t0 + k * beat / 2 + rng.uniform(0, 0.012), 0.10 + 0.06 * (k % 2 == 0))
        if b % 2 == 0 or rng.random() < 0.5:
            mix(buf, kick(rng, 0.5), t0, 0.6)
        if b >= 2:
            count = rng.choice((3, 4, 5))
            times = sorted(rng.sample([0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], count))
            for tt in times:
                nn = rng.choice(scale) + (12 if b > 13 and rng.random() < 0.3 else 0)
                note = pluck(midi(nn), beat * 1.6, rng, 0.7, 0.9975)
                mix(buf, lowpass(note, 3500), t0 + tt * beat + rng.uniform(0, 0.015), 0.3)

    return render_loop(bars, bar_len, fill)


def make_combat():
    rng = random.Random(118)
    bpm = 118.0
    beat = 60.0 / bpm
    bar_len = beat * 4
    bars = 24                       # 24 x 2.034 s = 48.8 s
    roots = [38, 38, 41, 36, 38, 43, 41, 40]

    def fill(buf, b, t0):
        root = roots[(b + b // 8) % len(roots)]
        for k in range(4):
            mix(buf, kick(rng, 1.0), t0 + k * beat, 0.8 if k % 2 == 0 else 0.6)
        pattern = [0.5, 1.5, 2.5, 3.25, 3.5] if b % 3 else [0.5, 1.75, 2.5, 3.5]
        for p in pattern:
            f = midi(root + rng.choice((12, 7, 5, 10)))
            mix(buf, tom(f, rng, 0.8), t0 + p * beat + rng.uniform(0, 0.01), 0.5)
        for k in range(8):
            mix(buf, brush(rng, 1.0, 0.05, 7000), t0 + k * beat / 2 + rng.uniform(0, 0.006), 0.07 + 0.04 * rng.random())
        bass_steps = [0, 0.75, 1.5, 2, 2.75, 3.5] if b % 2 else [0, 0.5, 1.5, 2, 3, 3.5]
        for k, st in enumerate(bass_steps):
            n = root + (0 if k % 3 else rng.choice((0, 0, 3, 5, 7)))
            d = beat * 0.45
            tone = lowpass(saw(midi(n), d, 0.0), 700 + 200 * (b % 3))
            tone = [x * math.exp(-i / (0.12 * SR)) * min(1, i / (0.002 * SR)) for i, x in enumerate(tone)]
            mix(buf, tone, t0 + st * beat, 0.35)
        chord = [root + 24, root + 27 + (1 if b % 4 == 3 else 0), root + 31]
        for off in (0.5, 1.5, 2.5, 3.5):
            if rng.random() < 0.85:
                d = beat * 0.22
                st_ = zeros(d)
                for n in chord:
                    mix(st_, saw(midi(n), d, rng.uniform(-0.004, 0.004)), 0, 0.12)
                st_ = lowpass(st_, 2200 + 800 * rng.random())
                st_ = [x * math.exp(-i / (0.05 * SR)) * min(1, i / (0.002 * SR)) for i, x in enumerate(st_)]
                mix(buf, st_, t0 + off * beat, 0.5)
        if b % 4 == 3:
            for k in range(4):
                mix(buf, tom(midi(root + 12 - 3 * k), rng, 1.0), t0 + (3 + k * 0.25) * beat, 0.5)

    return render_loop(bars, bar_len, fill)


# ---------------------------------------------------------------- verify

def band_energy(s, lo=None, hi=None):
    x = s
    if hi is not None:
        x = lowpass(lowpass(x, hi), hi)
    if lo is not None:
        x = highpass(highpass(x, lo), lo)
    return sum(v * v for v in x)


def verify():
    ok = True
    bad = []
    for name in sorted(os.listdir(SFX_DIR)):
        if not name.endswith(".wav"):
            continue
        s = read(os.path.join(SFX_DIR, name))
        peak = max(abs(v) for v in s)
        first = next(i for i, v in enumerate(s) if abs(v) >= 0.25 * peak)
        attack_ms = first * 1000.0 / SR
        head = s[: int(0.03 * SR)]
        tot = sum(v * v for v in head) + 1e-12
        low = band_energy(head, hi=200) / tot
        high = band_energy(head, lo=2000) / tot
        passed = attack_ms < 5.0 and low > 0.002 and high > 0.002
        if not passed:
            ok = False
            bad.append("%s attack=%.1fms low=%.4f high=%.4f" % (name, attack_ms, low, high))
    print("SFX files checked: %d, failing: %d" % (len([n for n in os.listdir(SFX_DIR) if n.endswith('.wav')]), len(bad)))
    for b in bad:
        print("  FAIL", b)
    for name, bpm in (("menu.wav", 88.0), ("combat.wav", 118.0)):
        s = read(os.path.join(MUSIC_DIR, name))
        dur = len(s) / SR
        seam = abs(s[-1] - s[0])
        bar = int(SR * 240.0 / bpm)
        bars = [s[i:i + bar] for i in range(0, len(s) - bar + 1, bar)]
        repeats = 0
        for i in range(len(bars)):
            for j in range(i):
                d = max(abs(a - b) for a, b in zip(bars[i][::7], bars[j][::7]))
                if d < 0.01:
                    repeats += 1
        crest_min = 99.0
        win = 2 * SR
        for i in range(0, len(s) - win, win):
            w = s[i:i + win]
            rms = math.sqrt(sum(v * v for v in w) / len(w)) + 1e-9
            crest_min = min(crest_min, max(abs(v) for v in w) / rms)
        passed = dur >= 45.0 and seam < 0.02 and repeats == 0 and crest_min > 1.6
        ok = ok and passed
        print("%s %s: %.1f s, seam %.4f, repeated bars %d, min crest factor %.2f (a square lead would be near 1.0)"
              % ("PASS" if passed else "FAIL", name, dur, seam, repeats, crest_min))
    print("ALL PASS" if ok else "VERIFY FAILED")
    return ok


def main():
    random.seed(5)
    if "--verify" in sys.argv:
        sys.exit(0 if verify() else 1)
    for name, s in make_sfx().items():
        write(os.path.join(SFX_DIR, name + ".wav"), s)
        print("sfx", name, "%.2f s" % (len(s) / SR))
    for name, fn in (("menu", make_menu), ("combat", make_combat)):
        s = fn()
        write(os.path.join(MUSIC_DIR, name + ".wav"), s)
        print("music", name, "%.1f s" % (len(s) / SR))


if __name__ == "__main__":
    main()
