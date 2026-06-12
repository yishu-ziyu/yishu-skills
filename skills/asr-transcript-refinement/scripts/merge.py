#!/usr/bin/env python3
"""merge.py — Merge per-chunk SRT/TXT into a single file, adjusting timestamps.
Usage: python merge.py <chunks_dir> <output_srt> <output_txt>
"""
import re
import sys
from pathlib import Path

SRT_TS_RE = re.compile(r"(\d{2}):(\d{2}):(\d{2}),(\d{3})")


def parse_srt_ts(ts: str) -> float:
    m = SRT_TS_RE.match(ts)
    if not m:
        return 0.0
    h, mn, s, ms = m.groups()
    return int(h) * 3600 + int(mn) * 60 + int(s) + int(ms) / 1000.0


def format_srt_ts(sec: float) -> str:
    h = int(sec // 3600)
    mn = int((sec % 3600) // 60)
    s = int(sec % 60)
    ms = int((sec - int(sec)) * 1000)
    return f"{h:02d}:{mn:02d}:{s:02d},{ms:03d}"


def main():
    if len(sys.argv) < 4:
        print("Usage: merge.py <chunks_dir> <output_srt> <output_txt>", file=sys.stderr)
        sys.exit(1)

    chunks_dir = Path(sys.argv[1])
    out_srt = Path(sys.argv[2])
    out_txt = Path(sys.argv[3])

    chunk_files = sorted(chunks_dir.glob("chunk_*.srt"))
    if not chunk_files:
        print(f"❌ No chunk_*.srt files in {chunks_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"[merge] Found {len(chunk_files)} chunks")

    # Compute time offset per chunk based on previous chunk's last end
    offset = 0.0
    merged_srt_blocks = []
    merged_txt_lines = []

    for chunk_path in chunk_files:
        text = chunk_path.read_text()
        blocks = re.split(r"\n\n+", text.strip())
        chunk_max_end = 0.0
        for block in blocks:
            lines = block.strip().split("\n")
            if len(lines) < 3:
                continue
            idx_line = lines[0]
            ts_line = lines[1]
            content_lines = lines[2:]
            m = re.match(r"(\S+)\s*-->\s*(\S+)", ts_line)
            if not m:
                continue
            start_sec = parse_srt_ts(m.group(1)) + offset
            end_sec = parse_srt_ts(m.group(2)) + offset
            chunk_max_end = max(chunk_max_end, end_sec - offset)
            merged_srt_blocks.append(f"{idx_line}\n{format_srt_ts(start_sec)} --> {format_srt_ts(end_sec)}\n" + "\n".join(content_lines))
        # Also read .txt for plain text
        txt_path = chunk_path.with_suffix(".txt")
        if txt_path.exists():
            for line in txt_path.read_text().splitlines():
                m = re.match(r"\[(\S+)\] (Speaker \d+: .*)", line)
                if m:
                    ts = parse_srt_ts(m.group(1))
                    merged_txt_lines.append(f"[{format_srt_ts(ts + offset)}] {m.group(2)}")
        offset += chunk_max_end

    # Renumber SRT blocks
    renumbered = []
    for i, block in enumerate(merged_srt_blocks, 1):
        # Replace first line with new index
        lines = block.split("\n", 1)
        lines[0] = str(i)
        renumbered.append("\n".join(lines))

    out_srt.write_text("\n\n".join(renumbered) + "\n")
    out_txt.write_text("\n".join(merged_txt_lines) + "\n")
    print(f"[merge] Wrote {out_srt} ({out_srt.stat().st_size} bytes, {len(renumbered)} blocks)")
    print(f"[merge] Wrote {out_txt} ({out_txt.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
