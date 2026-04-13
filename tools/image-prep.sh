#!/usr/bin/env bash
# image-prep.sh — prepare large / HEIC / unsorted images for Figma upload.
#
# Fixes the three common pains when dragging pictures from Finder into
# Figma Desktop:
#   1. HEIC (iPhone) files Figma can't decode → convert to JPG
#   2. Images above Figma's 4096×4096 cap fail silently → downscale
#   3. Massive originals time out the drag-and-drop → re-encode at JPEG q=92
#
# Uses only macOS built-ins (sips, file). No Homebrew ImageMagick needed.
#
# Usage:
#   figx images prep <dir-or-file> [--out <dir>] [--max 4096] [--quality 92]
#
# Output: writes prepared copies to <out>/, leaving originals untouched.
# The output directory becomes a safe drag-and-drop source for Figma.

set -Eeuo pipefail

src=""
out="$PWD/figma-ready"
max="4096"
quality="92"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)     out="$2"; shift 2 ;;
    --max)     max="$2"; shift 2 ;;
    --quality) quality="$2"; shift 2 ;;
    --)        shift ;;
    *)         src="$1"; shift ;;
  esac
done

[ -n "$src" ] || { echo "usage: image-prep.sh <dir-or-file> [--out <dir>] [--max 4096] [--quality 92]" >&2; exit 2; }

mkdir -p "$out"

prep_one() {
  local in="$1"
  local name; name="$(basename "$in")"
  local ext="${name##*.}"
  local base="${name%.*}"
  local tmp; tmp="$(mktemp -t figx_img.XXXXXX.png)"
  local dest_ext="jpg"

  # Convert HEIC/HEIF to JPG straightaway
  case "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" in
    heic|heif) sips -s format jpeg "$in" --out "$tmp" >/dev/null 2>&1 ;;
    png)       cp "$in" "$tmp"; dest_ext="png" ;;
    jpg|jpeg)  cp "$in" "$tmp" ;;
    webp|gif)  sips -s format jpeg "$in" --out "$tmp" >/dev/null 2>&1 ;;
    *)         echo "  skip (unsupported): $name" >&2; return ;;
  esac

  # Downscale if bigger than $max in either axis
  local w; w="$(sips -g pixelWidth  "$tmp" | awk '/pixelWidth/{print $2}')"
  local h; h="$(sips -g pixelHeight "$tmp" | awk '/pixelHeight/{print $2}')"
  if [ "$w" -gt "$max" ] || [ "$h" -gt "$max" ]; then
    sips -Z "$max" "$tmp" >/dev/null 2>&1
  fi

  local dest="$out/${base}.${dest_ext}"
  if [ "$dest_ext" = "jpg" ]; then
    sips -s format jpeg -s formatOptions "$quality" "$tmp" --out "$dest" >/dev/null 2>&1
  else
    mv "$tmp" "$dest"
  fi
  rm -f "$tmp"

  local bytes; bytes="$(stat -f%z "$dest" 2>/dev/null || echo '?')"
  echo "  ✓ $name → $(basename "$dest")  (${w}×${h} src, ${bytes} B out)"
}

if [ -d "$src" ]; then
  count=0
  # shellcheck disable=SC2044
  for f in "$src"/*; do
    [ -f "$f" ] || continue
    case "$(echo "$f" | tr '[:upper:]' '[:lower:]')" in
      *.heic|*.heif|*.png|*.jpg|*.jpeg|*.webp|*.gif) prep_one "$f"; count=$((count+1)) ;;
    esac
  done
  echo "→ $count image(s) written to $out"
else
  prep_one "$src"
  echo "→ 1 image written to $out"
fi

echo ""
echo "Next:"
echo "  1. Open $out in Finder"
echo "  2. Select all, drag into your Figma file"
echo "     (files are ≤${max}px and JPEG-optimized — Figma handles them cleanly)"
