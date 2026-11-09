import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paints every mood at small and large sizes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final mood in AhniMood.values)
                for (final size in [32.0, 104.0])
                  AhniMascot(mood: mood, size: size),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AhniMascot), findsNWidgets(AhniMood.values.length * 2));
    expect(tester.getSize(find.byType(AhniMascot).first), const Size(32, 32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state reads its text, not the decorative mascot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            mood: AhniMood.oops,
            title: '성적을 불러오지 못했어요',
            message: '잠시 후 다시 시도해 주세요.',
          ),
        ),
      ),
    );

    expect(find.byType(AhniMascot), findsOneWidget);
    expect(find.bySemanticsLabel('성적을 불러오지 못했어요'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AhniMascot)).label, isEmpty);
    semantics.dispose();
  });
}
