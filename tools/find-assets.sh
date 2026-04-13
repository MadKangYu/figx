#!/usr/bin/env bash
# find-assets.sh — locate image/asset files by fuzzy name and/or by
# 7-segment filename convention axes (brand/category/subject/variant/
# locale/version). macOS-native: uses mdfind (Spotlight) first, falls
# back to find(1) for directories Spotlight doesn't index.
#
# Usage:
#   figx find <query>
#     # fuzzy substring match on filename (quick)
#
#   figx find --brand amplen --category skincare --subject hero
#     # structured filter via 7-segment filename convention
#
#   figx find <query> --open         # reveal results in Finder
#   figx find <query> --limit 20
#   figx find <query> --in ~/Pictures  (or @drive for rclone mount)
#   figx find <query> --ext jpg,png,heic

set -Eeuo pipefail

query=""
search_root=""
extensions="jpg,jpeg,png,heic,heif,webp,gif,mp4"
limit=50
open_finder=0
brand=""; category=""; subject=""; variant=""; locale=""; version=""

while [ $# -gt 0 ]; do
  case "$1" in
    --in)        search_root="$2"; shift 2 ;;
    --ext)       extensions="$2"; shift 2 ;;
    --limit)     limit="$2"; shift 2 ;;
    --open)      open_finder=1; shift ;;
    --brand)     brand="$2"; shift 2 ;;
    --category)  category="$2"; shift 2 ;;
    --subject)   subject="$2"; shift 2 ;;
    --variant)   variant="$2"; shift 2 ;;
    --locale)    locale="$2"; shift 2 ;;
    --version)   version="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,18p' "$0"; exit 0 ;;
    *)           query="$1"; shift ;;
  esac
done

# Build the structured filter substring (7-segment name).
# When any axis is set, we assemble a glob-ish substring like
# `amplen-skincare-hero-`. Unset segments become `*` wildcards.
structured=""
if [ -n "$brand$category$subject$variant$locale$version" ]; then
  segs=("${brand:-*}" "${category:-*}" "${subject:-*}" "${variant:-*}" "${locale:-*}" "${version:-*}")
  structured="$(printf '%s-' "${segs[@]}")"; structured="${structured%-}"
  # Collapse consecutive wildcards: "amplen-*-hero-*" stays expressive.
fi

effective_query="$query"
[ -n "$structured" ] && effective_query="$structured"
[ -z "$effective_query" ] && effective_query="*"

default_roots=(
  "$HOME/Pictures"
  "$HOME/Documents"
  "$HOME/Desktop"
  "$HOME/Downloads"
)
# Permit @drive shortcut for rclone mount
if [ "$search_root" = "@drive" ]; then
  if [ -d "$HOME/Drives" ]; then
    default_roots=("$HOME/Drives"); search_root=""
  fi
fi
[ -n "$search_root" ] && default_roots=("$search_root")

found=()

# 1. Spotlight (fast on indexed volumes). Narrow by filename substring and ext.
if command -v mdfind >/dev/null 2>&1; then
  for root in "${default_roots[@]}"; do
    [ -d "$root" ] || continue
    for ext_one in ${extensions//,/ }; do
      mdfind -onlyin "$root" "kMDItemFSName == '*${effective_query//\*/}*.${ext_one}'cd" 2>/dev/null
    done
  done > /tmp/figx-find.$$ 2>/dev/null || true
  while IFS= read -r line; do [ -n "$line" ] && found+=("$line"); done < /tmp/figx-find.$$
  rm -f /tmp/figx-find.$$
fi

# 2. find(1) fallback for un-indexed paths (rclone mounts, external drives).
for root in "${default_roots[@]}"; do
  [ -d "$root" ] || continue
  # Check if the root is Spotlight-indexed; if yes we already did it.
  if mdutil -s "$root" 2>/dev/null | grep -q "Indexing enabled"; then
    continue
  fi
  ext_args=()
  for e in ${extensions//,/ }; do
    ext_args+=("-iname" "*${effective_query//\*/}*.$e" "-o")
  done
  # remove trailing -o
  unset 'ext_args[-1]'
  # shellcheck disable=SC2156
  while IFS= read -r line; do found+=("$line"); done < <(find "$root" -type f \( "${ext_args[@]}" \) 2>/dev/null)
done

# De-duplicate, sort by mtime (newest first), limit.
if [ "${#found[@]}" -eq 0 ]; then
  echo "(no matches)"
  exit 1
fi
printf '%s\n' "${found[@]}" \
  | awk '!seen[$0]++' \
  | xargs -I{} stat -f '%m\t{}' {} 2>/dev/null \
  | sort -rn \
  | head -n "$limit" \
  | cut -f2-

if [ "$open_finder" = 1 ] && command -v open >/dev/null 2>&1; then
  printf '%s\n' "${found[@]}" | awk '!seen[$0]++' | head -n "$limit" | while read -r p; do
    [ -f "$p" ] && open -R "$p"
  done
fi
