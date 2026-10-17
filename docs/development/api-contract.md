# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/timetable` working tree with `origin/main` at `f24fec2`, professor-name and inquiry-attachment contracts (2026-10-18)
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `95ed981677dc0304d6fce6dfc8bea7b67866d2c63209656dbcebdeb622d81799`

This snapshot includes authenticated lecture lookup and student timetable CRUD.
The app sends only lecture UUIDs; the backend checks ownership and time conflicts.
Lecture responses now expose `professorName` directly, preserving joint-instructor
text. The old nested `professor` object and professor CRUD are removed. Deploy
this client with the backend V26 migration and updated administrator client.
The snapshot also includes the administrator-only atomic lecture import API.
Scholarship eligibility and administrator scholarship criteria endpoints are preserved.

Inquiry attachment uploads must set the multipart part `Content-Type` (`image/jpeg`, `image/png`, or `application/pdf`); the backend rejects `application/octet-stream` with `UNSUPPORTED_INQUIRY_ATTACHMENT_TYPE`.

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
