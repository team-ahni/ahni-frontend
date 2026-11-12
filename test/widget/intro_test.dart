import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/intro/data/intro_store.dart';
import 'package:ahni_mobile/features/intro/presentation/intro_gate.dart';
import 'package:ahni_mobile/features/intro/presentation/intro_page.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';

class _MemoryIntroStore implements IntroStore {
  _MemoryIntroStore({this.seen = false});
  bool seen;
  int marks = 0;

  @override
  Future<bool> isSeen() async => seen;

  @override
  Future<void> markSeen() async {
    seen = true;
    marks++;
  }
}

Widget _gate(IntroStore store) => MaterialApp(
  home: IntroGate(store: store, child: const Text('로그인 흐름')),
);

Widget _app(AppEnvironment environment) {
  final api = FakeStudentApi()..getProfileHandler = (_) async => testProfile;
  return AhniApp(
    environment: environment,
    controller: OnboardingController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    ),
    gradeController: buildTestGradeListController(),
    graduationController: buildTestGraduationController(),
    scholarshipController: buildTestScholarshipController(),
    courseController: buildTestCourseCatalogController(),
    gradeRegistrationController: buildTestGradeRegistrationController(),
    gradeEditController: buildTestGradeEditController(),
    gradeSimulationController: buildTestGradeSimulationController(),
    inquiryController: buildTestInquiryController(),
  );
}

// 로그인하면 '내 정보' 탭에서 시작한다.
Future<void> _openProfile(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows the intro until it is finished', (
    tester,
  ) async {
    final store = _MemoryIntroStore();
    await tester.pumpWidget(_gate(store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('intro-page')), findsOneWidget);
    expect(find.text('로그인 흐름'), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('intro-next')));
      await tester.pumpAndSettle();
    }
    // 마지막 장은 '시작하기'로 끝나고 건너뛰기는 보이지 않는다.
    expect(find.text('시작하기'), findsOneWidget);
    expect(
      tester
          .widget<Visibility>(
            find.ancestor(
              of: find.byKey(const Key('intro-skip')),
              matching: find.byType(Visibility),
            ),
          )
          .visible,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('intro-next')));
    await tester.pumpAndSettle();

    expect(find.text('로그인 흐름'), findsOneWidget);
    expect(store.marks, 1);
  });

  testWidgets('skipping also records that the intro was seen', (tester) async {
    final store = _MemoryIntroStore();
    await tester.pumpWidget(_gate(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('intro-skip')));
    await tester.pumpAndSettle();

    expect(find.text('로그인 흐름'), findsOneWidget);
    expect(store.seen, isTrue);
  });

  testWidgets('a returning user goes straight to the app', (tester) async {
    await tester.pumpWidget(_gate(_MemoryIntroStore(seen: true)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('intro-page')), findsNothing);
    expect(find.text('로그인 흐름'), findsOneWidget);
  });

  testWidgets('development builds can replay the intro from the profile', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppEnvironment.development));
    await _openProfile(tester);

    final replay = find.byKey(const Key('replay-intro'));
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intro-page')), findsNothing);
    expect(find.byKey(const Key('developer-tools')), findsOneWidget);
  });

  testWidgets('staging and production hide the developer tools', (
    tester,
  ) async {
    for (final environment in [
      AppEnvironment.staging,
      AppEnvironment.production,
    ]) {
      await tester.pumpWidget(
        KeyedSubtree(key: UniqueKey(), child: _app(environment)),
      );
      await _openProfile(tester);
      expect(find.byKey(const Key('developer-tools')), findsNothing);
    }
  });

  testWidgets('every intro slide fits a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(home: IntroPage(onDone: () {})));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('intro-next')));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('intro meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(home: IntroPage(onDone: () {})));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
