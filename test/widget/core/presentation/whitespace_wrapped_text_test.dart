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
    // 띄어쓰기는 단어 끝이 아니라 단어 사이 간격으로 둔다. 실제 기기 글꼴은 단어 끝 공백 폭을
    // 0으로 재서 단어가 붙고 가운데 정렬이 어긋났다.
    expect(words, ['학사', '준비,', '함께', '이어가요']);
    expect(tester.widget<Wrap>(find.byType(Wrap)).spacing, greaterThan(0));
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

  Map<double, Rect> lines(WidgetTester tester) {
    final rows = <double, Rect>{};
    for (final element
        in find
            .descendant(
              of: find.byType(WhitespaceWrappedText),
              matching: find.byType(Text),
            )
            .evaluate()) {
      final box = element.renderObject! as RenderBox;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      rows.update(
        rect.top,
        (row) => row.expandToInclude(rect),
        ifAbsent: () => rect,
      );
    }
    return rows;
  }

  testWidgets('centers every line exactly and balances line lengths', (
    tester,
  ) async {
    const width = 300.0;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: WhitespaceWrappedText(
                '성적을 등록하면 평점과 남은 졸업 학점 필수과목을 바로 보여 줘요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );

    final rows = lines(tester).values.toList();
    expect(rows, hasLength(2));
    final center = tester.getCenter(find.byType(SizedBox).last).dx;
    for (final row in rows) {
      expect(row.center.dx, moreOrLessEquals(center, epsilon: 0.5));
    }
    // 첫 줄만 길고 둘째 줄이 짧게 남지 않도록 두 줄 길이를 고르게 나눈다.
    expect(
      (rows.first.width - rows.last.width).abs(),
      lessThan(rows.first.width * 0.35),
    );
  });
}
