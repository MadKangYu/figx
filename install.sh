#!/usr/bin/env bash
# figx install script — one-shot setup on macOS
# Usage:   curl -fsSL https://raw.githubusercontent.com/MadKangYu/figx/main/install.sh | bash
# Or:      ./install.sh

set -Eeuo pipefail

REPO="${FIGX_REPO:-MadKangYu/figx}"
BRANCH="${FIGX_BRANCH:-main}"
PREFIX="${FIGX_PREFIX:-$HOME/.local/share/figx}"
BIN_DIR="${FIGX_BIN:-$HOME/.local/bin}"

say()  { printf '\033[32m→\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null || die "curl required"
command -v git  >/dev/null || die "git required"

say "fetching figx from github.com/$REPO@$BRANCH"
rm -rf "$PREFIX"
mkdir -p "$(dirname "$PREFIX")" "$BIN_DIR"
git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$PREFIX"

chmod +x "$PREFIX/figma"
chmod +x "$PREFIX/tools/extract_from_py.py" 2>/dev/null || true

ln -sf "$PREFIX/figma" "$BIN_DIR/figx"
say "installed $BIN_DIR/figx → $PREFIX/figma"

# PATH hint
case ":$PATH:" in
  *":$BIN_DIR:"*) say "$BIN_DIR already on PATH" ;;
  *) warn "$BIN_DIR not on PATH — add to your shell rc:"
     echo "    export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

# Sanity check
"$BIN_DIR/figx" version
"$BIN_DIR/figx" doctor || warn "doctor reported issues"

say "done. Next: figx auth login && figx onboarding"
