#!/usr/bin/env bash
# docs-sync.sh — one command to regenerate tokens, re-upload the diagram,
# and refresh the README's live-diagram URL. Commit and push if requested.
#
# Usage:
#   ./tools/docs-sync.sh [--src <make_pdp.py>] [--out <dir>] [--push]
#
# Designed so that any contributor — beginner included — can run it after
# changing token constants or the architecture diagram, without thinking
# about which artifact to regenerate.

set -Eeuo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
src="${FIGX_TOKENS_SRC:-$HOME/Documents/AmpleN_Uzum_Uzb/pdp_pipeline/make_pdp.py}"
out="${FIGX_TOKENS_OUT:-$HOME/Documents/AmpleN_Uzum_Uzb/design-tokens}"
diagram="$here/assets/diagrams/figx-architecture.excalidraw"
upload_script="$HOME/.hermes/hermes-agent-ci-baseline/skills/creative/excalidraw/scripts/upload.py"
push=0

while [ $# -gt 0 ]; do
  case "$1" in
    --src)  src="$2";  shift 2 ;;
    --out)  out="$2";  shift 2 ;;
    --push) push=1;    shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

echo "→ regenerating tokens from $src"
if [ -f "$src" ] && [ -x "$here/tools/extract_from_py.py" ]; then
  python3 "$here/tools/extract_from_py.py" --src "$src" --out "$out"
else
  echo "  (skip — source or extractor missing)"
fi

echo "→ re-uploading excalidraw diagram"
if [ -x "$upload_script" ] && [ -f "$diagram" ]; then
  # Python SSL fallback via certifi (if installed)
  if python3 -c "import certifi" >/dev/null 2>&1; then
    export SSL_CERT_FILE="$(python3 -c 'import certifi; print(certifi.where())')"
  fi
  url="$(python3 "$upload_script" "$diagram" | tail -1)"
  if [[ "$url" =~ ^https://excalidraw.com ]]; then
    echo "  got: $url"
    # Replace the Excalidraw URL in README.md
    if [ -f "$here/README.md" ] && grep -q 'excalidraw.com/#json=' "$here/README.md"; then
      # macOS sed-inplace
      sed -i.bak -E "s|https://excalidraw.com/#json=[^ )]+|$url|g" "$here/README.md" "$here/assets/README.md" 2>/dev/null || true
      rm -f "$here/README.md.bak" "$here/assets/README.md.bak" 2>/dev/null || true
      echo "  README updated"
    fi
  else
    echo "  upload failed: $url"
  fi
else
  echo "  (skip — upload script or diagram missing)"
fi

echo "→ shell syntax check"
bash -n "$here/figma"
for f in "$here"/lib/*.sh "$here/install.sh" "$here/bootstrap.sh" "$here"/tools/*.sh; do
  [ -f "$f" ] && bash -n "$f"
done
python3 -m py_compile "$here/tools/extract_from_py.py"

if [ "$push" = 1 ]; then
  echo "→ committing + pushing"
  ( cd "$here" && git add -A && git commit -m "docs: sync (tokens + excalidraw)" 2>/dev/null || echo "  nothing to commit" )
  ( cd "$here" && git push origin main 2>&1 | tail -3 )
fi

echo "✓ docs-sync complete"
