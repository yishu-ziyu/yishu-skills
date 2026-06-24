#!/usr/bin/env python3
"""transcribe_chunk.py — GGUF binary per-chunk transcription for sub-agent dispatch.

Uses llama-funasr-cli (Fun-ASR-Nano GGUF) as subprocess — no Python venv, no PyTorch.
Outputs: <output_prefix>.srt and <output_prefix>.txt (same interface as before).
"""
import re
import subprocess
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
NANO_BIN = SKILL_DIR / ".bin/llama-funasr-nano"
NANO_ENC = SKILL_DIR / "gguf/funasr-encoder-f16.gguf"
NANO_LLM = SKILL_DIR / "gguf/qwen3-0.6b-q8_0.gguf"
NANO_VAD = SKILL_DIR / "gguf/fsmn-vad.gguf"

TAG_RE = re.compile(r"<\|[^|]+\|>")


def strip_tags(text: str) -> str:
    return TAG_RE.sub("", text).strip()


def fmt_ts(sec: float) -> str:
    h = int(sec // 3600)
    m = int((sec % 3600) // 60)
    s = int(sec % 60)
    ms = int((sec - int(sec)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def main():
    if len(sys.argv) < 3:
        print("Usage: transcribe_chunk.py <input.wav> <output_prefix>", file=sys.stderr)
        sys.exit(1)

    wav_path = Path(sys.argv[1]).resolve()
    prefix = Path(sys.argv[2]).resolve()
    srt_path = prefix.with_suffix(".srt")
    txt_path = prefix.with_suffix(".txt")

    if not wav_path.exists():
        print(f"Input not found: {wav_path}", file=sys.stderr)
        sys.exit(1)

    for p, name in [(NANO_BIN, "llama-funasr-nano binary"), (NANO_ENC, "Nano encoder"),
                    (NANO_LLM, "Nano LLM"), (NANO_VAD, "VAD")]:
        if not p.exists():
            print(f"{name} not found: {p}", file=sys.stderr)
            print("Run: bash setup.sh", file=sys.stderr)
            sys.exit(1)

    print(f"[transcribe_chunk] Transcribing {wav_path.name} ({wav_path.stat().st_size / 1024 / 1024:.1f} MB)...", file=sys.stderr)
    t0 = time.time()
    result = subprocess.run(
        [str(NANO_BIN), "--enc", str(NANO_ENC), "-m", str(NANO_LLM),
         "--vad", str(NANO_VAD), "-a", str(wav_path)],
        capture_output=True, text=True, timeout=600,
    )
    elapsed = time.time() - t0

    if result.returncode != 0:
        print(f"Binary failed (exit {result.returncode}): {result.stderr[:200]}", file=sys.stderr)
        sys.exit(1)

    raw = result.stdout.strip()
    lines = [l for l in raw.split("\n")
             if l and not any(l.startswith(p) for p in ("[", "ggml", "llama", "sched", "graph", "~", "ggml_metal"))]
    text = lines[-1] if lines else ""

    if not text:
        print("Empty output from binary", file=sys.stderr)
        sys.exit(1)

    text = strip_tags(text)

    # Output: SRT + TXT (same format as FunASR backend for merge.py compat)
    srt_path.write_text(f"1\n00:00:00,000 --> 99:99:99,999\n{text}\n")
    txt_path.write_text(f"[00:00:00.000] Speaker 0: {text}\n")

    print(f"[transcribe_chunk] Wrote {srt_path.name} ({srt_path.stat().st_size} bytes) in {elapsed:.1f}s", file=sys.stderr)
    print(f"[transcribe_chunk] DONE: {elapsed:.1f}s")


if __name__ == "__main__":
    main()
