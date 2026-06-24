#!/bin/bash
# pipeline.sh — One-click speed-first pipeline for asr-transcript-refinement.
# Usage: pipeline.sh <input_audio> [output_dir]
# Steps: transcribe (Fun-ASR-Nano GGUF default; Stepfun cloud if STEP_API_KEY) →
#        verify raw output → ready for main LLM cleanup pass.
#
# Notes:
#   - GGUF backend has built-in FSMN-VAD, so NO ffmpeg chunking needed.
#   - Single binary + no Python venv + ~1s startup = much faster than the old
#     PyTorch SenseVoiceSmall path (which reloaded the model per chunk).
#   - For Stepfun cloud, audio is auto-chunked to 3 min (10MB SSE base64 limit).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Real working GGUF backend lives outside the skill (user's 2026-06-22 install).
NANO_DIR="${NANO_DIR:-$HOME/Downloads/项目与数据/agent_audio_funasr}"

INPUT="${1:?Usage: $0 <input_audio> [output_dir]}"
OUT_DIR="${2:-$(dirname "$INPUT")/transcript_run_$(date +%Y%m%d_%H%M%S)}"

if [ ! -f "$INPUT" ]; then
  echo "❌ Input not found: $INPUT"
  exit 1
fi

# Backend selection — Stepfun cloud only when explicitly opted in via STEP_ASR_BACKEND=stepfun.
# (Previously auto-selected on STEP_API_KEY presence, but the user always has STEP_API_KEY set
#  for unrelated tooling — auto-selection made every run go to cloud unintentionally.)
if [ "${STEP_ASR_BACKEND:-}" = "stepfun" ]; then
  BACKEND="stepfun"
else
  BACKEND="nano"
  if [ ! -x "$NANO_DIR/llama-funasr-nano" ]; then
    echo "❌ Nano binary not found at $NANO_DIR/llama-funasr-nano"
    echo "   Expected layout from 2026-06-22 install. To use Stepfun instead:"
    echo "   STEP_ASR_BACKEND=stepfun bash $0 <audio>"
    exit 1
  fi
fi

mkdir -p "$OUT_DIR"

echo "=== ASR Pipeline (speed-first, backend=$BACKEND) ==="
echo "Input:    $INPUT"
echo "Output:   $OUT_DIR"
[ "$BACKEND" = "nano" ] && echo "Nano dir:  $NANO_DIR"
echo ""

# Step 1: transcribe
if [ "$BACKEND" = "nano" ]; then
  echo "--- Step 1/2: transcribe (Fun-ASR-Nano GGUF, built-in VAD, no chunking) ---"
  PREFIX="$OUT_DIR/source"
  python3 "$NANO_DIR/transcribe_funasr.py" "$INPUT" "$PREFIX.txt"
else
  echo "--- Step 1/2: transcribe (Stepfun cloud, auto-chunked 3min) ---"
  CHUNKS_DIR="$OUT_DIR/chunks"
  bash "$SCRIPT_DIR/split.sh" "$INPUT" "$CHUNKS_DIR" 180
  for chunk_wav in "$CHUNKS_DIR"/chunk_*.wav; do
    chunk_prefix="${chunk_wav%.wav}"
    echo "[chunk] $(basename "$chunk_wav")"
    python3 "$SCRIPT_DIR/transcribe_stepfun.py" "$chunk_wav" "$chunk_prefix"
  done
  # Merge Stepfun chunks
  mkdir -p "$OUT_DIR/merged"
  python3 "$SCRIPT_DIR/merge.py" "$CHUNKS_DIR" "$OUT_DIR/merged/all.srt" "$OUT_DIR/merged/all.txt"
fi

# Step 2: verify (raw ASR — expect some hits, esp. for Nano since no timestamp leak)
echo ""
echo "--- Step 2/2: verify (raw output, expect false positives) ---"
if [ "$BACKEND" = "nano" ]; then
  SRT="$OUT_DIR/source.srt"
  TXT="$OUT_DIR/source.txt"
else
  SRT="$OUT_DIR/merged/all.srt"
  TXT="$OUT_DIR/merged/all.txt"
fi
echo "SRT:  $SRT"
echo "TXT:  $TXT"
echo ""
echo "✅ Pipeline done. Next: hand off SRT/TXT to main LLM for cleanup pass,"
echo "   then run: bash $SCRIPT_DIR/verify.sh <cleaned_transcript.md>"