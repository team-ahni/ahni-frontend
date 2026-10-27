# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: generated from the current working tree with semester-based offered-course registration (2026-10-27; uncommitted)
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

성적 등록은 `GET /api/v1/lectures/courses`에 수강연도와 학기를 전달하고 개설 과목을 조회합니다. 신규 저장과 학기 변경은 해당 학기 강의가 있는지 검증합니다. 새 서버 API와 함께 배포해야 합니다. 이 명세는 현재 작업 중인 백엔드에서 생성했습니다.
