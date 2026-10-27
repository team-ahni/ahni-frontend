import 'package:ahni_mobile/features/recommendation/data/course_recommendation_api.dart';
import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';
import 'package:ahni_mobile/features/recommendation/presentation/course_recommendation_page.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/presentation/timetable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/recommendation_fakes.dart';
import '../support/timetable_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

void main() {
  Widget page(FakeCourseRecommendationApi api) => MaterialApp(
    home: CourseRecommendationPage(
      controller: buildTestRecommendationController(api),
      academicYear: 2026,
      term: 'SECOND',
      onAuthenticationRequired: () {},
    ),
  );

  testWidgets('shows recommended courses by major with reasons and sections', (
    tester,
  ) async {
    final api = FakeCourseRecommendationApi();
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();

    expect(api.requests, [(2026, 'SECOND')]);
    expect(find.text('2026년 2학기 수강 추천'), findsOneWidget);
    expect(findWhitespaceWrappedText('성적 기준 3학년 2학기로 계산했어요.'), findsOneWidget);
    expect(findWhitespaceWrappedText('주전공 · 소프트웨어융합공학과'), findsOneWidget);
    expect(findWhitespaceWrappedText('컴퓨터네트워크'), findsOneWidget);
    expect(find.text('졸업 필수'), findsOneWidget);
    expect(find.text('권장 학기 지남'), findsOneWidget);
    expect(
      findWhitespaceWrappedText('001분반 · 김교수 · 화 09:00–10:30'),
      findsOneWidget,
    );
    expect(find.text('재수강 추천 (C+)'), findsOneWidget);
    await tester.scrollUntilVisible(
      findWhitespaceWrappedText('이 학기 교과과정이 아직 공개되지 않아 추천할 수 없어요.'),
      150,
    );
    expect(find.byKey(const Key('recommendation-no-lectures')), findsNothing);
  });

  testWidgets('explains when the semester has no lecture data', (tester) async {
    final api = FakeCourseRecommendationApi()
      ..result = CourseRecommendation.fromJson(
        recommendationJson(lectureDataAvailable: false, majors: []),
      );
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommendation-no-lectures')), findsOneWidget);
    expect(find.byKey(const Key('recommendation-no-major')), findsOneWidget);
  });

  testWidgets('retries a recoverable failure', (tester) async {
    var calls = 0;
    final api = FakeCourseRecommendationApi();
    api.handler = () async {
      calls++;
      if (calls == 1) {
        throw const CourseRecommendationApiFailure(
          CourseRecommendationFailureKind.recoverable,
          '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.',
        );
      }
      return api.result;
    };
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();

    expect(
      findWhitespaceWrappedText('수강 추천을 불러오지 못했어요. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(findWhitespaceWrappedText('컴퓨터네트워크'), findsOneWidget);
  });

  testWidgets('opens recommendations for the selected timetable semester', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final timetable = TimetableController(auth: auth, api: FakeTimetableApi())
      ..year = 2026
      ..term = 'SECOND';
    final api = FakeCourseRecommendationApi();
    await tester.pumpWidget(
      MaterialApp(
        home: TimetablePage(
          controller: timetable,
          recommendationController: buildTestRecommendationController(api),
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-course-recommendation')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-recommendation-page')), findsOneWidget);
    expect(api.requests, [(2026, 'SECOND')]);
  });

  testWidgets('disables recommendations for seasonal terms', (tester) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final timetable = TimetableController(auth: auth, api: FakeTimetableApi())
      ..term = 'SUMMER';
    await tester.pumpWidget(
      MaterialApp(
        home: TimetablePage(
          controller: timetable,
          recommendationController: buildTestRecommendationController(),
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.byKey(const Key('open-course-recommendation')),
    );
    expect(button.onPressed, isNull);
  });
}
