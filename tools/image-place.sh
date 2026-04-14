#!/usr/bin/env bash
# image-place.sh — drive Figma Desktop's official "Place image" flow.
#
# Usage:
#   figx images place <dir>
#
# This does not use MCP or the REST API. It activates Figma Desktop,
# triggers the official Shift+Cmd+K shortcut, jumps to <dir>, selects all
# files in that folder, and confirms the picker. Figma then loads the
# selected files into the placement cursor for canvas placement.

set -Eeuo pipefail

src_dir="${1:-}"
[ -n "$src_dir" ] || {
  echo "usage: image-place.sh <dir>" >&2
  exit 2
}
[ -d "$src_dir" ] || {
  echo "error: not a directory: $src_dir" >&2
  exit 2
}

src_dir="$(cd "$src_dir" && pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd)"

count="$(
  find "$src_dir" -maxdepth 1 -type f \( \
    -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o \
    -iname '*.heic' -o -iname '*.heif' -o -iname '*.webp' -o \
    -iname '*.gif' -o -iname '*.tif' -o -iname '*.tiff' \
  \) | wc -l | tr -d ' '
)"
[ "${count:-0}" -gt 0 ] || {
  echo "error: no supported image files found in $src_dir" >&2
  exit 2
}

osascript "$script_dir/place-images.applescript" "$src_dir"

echo "→ loaded $count image(s) into Figma's Place image cursor"
echo "  Next: click the canvas once per image, or press Esc to cancel the rest."
echo "  Note: this is Figma's official desktop flow, so no PAT or MCP is required."
