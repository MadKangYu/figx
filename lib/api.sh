#!/usr/bin/env bash
# lib/api.sh — Figma REST API wrapper with retry + error surfacing

FIGMA_API_BASE="${FIGMA_API_BASE:-https://api.figma.com}"

_api_pat() {
  # Order: explicit env var → Keychain → fail
  if [ -n "${FIGMA_PAT:-}" ]; then
    echo "$FIGMA_PAT"
    return 0
  fi
  if command -v security >/dev/null 2>&1; then
    security find-generic-password -s figma-cli -a default -w 2>/dev/null || true
  fi
}

api_request() {
  # Usage: api_request METHOD PATH [DATA_FILE_OR_JSON]
  local method="$1"; local path="$2"; local data="${3:-}"
  local pat; pat="$(_api_pat)"
  [ -n "$pat" ] || { echo "no Figma PAT (run: figma auth login)" >&2; return 2; }

  local url="$FIGMA_API_BASE$path"
  local attempt=0 max=5 delay=2
  while : ; do
    attempt=$((attempt+1))
    local tmp; tmp="$(mktemp)"
    local status
    if [ -n "$data" ]; then
      # data may be a JSON string or a file path
      local data_arg
      if [ -f "$data" ]; then data_arg="@$data"; else data_arg="$data"; fi
      status="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" \
        -H "X-Figma-Token: $pat" \
        -H "Content-Type: application/json" \
        --data "$data_arg" "$url" || echo '000')"
    else
      status="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" \
        -H "X-Figma-Token: $pat" "$url" || echo '000')"
    fi

    case "$status" in
      2??) cat "$tmp"; rm -f "$tmp"; return 0 ;;
      401|403)
        echo "api: $status — PAT invalid or missing scope" >&2
        cat "$tmp" >&2; rm -f "$tmp"; return 3 ;;
      429)
        echo "api: 429 rate-limited — retry $attempt/$max in ${delay}s" >&2
        rm -f "$tmp"
        (( attempt < max )) || { echo "api: gave up" >&2; return 4; }
        sleep "$delay"; delay=$(( delay * 2 ))
        continue ;;
      5??|000)
        echo "api: transient $status — retry $attempt/$max in ${delay}s" >&2
        rm -f "$tmp"
        (( attempt < max )) || { echo "api: gave up" >&2; return 5; }
        sleep "$delay"; delay=$(( delay * 2 ))
        continue ;;
      *)
        echo "api: $status" >&2; cat "$tmp" >&2; rm -f "$tmp"; return 6 ;;
    esac
  done
}

api_get()  { api_request GET  "$1"; }
api_post() { api_request POST "$1" "${2:-}"; }
api_put()  { api_request PUT  "$1" "${2:-}"; }
