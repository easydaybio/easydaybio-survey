# 온츄 시식 설문

시제품을 무료로 제공하거나 시식할 때마다 QR로 받는 설문과, 운영자용 관리 화면입니다.
빌드 과정이 없는 정적 페이지라 폴더를 그대로 올리면 됩니다.

| 파일 | 내용 |
|---|---|
| `docs/index.html` | 응답자용 설문 (QR로 진입, 로그인 없음) |
| `docs/admin.html` | 운영자용 관리 화면 (행사 등록과 QR, 결과, 개선 기록) |
| `docs/questions.js` | 문항 정의. 문항을 고칠 때 이 파일을 고칩니다 |
| `docs/config.js` | Supabase 주소와 공개 키 |
| `supabase/schema.sql` | DB 구조와 보안 규칙 |

## 처음 한 번 설정

1. Supabase에서 새 프로젝트를 만듭니다. 회사 업무 앱(`easydaybio`)과 다른 프로젝트여야 합니다.
2. SQL Editor에 `supabase/schema.sql`을 통째로 붙여넣어 실행합니다.
3. Authentication → Users → Add user로 운영자 계정(이메일, 비밀번호)을 만듭니다.
4. SQL Editor에서 그 이메일을 운영자로 등록합니다.
   `insert into public.admins (email) values ('운영자 이메일');`
5. Project Settings → API의 Project URL과 publishable 키를 `config.js`에 넣습니다.
6. GitHub 저장소 Settings → Pages에서 Branch를 `main`, 폴더를 `/docs`로 정합니다. 주소는 `https://easydaybio.github.io/easydaybio-survey/`입니다.

## 운영

1. `admin.html`에 로그인해 행사를 등록합니다. 유형은 현장 시식(짧은 설문)과 제품 제공(긴 설문) 중에서 고릅니다.
2. 나온 QR을 내려받아 인쇄하거나 링크를 보냅니다.
3. 행사가 끝나면 '마감하기'를 누릅니다. 마감된 QR로는 응답할 수 없습니다.
4. 결과 탭에서 집단별로 보고, 바꾼 내용은 개선 기록 탭에 남깁니다.

## 지킬 것

- 한 집단이 30명이 되기 전에는 '경향' 표시가 붙습니다. 결론으로 말하지 않습니다.
- `q_comfort`(속 편함)는 내부 분석 전용입니다. 외부 소개나 광고 문구로 쓰지 않습니다.
- 인용은 `consent_quote`가 동의인 한마디 원문만 씁니다.
- 응답 표에는 이름과 연락처를 두지 않습니다.
- 새 제품 버전이 나오면 행사 등록 때 제품 버전만 바꿉니다. 문항과 척도는 그대로 두어야 버전끼리 비교됩니다.
