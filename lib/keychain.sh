#!/usr/bin/env bash
# lib/keychain.sh — macOS Keychain wrapper for the Figma PAT
# Fallback: $FIGMA_PAT env var when Keychain is unavailable (non-mac or denied)

_KC_SERVICE="figma-cli"
_KC_ACCOUNT="default"

keychain_has_pat() {
  command -v security >/dev/null 2>&1 || return 1
  security find-generic-password -s "$_KC_SERVICE" -a "$_KC_ACCOUNT" -w >/dev/null 2>&1
}

keychain_login() {
  if ! command -v security >/dev/null 2>&1; then
    echo "macOS 'security' tool not available; export FIGMA_PAT instead." >&2
    return 2
  fi
  local pat
  printf 'Enter Figma Personal Access Token (hidden): '
  stty -echo 2>/dev/null; IFS= read -r pat; stty echo 2>/dev/null; echo
  [ -n "$pat" ] || { echo "empty PAT; aborted" >&2; return 2; }
  # Validate by calling /v1/me before persisting
  local resp
  resp="$(curl -sS -H "X-Figma-Token: $pat" "${FIGMA_API_BASE:-https://api.figma.com}/v1/me")" || {
    echo "network error validating PAT" >&2; return 2; }
  if ! echo "$resp" | jq -e '.id' >/dev/null 2>&1; then
    echo "PAT rejected: $(echo "$resp" | jq -r '.err // .message // .' 2>/dev/null)" >&2
    return 3
  fi
  # Persist (overwrite)
  security delete-generic-password -s "$_KC_SERVICE" -a "$_KC_ACCOUNT" >/dev/null 2>&1 || true
  security add-generic-password -s "$_KC_SERVICE" -a "$_KC_ACCOUNT" -w "$pat" -U
  echo "✓ PAT saved to Keychain (service=$_KC_SERVICE)"
  echo "  user: $(echo "$resp" | jq -r '.email // .handle // .id')"
}

keychain_status() {
  if keychain_has_pat; then
    echo "✓ PAT present in Keychain (service=$_KC_SERVICE)"
  elif [ -n "${FIGMA_PAT:-}" ]; then
    echo "○ PAT from \$FIGMA_PAT env var"
  else
    echo "✗ no PAT configured (run: figma auth login)"
    return 1
  fi
}

keychain_logout() {
  security delete-generic-password -s "$_KC_SERVICE" -a "$_KC_ACCOUNT" 2>/dev/null || true
  echo "✓ PAT removed from Keychain"
}
