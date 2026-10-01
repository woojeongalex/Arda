# Arda — 채용 지원 관리 시스템

# (Applicant Tracking System(ATS))

Seuk 의 팀 프로젝트입니다. **이 저장소는 [`Seuk-Team/Arda`](https://github.com/Seuk-Team/Arda) 의 포크**이고,
개인 운영본(주소·서버·키를 내 것으로 바꾼 것)입니다.
달라진 것은 [`docs/00_overview/11-personal-ops.md`](docs/00_overview/11-personal-ops.md) 에만 적고,
팀 시절 기록(ADR·배포 문서)은 고치지 않습니다 — 지난 결정을 고쳐 쓰면 기록이 거짓말을 합니다.

> 📄 프로젝트 소개 사이트 <https://ats.suvisdev.cloud> · 실제 서비스 <https://seuk.suvisdev.cloud>

---

## 내가 맡은 부분 (`woojeongalex`)

팀이 정한 담당은 **백엔드**(`backend/`, agent 폴더 제외)이고, 진행 중에
**인증(A1~A3)과 단계 전환 로직(D3)** 을 이관받았습니다
([04-team.md](docs/00_overview/04-team.md)).

**커밋 304개**로 전체 1,098개 중 두 번째입니다 — `git shortlog -sne --all` 로 확인됩니다.

| 영역 | 커밋이 닿은 곳 |
|:--|:--|
| **백엔드 API·스키마** | `backend/app/api` · `backend/app/schemas` — 라우트와 요청/응답 계약 |
| **프론트엔드** | `frontend/app/src` — 단일 폴더로는 가장 많이 만졌다 |
| **API 문서·ERD** | `docs/00_overview/02-api.md` · `01-erd.md` — 계약을 코드와 같은 커밋에서 갱신 |
| **AI 면접 실시간 서버** | `ai/lie-detection/app.py` · `interview_ws.py` |
| **마이그레이션·시드** | `backend/alembic/versions` · `backend/scripts/seed` |

팀 문서가 제 발표 몫으로 적어 둔 것은 **상태 전환 규칙을 DB 와 코드 중 어디서 강제했는가**,
**인덱스 튜닝 전/후 수치**, **제출물 무결성 앵커**([ADR-0028](docs/03_decision/0028-제출물-무결성-앵커.md))입니다.

실시간 면접은 **프로세스 하나를 전제로** 돕니다 — 면접 방·입장권·로그인 잠금·STT 모델이
프로세스 메모리에 있어, 워커를 늘리면 지원자와 담당자가 서로 다른 프로세스에 앉아 서로를
못 봅니다. 그래서 `--workers 1` 을 유지합니다.

---

> **Arda** — 퀘냐로 "영역(Realm)", 사람들이 모여 사는 터전. 판단하는 주체가 아니라 판단이 일어나는 장소다 — 도구는 자리를 마련하고, 판단은 그 안의 사람이 한다 ([ADR-0014](docs/03_decision/0014-프로젝트-이름-arda.md)).

- 스택:
  FastAPI
  PostgreSQL
  React (Vite · TS)
  AWS (S3 · SES · SQS)
  Docker
  Vercel

- **메인 화면**: 지원자 칸반 보드 — 카드를 드래그해 단계 이동, 이동 시 지원자에게 메일 자동 발송

## 문서

| 문서                                             | 내용                                                              |
| ------------------------------------------------ | ----------------------------------------------------------------- |
| [docs/00_overview/](docs/00_overview)            | 핵심 공용 문서 — 개요 `00` · ERD `01` · API `02` · 협업 규칙 `03` · 팀 `04` · 디자인 `05` · 주차별 계획 `06` |
| [docs/01_role/](docs/01_role)                    | **도메인별 로드맵 — 각자 자기 것부터 읽는다** (범위·마일스톤·작업 큐) |
| [docs/02_tasks/](docs/02_tasks)                  | 작업 지시서 (기능 번호 단위)                                      |
| [docs/03_decision/](docs/03_decision)                      | 기술 결정 기록 (왜 안 썼는가 포함)                                |
| [docs/04_planning/](docs/04_planning)            | 원본 기획 문서 · 동작 프로토타입                                  |

## 구조

```
backend/    FastAPI 서버 (backend/app/agent/ 는 에이전트 도메인)
frontend/   React 앱 (Vercel 배포)
mobile/     모바일 앱 (Flutter · Android — 예정)
infra/      Docker · AWS · CI/CD
docs/       위 문서 전부
```

## 시작하기

작업 전에 [CLAUDE.md](CLAUDE.md)(작업 규칙)와 **자기 도메인의 [docs/01_role/](docs/01_role) 로드맵**을 먼저 읽는다. 도메인·오너는 [docs/00_overview/04-team.md](docs/00_overview/04-team.md).
기능은 번호로 부른다 (예: D3 = 드래그로 단계 이동) — 전체 목록은 [docs/04_planning/00_summary_ko.md](docs/04_planning/00_summary_ko.md) 6장.
