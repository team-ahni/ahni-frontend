import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/grade_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

void main() {
  testWidgets('launches the AHNI onboarding entry point', (tester) async {
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
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
