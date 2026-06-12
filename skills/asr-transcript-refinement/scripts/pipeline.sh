#!/bin/bash
# pipeline.sh — One-click speed-first pipeline (no LLM cleanup; that's main thread's job)
# Usage: pipeline.sh <input_audio> [output_dir]
# Steps: split → transcribe (sequential) → merge → verify
# For >3 chunks, dispatch sub-agents in parallel from the main thread instead.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/../.venv-funasr"

INPUT="${1:?Usage: $0 <input_audio> [output_dir]}"
OUT_DIR="${2:-$(dirname "$INPUT")/transcript_run_$(date +%Y%m%d_%H%M%S)}"

if [ ! -f "$INPUT" ]; then
  echo "❌ Input not found: $INPUT"
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "❌ Venv not found at $VENV_DIR. Run: bash setup.sh"
  exit 1
fi

mkdir -p "$OUT_DIR"
CHUNKS_DIR="$OUT_DIR/chunks"
MERGED_DIR="$OUT_DIR/merged"

echo "=== ASR Transcript Pipeline (speed-first, sequential) ==="
echo "Input:    $INPUT"
echo "Output:   $OUT_DIR"
echo "Venv:     $VENV_DIR"
echo ""

# Step 1: split
echo "--- Step 1/4: split ---"
CHUNKS_DIR_RES=$(bash "$SCRIPT_DIR/split.sh" "$INPUT" "$CHUNKS_DIR" 600)
N_CHUNKS=$(ls -1 "$CHUNKS_DIR"/chunk_*.wav 2>/dev/null | wc -l | tr -d ' ')

# Step 2: transcribe each chunk (sequential — for parallel, dispatch sub-agents from main)
echo ""
# Backend selection: Stepfun cloud (fast, cheap) if STEP_API_KEY is set, else FunASR local
if [ -n "$STEP_API_KEY" ]; then
  BACKEND="stepfun"
  echo "--- Step 2/4: transcribe ($N_CHUNKS chunks, sequential) [backend=stepfun] ---"
  for chunk_wav in "$CHUNKS_DIR"/chunk_*.wav; do
    chunk_prefix="${chunk_wav%.wav}"
    echo "[chunk] $(basename "$chunk_wav")"
    python3 "$SCRIPT_DIR/transcribe_stepfun.py" "$chunk_wav" "$chunk_prefix"
  done
else
  BACKEND="funasr"
  echo "--- Step 2/4: transcribe ($N_CHUNKS chunks, sequential) [backend=funasr] ---"
  source "$VENV_DIR/bin/activate"
  for chunk_wav in "$CHUNKS_DIR"/chunk_*.wav; do
    chunk_prefix="${chunk_wav%.wav}"
    echo "[chunk] $(basename "$chunk_wav")"
    python "$SCRIPT_DIR/transcribe_chunk.py" "$chunk_wav" "$chunk_prefix"
  done
fi

# Step 3: merge
echo ""
echo "--- Step 3/4: merge ---"
mkdir -p "$MERGED_DIR"
python "$SCRIPT_DIR/merge.py" "$CHUNKS_DIR" "$MERGED_DIR/all.srt" "$MERGED_DIR/all.txt"

# Step 4: verify (raw FunASR output will have many hits — that's expected before LLM cleanup)
echo ""
echo "--- Step 4/4: verify (raw — expect hits) ---"
echo "(verify.sh is meant for post-LLM-cleanup transcripts. Raw ASR output will trigger patterns.)"
echo "RAW_SRT:  $MERGED_DIR/all.srt"
echo "RAW_TXT:  $MERGED_DIR/all.txt"
echo ""
echo "✅ Pipeline done. Next: hand off SRT/TXT to main LLM for cleanup pass,"
echo "   then run: bash $SCRIPT_DIR/verify.sh <cleaned_transcript.md>"
