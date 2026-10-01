# 11. 개인 운영본 — 주소·서버·키

> 2026-09-28 신설. 팀 저장소(`Seuk-Team/Arda`)에서 복제해 개인 운영본으로 갈라진 뒤의 구성이다.
> 팀 서버 이야기는 [07-deploy.md](07-deploy.md) 가 그대로 진실이다 — 그 문서는 **고치지 않는다**(지난 일의 기록).
> 이 문서는 "여기서는 무엇이 다른가"만 적는다.

## 주소

| 무엇 | 개인 운영본 | 팀 (참고) |
|---|---|---|
| 프론트 | `https://ats.woojeongalex.cloud` | `https://seuk.suvisdev.cloud` |
| API | `https://api.ats.woojeongalex.cloud` | `https://api.seuk.suvisdev.cloud` |
| 공개 지원 링크 | `https://ats.woojeongalex.cloud/apply/<token>` | 〃 |
| 저장소 | `woojeongalex/arda` | `Seuk-Team/Arda` |

**이름을 `ats.` 로 잡은 이유**: 개인 도메인의 apex(`woojeongalex.cloud`)는 포트폴리오 허브가 이미 쓰고 있고, 다른 프로젝트도 `ieum.` 처럼 하위 이름으로 나뉘어 있다. 소개 사이트 저장소(`ats.woojeongalex.cloud`)가 데모 링크를 이미 이 주소로 걸어 둔 것도 맞춘 근거다.

## 도메인이 정해지는 곳 — 이제 한 군데다

옮기면서 코드에 박혀 있던 주소를 걷어냈다. 다음에 또 옮길 때 고칠 곳:

| 무엇 | 어디 | 값 |
|---|---|---|
| 서버가 받는 주소 | 서버 `~/arda/.env` | `API_DOMAIN` — Caddyfile 의 `{$API_DOMAIN}` 과 compose 의 n8n 주소 3줄을 한꺼번에 채운다 |
| 메일에 들어가는 링크 | 서버 `~/arda/backend/.env` | `PUBLIC_APP_BASE_URL` · `PUBLIC_API_BASE_URL` |
| 브라우저 허용 출처 | 〃 | `CORS_ORIGINS` (빠지면 화면이 조용히 안 뜬다) |
| 프론트가 부르는 API | `frontend/app/.env.production` | `VITE_API_BASE` |
| 앱이 부르는 API | 빌드 인자 | `flutter build apk --dart-define=API_BASE=...` |

**코드에 새로 박지 않는다.** 한 번 흩어지면 다음 이전 때 20개 파일을 다시 뒤지게 된다.

## 서버 (개인 AWS)

- EC2 **t3.medium (4GB)** · 서울(ap-northeast-2) · Ubuntu 24.04 · gp3 30GB · Elastic IP
  - 4GB 아래로 내리지 않는다 — 거짓말 탐지 서비스가 분석 1건에 574MiB 를 쓴다(팀 09-07 실측, t3.small 2GB 에서 api 와 같이 못 돌았다).
- 보안그룹 인바운드: 22(내 IP 만) · 80 · 443. **8000 은 열지 않는다** — Caddy 만 밖을 본다.
- 컨테이너 5개: `db`(pgvector/pg16) · `api` · `lie-detection` · `n8n` · `caddy`
- **`--workers 1` 은 그대로 둔다.** 면접 방·입장권·로그인 잠금·STT 모델이 프로세스 메모리라 늘리면 지원자와 담당자가 다른 프로세스에 앉는다.

## DNS (Cloudflare)

| 유형 | 이름 | 값 | 프록시 |
|---|---|---|---|
| A | `api.ats` | EC2 Elastic IP | **꺼 둔다 (DNS only · 회색 구름)** |
| CNAME/A | `ats` | Vercel 이 지정하는 값 | Vercel 안내대로 |

**프록시를 끄는 이유**: Caddy 가 Let's Encrypt 인증서를 직접 받고(HTTP-01), 실시간 면접이 WebSocket + WebRTC 시그널링을 쓴다. 주황 구름을 켜면 인증서 발급과 긴 연결에서 각각 다른 방식으로 막히는데, 둘 다 증상이 "가끔 안 된다"로만 보여 원인을 찾기 어렵다.

## 파일 저장소 (S3)

- 개인 AWS 에 버킷 하나(서울). 코드는 `S3_ENDPOINT_URL` 스위치가 있어 나중에 MinIO 로 바꿀 수 있다.
- **버킷 CORS 에 `https://ats.woojeongalex.cloud` 를 넣는다.** 빠뜨리면 **브라우저 이력서 업로드만 실패하고 서버 로그에도 안 남는다** — CORS 는 브라우저만 검사하기 때문이다. curl 로는 멀쩡해 보여서, 실제 브라우저로 파일을 올려봐야만 드러난다.
  - AllowedMethods `PUT` · AllowedOrigins 위 주소 + `http://localhost:5173` · AllowedHeaders `*`
- IAM 은 이 버킷만 만지는 전용 사용자로 만든다. 개인 계정의 다른 것에 손이 닿지 않게.

> **콘솔에서 그대로 붙여넣을 CORS·IAM JSON 은 [12-s3-setup](12-s3-setup.md) 에 있다.**
> 코드가 부르는 S3 동작을 저장소 전체에서 세어 보고 거기에만 권한을 맞췄다
> (`put_object`·`get_object` 둘뿐이다).

## 데이터

**팀 운영 DB 를 복원하지 않는다.** 실제 지원자의 이름·이메일·이력서가 들어 있고, 그 사람들이 동의한 범위 밖이다. 새로 만든다:

```bash
docker compose -p arda -f infra/docker-compose.prod.yml run --rm api /app/.venv/bin/alembic upgrade head
```

리비전 26개가 올라가며 테이블 28개가 생긴다. 그 뒤 admin 계정 하나 → 시연용 공고·지원자 시드.

## 키 — 전부 새로 발급한다

팀 것을 가져오지 않는다. 팀 키가 폐기되면 이쪽도 같이 멈추고, 09-02 에 그 일이 실제로 일어났다([ADR-0025](../03_decision/0025-운영-권한-이관.md)).

| 키 | 어디서 | 비고 |
|---|---|---|
| `JWT_SECRET` | `openssl rand -hex 32` | |
| `DB_PASSWORD` | 직접 정함 | |
| `ANTHROPIC_API_KEY` | 개인 콘솔 | 요약·채점·채팅 |
| `OPENAI_API_KEY` | 개인 콘솔 | 실시간 전사(분당 $0.006) |
| `TURN_KEY_ID` · `TURN_KEY_API_TOKEN` | Cloudflare Realtime → TURN Server | 24시간짜리라 **서버가 직접 발급**한다, 손으로 박지 않는다 |
| 지메일 앱 비밀번호 | 구글 계정 → 보안 → 앱 비밀번호 | n8n SMTP |
| `N8N_ENCRYPTION_KEY` | `openssl rand -hex 32` | **한 번 정하면 못 바꾼다** — 잃으면 백업을 복원해도 자격 증명을 못 푼다. 서버 밖에도 한 벌 |
| `ARDA_SERVICE_TOKEN` | 직접 정함 | 판정 워커·n8n 이 `/internal/*` 을 부를 때 |
| S3 자격 | 개인 IAM | 위 버킷 전용 |

## 자동 배포

서버 systemd 타이머가 2분마다 `infra/deploy-arda.sh` 를 부른다. `main` 에 새 커밋이 있으면 **바뀐 부분만** 다시 빌드하고(`backend/` → api, `ai/lie-detection/` → 판정 워커), alembic 을 올린 뒤 컨테이너를 재구성한다. 스크립트 안의 저장소 주소는 개인 저장소로 바꿔 뒀다.

## 켜지 않는 것

- **무결성 앵커 게시**(`.github/workflows/anchor-publish.yml`) — Polygon 테스트넷 개인키를 GitHub Secret 으로 읽는다. 새 지갑을 만들어 넣기 전까지는 꺼 둔다. 지문(SHA-256)과 내부 사슬은 서버에서 그대로 돌고, 공개 체인에 못 박는 단계만 빠진다.
- **CloudWatch 경보·SNS** — 팀 계정 기준이다. 개인 계정에서는 `infra/server-status.sh` 로 충분하다.
