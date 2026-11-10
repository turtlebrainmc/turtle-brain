"""Turtle Brain AI voice: Kokoro (Apache-2.0) voice am_puck plus a light robot effect.

Usage: python3 tb_voice.py "Line of dialogue" out.mp3
"""
import re
import subprocess
import sys

import soundfile as sf
from kokoro_onnx import Kokoro

VOICE, LANG, SPEED = "am_puck", "en-us", 1.0
# Fixed pronunciations: word -> IPA
PRONOUNCE = {
    "lebotats": "liːbˈoʊtæts",  # LEE-BOW-tats
}
FX = "chorus=0.6:0.8:40:0.35:0.25:2,highpass=f=120,aecho=0.8:0.6:25:0.18,volume=1.6"

_k = None


def say(text, out_path):
    global _k
    if _k is None:
        _k = Kokoro("kokoro-v1.0.onnx", "voices-v1.0.bin")
    # phonemize piece by piece so custom words get their fixed IPA
    parts = re.split(r"(\b(?:%s)\b)" % "|".join(PRONOUNCE), text, flags=re.I)
    ph = ""
    for p in parts:
        if p.lower() in PRONOUNCE:
            ph += " " + PRONOUNCE[p.lower()] + " "
        elif p:
            ph += _k.tokenizer.phonemize(p, LANG)
    ph = re.sub(r"\s+", " ", ph).strip()
    samples, sr = _k.create(ph, voice=VOICE, speed=SPEED, is_phonemes=True)
    sf.write("/tmp/_tb.wav", samples, sr)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", "/tmp/_tb.wav", "-af", FX,
                    "-c:a", "libmp3lame", "-q:a", "3", out_path], check=True)
    return ph


if __name__ == "__main__":
    print(say(sys.argv[1], sys.argv[2]))
