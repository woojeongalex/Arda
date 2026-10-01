# 12. S3 버킷 — 콘솔에서 만드는 절차

> 2026-10-01 신설. [11-personal-ops](11-personal-ops.md) 의 "파일 저장소" 절을 실제 절차로 푼 것이다.
> 로컬은 MinIO 로 대신하고 있어 **이 절차는 서버에 올릴 때 필요하다.**

이력서 파일은 **서버를 지나가지 않는다.** 브라우저가 S3 로 직접 올리고 내린다.
서버가 하는 일은 "이 키에 올려도 된다"는 서명을 만드는 것뿐이다.

그래서 틀어지면 **서버 로그에 아무것도 안 남는다.** 아래 세 가지를 정확히 맞춰야 한다.

---

## 1. 버킷

| 항목 | 값 |
|---|---|
| 리전 | **ap-northeast-2 (서울)** — `AWS_REGION` 과 같아야 한다 |
| 이름 | 예: `arda-resumes-woojeongalex` (전 세계에서 유일해야 함) |
| 퍼블릭 액세스 차단 | **전부 켠 채로 둔다** |
| 버전 관리 | 꺼도 된다 |

**퍼블릭으로 열지 않는다.** 브라우저는 서명된 주소로만 접근하므로 공개할 이유가 없다.

---

## 2. CORS — 여기가 조용히 깨지는 곳

버킷 → 권한 → CORS(Cross-origin resource sharing) 에 **그대로** 붙여넣는다.

```json
[
  {
    "AllowedOrigins": [
      "https://ats.woojeongalex.cloud",
      "http://localhost:5173",
      "http://localhost:4173"
    ],
    "AllowedMethods": ["PUT", "GET"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

**빠뜨리면 브라우저 업로드만 실패하고 서버 로그에는 안 남는다.** CORS 는 브라우저만
검사하기 때문이다. `curl` 로 눌러 보면 멀쩡해서 원인을 코드에서 찾다가 오래 헤맨다.

- `PUT` 은 업로드(presign put_object), `GET` 은 다운로드(presign get_object)다. 코드가
  쓰는 것은 이 둘뿐이라 더 열지 않는다.
- `localhost` 두 개는 로컬에서 **진짜 S3** 로 붙여 볼 때만 쓴다. 평소 로컬은 MinIO 다.
- 주소를 옮기면 `AllowedOrigins` 를 같이 고친다. 안 고치면 업로드만 조용히 죽는다.

**확인은 반드시 실제 브라우저로 한다.** 지원 폼에서 파일을 하나 올려 봐야 드러난다.

---

## 3. IAM — 이 버킷만 만지는 사용자

사용자를 따로 만들고 아래 인라인 정책만 붙인다. `BUCKET-NAME` 두 군데를 바꾼다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ObjectReadWrite",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::BUCKET-NAME/*"
    },
    {
      "Sid": "LocateBucket",
      "Effect": "Allow",
      "Action": "s3:GetBucketLocation",
      "Resource": "arn:aws:s3:::BUCKET-NAME"
    }
  ]
}
```

**딱 두 가지만 연 이유**: 저장소 전체를 뒤져 보니 코드가 부르는 S3 동작은
`put_object` 와 `get_object` 뿐이다(`generate_presigned_url` 2곳, `get_object` 3곳,
`put_object` 1곳). 목록 조회도 삭제도 하지 않는다.

- `s3:ListBucket` 을 넣지 않았다. 없으면 **없는 키를 받을 때 403 이 404 대신 온다** —
  동작에는 지장이 없다. 목록을 콘솔에서 보고 싶으면 그때 본인 계정으로 보면 된다.
- `s3:DeleteObject` 도 넣지 않았다. 제출물 파일을 서버가 지울 일이 없다.

액세스 키를 발급해 서버 `~/arda/backend/.env` 에 넣는다. **개인 계정의 루트 키를
쓰지 않는다.**

```
AWS_REGION=ap-northeast-2
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET=<버킷 이름>
S3_ENDPOINT_URL=        # 비운다. 값이 있으면 MinIO 로 간다
```

`S3_ENDPOINT_URL` 을 **반드시 비운다.** 로컬 설정을 그대로 복사해 오면 서버가
있지도 않은 MinIO 를 찾는다.

---

## 4. 올린 뒤 확인

1. 지원 폼에서 **브라우저로** 이력서를 올린다 → 콘솔의 버킷에 객체가 생기는지 본다
2. 담당자 화면에서 그 이력서를 **내려받아** 본다 (presign get_object 경로)
3. 일부러 CORS 규칙을 지웠다가 1번을 다시 해 본다 — **증상을 한 번 봐 두면**
   나중에 5분이면 알아본다. 확인했으면 규칙을 되돌린다

브라우저 개발자도구 네트워크 탭에서 S3 로 가는 `PUT` 이 보이면 서명까지는 맞은 것이다.
거기서 CORS 오류가 뜨면 2번 절, 403 이 뜨면 3번 절을 본다.

---

## 비용

이력서 몇 MB 기준으로 **사실상 0** 이다. 서울 표준 스토리지가 GB당 월 $0.025 이고,
프리티어(가입 12개월 내)는 5GB·PUT 2,000·GET 20,000 까지 공짜다.
EC2 와 달리 시간당이 아니라 **쓴 만큼**이라 안 쓰면 안 나간다.

> MinIO 로 계속 가고 싶으면 `S3_ENDPOINT_URL` 을 MinIO 주소로 두면 된다.
> 코드에 스위치가 있어 바꿔 끼울 수 있다 — 로컬은 지금 그렇게 돌고 있다.
