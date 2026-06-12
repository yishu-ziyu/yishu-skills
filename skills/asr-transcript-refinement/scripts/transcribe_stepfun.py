#!/usr/bin/env python3
"""transcribe_stepfun.py — Stepfun ASR (stepaudio-2.5-asr) per-chunk transcription.

Cloud backend for the asr-transcript-refinement skill. Same output interface as
transcribe_chunk.py (FunASR) so merge.py and verify.sh work unchanged.

Requires: STEP_API_KEY env var (Step Plan subscription key, base URL
https://api.stepfun.com/step_plan/v1). Get one at https://platform.stepfun.com.

Usage: python transcribe_stepfun.py <input.wav> <output_prefix>
Outputs: <output_prefix>.srt and <output_prefix>.txt

Pricing: 0.15 元/小时 for stepaudio-2.5-asr (cheapest ASR model on Step Plan).
The 5-hour weekly quota is more than enough for typical podcast runs.
"""
import base64
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

API_KEY = os.environ.get("STEP_API_KEY")
URL = "https://api.stepfun.com/step_plan/v1/audio/asr/sse"
MODEL = "stepaudio-2.5-asr"
SENTINEL_END_RE = re.compile(r"[.!?。？！]")


def fmt_ts(sec: float) -> str:
    """SRT timestamp format: HH:MM:SS,mmm (comma, not period)."""
    h = int(sec // 3600)
    m = int((sec % 3600) // 60)
    s = int(sec % 60)
    ms = int((sec - int(sec)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def transcribe(audio_path: Path) -> list[tuple[int, int, str]]:
    """Returns list of (start_ms, end_ms, text) segments from the SSE stream."""
    with open(audio_path, "rb") as f:
        audio_b64 = base64.b64encode(f.read()).decode()

    # Auto-detect format from extension (split.sh always produces wav, but be safe)
    ext = audio_path.suffix.lower().lstrip(".")
    fmt_type = ext if ext in ("wav", "mp3", "ogg", "pcm") else "wav"

    payload = {
        "audio": {
            "data": audio_b64,
            "input": {
                "transcription": {
                    "model": MODEL,
                    "language": "zh",
                    "enable_itn": True,
                    "enable_timestamp": True,
                },
                "format": {
                    "type": fmt_type,
                    "rate": 16000,
                    "bits": 16,
                    "channel": 1,
                },
            },
        }
    }

    headers = {
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
        "Authorization": f"Bearer {API_KEY}",
    }

    segments: list[tuple[int, int, str]] = []
    buf_text = ""
    buf_start: int | None = None
    buf_end: int | None = None

    t0 = time.time()
    with requests.post(URL, json=payload, headers=headers, stream=True, timeout=600) as resp:
        if resp.status_code != 200:
            print(f"❌ HTTP {resp.status_code}: {resp.text[:500]}", file=sys.stderr)
            sys.exit(1)
        for line in resp.iter_lines(decode_unicode=True):
            if not line or not line.startswith("data:"):
                continue
            data_str = line[5:].strip()
            if not data_str:
                continue
            try:
                event = json.loads(data_str)
            except json.JSONDecodeError:
                continue
            etype = event.get("type")
            if etype == "transcript.text.delta":
                d = event.get("delta", "")
                st = event.get("start_time")
                et = event.get("end_time")
                if st is not None and buf_start is None:
                    buf_start = st
                if et is not None:
                    buf_end = et
                buf_text += d
                # Flush on sentence boundary for SRT-level granularity
                if SENTINEL_END_RE.search(d) and buf_text.strip():
                    segments.append((buf_start or 0, buf_end or 0, buf_text.strip()))
                    buf_text = ""
                    buf_start = None
                    buf_end = None
            elif etype == "transcript.text.done":
                if buf_text.strip():
                    segments.append((buf_start or 0, buf_end or 0, buf_text.strip()))
                usage = event.get("usage") or {}
                elapsed = time.time() - t0
                print(
                    f"[transcribe_stepfun] API: total_tokens={usage.get('total_tokens')} "
                    f"elapsed={elapsed:.1f}s",
                    file=sys.stderr,
                )
            elif etype == "error":
                print(f"❌ API error: {event.get('message')}", file=sys.stderr)
                sys.exit(1)

    return segments


def main():
    if not API_KEY:
        print(
            "❌ STEP_API_KEY not set. Get one at https://platform.stepfun.com\n"
            "   export STEP_API_KEY=sk-...  (or your Step Plan key)",
            file=sys.stderr,
        )
        sys.exit(1)
    if len(sys.argv) < 3:
        print(
            "Usage: transcribe_stepfun.py <input.wav> <output_prefix>",
            file=sys.stderr,
        )
        sys.exit(1)

    wav_path = Path(sys.argv[1]).resolve()
    prefix = Path(sys.argv[2]).resolve()
    srt_path = prefix.with_suffix(".srt")
    txt_path = prefix.with_suffix(".txt")

    if not wav_path.exists():
        print(f"❌ Input not found: {wav_path}", file=sys.stderr)
        sys.exit(1)

    size_mb = wav_path.stat().st_size / 1024 / 1024
    print(
        f"[transcribe_stepfun] Transcribing {wav_path.name} ({size_mb:.2f} MB) via {MODEL}...",
        file=sys.stderr,
    )
    t0 = time.time()
    segments = transcribe(wav_path)
    elapsed = time.time() - t0

    # SRT: index, timestamps, text (matches FunASR output)
    srt_lines = []
    txt_lines = []
    for idx, (start_ms, end_ms, text) in enumerate(segments, 1):
        srt_lines.append(
            f"{idx}\n{fmt_ts(start_ms/1000.0)} --> {fmt_ts(end_ms/1000.0)}\n{text}\n"
        )
        # TXT format mirrors FunASR's `[HH:MM:SS.mmm] Speaker N: text` for merge.py compat
        txt_lines.append(f"[{fmt_ts(start_ms/1000.0)}] Speaker 0: {text}")

    srt_path.write_text("\n".join(srt_lines))
    txt_path.write_text("\n".join(txt_lines) + "\n")
    print(
        f"[transcribe_stepfun] Wrote {srt_path.name} ({srt_path.stat().st_size} bytes, "
        f"{len(segments)} segments) in {elapsed:.1f}s",
        file=sys.stderr,
    )
    print(f"[transcribe_stepfun] DONE: {len(segments)} segments")


if __name__ == "__main__":
    main()
