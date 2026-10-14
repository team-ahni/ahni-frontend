import 'dart:convert';

import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';

void main() {
  testWidgets(
    'authenticated app calculates expected grades through the HTTP adapter without registration',
    (tester) async {
      final auth = FakeAuthGateway(currentSession: testSession);
      var calculations = 0;
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(
            request.headers['authorization'],
            'Bearer ${testSession.accessToken}',
          );
          if (request.url.path == '/api/v1/grades' && request.method == 'GET') {
            return http.Response('[]', 200);
          }
          if (request.url.path == '/api/v1/grades/summary' &&
              request.method == 'GET') {
            return http.Response(jsonEncode(_summary(0, 0)), 200);
          }
          expect(request.url.path, '/api/v1/grades/simulation');
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'expectedGrades': [
              {'category': 'MAJOR', 'credit': 3.0, 'gradeCode': 'A_PLUS'},
            ],
          });
          calculations++;
          return http.Response(
            jsonEncode({
              'current': _summary(0, 0),
              'projected': _summary(4.5, 3),
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        AhniApp(
          environment: AppEnvironment.development,
          controller: OnboardingController(
            auth: auth,
            api: FakeStudentApi()..getProfileHandler = (_) async => testProfile,
          ),
          gradeController: GradeListController(auth: auth, api: api),
          gradeSimulationController: GradeSimulationController(
            auth: auth,
            api: api,
          ),
          inquiryController: buildTestInquiryController(auth: auth),
          graduationController: buildTestGraduationController(),
          scholarshipController: buildTestScholarshipController(),
          courseController: buildTestCourseCatalogController(auth: auth),
          gradeRegistrationController: buildTestGradeRegistrationController(
            auth: auth,
            api: api,
          ),
          gradeEditController: buildTestGradeEditController(
            auth: auth,
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('성적'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('평점 시뮬레이션'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expected-credit-0')), '3');
      final grade = find.byKey(const Key('expected-code-0'));
      await tester.ensureVisible(grade);
      await tester.tap(grade);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A+').last);
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('calculate-gpa'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('4.50'), findsOneWidget);
      expect(calculations, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('grade-list-page')), findsOneWidget);
      expect(find.byKey(const Key('simulation-result')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, Object?> _summary(double gpa, double credits) => {
  'gpa': gpa,
  'completedCredits': credits,
  'gpaCredits': credits,
  'categories': [
    {
      'category': 'MAJOR',
      'gpa': gpa,
      'completedCredits': credits,
      'gpaCredits': credits,
    },
    {
      'category': 'GENERAL_EDUCATION',
      'gpa': 0,
      'completedCredits': 0,
      'gpaCredits': 0,
    },
    {'category': 'ELECTIVE', 'gpa': 0, 'completedCredits': 0, 'gpaCredits': 0},
  ],
};
