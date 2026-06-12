#!/bin/bash
# cleanup.sh — Remove ASR intermediate files after final .md is generated.
# Usage: bash cleanup.sh [--purge] [--dry-run] [--keep-wav] [DIR]
# Operates on CWD by default, or DIR if provided.
#
# Default behavior (RECOMMENDED after final .md is written):
#   - Delete chunks/ from transcript_run_*/ and transcript_<backend>_part<N>/
#   - KEEP merged/all.txt + merged/all.srt (small, for re-cleanup reference)
#
# Flags:
#   --purge      Also delete merged/ and the parent dir entirely
#   --keep-wav   Keep chunks/ (override default)
#   --dry-run    Print what would be deleted, do not delete
#   --help       Show this help
#
# Examples:
#   bash cleanup.sh --dry-run
#   bash cleanup.sh                    # delete chunks/, keep merged/
#   bash cleanup.sh --purge            # delete everything
#   bash cleanup.sh /path/to/audio/dir # operate on specific dir
set -e

DRY_RUN=0
KEEP_WAV=0
PURGE=0
TARGET_DIR="."

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --keep-wav) KEEP_WAV=1 ;;
    --purge) PURGE=1 ;;
    --help|-h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      if [ -d "$arg" ]; then
        TARGET_DIR="$arg"
      else
        echo "Not a directory: $arg" >&2
        exit 1
      fi
      ;;
  esac
done

cd "$TARGET_DIR"

DELETED=0
for dir in transcript_run_* transcript_*_part*; do
  if [ ! -d "$dir" ]; then
    continue
  fi
  echo "[cleanup] Found: $dir"

  if [ -d "$dir/chunks" ]; then
    if [ "$KEEP_WAV" = 1 ]; then
      echo "  keeping $dir/chunks/ (--keep-wav)"
    else
      if [ "$DRY_RUN" = 1 ]; then
        echo "  would delete $dir/chunks/"
      else
        echo "  deleting $dir/chunks/"
        rm -rf "$dir/chunks"
        DELETED=$((DELETED + 1))
      fi
    fi
  fi

  if [ "$PURGE" = 1 ]; then
    if [ "$DRY_RUN" = 1 ]; then
      echo "  would purge $dir (entire dir)"
    else
      echo "  purging $dir (entire dir)"
      rm -rf "$dir"
      DELETED=$((DELETED + 1))
    fi
  fi
done

if [ "$DRY_RUN" = 1 ]; then
  echo ""
  echo "[cleanup] DRY RUN — no files deleted. Re-run without --dry-run to apply."
elif [ "$DELETED" = 0 ]; then
  echo "[cleanup] No matching transcript_run_*/ or transcript_*_part*/ dirs in $TARGET_DIR"
else
  echo "[cleanup] Done. Deleted $DELETED chunks/ dir(s)."
  if [ "$KEEP_WAV" = 0 ] && [ "$PURGE" = 0 ]; then
    echo "[cleanup] Kept: merged/all.txt + merged/all.srt (per part) for re-cleanup reference"
  fi
fi
