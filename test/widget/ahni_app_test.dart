import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/grade_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

void main() {
  testWidgets('renders the AHNI student authentication shell', (tester) async {
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );
    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: controller,
        gradeController: buildTestGradeListController(),
        graduationController: buildTestGraduationController(),
        scholarshipController: buildTestScholarshipController(),
        courseController: buildTestCourseCatalogController(),
        gradeRegistrationController: buildTestGradeRegistrationController(),
        gradeEditController: buildTestGradeEditController(),
        gradeSimulationController: buildTestGradeSimulationController(),
        inquiryController: buildTestInquiryController(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AHNI'), findsOneWidget);
    expect(findWhitespaceWrappedText('학사 준비, 함께 이어가요'), findsOneWidget);
    expect(find.text('학생 포털'), findsNothing);
    expect(find.text('학교 이메일'), findsOneWidget);
    expect(find.byKey(const Key('auth-mode-switch')), findsOneWidget);
    expect(find.byKey(const Key('auth-card')), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final theme = Theme.of(tester.element(find.byType(Scaffold)));

    expect(theme.colorScheme.primary, const Color(0xFF1558A6));
    expect(theme.textTheme.headlineMedium!.fontSize, 24);
    expect(appBar.titleSpacing, 24);
    expect(theme.appBarTheme.titleTextStyle!.fontSize, 20);
    expect(theme.appBarTheme.titleTextStyle!.height, 1.4);
    expect(
      theme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.dark,
    );
    expect(
      theme.appBarTheme.systemOverlayStyle?.statusBarBrightness,
      Brightness.light,
    );
  });

  testWidgets('keeps authentication usable on a compact screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = OnboardingController(
      auth: FakeAuthGateway(),
      api: FakeStudentApi(),
    );

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: controller,
        gradeController: buildTestGradeListController(),
        graduationController: buildTestGraduationController(),
        scholarshipController: buildTestScholarshipController(),
        courseController: buildTestCourseCatalogController(),
        gradeRegistrationController: buildTestGradeRegistrationController(),
        gradeEditController: buildTestGradeEditController(),
        gradeSimulationController: buildTestGradeSimulationController(),
        inquiryController: buildTestInquiryController(),
      ),
    );
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('학사 준비, 함께 이어가요'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
