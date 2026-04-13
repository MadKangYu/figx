#!/usr/bin/env bash
# lib/hermes.sh — Best-effort Hermes-Agent notification adapter
# Never blocks the parent command; always falls back to a local event log.

hermes_notify() {
  local msg="$*"
  [ -n "$msg" ] || return 0
  # Always log locally first
  printf '[%s] NOTIFY %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$msg" \
    >>"${FIGMA_CLI_EVENT_LOG:-$HOME/.local/state/figma-cli/events.log}" 2>/dev/null || true

  # Try Hermes push if the binary exists; swallow all errors
  if command -v hermes >/dev/null 2>&1; then
    # Hermes exposes webhook and chat subcommands; use webhook test as a lightweight push
    # If the user has a custom "figma-tokens" webhook, prefer it.
    (hermes webhook test --route figma-tokens --payload "{\"message\":$(printf '%s' "$msg" | jq -Rs .)}" \
      >/dev/null 2>&1) || true
  fi
  return 0
}

hermes_check() {
  if ! command -v hermes >/dev/null 2>&1; then
    echo "✗ hermes not on PATH"; return 1
  fi
  local ver; ver="$(hermes --version 2>&1 | head -1)"
  echo "✓ $ver"
  # Update freshness
  if hermes --version 2>&1 | grep -q 'Up to date'; then
    echo "✓ Up to date"
  else
    echo "○ run: hermes update"
  fi
}
