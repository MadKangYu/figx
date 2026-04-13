#!/usr/bin/env python3
"""Classify a flat folder of images into three buckets used on an ecommerce
detail page:

    model/       - full-body or face model shots (portrait, 2:3 / 3:4 ratio,
                   taller than wide, typically from a phone shoot)
    gif/         - burst/sequence source (filenames like IMG_0001…0024,
                   timestamps clustered within 30 s, same aspect ratio)
    pdp/         - detail-page hero / ingredient / packshot
                   (square-ish or landscape, single object, large pixels)
    ambiguous/   - falls through the above (review manually)

Uses only the Python stdlib + macOS `sips` (for dimensions without PIL).
Output is the reclassified symlink tree; originals are untouched.

Usage:
    python3 asset-classify.py <input_dir> --out <output_dir>
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
from pathlib import Path


SEQ_RE = re.compile(r"^(?P<stem>.+?)[_\-]?(?P<num>\d{3,6})\.(?P<ext>[a-zA-Z]+)$")


def sips_dims(p: Path) -> tuple[int, int] | None:
    try:
        out = subprocess.check_output(
            ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(p)],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        return None
    d: dict[str, int] = {}
    for line in out.splitlines():
        parts = line.strip().split(":")
        if len(parts) == 2 and parts[0].strip() in ("pixelWidth", "pixelHeight"):
            d[parts[0].strip()] = int(parts[1].strip())
    if "pixelWidth" in d and "pixelHeight" in d:
        return d["pixelWidth"], d["pixelHeight"]
    return None


def cluster_sequences(files: list[Path]) -> dict[str, list[Path]]:
    """Group files whose stems share a numeric suffix run."""
    groups: dict[str, list[Path]] = {}
    for f in files:
        m = SEQ_RE.match(f.name)
        if not m:
            continue
        groups.setdefault(m.group("stem"), []).append(f)
    # keep groups of 3+ numbered files
    return {k: sorted(v) for k, v in groups.items() if len(v) >= 3}


def classify_one(p: Path, seq_members: set[Path]) -> str:
    if p in seq_members:
        return "gif"
    dims = sips_dims(p)
    if not dims:
        return "ambiguous"
    w, h = dims
    if w == 0 or h == 0:
        return "ambiguous"
    ratio = h / w  # > 1 means taller (portrait)
    # Heuristic: portrait & tall & medium-to-large resolution → model
    if ratio >= 1.2 and h >= 1200:
        return "model"
    # Square-ish or landscape, reasonably large → detail page
    if 0.7 <= ratio <= 1.4 and max(w, h) >= 800:
        return "pdp"
    return "ambiguous"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("source", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--move", action="store_true",
                    help="move files instead of symlinking (default symlink, originals kept)")
    args = ap.parse_args()

    for bucket in ("model", "gif", "pdp", "ambiguous"):
        (args.out / bucket).mkdir(parents=True, exist_ok=True)

    files = sorted(p for p in args.source.iterdir()
                   if p.is_file() and p.suffix.lower() in
                   {".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp"})
    seqs = cluster_sequences(files)
    seq_members: set[Path] = {f for fs in seqs.values() for f in fs}

    counts = {"model": 0, "gif": 0, "pdp": 0, "ambiguous": 0}
    for p in files:
        bucket = classify_one(p, seq_members)
        dest = args.out / bucket / p.name
        if args.move:
            shutil.move(str(p), str(dest))
        else:
            if dest.exists() or dest.is_symlink():
                dest.unlink()
            dest.symlink_to(p.resolve())
        counts[bucket] += 1

    for b, n in counts.items():
        print(f"  {b:10s}: {n}")
    print(f"→ {args.out}")


if __name__ == "__main__":
    main()
