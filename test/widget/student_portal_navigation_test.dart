import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';

void main() {
  testWidgets('authenticated students move between grades and profile', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final studentApi = FakeStudentApi()
      ..getProfileHandler = (_) async => testProfile;
    final gradeApi = FakeGradeApi()..results = [testGrade];
    final onboardingController = OnboardingController(
      auth: auth,
      api: studentApi,
    );
    final gradeController = GradeListController(auth: auth, api: gradeApi);

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: onboardingController,
        gradeController: gradeController,
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

    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('성적'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grade-list-page')), findsOneWidget);
    expect(find.text('프로그래밍 기초'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-grade-simulation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-simulation-page')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('프로그래밍 기초'), findsOneWidget);

    await tester.tap(find.text('졸업'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graduation-progress-page')), findsOneWidget);

    await tester.tap(find.text('내 정보'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-summary')), findsOneWidget);
  });

  testWidgets('students create, update, and delete inquiries from profile', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final inquiryApi = FakeInquiryApi();
    final onboardingController = OnboardingController(
      auth: auth,
      api: FakeStudentApi()..getProfileHandler = (_) async => testProfile,
    );

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: onboardingController,
        gradeController: buildTestGradeListController(auth: auth),
        graduationController: buildTestGraduationController(),
        scholarshipController: buildTestScholarshipController(),
        courseController: buildTestCourseCatalogController(),
        gradeRegistrationController: buildTestGradeRegistrationController(),
        gradeEditController: buildTestGradeEditController(),
        gradeSimulationController: buildTestGradeSimulationController(),
        inquiryController: InquiryController(auth: auth, api: inquiryApi),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-inquiries')));
    await tester.tap(find.byKey(const Key('open-inquiries')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inquiry-page')), findsOneWidget);
    expect(find.byKey(const Key('open-inquiry-form')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-inquiry-form')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inquiry-title-field')),
      ' 성적 등록 문의 ',
    );
    await tester.enterText(
      find.byKey(const Key('inquiry-content-field')),
      ' 2025년 과목이 보이지 않습니다. ',
    );
    await tester.tap(find.byKey(const Key('submit-inquiry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inquiry-page')), findsOneWidget);
    expect(find.text('성적 등록 문의'), findsOneWidget);
    expect(inquiryApi.createCalls, 1);
    expect(inquiryApi.lastDraft?.title, ' 성적 등록 문의 ');

    expect(find.byKey(const Key('edit-inquiry-inquiry-id-2')), findsNothing);
    expect(find.byKey(const Key('delete-inquiry-inquiry-id-2')), findsNothing);

    await tester.tap(find.text('성적 등록 문의'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inquiry-detail-page')), findsOneWidget);
    expect(find.byKey(const Key('edit-inquiry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-inquiry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inquiry-title-field')),
      '수정 문의',
    );
    await tester.enterText(
      find.byKey(const Key('inquiry-content-field')),
      '수정된 내용입니다.',
    );
    await tester.tap(find.byKey(const Key('submit-inquiry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inquiry-detail-page')), findsOneWidget);
    expect(_wrappedText('수정 문의'), findsOneWidget);
    expect(_wrappedText('수정된 내용입니다.'), findsOneWidget);
    expect(inquiryApi.updateCalls, 1);
    expect(inquiryApi.lastUpdatedInquiryEntityId, 'inquiry-id-2');
    expect(inquiryApi.lastUpdateDraft?.title, '수정 문의');

    await tester.tap(find.byKey(const Key('delete-inquiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-inquiry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inquiry-page')), findsOneWidget);
    expect(_wrappedText('등록된 문의가 없어요.'), findsOneWidget);
    expect(inquiryApi.deleteCalls, 1);
    expect(inquiryApi.lastDeletedInquiryEntityId, 'inquiry-id-2');
  });

  testWidgets('sign-out clears grades owned by the previous student', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final onboardingController = OnboardingController(
      auth: auth,
      api: FakeStudentApi()..getProfileHandler = (_) async => testProfile,
    );
    final gradeController = GradeListController(
      auth: auth,
      api: FakeGradeApi()..results = [testGrade],
    );

    await tester.pumpWidget(
      AhniApp(
        environment: AppEnvironment.development,
        controller: onboardingController,
        gradeController: gradeController,
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
    await tester.tap(find.text('성적'));
    await tester.pumpAndSettle();
    expect(gradeController.state, isA<GradeListReady>());

    await tester.tap(find.text('내 정보'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();

    expect(gradeController.state, isA<GradeListInitial>());
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
  });
}

Finder _wrappedText(String data) {
  return find.byWidgetPredicate(
    (widget) => widget is WhitespaceWrappedText && widget.data == data,
  );
}
