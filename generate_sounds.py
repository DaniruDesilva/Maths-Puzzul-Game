import wave
import math
import struct
import os
import random

os.makedirs('assets/sounds', exist_ok=True)

def write_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for s in samples:
            val = int(max(-1.0, min(1.0, s)) * 32767)
            w.writeframesraw(struct.pack('<h', val))

# 1. Thwack (Wood block / tactile thud sound)
# Mix of a fast sine sweep down and some noise
thwack = []
for i in range(3000): # ~68ms
    env = math.exp(-i / 500)
    freq = 300 * math.exp(-i / 1000) # fast drop
    s = math.sin(2 * math.pi * freq * i / 44100)
    noise = random.uniform(-1, 1) * 0.1
    thwack.append((s + noise) * env * 0.8)
write_wav('assets/sounds/thwack.wav', thwack)

# 2. Success (Nice glissando/chime)
success = []
for i in range(20000):
    env = math.exp(-i / 5000)
    freq = 600 + min(i, 5000) / 10 # slide up
    s = math.sin(2 * math.pi * freq * i / 44100)
    s += 0.5 * math.sin(2 * math.pi * (freq * 1.5) * i / 44100)
    success.append(s * env * 0.4)
write_wav('assets/sounds/success.wav', success)

# 3. Fanfare (C Major Arpeggio for victory)
fanfare = []
notes = [523.25, 659.25, 783.99, 1046.50]
for idx, freq in enumerate(notes):
    length = 6000 if idx < 3 else 30000
    for i in range(length):
        env = math.exp(-i / (length/3))
        s = math.sin(2 * math.pi * freq * i / 44100)
        s += 0.3 * math.sin(2 * math.pi * freq * 2 * i / 44100) # harmonic
        fanfare.append(s * env * 0.4)
write_wav('assets/sounds/level_complete.wav', fanfare)
