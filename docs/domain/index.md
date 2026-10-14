# Domain Map

- Academic records: courses, credits, grades, GPA, RPL, retakes.
- Graduation and scholarships: criteria vary by entry year and department.
- Timetable: conflict detection, custom start times, alarms, permission state.

시간표 탭은 연도·학기별 개설 강의를 조회하고 학생 본인의 시간표에
등록·변경·삭제합니다. 같은 학기의 다른 강의로만 변경하며 시간 충돌은
서버가 판정합니다. 수업은 학교 현지 시간으로 표시하며 월~토 6열을
항상 화면 너비 안에 표시합니다. 일요일 수업이 있으면 일요일도 함께 표시합니다.
강의 블록을 누르면 전체 과목명·교수·시간·강의실을 확인합니다.
계정 변경 시 시간표와 진행 중 요청을 초기화합니다.
개인 시간 변경과 기기 알림은 후속 범위입니다.
- Recommendations: prerequisites, graduation urgency, professor preference.
- Notices and inquiries: authenticated student scope and notification state.

Pure domain rules must not import Flutter widgets or platform plugins.

성적 등록은 수강연도 → 학기 → 과목 순서이며 `/api/v1/curriculum-courses?academicYear=...`의 해당 연도 공개 과목만 검색합니다. 연도를 바꾸면 과목·자동 학점·재수강 선택과 검색을 초기화하고 이전 요청의 늦은 응답은 무시합니다. 과목 로딩·실패 중에는 선택과 저장을 막으며 미등록 연도와 네트워크 오류를 구분합니다. 기존 같은 연도 성적 수정은 그대로 허용되지만 연도 변경은 서버에서 교과과정을 재검증합니다.

평점 시뮬레이션은 `성적` 화면의 계산기 버튼에서 시작합니다. 과목 분류·학점·예상 등급을 입력하고 `POST /api/v1/grades/simulation`이 반환한 현재·예상 GPA와 이수학점을 비교합니다. 화면에서는 GPA를 자체 계산하지 않습니다.

예상 과목은 최대 50건이며 실제 성적이나 기기에 저장하지 않습니다. 입력 변경, 화면 종료, 학생 계정 변경 시 결과를 초기화합니다. 실패 시 입력을 유지하여 다시 계산할 수 있고, 인증 만료 시 로그인으로 돌아갑니다. 예상 재수강/RPL과 목표 평점 역산은 이번 범위에 포함하지 않습니다.

단위·위젯·호스트 통합 테스트는 `./scripts/verify`로 검증합니다. 기기 확인은 로그인 → 성적 → 평점 시뮬레이션 → 예상 성적 입력 → 계산 → 입력 수정 후 재계산 순서로 진행합니다. 실제 성적 목록이 바뀌지 않는지도 확인합니다.
