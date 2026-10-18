"""Compose and synthesize original CC0 café music and game cues.

Python 3 + NumPy. No recordings, downloaded samples, or external instruments.
The same score is exported to Luau for the game's built-in chime arrangement.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio"
RATE = 32000
BPM = 90
BEATS = 64
SECONDS_PER_BEAT = 60 / BPM

CUES = {
    "Click": [(0, 84, .12, .20)],
    "Claim": [(0, 72, .28, .65), (.12, 76, .28, .60), (.24, 79, .35, .60), (.40, 84, .55, .55)],
    "Collect": [(0, 79, .22, .60), (.09, 84, .25, .55), (.18, 88, .40, .50)],
    "BuyRecipe": [(0, 72, .30, .65), (.15, 76, .30, .60), (.30, 79, .30, .60), (.45, 84, .60, .55)],
    "UpgradeOven": [(0, 67, .25, .60), (.12, 72, .28, .60), (.26, 79, .55, .55)],
    "BuyModifier": [(0, 84, .25, .55), (.12, 88, .25, .55), (.24, 91, .50, .45)],
    "UpgradePermanent": [(0, 72, .32, .60), (.15, 79, .32, .55), (.30, 84, .32, .55), (.45, 88, .60, .50)],
    "Rebirth": [(i * .13, note, .65, .62) for i, note in enumerate((60, 64, 67, 72, 76, 79, 84, 88))],
    "Error": [(0, 60, .17, .35), (.16, 59, .23, .30)],
}


def score():
    # Cmaj7 / Am7 / Fmaj7 / G6, with an original two-phrase melody.
    chords = [(48, 60, 64, 67, 71), (45, 57, 60, 64, 67),
              (41, 57, 60, 64, 69), (43, 55, 59, 62, 67)]
    melody = [
        (76, 79, 83, 79, 76, 74), (72, 76, 79, 76, 74, 72),
        (77, 81, 84, 81, 79, 76), (74, 79, 83, 81, 79, 74),
        (79, 83, 86, 83, 79, 76), (76, 79, 84, 83, 79, 76),
        (77, 81, 84, 86, 84, 81), (79, 74, 71, 74, 76, 79),
        (76, 79, 84, 83, 79, 76), (72, 76, 81, 79, 76, 72),
        (77, 81, 84, 81, 79, 77), (74, 79, 83, 86, 83, 79),
        (79, 83, 84, 83, 79, 76), (76, 79, 81, 79, 76, 72),
        (77, 81, 79, 77, 76, 74), (74, 71, 67, 71, 74, 79),
    ]
    notes = []
    for bar in range(16):
        beat = bar * 4
        root, *voicing = chords[bar % 4]
        for offset, pitch in enumerate(voicing):
            notes.append((beat + offset * .035, pitch, 3.6, .16, "keys"))
        notes.extend([(beat, root, 1.3, .30, "bass"), (beat + 2, root + 7, 1.1, .23, "bass")])
        for offset, pitch in zip((.5, 1, 1.5, 2.5, 3, 3.5), melody[bar]):
            notes.append((beat + offset, pitch, .42 if offset != 3.5 else .48, .30, "bell"))
    return sorted(notes)


def tone(midi, seconds, instrument):
    t = np.arange(max(1, round(seconds * RATE))) / RATE
    hz = 440 * 2 ** ((midi - 69) / 12)
    if instrument == "bass":
        signal = np.sin(2 * np.pi * hz * t) + .18 * np.sin(2 * np.pi * hz * 2 * t)
        envelope = (1 - np.exp(-t * 70)) * np.exp(-t * 3.5)
    elif instrument == "keys":
        signal = (np.sin(2 * np.pi * hz * t) + .22 * np.sin(2 * np.pi * hz * 2 * t)
                  + .08 * np.sin(2 * np.pi * hz * 3 * t))
        envelope = (1 - np.exp(-t * 90)) * np.exp(-t * 1.8)
    else:
        signal = (np.sin(2 * np.pi * hz * t) + .24 * np.sin(2 * np.pi * hz * 2 * t) * np.exp(-t * 10)
                  + .06 * np.sin(2 * np.pi * hz * 3 * t))
        envelope = (1 - np.exp(-t * 220)) * np.exp(-t * 5)
    release = np.minimum(1, (seconds - t) / .035)
    return signal * envelope * np.maximum(0, release)


def add(buffer, sample, offset, gain, pan=0, wrap=False):
    start = round(offset * RATE)
    stereo = sample[:, None] * np.array([math.sqrt((1 - pan) / 2), math.sqrt((1 + pan) / 2)]) * gain
    if wrap:
        # Echo tails crossing the boundary land at the start for a continuous loop.
        indices = (start + np.arange(len(sample))) % len(buffer)
        np.add.at(buffer, indices, stereo)
    else:
        count = min(len(sample), len(buffer) - start)
        if count > 0:
            buffer[start:start + count] += stereo[:count]


def write_wav(name, buffer):
    peak = float(np.max(np.abs(buffer)))
    if peak > .87:
        buffer = buffer * (.87 / peak)
    pcm = np.round(np.clip(buffer, -1, 1) * 32767).astype("<i2")
    path = OUT / name
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    return {"file": name, "seconds": len(buffer) / RATE, "sampleRate": RATE,
            "channels": 2, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    notes = score()
    buffer = np.zeros((round(BEATS * SECONDS_PER_BEAT * RATE), 2))
    for beat, midi, length, gain, instrument in notes:
        sample = tone(midi, length * SECONDS_PER_BEAT, instrument)
        pan = -.18 if instrument == "keys" else .18 if instrument == "bell" else 0
        add(buffer, sample, beat * SECONDS_PER_BEAT, gain, pan, wrap=True)
        if instrument == "bell":
            add(buffer, sample, (beat + .75) * SECONDS_PER_BEAT, gain * .16, -pan, wrap=True)
    rng = np.random.default_rng(127)
    for beat in range(BEATS):
        t = np.arange(round(.22 * RATE)) / RATE
        kick = np.sin(2 * np.pi * (48 * t + 55 * (1 - np.exp(-t * 35)) / 35)) * np.exp(-t * 24)
        add(buffer, kick, beat * SECONDS_PER_BEAT, .10 if beat % 2 == 0 else .055, wrap=True)
        t = np.arange(round(.07 * RATE)) / RATE
        noise = rng.uniform(-1, 1, len(t))
        hat = (noise - np.roll(noise, 1)) * np.exp(-t * 70)
        add(buffer, hat, (beat + .5) * SECONDS_PER_BEAT, .016, .3, wrap=True)
    records = [write_wav("CookieCornerCafe.wav", buffer)]
    for name, cue in CUES.items():
        length = max(start + duration for start, _, duration, _ in cue) + .12
        buffer = np.zeros((round(length * RATE), 2))
        for start, midi, duration, gain in cue:
            add(buffer, tone(midi, duration, "bell"), start, gain * .7)
        records.append(write_wav(name + ".wav", buffer))

    module = ["-- Generated by tools/build_audio.py; original CC0 composition.", "return {",
              f"\tBPM = {BPM},", f"\tBeats = {BEATS},", "\tNotes = {"]
    for beat, midi, length, gain, instrument in notes:
        # The bundled sampler is deliberately sparser than the mixed recording.
        if instrument == "keys":
            continue
        module.append(f"\t\t{{ {beat:g}, {midi}, {length:g}, {gain:g} }},")
    module.extend(["\t},", "\tCues = {"])
    for name, cue in CUES.items():
        entries = ", ".join(f"{{ {start:g}, {midi}, {length:g}, {gain:g} }}" for start, midi, length, gain in cue)
        module.append(f"\t\t{name} = {{ {entries} }},")
    module.extend(["\t},", "}", ""])
    (ROOT / "src/shared/MusicScore.luau").write_text("\n".join(module))
    (OUT / "manifest.json").write_text(json.dumps({"license": "CC0-1.0", "title": "Cookie Corner Café",
                                                  "bpm": BPM, "beats": BEATS, "files": records}, indent=2) + "\n")
    print(f"Generated an original {BEATS * SECONDS_PER_BEAT:.2f}s music loop and {len(CUES)} sound effects.")


if __name__ == "__main__":
    main()
