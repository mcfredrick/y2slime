"""Synthesize the game's sound effects as 16-bit mono WAVs.

Run: uv run --with numpy python -I tools/sfx.py
Writes godot_web_game/assets/sfx/<name>.wav.
"""

import wave
from pathlib import Path

import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "godot_web_game" / "assets" / "sfx"


def tone(freq, seconds, decay):
    t = np.arange(int(RATE * seconds)) / RATE
    return np.sin(2 * np.pi * freq * t) * np.exp(-t * decay)


def boop():
    """A bright two-note chime, like a turn-of-the-century messenger alert."""
    a = tone(1318.5, 0.35, 9) + 0.4 * tone(2637, 0.35, 14)
    b = tone(1760, 0.5, 7) + 0.4 * tone(3520, 0.5, 12)
    return np.concatenate([a[: int(RATE * 0.09)], b])


def munch():
    """A soft squelchy bite: filtered noise with a falling wobble."""
    n = int(RATE * 0.22)
    t = np.arange(n) / RATE
    noise = np.random.default_rng(4).standard_normal(n)
    smooth = np.convolve(noise, np.ones(40) / 40, mode="same")
    wobble = np.sin(2 * np.pi * (300 - 600 * t) * t)
    return (smooth * 4 + wobble * 0.5) * np.exp(-t * 18) * 0.5


def write(name, samples):
    samples = np.clip(samples / max(np.max(np.abs(samples)), 1e-9) * 0.8, -1, 1)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((samples * 32767).astype(np.int16).tobytes())


OUT.mkdir(parents=True, exist_ok=True)
write("boop", boop())
write("munch", munch())
