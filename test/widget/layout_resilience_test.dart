// 작은 화면과 큰 글자 설정에서 주요 화면을 모두 열어 레이아웃 넘침이 없는지 확인한다.
// RenderFlex 넘침 같은 레이아웃 오류는 테스트 실패로 이어지므로 글자 잘림이 다시 생기면 여기서 잡힌다.
import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';
import '../support/recommendation_fakes.dart';
import '../support/timetable_fakes.dart';
import '../unit/graduation/graduation_test.dart' show policy, progress;

Lecture _lecture(String id, String name, int day, String start, String end) =>
    Lecture(
      entityId: id,
      courseCode: 'C$id',
      courseName: name,
      credit: 3,
      professorName: '김교수, 이교수',
      section: '001',
      schedules: [
        LectureSchedule(
          entityId: 's$id',
          dayOfWeek: day,
          startTime: start,
          endTime: end,
          classroom: '하이테크센터 101호',
        ),
      ],
    );

Widget _app({required bool signedIn}) {
  final api = FakeStudentApi();
  if (signedIn) api.getProfileHandler = (_) async => testProfile;
  api.getDepartmentsHandler = () async => const [testDepartment];
  return AhniApp(
    environment: AppEnvironment.development,
    controller: OnboardingController(
      auth: FakeAuthGateway(currentSession: signedIn ? testSession : null),
      api: api,
    ),
    gradeController: buildTestGradeListController(
      grades: [testGrade, testPassGrade, testRplGrade],
    ),
    graduationController: GraduationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: FakeGraduationApi()
        ..results = [GraduationOverview.fromJson(policy(), progress())],
    ),
    scholarshipController: buildTestScholarshipController(),
    courseController: buildTestCourseCatalogController(),
    gradeRegistrationController: buildTestGradeRegistrationController(),
    gradeEditController: buildTestGradeEditController(),
    gradeSimulationController: buildTestGradeSimulationController(),
    inquiryController: buildTestInquiryController(),
    timetableController: TimetableController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: FakeTimetableApi()
        ..current = [
          TimetableEntry(
            entityId: 'e1',
            lecture: _lecture('1', '컴퓨터네트워크와 보안', 1, '09:00:00', '10:30:00'),
          ),
          TimetableEntry(
            entityId: 'e2',
            lecture: _lecture('2', '운영체제', 2, '10:30:00', '11:00:00'),
          ),
        ],
    ),
    recommendationController: buildTestRecommendationController(),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target.first);
  await tester.tap(target.first);
  await _settle(tester);
}

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await _settle(tester);
}

void main() {
  for (final (width, scale) in [(320.0, 1.0), (320.0, 1.6), (390.0, 2.0)]) {
    testWidgets('main screens lay out without overflow at ${width.toInt()}pt '
        'and ${scale}x text', (tester) async {
      tester.view.physicalSize = Size(width * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(signedIn: false));
      await _settle(tester);

      await tester.pumpWidget(
        KeyedSubtree(key: UniqueKey(), child: _app(signedIn: true)),
      );
      await _settle(tester);
      await _open(tester, find.widgetWithText(OutlinedButton, '전공 수정'));
      await _open(tester, find.text('취소'));

      await _open(tester, find.text('성적'));
      await _open(tester, find.byKey(const Key('open-grade-registration')));
      await _back(tester);
      await _open(tester, find.byKey(const Key('open-grade-simulation')));
      await _back(tester);
      await _open(tester, find.byKey(const Key('open-scholarship')));
      await _back(tester);

      await _open(tester, find.text('졸업'));
      await _open(tester, find.text('시간표'));
      await _open(tester, find.byKey(const Key('open-course-recommendation')));
      await _back(tester);

      await _open(tester, find.text('내 정보'));
      await _open(tester, find.byKey(const Key('open-inquiries')));
      await _back(tester);

      expect(tester.takeException(), isNull);
    });
  }
}
