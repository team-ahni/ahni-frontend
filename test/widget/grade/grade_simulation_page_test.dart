import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_simulation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';
import '../../support/whitespace_wrapped_text_finder.dart';

void main() {
  testWidgets(
    'compares backend GPA and removes stale results after input changes',
    (tester) async {
      final api = FakeGradeApi()
        ..simulationHandler = (_, rows) async {
          expect(rows.single.credit, 3);
          return _comparison;
        };
      await tester.pumpWidget(_app(api));
      await _fill(tester);
      await _calculate(tester);
      expect(find.text('3.00'), findsOneWidget);
      expect(find.text('3.75'), findsOneWidget);
      expect(findWhitespaceWrappedText('실제 성적은 바뀌지 않아요.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('expected-credit-0')));
      await tester.enterText(find.byKey(const Key('expected-credit-0')), '2');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('simulation-result')), findsNothing);
    },
  );

  testWidgets('shows no current GPA instead of 0.00 without graded credits', (
    tester,
  ) async {
    final api = FakeGradeApi()
      ..simulationHandler = (_, _) async => const GradeSimulation(
        current: GradeSummary(
          gpa: 0,
          completedCredits: 0,
          gpaCredits: 0,
          categories: [],
        ),
        projected: GradeSummary(
          gpa: 4.5,
          completedCredits: 3,
          gpaCredits: 3,
          categories: [],
        ),
      );
    await tester.pumpWidget(_app(api));
    await _fill(tester);
    await _calculate(tester);
    await tester.ensureVisible(find.byKey(const Key('simulation-result')));
    await tester.pumpAndSettle();

    expect(find.text('0.00'), findsNothing);
    expect(find.text('-'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('반영된 성적 없음')), findsOneWidget);
    expect(find.text('4.50'), findsOneWidget);
    expect(find.byKey(const Key('simulation-no-current-gpa')), findsOneWidget);
  });

  testWidgets(
    'adds and removes expected courses without touching saved grades',
    (tester) async {
      final api = FakeGradeApi()
        ..simulationHandler = (_, rows) async {
          expect(rows, hasLength(1));
          expect(rows.single.credit, 3);
          return _comparison;
        };
      await tester.pumpWidget(_app(api));
      await _fill(tester);
      await tester.ensureVisible(find.byKey(const Key('add-expected-grade')));
      await tester.tap(find.byKey(const Key('add-expected-grade')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expected-credit-1')), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('예상 과목 2 제거'));
      await tester.tap(find.byTooltip('예상 과목 2 제거'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expected-credit-1')), findsNothing);
      await _calculate(tester);
      expect(find.text('3.75'), findsOneWidget);
      expect(api.registerCalls + api.updateCalls + api.deleteCalls, 0);
    },
  );

  testWidgets('validation explains invalid credits before sending a request', (
    tester,
  ) async {
    var requests = 0;
    final api = FakeGradeApi()
      ..simulationHandler = (_, _) async {
        requests++;
        return _comparison;
      };
    await tester.pumpWidget(_app(api));
    await _fill(tester, credit: '1.25');
    await _calculate(tester);
    expect(requests, 0);
    expect(
      findWhitespaceWrappedText('학점은 0 초과 30 이하, 소수점 한 자리까지 입력해 주세요.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'retry keeps the expected grades and clears the error after success',
    (tester) async {
      final api = FakeGradeApi()
        ..error = const GradeApiFailure(
          GradeApiFailureKind.recoverable,
          '다시 시도해 주세요.',
        );
      await tester.pumpWidget(_app(api));
      await _fill(tester);
      await _calculate(tester);
      expect(findWhitespaceWrappedText('다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      api
        ..error = null
        ..simulationHandler = (_, _) async => _comparison;
      await _calculate(tester);
      expect(find.text('3.75'), findsOneWidget);
      expect(findWhitespaceWrappedText('다시 시도해 주세요.'), findsNothing);
    },
  );

  testWidgets(
    'expired session offers return to sign-in without showing a result',
    (tester) async {
      var signIns = 0;
      final api = FakeGradeApi()
        ..error = const GradeApiFailure(
          GradeApiFailureKind.unauthorized,
          '다시 로그인해 주세요.',
        );
      await tester.pumpWidget(_app(api, onAuth: () => signIns++));
      await _fill(tester);
      await _calculate(tester);
      final button = find.text('로그인으로 돌아가기');
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(signIns, 1);
      expect(find.byKey(const Key('simulation-result')), findsNothing);
    },
  );

  testWidgets('compact screen and large text remain usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeGradeApi()..simulationHandler = (_, _) async => _comparison;
    await tester.pumpWidget(_app(api, scale: 2));
    await _fill(tester);
    await _calculate(tester);
    await tester.ensureVisible(find.byKey(const Key('simulation-result')));
    await tester.pumpAndSettle();
    expect(find.text('3.75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _comparison = GradeSimulation(
  current: GradeSummary(
    gpa: 3,
    completedCredits: 3,
    gpaCredits: 3,
    categories: [],
  ),
  projected: GradeSummary(
    gpa: 3.75,
    completedCredits: 6,
    gpaCredits: 6,
    categories: [],
  ),
);

Widget _app(FakeGradeApi api, {VoidCallback? onAuth, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1558A6)),
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: GradeSimulationPage(
          controller: GradeSimulationController(
            auth: FakeAuthGateway(currentSession: testSession),
            api: api,
          ),
          onAuthenticationRequired: onAuth ?? () {},
        ),
      ),
    );

Future<void> _fill(WidgetTester tester, {String credit = '3'}) async {
  final field = find.byKey(const Key('expected-credit-0'));
  await tester.ensureVisible(field);
  await tester.enterText(field, credit);
  final grade = find.byKey(const Key('expected-code-0'));
  await tester.ensureVisible(grade);
  await tester.tap(grade);
  await tester.pumpAndSettle();
  await tester.tap(find.text('A+').last);
  await tester.pumpAndSettle();
}

Future<void> _calculate(WidgetTester tester) async {
  final button = find.byKey(const Key('calculate-gpa'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
