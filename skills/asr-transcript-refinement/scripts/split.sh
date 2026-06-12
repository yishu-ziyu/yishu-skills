#!/bin/bash
# split.sh — Split long audio into 10-min chunks for parallel transcription
# Usage: split.sh <input_audio> [output_dir] [chunk_seconds]
# Default chunk_seconds=600 (10 min). For <10min audio, just copies the file.
set -e

INPUT="$1"
OUT_DIR="${2:-$(dirname "$INPUT")/chunks}"
CHUNK_SEC="${3:-600}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 <input_audio> [output_dir] [chunk_seconds=600]"
  exit 1
fi

mkdir -p "$OUT_DIR"
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | cut -d. -f1)
echo "Input: $INPUT  Duration: ${DUR}s  Chunk: ${CHUNK_SEC}s"

if [ "$DUR" -le "$CHUNK_SEC" ]; then
  echo "Audio is < ${CHUNK_SEC}s, no splitting needed. Copying to ${OUT_DIR}/."
  ffmpeg -y -i "$INPUT" -ac 1 -ar 16000 -acodec pcm_s16le "${OUT_DIR}/chunk_00.wav" 2>/dev/null
  echo "Chunks: 1 (no split)"
  echo "$OUT_DIR"
  exit 0
fi

# Use segment muxer
PREFIX="${OUT_DIR}/chunk_"
ffmpeg -y -i "$INPUT" -ac 1 -ar 16000 -acodec pcm_s16le \
  -f segment -segment_time "$CHUNK_SEC" -reset_timestamps 1 \
  "${PREFIX}%02d.wav" 2>/dev/null

# List chunks
N=$(ls -1 "${OUT_DIR}"/chunk_*.wav 2>/dev/null | wc -l | tr -d ' ')
echo "Chunks: $N written to ${OUT_DIR}/"
ls -lh "${OUT_DIR}"/chunk_*.wav
echo "$OUT_DIR"
