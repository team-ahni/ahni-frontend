# Backend API contract

The backend-generated OpenAPI document is AHNI Mobile's only API contract. The app must not connect to Supabase PostgreSQL directly.

## Current snapshot

- Backend source: `feat/inquiry-attachments` commit `d62d1a1dc48524a2dd9e845abff8bfb2119916d6` (ahni-backend PR #53)
- OpenAPI title: `AHNI API`
- OpenAPI version: `v1`
- Source SHA-256: `c7e9c4659eda5bbebc63e7c79133c72e7d48569969375733741ab237a0acce29`

Inquiry attachment uploads must set the multipart part `Content-Type` (`image/jpeg`, `image/png`, or `application/pdf`); the backend rejects `application/octet-stream` with `UNSUPPORTED_INQUIRY_ATTACHMENT_TYPE`.

## Update procedure

From the mobile repository root, run:

```bash
./scripts/update-api-contract /absolute/path/to/ahni-backend/docs/api/openapi.json
```

The script copies the exact generated JSON and immediately runs the contract test. Do not edit `contracts/backend-openapi.json` manually. Every update must record the source backend commit and SHA-256 in this guide.

A backend API change is ready for mobile consumption only after the backend implementation, tests, authentication and authorization requirements, stable error examples, and generated OpenAPI document are updated together.
