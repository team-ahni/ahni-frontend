import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps words intact while preserving the readable label', (
    tester,
  ) async {
    const source = '학사 준비, 함께 이어가요';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WhitespaceWrappedText(source))),
    );

    final words = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(WhitespaceWrappedText),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();
    expect(words, ['학사 ', '준비, ', '함께 ', '이어가요']);
    expect(find.bySemanticsLabel(source), findsOneWidget);
  });

  testWidgets(
    'never paints a word past the available width, even with tight letter spacing',
    (tester) async {
      const source = '등록한 성적과 공개된 교과과정으로 들으면 좋은 과목을 골라 봤어요. 학교 안내를 함께 확인해 주세요.';
      const width = 230.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: WhitespaceWrappedText(
                  source,
                  style: TextStyle(fontSize: 16, letterSpacing: -0.6),
                ),
              ),
            ),
          ),
        ),
      );

      final texts = find.descendant(
        of: find.byType(WhitespaceWrappedText),
        matching: find.byType(Text),
      );
      expect(texts, findsWidgets);
      for (final element in texts.evaluate()) {
        final box = element.renderObject! as RenderBox;
        final right = box.localToGlobal(Offset(box.size.width, 0)).dx;
        expect(right, lessThanOrEqualTo(width + 0.01));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps explicit line breaks and alignment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WhitespaceWrappedText(
            '첫 줄\n\n둘째 줄',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsNWidgets(2));
    expect(
      tester.widget<Wrap>(find.byType(Wrap).first).alignment,
      WrapAlignment.center,
    );
    expect(find.bySemanticsLabel('첫 줄\n\n둘째 줄'), findsOneWidget);
  });
}
