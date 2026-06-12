#!/bin/bash
# verify.sh — Check for known-bad patterns in final transcript
# Usage: verify.sh <transcript.md>
# Exits non-zero if any patterns found.
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
# Find line of first "## " (heading) — transcript body is before it
HEADING_LINE=$(grep -nE '^## ' "$FILE" | head -1 | cut -d: -f1)
if [ -n "$HEADING_LINE" ]; then
  head -n $((HEADING_LINE - 1)) "$FILE" > "$TMP"
else
  cp "$FILE" "$TMP"
fi

# Patterns known to be common ASR errors or cleanup failures
PATTERNS=(
  # Timestamp leakage (should be removed in cleanup)
  '\[00:[0-9]{2}:[0-9]{2}\]'
  # Common FunASR English-lettered Chinese words that should be Chinese
  'eng 准'
  'eng準'
  'N準'
  'N准'
  # ASR typos (FunASR-specific)
  '協修'
  '協修方法'
  # Whisper base specific (in case old version still around)
  '寫修'
  '掉用'
  '壓說'
  '文納'
  # Tag leakage (FunASR metadata not stripped)
  '<\|zh\|>'
  '<\|NEUTRAL\|>'
  '<\|Speech\|>'
  '<\|withitn\|>'
  # Speaker label leakage (should be removed in cleanup)
  '^[Ss]peaker [0-9]+:'
  '\[Speaker [0-9]+\]'
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
  echo "⚠️  verify.sh: bad patterns present. Cleanup pass needed."
  exit 1
fi
