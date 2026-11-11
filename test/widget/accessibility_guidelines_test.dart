// 주요 화면을 모두 열어 터치 영역·버튼 이름·글자 대비 기준을 지키는지 확인한다.
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
          const TimetableEntry(entityId: 'e1', lecture: testLecture),
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

final _failures = <String>[];

Future<void> _check(WidgetTester tester, String screen) async {
  for (final (name, guideline) in [
    ('android tap target', androidTapTargetGuideline),
    ('ios tap target', iOSTapTargetGuideline),
    ('labeled tap target', labeledTapTargetGuideline),
    ('text contrast', textContrastGuideline),
  ]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) _failures.add('[$screen] $name: ${result.reason}');
  }
}

Future<void> _open(WidgetTester tester, Finder target, String screen) async {
  await tester.ensureVisible(target.first);
  await tester.tap(target.first);
  await _settle(tester);
  await _check(tester, screen);
}

void main() {
  testWidgets('main screens meet tap target, label and contrast guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(signedIn: false));
    await _settle(tester);
    await _check(tester, 'login');

    await tester.pumpWidget(
      KeyedSubtree(key: UniqueKey(), child: _app(signedIn: true)),
    );
    await _settle(tester);
    await _check(tester, 'profile-home');
    await _open(tester, find.text('성적'), 'grades');
    await _open(
      tester,
      find.byKey(const Key('open-grade-registration')),
      'grade-registration',
    );
    await tester.pageBack();
    await _settle(tester);
    await _open(
      tester,
      find.byKey(const Key('open-grade-simulation')),
      'grade-simulation',
    );
    await tester.pageBack();
    await _settle(tester);
    await _open(
      tester,
      find.byKey(const Key('open-scholarship')),
      'scholarship',
    );
    await tester.pageBack();
    await _settle(tester);
    await _open(tester, find.text('졸업'), 'graduation');
    await _open(tester, find.text('시간표'), 'timetable');
    await _open(
      tester,
      find.byKey(const Key('open-course-recommendation')),
      'recommendation',
    );
    await tester.pageBack();
    await _settle(tester);
    await _open(
      tester,
      find.byKey(const Key('import-registration')),
      'import-sheet',
    );
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    await _open(tester, find.text('내 정보'), 'profile');
    await _open(tester, find.byKey(const Key('open-inquiries')), 'inquiries');

    semantics.dispose();
    expect(_failures, isEmpty, reason: _failures.join('\n\n'));
  });
}
