# GitHub 자동화

## 동작

- `feat/**`, `fix/**`, `docs/**`, `refactor/**`, `chore/**` 브랜치에 푸시하면 `auto-pr.yml`이 `main` 대상 PR을 자동 생성합니다.
- 동일한 브랜치에 열린 PR이 있으면 새 PR을 만들지 않습니다.
- push 사용자별 PAT로 PR을 생성하거나 기존 PR의 커밋 내역 섹션을 갱신합니다. Secret 누락·소유자 불일치 시 PR 처리를 중단합니다.
- PR과 대상 브랜치에 `ci.yml`이 실행되며 `./scripts/verify`가 통과해야 합니다.

## GitHub에서 한 번만 설정할 항목

저장소 Settings → Secrets and variables → Actions에 작업자별 `GH_PAT_<사용자 ID 대문자>`를 등록합니다. 하이픈은 밑줄로 바꿉니다. 예: `GH_PAT_NIMUSEEL`. 공용 `GH_PAT`는 사용하지 않습니다. 권한·외부 협업자 제한·등록 방법은 [작업자별 설정 안내](automatic-pr.md)를 따릅니다.

## Copilot 리뷰

Copilot 자동 리뷰는 사용하지 않습니다(2026-11 제거). 워크플로에서 리뷰를 요청하지 않으며, 저장소 Settings의 Copilot automatic code review 규칙도 켜지 않습니다. 리뷰는 사람이 합니다.
