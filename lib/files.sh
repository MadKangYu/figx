#!/usr/bin/env bash
# lib/files.sh — file key discovery + config persistence

_config_get() {
  local key="$1"
  [ -f "$FIGMA_CLI_CONFIG" ] || return 1
  awk -v k="$key" -F'=' '$1~k{gsub(/[ "]/,"",$2); print $2; exit}' "$FIGMA_CLI_CONFIG"
}

_config_set() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$FIGMA_CLI_CONFIG")"
  touch "$FIGMA_CLI_CONFIG"
  if grep -q "^$key\s*=" "$FIGMA_CLI_CONFIG" 2>/dev/null; then
    sed -i.bak "s|^$key\s*=.*|$key = \"$val\"|" "$FIGMA_CLI_CONFIG" && rm -f "$FIGMA_CLI_CONFIG.bak"
  else
    printf '%s = "%s"\n' "$key" "$val" >>"$FIGMA_CLI_CONFIG"
  fi
}

files_current() {
  local key; key="$(_config_get default_file_key)"
  if [ -n "$key" ]; then echo "$key"; else echo "(none set)"; return 1; fi
}

files_set() {
  local key="${1:-}"
  [ -n "$key" ] || { echo "usage: figma files set <file_key>" >&2; return 2; }
  _config_set default_file_key "$key"
  echo "✓ default file key set: $key"
}

files_resolve_key() {
  # Priority: --file <key> arg → env FIGMA_FILE_KEY → config
  while [ $# -gt 0 ]; do
    case "$1" in
      --file) echo "$2"; return 0 ;;
    esac
    shift
  done
  if [ -n "${FIGMA_FILE_KEY:-}" ]; then echo "$FIGMA_FILE_KEY"; return 0; fi
  local key; key="$(_config_get default_file_key)"
  if [ -n "$key" ]; then echo "$key"; return 0; fi
  echo "no file key — pass --file <key>, export FIGMA_FILE_KEY, or run: figma files set <key>" >&2
  return 2
}

files_list() {
  # /v1/me/files returns recent files (uses file_content:read on some accounts).
  # Enterprise teams have a different endpoint. Attempt /v1/me first, then fall back.
  local team="${1:-}"
  if [ -n "$team" ]; then
    api_get "/v1/teams/$team/projects" | jq -r '.projects[]? | "\(.id)\t\(.name)"'
    return 0
  fi
  local resp
  resp="$(api_get "/v1/me" 2>/dev/null || echo '{}')"
  local user_id; user_id="$(echo "$resp" | jq -r '.id // empty')"
  if [ -z "$user_id" ]; then
    echo "could not resolve current user (check PAT scope)" >&2; return 2
  fi
  # Figma does not provide a public "list all my files" REST endpoint.
  # Best path is to ask the user to paste a file URL; we parse the key.
  echo "Figma REST has no 'list all files' endpoint."
  echo "Paste a Figma design URL (or press Enter to cancel):"
  read -r url || true
  [ -n "$url" ] || return 1
  files_find_from_url "$url"
}

files_find_from_url() {
  local url="$1"
  local key
  key="$(echo "$url" | sed -n 's|.*figma.com/\(design\|file\|board\)/\([A-Za-z0-9]*\).*|\2|p')"
  [ -n "$key" ] || { echo "could not parse file key from URL" >&2; return 2; }
  echo "$key"
  files_set "$key" >/dev/null
  echo "✓ default file key set: $key"
}

files_find() {
  # Accepts either a file URL or a pattern (for pattern search, requires recent file list —
  # since REST has no search endpoint, we fall back to URL parsing).
  local arg="${1:-}"
  [ -n "$arg" ] || { echo "usage: figma files find <url|pattern>" >&2; return 2; }
  if echo "$arg" | grep -q 'figma.com/'; then
    files_find_from_url "$arg"
  else
    echo "no search endpoint — paste the file URL from Figma for: $arg" >&2
    return 2
  fi
}
