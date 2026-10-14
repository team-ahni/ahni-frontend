# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/timetable` commit `9eb1002cc1739e7fe966e13e25fa6e6dacf9e05e`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `9e2004ab213e212d35efde853e618efc2b17efa19afa56473f2e391e0acda1c9`

This snapshot includes authenticated lecture lookup and student timetable CRUD.
The app sends only lecture UUIDs; the backend checks ownership and time conflicts.
The snapshot also includes the administrator-only atomic lecture import API.
Scholarship eligibility and administrator scholarship criteria endpoints are preserved.

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
