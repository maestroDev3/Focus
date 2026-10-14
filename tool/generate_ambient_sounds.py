"""Generates Focus' ambient sound loops (no third-party recordings).

Writes seamless 45-second mono loops as OGG Vorbis into
android/app/src/main/res/raw/: rain, soft noise, deep noise and fireplace.
Run from the repository root: python3 tool/generate_ambient_sounds.py
Needs numpy, scipy and ffmpeg.
"""

import os
import subprocess
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

RATE = 44100
SECONDS = 45
FADE = 3  # seconds of crossfade that make the loop seamless
OUT = "android/app/src/main/res/raw"
rng = np.random.default_rng(seed=7)


def white(n):
    return rng.standard_normal(n)


def pink(n):
    """Pink noise via spectral shaping (1/f power)."""
    spectrum = np.fft.rfft(white(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    freqs[0] = freqs[1]
    return np.fft.irfft(spectrum / np.sqrt(freqs), n)


def brown(n):
    signal = np.cumsum(white(n))
    return filt(signal, "highpass", 20)


def filt(signal, kind, cutoff, order=4):
    sos = butter(order, cutoff, btype=kind, fs=RATE, output="sos")
    return sosfilt(sos, signal)


def bursts(n, per_second, length_ms, band, decay_ms):
    """Short decaying noise bursts, e.g. rain drops or fire crackles."""
    out = np.zeros(n)
    count = int(per_second * n / RATE)
    length = int(RATE * length_ms / 1000)
    envelope = np.exp(-np.arange(length) / (RATE * decay_ms / 1000))
    for start in rng.integers(0, n - length, count):
        burst = filt(white(length), "bandpass", band, order=2) * envelope
        out[start:start + length] += burst * rng.uniform(0.2, 1.0)
    return out


def slow_swell(n, depth, period_s):
    t = np.arange(n) / RATE
    return 1 - depth / 2 + depth / 2 * np.sin(2 * np.pi * t / period_s)


def loop(signal):
    """Crossfades the extra tail into the start so the file loops smoothly."""
    fade = FADE * RATE
    body = signal[:-fade].copy()
    ramp = np.linspace(0, 1, fade)
    body[:fade] = body[:fade] * ramp + signal[-fade:] * (1 - ramp)
    return body


def normalize(signal, rms=0.12):
    signal = signal - np.mean(signal)
    signal *= rms / np.sqrt(np.mean(signal ** 2))
    peak = np.max(np.abs(signal))
    return signal * (0.9 / peak) if peak > 0.9 else signal


def rain(n):
    hiss = filt(filt(pink(n), "highpass", 400), "lowpass", 9000)
    drops = bursts(n, 90, 25, [1500, 7000], 6)
    return normalize(hiss * slow_swell(n, 0.25, 11) + 0.6 * normalize(drops))


def soft_noise(n):
    return normalize(filt(pink(n), "lowpass", 3500))


def deep_noise(n):
    return normalize(filt(brown(n), "lowpass", 900))


def fireplace(n):
    rumble = filt(brown(n), "lowpass", 400) * slow_swell(n, 0.4, 7)
    crackles = bursts(n, 14, 40, [900, 5000], 8)
    pops = bursts(n, 1.5, 120, [300, 2500], 30)
    return normalize(
        normalize(rumble) + 0.8 * normalize(crackles) + 0.5 * normalize(pops)
    )


SOUNDS = {
    "ambient_rain": rain,
    "ambient_soft_noise": soft_noise,
    "ambient_deep_noise": deep_noise,
    "ambient_fireplace": fireplace,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    n = (SECONDS + FADE) * RATE
    with tempfile.TemporaryDirectory() as tmp:
        for name, make in SOUNDS.items():
            samples = loop(make(n))
            wav = os.path.join(tmp, name + ".wav")
            wavfile.write(wav, RATE, (samples * 32767).astype(np.int16))
            subprocess.run(
                ["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
                 "-c:a", "libvorbis", "-q:a", "2",
                 os.path.join(OUT, name + ".ogg")],
                check=True,
            )
            print(name, os.path.getsize(os.path.join(OUT, name + ".ogg")) // 1024, "KB")


if __name__ == "__main__":
    main()
