#!/usr/bin/env bash
# 빠진 파일·깨진 링크를 훑는다.
#
#   bash infra/local/check-404.sh                                  # 로컬 기본값
#   bash infra/local/check-404.sh http://localhost:4173 http://localhost:8080
#   bash infra/local/check-404.sh https://ats.woojeongalex.cloud https://api.ats.woojeongalex.cloud
#
# **상태 코드만 보면 안 된다.** 이 프론트는 SPA 라 없는 경로도 index.html 을 200 으로
# 돌려준다 — 2026-10-01 실측에서 robots.txt·sitemap.xml·manifest.json·apple-touch-icon
# 넷이 전부 "200" 이었는데 내용은 HTML 이었다. 그래서 content-type 까지 본다.

set -uo pipefail
FRONT="${1:-http://localhost:4173}"; FRONT="${FRONT%/}"
API="${2:-http://localhost:8080}";   API="${API%/}"
fail=0; pass=0

code()  { curl -s -o /dev/null -w '%{http_code}'   --max-time 20 "$@"; }
ctype() { curl -s -o /dev/null -w '%{content_type}' --max-time 20 "$@"; }

# want_type 을 주면 content-type 에 그 문자열이 들어 있어야 통과다.
check() {  # check <url> <기대코드> [기대타입]
  local url="$1" want="${2:-200}" want_type="${3:-}" got ct
  got=$(code "$url")
  if [ "$got" != "$want" ]; then
    printf '  ❌ %-46s %s (기대 %s)\n' "${url#"$FRONT"}" "$got" "$want"; fail=$((fail+1)); return
  fi
  if [ -n "$want_type" ]; then
    ct=$(ctype "$url")
    case "$ct" in
      *"$want_type"*) ;;
      *) printf '  ❌ %-46s 200 인데 내용이 %s — SPA 폴백이다(파일이 없다)\n' "${url#"$FRONT"}" "$ct"
         fail=$((fail+1)); return ;;
    esac
  fi
  pass=$((pass+1))
}

echo "프론트: $FRONT"
echo "API   : $API"
echo
echo "[API]"
check "$API/health" 200
# 인증 게이트는 401 이 정상이다. 200 이면 오히려 구멍이다.
check "$API/api/v1/integrity/chain" 401
check "$API/api/v1/internal/email-logs/1/render" 401

echo "[프론트 — 사람이 여는 화면]"
# SPA 라 서버는 어느 경로든 index.html 을 준다. 그래도 번들이 깨지면 여기서 드러난다.
for p in / /login /dashboard /applicants; do check "$FRONT$p" 200 "text/html"; done

echo "[브라우저·크롤러가 말없이 찾는 것]"
check "$FRONT/favicon.svg"           200 "image/svg"
check "$FRONT/favicon.ico"           200 "image/"
check "$FRONT/robots.txt"            200 "text/plain"
check "$FRONT/apple-touch-icon.png"  200 "image/png"

echo "[링크 미리보기]"
og=$(curl -s --max-time 20 "$FRONT/" \
     | grep -oE '<meta[^>]*property="og:image"[^>]*content="[^"]*"' \
     | grep -oE 'content="[^"]*"' | sed 's/content="//;s/"//' | head -1)
if [ -z "$og" ]; then
  echo "  ❌ og:image 메타가 없다 — 링크를 붙여도 미리보기가 안 뜬다"; fail=$((fail+1))
else
  case "$og" in http*) u="$og" ;; *) u="$FRONT$og" ;; esac
  check "$u" 200 "image/"
fi

echo "[index.html 이 선언한 파일]"
while read -r asset; do
  [ -z "$asset" ] && continue
  case "$asset" in http*) u="$asset" ;; /*) u="$FRONT$asset" ;; *) continue ;; esac
  check "$u" 200
done < <(curl -s --max-time 20 "$FRONT/" \
    | grep -oE '(href|src)="[^"]+\.(css|js|svg|png|jpg|ico|webmanifest|woff2?|glb|mp4)"' \
    | sed -E 's/^(href|src)="//; s/"$//' | sort -u)

echo
echo "결과: ✅ $pass  ❌ $fail"
[ "$fail" = 0 ]
