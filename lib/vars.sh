#!/usr/bin/env bash
# lib/vars.sh — variables CRUD (Enterprise Full seat required for POST)

vars_get() {
  local file_key; file_key="$(files_resolve_key "$@")" || return 2
  api_get "/v1/files/$file_key/variables/local"
}

vars_dump() {
  local out="${1:-variables-$(date +%Y%m%d-%H%M%S).json}"
  shift || true
  local file_key; file_key="$(files_resolve_key "$@")" || return 2
  api_get "/v1/files/$file_key/variables/local" | jq '.' >"$out"
  echo "→ wrote $out"
}

vars_apply() {
  local tokens_file="${1:-}"; shift || true
  [ -f "$tokens_file" ] || { echo "vars apply: tokens file '$tokens_file' not found" >&2; return 2; }
  local file_key; file_key="$(files_resolve_key "$@")" || return 2

  # Pre-flight: ensure we can read variables (surfaces 403 early)
  if ! api_get "/v1/files/$file_key/variables/local" >/dev/null 2>&1; then
    echo "vars apply: pre-flight GET failed — Enterprise Full seat + file_variables:read required" >&2
    hermes_notify "figma-cli ABORT: pre-flight GET failed for $file_key" || true
    return 3
  fi

  echo "→ POST /v1/files/$file_key/variables"
  local resp
  resp="$(api_post "/v1/files/$file_key/variables" "$tokens_file")" || {
    echo "vars apply: POST failed" >&2; return 4; }
  echo "$resp" | jq '.' 2>/dev/null || echo "$resp"
  hermes_notify "figma-cli: variables applied to $file_key" || true
}
