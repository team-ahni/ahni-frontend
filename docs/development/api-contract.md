# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/timetable` working tree based on `f93fd0ca4e440973a86325dd2e43c69e39cab5b4` (uncommitted timetable API additions)
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `77775a84f517dda54eef98813ba4cc6116ef53e30c413b2fe61e2731518b11f6`

This snapshot includes authenticated lecture lookup and student timetable CRUD.
The app sends only lecture UUIDs; the backend checks ownership and time conflicts.
The snapshot also includes the administrator-only atomic lecture import API.

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
