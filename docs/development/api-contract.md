# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/scholarship-requirements` commit `5ff82a4d251a3f7f5b0f69ea62e2304f7c6ad49f`
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `c0fa459ae8e3df1779f7092d2fc61631278c8db28a1a539546a7af25c1df93bc`

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
