#!/bin/bash
# verify.sh — Check for known-bad patterns in FINAL cleaned transcript.
# Usage: verify.sh <transcript.md>
# Exits non-zero if any patterns found. Run AFTER LLM cleanup, not on raw ASR output.
#
# Note: raw ASR output (Fun-ASR-Nano GGUF or Stepfun) is NOT verified here — it will
# naturally have tags / numerics / speaker fragments. LLM cleanup is expected to
# remove those. Run this on the post-cleanup .md to confirm the cleanup pass worked.
set -e

FILE="${1:?Usage: $0 <transcript.md>}"
if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 2
fi

# Only check the TRANSCRIPT body, not the meta-documentation section.
# Convention: transcript body is between the first "---" separator and the
# "## 精修说明" (or similar) section. Extract just that range.
TMP=$(mktemp)
HEADING_LINE=$(grep -nE '^## ' "$FILE" | head -1 | cut -d: -f1)
if [ -n "$HEADING_LINE" ]; then
  head -n $((HEADING_LINE - 1)) "$FILE" > "$TMP"
else
  cp "$FILE" "$TMP"
fi

# Patterns that should NEVER appear in a cleaned transcript.
# These are the cleanup-pass failures we want to catch.
PATTERNS=(
  # FunASR metadata tag leakage (cleanup should strip <|...|>)
  '<\|zh\|>'
  '<\|NEUTRAL\|>'
  '<\|Speech\|>'
  '<\|withitn\|>'
  '<\|HAPPY\|>'
  '<\|SAD\|>'
  '<\|ANGRY\|>'
  '<\|SURPRISED\|>'
  # Cleanup missed speaker labels in raw format
  '^Speaker [0-9]+:'
  '\[Speaker [0-9]+\]'
  # Cleanup missed time-prefix lines (FunASR TXT format `[HH:MM:SS,mmm] Speaker N:`)
  '^\[[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}\]'
  # Repeated single character noise (cleanup pass should not leave these)
  '^哈哈哈哈哈哈'
)

FOUND=0
for p in "${PATTERNS[@]}"; do
  HITS=$(grep -E -c "$p" "$TMP" 2>/dev/null || true)
  if [ -n "$HITS" ] && [ "$HITS" -gt 0 ]; then
    echo "❌ Found $HITS occurrence(s) of: $p"
    grep -E -n "$p" "$TMP" | head -3
    FOUND=1
  fi
done

rm -f "$TMP"

if [ "$FOUND" -eq 0 ]; then
  echo "✅ verify.sh: no known-bad patterns in transcript body of $FILE"
  exit 0
else
  echo "⚠️  verify.sh: bad patterns present. Cleanup pass incomplete."
  exit 1
fi
