import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:ahni_mobile/features/graduation/presentation/graduation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';

import '../support/graduation_fakes.dart';
import '../support/onboarding_fakes.dart';
import '../unit/graduation/graduation_test.dart' show policy, progress;

void main() {
  testWidgets(
    'completion and category filters show only matching required courses',
    (tester) async {
      final controller = GraduationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: FakeGraduationApi()
          ..results = [GraduationOverview.fromJson(policy(), progress())],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GraduationPage(
            controller: controller,
            onAuthenticationRequired: () {},
            bottomNavigationBar: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('미이수').hitTestable(), 150);
      await tester.tap(find.text('미이수'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '미이수'))
            .selected,
        isTrue,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is WhitespaceWrappedText && widget.data == '프로그래밍',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('이수'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is WhitespaceWrappedText && widget.data == '프로그래밍',
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is WhitespaceWrappedText &&
              widget.data.startsWith('선택한 조건'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('분류 전체'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('교양 필수').last);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is WhitespaceWrappedText && widget.data == '프로그래밍',
        ),
        findsNothing,
      );
    },
  );
  testWidgets('shows progress and sources at narrow width with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GraduationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: FakeGraduationApi()
        ..results = [GraduationOverview.fromJson(policy(), progress())],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: GraduationPage(
            controller: controller,
            onAuthenticationRequired: () {},
            bottomNavigationBar: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 / 30학점'), findsNWidgets(3));
    final source = find.byWidgetPredicate(
      (widget) =>
          widget is WhitespaceWrappedText && widget.data == '기준 출처: 학과 안내',
    );
    await tester.scrollUntilVisible(source, 150);
    expect(source, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing policies allow retry without hiding navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GraduationPage(
          controller: buildTestGraduationController(),
          onAuthenticationRequired: () {},
          bottomNavigationBar: const Text('탭 이동'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is WhitespaceWrappedText && widget.data.startsWith('아직 등록된'),
      ),
      findsOneWidget,
    );
    expect(find.text('탭 이동'), findsOneWidget);
    // 기준이 없는 건 실패가 아니라 빈 상태라 '다시 확인'으로 묻는다.
    await tester.tap(find.text('다시 확인'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
