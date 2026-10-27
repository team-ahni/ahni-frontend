import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_list_page.dart';
import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';
import '../../support/whitespace_wrapped_text_finder.dart';

void main() {
  testWidgets('groups grade rows by academic year and term', (tester) async {
    final controller = _controllerWith([
      testGrade,
      testPassGrade,
      testRplGrade,
    ]);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('학기별 성적을 확인하세요'), findsOneWidget);
    expect(find.text('2025년 2학기'), findsOneWidget);
    expect(find.byKey(const Key('grade-summary')), findsOneWidget);
    expect(find.text('3.83'), findsOneWidget);
    expect(find.text('전공'), findsOneWidget);
    expect(find.text('2025년 1학기'), findsOneWidget);
    expect(find.text('프로그래밍 기초'), findsOneWidget);
    expect(find.text('CSE101 · 3학점 · 재수강'), findsOneWidget);
    expect(find.text('A+'), findsOneWidget);
    expect(find.text('4.5점'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    expect(find.text('RPL'), findsOneWidget);
    expect(find.byKey(const Key('grade-row-grade-id-1')), findsOneWidget);
    expect(find.byKey(const Key('grade-term-2025-SECOND')), findsOneWidget);
  });

  testWidgets('shows a useful empty state when no grades exist', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_controllerWith(const [])));
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('아직 등록된 성적이 없어요'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('성적을 등록하면 학기별 이력을 여기서 확인할 수 있어요.'),
      findsOneWidget,
    );
  });

  testWidgets('registers a grade from the empty state and refreshes the list', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeGradeApi()..results = const [];
    api.registerHandler = (_, _) async {
      api.results = [testGrade];
      return testGrade;
    };

    await tester.pumpWidget(
      _testApp(
        GradeListController(auth: auth, api: api),
        courseController: buildTestCourseCatalogController(auth: auth),
        registrationController: GradeRegistrationController(
          auth: auth,
          api: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-grade-registration-empty')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-registration-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('term-SECOND')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-option-course-id-1')));
    await tester.pumpAndSettle();
    final gradeCode = find.byKey(const Key('grade-code'));
    await tester.ensureVisible(gradeCode);
    await tester.tap(gradeCode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A+').last);
    final submit = find.byKey(const Key('register-grade'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grade-registration-page')), findsNothing);
    expect(find.text('프로그래밍 기초'), findsOneWidget);
    expect(api.registerCalls, 1);
    expect(api.calls, 2);
  });

  testWidgets('deletes a selected grade and refreshes the list', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeGradeApi()..results = [testGrade];
    api.deleteHandler = (_, _) async => api.results = const [];

    await tester.pumpWidget(
      _testApp(
        GradeListController(auth: auth, api: api),
        editController: GradeEditController(auth: auth, api: api),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('grade-row-grade-id-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-edit-page')), findsOneWidget);

    final delete = find.byKey(const Key('delete-grade'));
    await tester.ensureVisible(delete);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-grade')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grade-edit-page')), findsNothing);
    expect(findWhitespaceWrappedText('아직 등록된 성적이 없어요'), findsOneWidget);
    expect(api.deleteCalls, 1);
    expect(api.calls, 2);
  });

  testWidgets('retries a recoverable grade-list failure', (tester) async {
    final api = FakeGradeApi()
      ..error = const GradeApiFailure(
        GradeApiFailureKind.recoverable,
        '성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    final controller = GradeListController(auth: _authenticated(), api: api);
    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();

    expect(
      findWhitespaceWrappedText('성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.'),
      findsOneWidget,
    );

    api
      ..error = null
      ..results = [testGrade];
    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('프로그래밍 기초'), findsOneWidget);
    expect(api.calls, 2);
  });

  testWidgets('expired authentication returns to sign-in', (tester) async {
    var authenticationRequests = 0;
    final controller = GradeListController(
      auth: FakeAuthGateway(),
      api: FakeGradeApi(),
    );
    await tester.pumpWidget(
      _testApp(
        controller,
        onAuthenticationRequired: () => authenticationRequests++,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      findWhitespaceWrappedText('로그인이 만료되었습니다. 다시 로그인해 주세요.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인으로 돌아가기'));

    expect(authenticationRequests, 1);
  });

  testWidgets('grade rows remain usable with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _testApp(_controllerWith([testGrade, testPassGrade])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

GradeListController _controllerWith(List<GradeRecord> grades) {
  return GradeListController(
    auth: _authenticated(),
    api: FakeGradeApi()..results = grades,
  );
}

AuthGateway _authenticated() {
  return FakeAuthGateway(
    currentSession: const AuthSession(
      accessToken: 'test-jwt',
      email: 'student@inha.edu',
    ),
  );
}

Widget _testApp(
  GradeListController controller, {
  VoidCallback? onAuthenticationRequired,
  CourseCatalogController? courseController,
  GradeRegistrationController? registrationController,
  GradeEditController? editController,
  ScholarshipController? scholarshipController,
}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1558A6),
        surface: Colors.white,
      ),
    ),
    home: GradeListPage(
      controller: controller,
      simulationController: buildTestGradeSimulationController(),
      courseController: courseController ?? buildTestCourseCatalogController(),
      registrationController:
          registrationController ?? buildTestGradeRegistrationController(),
      editController:
          editController ??
          GradeEditController(auth: _authenticated(), api: FakeGradeApi()),
      scholarshipController:
          scholarshipController ?? buildTestScholarshipController(),
      onAuthenticationRequired: onAuthenticationRequired ?? () {},
    ),
  );
}
