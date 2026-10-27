# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: generated from `origin/main` at `900f13f` plus `feat/lecture-management-mutations` at `1e27a2c`, preserving course recommendations, inquiry assignment, and administrator lecture update/delete contracts (2026-10-27)
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `f1c71cbedc20fb1898f9ac46a4d189f945d6a0f97c9b3cacb418ef9459ad5f9a`

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
