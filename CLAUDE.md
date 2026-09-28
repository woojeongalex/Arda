# Arda 작업 규칙 — 개인 운영본

> 2026-09-28 분기: 팀 저장소(`Seuk-Team/Arda`)에서 복제해 **개인 운영본**(`woojeongalex/arda`)으로 갈라졌다.
> 운영 주소는 `ats.woojeongalex.cloud`(프론트) · `api.ats.woojeongalex.cloud`(API), 서버는 개인 AWS.
> 팀 규칙(도메인 오너제 · 사후 공지 · 팀장 조율)은 **여기서는 적용되지 않는다** — 오너가 한 명이다.
> 팀 시절의 결정 기록(`docs/03_decision/`)과 운영 기록(`docs/00_overview/07-deploy.md`)은 **사실 그대로 남긴다.**
> 지난 일을 고쳐 쓰면 ADR 이 거짓말을 한다. 여기서 바뀐 것은 이 파일과 [docs/00_overview/11-personal-ops.md](docs/00_overview/11-personal-ops.md) 에 적는다.

## 시작 전

- [docs/00_overview/01-erd.md](docs/00_overview/01-erd.md)(테이블 정의서)와 [docs/00_overview/02-api.md](docs/00_overview/02-api.md)를 읽고 시작한다.
- **로컬에서 뭔가 안 돌면 [docs/00_overview/08-local-setup.md](docs/00_overview/08-local-setup.md)를 먼저 본다.** 코드가 아니라 환경이 원인인 것들(스키마 이행·포트 충돌·백엔드 스위치)이 거기 모여 있다.
- **프론트/UI 작업은 [docs/00_overview/05-design.md](docs/00_overview/05-design.md)를 먼저 읽는다.** 값 미확정("(시안에서 확정)") 토큰은 임의로 채우지 않는다.
- 운영 주소·서버·키가 팀 것과 어떻게 다른지는 [docs/00_overview/11-personal-ops.md](docs/00_overview/11-personal-ops.md).

## 범위

- **묻지 않고 진행한다.** 오너가 한 명이라 확인 절차가 없다. 먼저 말하는 것은 되돌리기 어려운 것뿐 — 스키마 파괴적 변경, 외부 서비스 계약, 도메인·서버 이전, 돈이 나가는 결정.
- **스키마 변경은 자유 — 단 코드와 같은 커밋에서 [01-erd.md](docs/00_overview/01-erd.md) 갱신 + alembic 리비전까지 한 묶음이다.** 문서 갱신 없는 스키마 변경 금지. API 변경도 같은 커밋에서 [02-api.md](docs/00_overview/02-api.md) 갱신.
- **되돌릴 수 있는 일은 결정하지 말고 그냥 한다.** 자료 조사·실험·프로토타입은 묻지 말고 진행하고 결과만 공유한다.
- **기능 추가와 ADR 개정은 자유다.** 과거 ADR 이 잘랐던 기능이라도 개정 ADR 을 쓰면 그것으로 확정. 다만 **반대 근거는 지우지 않고 남긴다** — 표정분석(ADR-0002 → ADR-0029)에서 그렇게 했고 그 기록이 값을 했다.

## 반영 방식

- **main 직접 push 를 하지 않는다 — 브랜치→PR→자체 머지.** 혼자여도 유지하는 이유는 승인이 아니라 **CI 게이트** 때문이다: 로컬에 node·docker 가 없을 때 프론트 빌드와 pytest 를 확인할 유일한 자리가 PR 의 CI 다.
- **`main` 머지 = 자동 배포.** 서버 systemd 타이머가 2분마다 `infra/deploy-arda.sh` 를 부른다 — 바뀐 부분만 다시 빌드하고 alembic 을 올린 뒤 컨테이너를 재구성한다. **CI 초록인 PR 만 머지한다.**
- 커밋 제목에 기능 번호(D3, G1, J7…)를 붙인다. 번호 없는 작업은 도메인명 접두어 — 예: `feat(front): React 라우팅 뼈대`.

## 금지

- 시크릿(AWS 키, DB 비밀번호, 토큰, 지메일 앱 비밀번호)을 코드·커밋·로그에 남기지 않는다. 환경변수는 `.env`(git 제외) + `.env.example`(키 이름만).
- 테스트를 통과시키려고 주석 처리하거나 우회하지 않는다. 실패하면 실패한 대로 커밋 메시지에 적는다.
- **실제 지원자 데이터를 이 서버에 넣지 않는다.** 이 운영본은 시연·포트폴리오용이고 DB 에는 더미만 둔다. 팀 운영 DB 덤프를 여기로 복원하지 않는다.
- **도메인 주소를 코드에 새로 박지 않는다.** 서버 주소는 `.env`(`API_DOMAIN` · `PUBLIC_APP_BASE_URL` · `CORS_ORIGINS`), 프론트는 `VITE_API_BASE`, 앱은 `--dart-define=API_BASE`. 한 번 흩어지면 다음 이전 때 20개 파일을 다시 뒤진다.

## 검증

- 코드 변경 후 해당 파트의 실행/테스트를 돌려 깨지지 않았는지 확인하고, 결과를 커밋 메시지에 한 줄 남긴다.
- **깨진 main 을 발견하면 묻지 말고 고치거나(fix-forward) revert 한다.**

## 팀 저장소와의 관계

- `upstream` 리모트로 `Seuk-Team/Arda` 가 붙어 있다. 팀이 고친 것을 가져오려면 `git fetch upstream` 후 필요한 커밋만 cherry-pick 한다.
- **여기서 고친 것을 upstream 으로 밀지 않는다.** 도메인·서버 설정이 달라 그대로 올라가면 팀 서버가 깨진다.
