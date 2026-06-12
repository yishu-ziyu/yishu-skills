#!/usr/bin/env python3
"""transcribe_chunk.py — FunASR per-chunk transcription for sub-agent dispatch.
Usage: python transcribe_chunk.py <input.wav> <output_prefix>
Outputs: <output_prefix>.srt and <output_prefix>.txt with speaker + timestamps.
Requires: .venv-funasr activated (or funasr importable).
"""
import os
import re
import sys
import time
from pathlib import Path

# Sanity check: funasr must be importable
try:
    from funasr import AutoModel
except ImportError:
    print("❌ funasr not installed. Run: bash setup.sh", file=sys.stderr)
    sys.exit(1)


def fmt_ts(sec: float) -> str:
    h = int(sec // 3600)
    m = int((sec % 3600) // 60)
    s = int(sec % 60)
    ms = int((sec - int(sec)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"  # SRT format uses comma


TAG_RE = re.compile(r"<\|[^|]+\|>")


def strip_tags(text: str) -> str:
    return TAG_RE.sub("", text).strip()


def main():
    if len(sys.argv) < 3:
        print("Usage: transcribe_chunk.py <input.wav> <output_prefix>", file=sys.stderr)
        sys.exit(1)

    wav_path = Path(sys.argv[1]).resolve()
    prefix = Path(sys.argv[2]).resolve()
    srt_path = prefix.with_suffix(".srt")
    txt_path = prefix.with_suffix(".txt")

    if not wav_path.exists():
        print(f"❌ Input not found: {wav_path}", file=sys.stderr)
        sys.exit(1)

    # Pick device: MPS for Apple Silicon, CUDA for NVIDIA, else CPU
    import torch
    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda:0"
    else:
        device = "cpu"

    print(f"[transcribe_chunk] Loading FunASR (device={device})...", file=sys.stderr)
    t0 = time.time()
    model = AutoModel(
        model="iic/SenseVoiceSmall",
        vad_model="fsmn-vad",
        spk_model="cam++",
        device=device,
    )
    print(f"[transcribe_chunk] Model loaded in {time.time()-t0:.1f}s", file=sys.stderr)

    print(f"[transcribe_chunk] Transcribing {wav_path}...", file=sys.stderr)
    t0 = time.time()
    result = model.generate(
        input=str(wav_path),
        language="auto",  # zh / en / ja / ko / yue / auto
        use_itn=True,
        batch_size_s=60,
    )
    audio_dur = time.time() - t0
    print(f"[transcribe_chunk] Inference done in {audio_dur:.1f}s", file=sys.stderr)

    # Extract sentence_info (FunASR returns list with one item containing sentence_info)
    srt_lines = []
    txt_lines = []
    if not result:
        print("⚠️ Empty result from FunASR", file=sys.stderr)
        srt_path.write_text("")
        txt_path.write_text("")
        return

    item = result[0] if isinstance(result, list) else result
    sentences = item.get("sentence_info", []) if isinstance(item, dict) else []
    idx = 0
    for sent in sentences:
        start_ms = sent.get("start", 0)
        end_ms = sent.get("end", 0)
        # FunASR's per-sentence key is "sentence" (not "text")
        text = strip_tags(sent.get("sentence", "") or sent.get("text", ""))
        spk = sent.get("spk", 0)
        if not text:
            continue
        idx += 1
        srt_lines.append(f"{idx}\n{fmt_ts(start_ms/1000.0)} --> {fmt_ts(end_ms/1000.0)}\n{text}\n")
        txt_lines.append(f"[{fmt_ts(start_ms/1000.0)}] Speaker {spk}: {text}")

    srt_path.write_text("\n".join(srt_lines))
    txt_path.write_text("\n".join(txt_lines) + "\n")
    print(f"[transcribe_chunk] Wrote {srt_path} ({srt_path.stat().st_size} bytes, {idx} segments)", file=sys.stderr)
    print(f"[transcribe_chunk] Wrote {txt_path} ({txt_path.stat().st_size} bytes)", file=sys.stderr)
    print(f"[transcribe_chunk] DONE: {idx} segments in {audio_dur:.1f}s inference time")


if __name__ == "__main__":
    main()
