# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: backend `962d105`, with semester-based offered-course registration (2026-10-31)
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `9bc62bc289b64ab42b2075d75af48cd28b8652ba1d2b4445a1a9e5c1b488394c`

This snapshot includes authenticated lecture lookup and student timetable CRUD.
The app sends only lecture UUIDs; the backend checks ownership and time conflicts.
Lecture responses now expose `professorName` directly, preserving joint-instructor
text. The old nested `professor` object and professor CRUD are removed. Deploy
this client with the backend V26 migration and updated administrator client.
The snapshot also includes the administrator-only atomic lecture import API.
Scholarship eligibility and administrator scholarship criteria endpoints are preserved.
Administrator lecture updates preserve lecture and timetable entry identities;
their details appear on the next mobile refresh. Deleting an offering removes
its student timetable entries but preserves catalog courses and grades. The
new administrator routes do not change the mobile request/response formats.

`GET /api/v1/course-recommendations?academicYear=&term=` returns read-only, rule-based course recommendations for a regular term (`FIRST`/`SECOND`; seasonal terms return `400 INVALID_REQUEST`). The timetable tab opens it for the selected semester. Reasons are `GRADUATION_REQUIRED`, `OVERDUE`, `RECOMMENDED_NOW`, and `RETAKE`; unknown values are rejected at the boundary. Deploy the backend before enabling this client.

Inquiry attachment uploads must set the multipart part `Content-Type` (`image/jpeg`, `image/png`, or `application/pdf`); the backend rejects `application/octet-stream` with `UNSUPPORTED_INQUIRY_ATTACHMENT_TYPE`.

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.

OCR 과목 조회는 `GET /api/v1/courses`의 활성 카탈로그를 한 번 받아 학수번호로 대조합니다. 과목 표시·확인을 위한 조회 기준이며 등록 가능 여부를 보장하지 않습니다. `POST /api/v1/grades` 및 연도·학기를 바꾸는 수정은 백엔드 `962d105`의 기존 정책대로 해당 학기 `lecture` 개설 여부를 검증합니다. 해당 학기의 개설 강의가 없는 과거 성적 등록은 현재 거절됩니다. 학생 소유권, 중복, 학점·등급 및 재수강 검증을 유지합니다. 수동 과목 검색도 기존 `/api/v1/lectures/courses`를 계속 사용합니다. 조회와 등록 기준 통합은 후속 작업입니다.
