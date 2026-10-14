import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_list_page.dart';
import 'package:ahni_mobile/features/scholarship/data/scholarship_api.dart';
import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';
import 'package:ahni_mobile/features/scholarship/presentation/scholarship_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';
import '../unit/features/scholarship/scholarship_test.dart'
    show eligibilityJson;

void main() {
  Widget page(
    FakeScholarshipApi api, {
    VoidCallback? onAuthenticationRequired,
  }) => MaterialApp(
    home: ScholarshipPage(
      controller: buildTestScholarshipController(api),
      onAuthenticationRequired: onAuthenticationRequired ?? () {},
    ),
  );

  testWidgets('shows each scholarship result with its shortfalls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final api = FakeScholarshipApi()
      ..result = ScholarshipEligibility.fromJson(eligibilityJson());
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();

    expect(find.text('누적 평점 3.20'), findsOneWidget);
    expect(find.text('학사경고 1회'), findsOneWidget);
    expect(findWhitespaceWrappedText('성적우수장학금'), findsOneWidget);
    expect(findWhitespaceWrappedText('평점 +0.30 필요'), findsOneWidget);
    expect(findWhitespaceWrappedText('이수학점 3학점 더 필요'), findsOneWidget);
    expect(find.bySemanticsLabel('기준 미충족'), findsOneWidget);
    await tester.scrollUntilVisible(findWhitespaceWrappedText('생활지원장학금'), 150);
    expect(find.bySemanticsLabel('기준 충족'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'guides the student to contact an administrator without criteria',
    (tester) async {
      await tester.pumpWidget(page(FakeScholarshipApi()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholarship-empty')), findsOneWidget);
    },
  );

  testWidgets('retries a recoverable failure', (tester) async {
    var calls = 0;
    final api = FakeScholarshipApi();
    api.handler = (_) async {
      calls++;
      if (calls == 1) {
        throw const ScholarshipApiFailure(
          ScholarshipFailureKind.recoverable,
          '장학 정보를 불러오지 못했어요. 다시 시도해 주세요.',
        );
      }
      return ScholarshipEligibility.fromJson(eligibilityJson());
    };
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();

    expect(
      findWhitespaceWrappedText('장학 정보를 불러오지 못했어요. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, '다시 시도'));
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('성적우수장학금'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('expired authentication returns to sign-in', (tester) async {
    var authenticationRequests = 0;
    final api = FakeScholarshipApi()
      ..handler = (_) async => throw const ScholarshipApiFailure(
        ScholarshipFailureKind.unauthorized,
        '다시 로그인해 주세요.',
      );
    await tester.pumpWidget(
      page(api, onAuthenticationRequired: () => authenticationRequests++),
    );
    await tester.pumpAndSettle();

    expect(authenticationRequests, 1);
  });

  testWidgets('opens scholarship requirements from the grade page', (
    tester,
  ) async {
    final scholarshipApi = FakeScholarshipApi()
      ..result = ScholarshipEligibility.fromJson(eligibilityJson());
    await tester.pumpWidget(
      MaterialApp(
        home: GradeListPage(
          controller: GradeListController(
            auth: FakeAuthGateway(currentSession: testSession),
            api: FakeGradeApi()..results = [testGrade],
          ),
          simulationController: buildTestGradeSimulationController(),
          courseController: buildTestCourseCatalogController(),
          registrationController: buildTestGradeRegistrationController(),
          editController: buildTestGradeEditController(),
          scholarshipController: buildTestScholarshipController(scholarshipApi),
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('장학요건'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scholarship-page')), findsOneWidget);
    expect(findWhitespaceWrappedText('성적우수장학금'), findsOneWidget);
  });
}
