#!/usr/bin/env bash
# bootstrap.sh — one-shot setup for the figx + figma-mcp-go stack on macOS
#
# Brings a fresh machine from zero to a state where `figx plugin open`
# successfully connects to Figma Desktop and the MCP WebSocket answers.
#
# Covers:
#   1. CLI prerequisites (brew deps)
#   2. figx CLI install (this repo)
#   3. figma-mcp-go plugin (GitHub release) extracted to a stable path
#   4. figma-mcp-go MCP server (npx @vkhanhqui/figma-mcp-go) warm-up
#   5. macOS Accessibility permission check
#   6. Optional: register Hermes 'figma-tokens' webhook if Hermes is installed

set -Eeuo pipefail

PLUGIN_REPO="${FIGX_PLUGIN_REPO:-vkhanhqui/figma-mcp-go}"
PLUGIN_DIR="${FIGX_PLUGIN_DIR:-$HOME/Projects/figma-mcp-learning/plugins/figma-mcp-go}"
FIGX_PREFIX="${FIGX_PREFIX:-$HOME/.local/share/figx}"
BIN_DIR="${FIGX_BIN:-$HOME/.local/bin}"

say()  { printf '\033[32m→\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname)" = Darwin ] || die "macOS only"

# 1. Prerequisites
say "checking prerequisites"
for bin in curl jq gh git python3 security nc osascript; do
  command -v "$bin" >/dev/null || die "missing '$bin' (try: brew install $bin)"
done

# 2. figx CLI
if [ -x "$BIN_DIR/figx" ]; then
  say "figx already installed at $BIN_DIR/figx"
else
  if [ -f "$(dirname "$0")/figma" ]; then
    # running from a cloned repo
    mkdir -p "$BIN_DIR"
    ln -sf "$(cd "$(dirname "$0")" && pwd)/figma" "$BIN_DIR/figx"
    say "linked figx → $(cd "$(dirname "$0")" && pwd)/figma"
  else
    say "cloning figx"
    rm -rf "$FIGX_PREFIX"
    git clone --depth 1 https://github.com/MadKangYu/figx.git "$FIGX_PREFIX"
    chmod +x "$FIGX_PREFIX/figma"
    mkdir -p "$BIN_DIR"
    ln -sf "$FIGX_PREFIX/figma" "$BIN_DIR/figx"
  fi
fi

# 3. figma-mcp-go plugin release — always pin to the current latest tag
latest_tag="$(gh release list --repo "$PLUGIN_REPO" --limit 1 --json tagName -q '.[0].tagName' 2>/dev/null)"
if [ -z "$latest_tag" ]; then
  warn "could not resolve latest release; retrying with implicit latest"
  latest_tag="latest"
fi
say "fetching figma-mcp-go plugin $latest_tag"
mkdir -p "$PLUGIN_DIR"
tmpzip="$(mktemp -t fmg.XXXXXX.zip)"
if [ "$latest_tag" = "latest" ]; then
  gh release download --repo "$PLUGIN_REPO" --pattern 'plugin.zip' --output "$tmpzip" --clobber
else
  gh release download "$latest_tag" --repo "$PLUGIN_REPO" --pattern 'plugin.zip' --output "$tmpzip" --clobber
fi
unzip -o -q "$tmpzip" -d "$PLUGIN_DIR"
rm -f "$tmpzip"
if [ -f "$PLUGIN_DIR/plugin/manifest.json" ]; then
  say "plugin manifest: $PLUGIN_DIR/plugin/manifest.json (version $latest_tag)"
else
  die "manifest.json not found after unzip — check release asset"
fi

# 3b. Auto-import the manifest into Figma Desktop (needs Figma running)
if pgrep -x Figma >/dev/null 2>&1; then
  say "auto-importing plugin manifest into Figma Desktop"
  "$BIN_DIR/figx" plugin install "$PLUGIN_DIR/plugin" || warn "auto-import failed; do it manually once"
else
  warn "Figma Desktop not running; open any file then run: figx plugin install"
fi

# 4. MCP server warm-up (triggers npm cache install)
if command -v npx >/dev/null 2>&1; then
  say "warming up MCP server (npx @vkhanhqui/figma-mcp-go --version)"
  (timeout 25 npx -y @vkhanhqui/figma-mcp-go --version >/dev/null 2>&1) || warn "warm-up timed out (non-fatal)"
else
  warn "npx not found — install Node to use plugin run"
fi

# 4b. Register figma-mcp-go as an MCP server
#     Claude Code / Cursor / VS Code → ~/.mcp.json
#     OpenAI Codex CLI                 → ~/.codex/config.toml
say "registering figma-mcp-go MCP (Claude/Cursor + Codex)"
"$BIN_DIR/figx" plugin register-mcp auto || warn "register-mcp failed (run manually later)"

# 5. Accessibility check (required for `figx plugin open`)
say "checking Accessibility permission"
if osascript -e 'tell application "System Events" to return (UI elements enabled)' 2>/dev/null | grep -qi true; then
  say "Accessibility enabled"
else
  warn "Accessibility not enabled for this terminal"
  warn "  Open System Settings → Privacy & Security → Accessibility"
  warn "  Add your terminal app (Terminal / iTerm / Ghostty) and toggle ON"
fi

# 6. Hermes webhook (optional)
if command -v hermes >/dev/null 2>&1; then
  if hermes webhook list 2>/dev/null | grep -q 'figma-tokens'; then
    say "Hermes webhook 'figma-tokens' already registered"
  else
    say "registering Hermes webhook 'figma-tokens'"
    hermes webhook subscribe figma-tokens \
      --description "figx pipeline events" \
      --deliver log \
      --prompt "figx: {message}" >/dev/null 2>&1 || warn "webhook register failed"
  fi
fi

# 7. Final doctor
say "running figx doctor"
"$BIN_DIR/figx" doctor || warn "doctor reported issues"

cat <<EOF

──────────────────────────────────────────────────────────────────────
Bootstrap complete.

Next:
  1) figx auth login          # paste PAT (stored in macOS Keychain)
  2) Open the target file in Figma Desktop
  3) figx plugin open         # launches Figma MCP Go via menu click
  4) figx onboarding          # interactive 7-step wizard

The plugin must be imported into Figma Desktop once manually:
  Plugins → Development → 매니페스트에서 플러그인 가져오기…
  →  $PLUGIN_DIR/plugin/manifest.json

After that single import, 'figx plugin open' can relaunch it
anytime — no clicks, no Quick Actions, locale-independent menu
traversal.
──────────────────────────────────────────────────────────────────────
EOF
