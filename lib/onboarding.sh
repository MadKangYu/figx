#!/usr/bin/env bash
# lib/onboarding.sh — step-by-step interactive wizard for first-time users
#
# Every step prints: what it is, why it matters, how to fix if it fails.
# Refuses to skip; never leaves ambiguous state.

_ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
_warn() { printf '  \033[33m○\033[0m %s\n' "$*"; }
_fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; }
_step() { printf '\n\033[1m[%s]\033[0m %s\n' "$1" "$2"; }

_ask() {
  # $1 = prompt, $2 = default (y or n). Returns 0 if user confirms.
  local prompt="$1" def="${2:-y}" ans
  if [ "$def" = "y" ]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  read -r -p "$prompt" ans
  ans="${ans:-$def}"
  [ "${ans:0:1}" = "y" ] || [ "${ans:0:1}" = "Y" ]
}

_pause() {
  printf '\n%s' "$1"
  read -r -p "  (준비됐으면 Enter) " _
}

onboarding_run() {
  clear
  cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  figx onboarding — 처음부터 끝까지 가이드

  이 마법사는 7단계에서 막히면 즉시 멈추고 해결법을 보여줍니다.
  실수할 만한 지점마다 한 번 더 확인합니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

  _step 1/7 "필수 도구 확인"
  local missing=0
  for bin in curl jq security python3; do
    if command -v "$bin" >/dev/null 2>&1; then _ok "$bin"; else _fail "$bin 없음"; missing=1; fi
  done
  if [ $missing -eq 1 ]; then
    cat <<'EOF'

    조치: macOS 기본이면 대부분 있음. 빠진 게 있으면:
        brew install jq python3
EOF
    return 1
  fi

  _step 2/7 "Figma Desktop 설치 확인"
  if [ -d "/Applications/Figma.app" ] || [ -d "$HOME/Applications/Figma.app" ]; then
    _ok "Figma.app 발견"
  else
    _fail "Figma Desktop 없음"
    cat <<'EOF'

    조치: https://www.figma.com/downloads/ 에서 Mac 버전 설치 후 다시 실행
EOF
    return 1
  fi

  _step 3/7 "Figma 플랜 확인 (Variables 멀티모드는 Professional+ 필요)"
  cat <<'EOF'

    https://www.figma.com/settings 열어 현재 플랜을 확인하세요.

    - Starter (무료): Pep/Cer 2모드 생성 불가 → Professional 이상 결재 필요
    - Professional/Organization: 플러그인으로 진행 가능 (이 가이드)
    - Enterprise: 추가로 REST API 경로도 가능 (여기선 안 씀)
EOF
  if ! _ask "Professional 이상 플랜을 확인하셨나요?" n; then
    cat <<'EOF'

    조치: Professional 결재 후 이 명령을 다시 실행하세요.
        figx onboarding
EOF
    return 1
  fi

  _step 4/7 "Figma PAT (Personal Access Token) 준비"
  if keychain_has_pat; then
    _ok "Keychain에 PAT 저장돼 있음"
    if ! _ask "기존 PAT 그대로 사용할까요?" y; then
      keychain_logout
      keychain_login || return 1
    fi
  else
    cat <<'EOF'

    PAT은 Figma가 이 CLI를 신뢰하게 해주는 열쇠입니다.
    생성 방법:
      1. https://www.figma.com/settings → Security 탭
      2. Personal access tokens → Generate new token
      3. 이름: amplen-cli, 만료: 90일
      4. 스코프 체크 (표시되는 것만 체크해도 OK, Variables는 있어도 없어도 상관없음
         — 이번 경로는 REST 안 씀):
         - 사용자: 읽기
         - 파일: 내용/메타데이터/버전 모두 읽기
         - 디자인 시스템: 전부 읽기
         - 개발: 개발 리소스 읽기
      5. Generate → 긴 문자열 복사 (이 화면에서만 보임)

EOF
    _pause "PAT을 복사했으면"
    keychain_login || return 1
  fi

  _step 5/7 "Figma 작업 파일 연결"
  local current_key; current_key="$(_config_get default_file_key 2>/dev/null || echo '')"
  if [ -n "$current_key" ]; then
    _ok "기본 파일 설정됨: $current_key"
    if ! _ask "이 파일에 토큰을 publish할까요?" y; then
      current_key=""
    fi
  fi
  if [ -z "$current_key" ]; then
    cat <<'EOF'

    Figma Desktop에서 작업할 파일을 열고, 브라우저 주소창 또는 "Share → Copy link"로
    URL을 복사하세요. 형태:
        https://www.figma.com/design/XXXXXXXX/파일이름
    또는 파일 key만 (XXXXXXXX 부분) 붙여넣어도 됩니다.

EOF
    local url
    read -r -p "  URL 또는 file key: " url
    if echo "$url" | grep -q 'figma.com/'; then
      files_find_from_url "$url" >/dev/null
    elif [ -n "$url" ]; then
      files_set "$url" >/dev/null
    else
      _fail "빈 입력"
      return 1
    fi
  fi
  current_key="$(_config_get default_file_key)"
  _ok "파일 key 저장: $current_key"

  _step 6/7 "Tokens Studio 플러그인 준비 (권장 경로)"
  cat <<'EOF'

    Tokens Studio for Figma는 무료 플러그인입니다. 이 플러그인이 있으면
    tokens.studio.json 파일 import 한 번으로 Pep/Cer Variables가 자동 생성됩니다.

    설치 (1회만):
      1. Figma Desktop 열기 → 아무 파일 열기
      2. 상단 메뉴 Resources (또는 Plugins) → Community 검색
      3. "Tokens Studio for Figma" 설치
      4. 해당 파일에서 Plugins → Tokens Studio for Figma 실행

EOF
  _pause "플러그인 설치했으면"

  _step 7/7 "토큰 JSON 생성 + import 경로 안내"
  local tokens_dir="$HOME/Documents/AmpleN_Uzum_Uzb/design-tokens"
  if [ -f "$tokens_dir/tokens.studio.json" ]; then
    _ok "$tokens_dir/tokens.studio.json 준비됨"
  else
    _warn "tokens.studio.json 없음 — 재생성 시도"
    python3 "$FIGMA_CLI_ROOT/tools/extract_from_py.py" \
      --src "$HOME/Documents/AmpleN_Uzum_Uzb/pdp_pipeline/make_pdp.py" \
      --out "$tokens_dir" || {
        _fail "재생성 실패 — make_pdp.py 경로 확인"
        return 1
      }
    _ok "tokens.studio.json 생성 완료"
  fi

  cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  완료. 이제 Figma Desktop에서 아래 5 동작만 하면 끝입니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Figma Desktop에서 이 파일을 여세요:
     https://www.figma.com/design/$current_key/

  2. Plugins → Tokens Studio for Figma 실행

  3. 플러그인 창 우상단 톱니 → Tools → Load from file system
     → 아래 파일 선택:
     $tokens_dir/tokens.studio.json

  4. 좌측 "Themes" 탭 → "Peptide" 또는 "Ceramide" 중 하나 활성화

  5. 하단 "Push to Figma" 버튼 클릭 → Create styles & variables 체크 → Apply

  → Figma Variables 패널(오른쪽 사이드바)에 6개 컬렉션 45개 변수가 생성됩니다.

  다음: 코드 측 CSS 변수도 필요하면
     $tokens_dir/tokens.css 를 프로젝트에 추가

EOF
  _ok "Onboarding 끝"
  hermes_notify "figx onboarding 완료 — 파일 $current_key" || true
  return 0
}
