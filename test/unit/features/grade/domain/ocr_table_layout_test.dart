import 'package:ahni_mobile/features/grade/domain/ocr_table_layout.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';
import 'package:flutter_test/flutter_test.dart';

OcrTextLine word(String text, double x, double y, {double width = 25}) =>
    OcrTextLine(text: text, left: x, top: y, right: x + width, bottom: y + 10);

void main() {
  test('isolates the credit and grade columns of each table', () {
    final layouts = locateOcrTables(
      width: 1000,
      height: 1000,
      fragments: [
        word('학수번호', 50, 100),
        word('학점', 260, 100),
        word('평점', 305, 100),
        word('학수번호', 550, 100),
        word('학점', 760, 100),
        word('평점', 805, 100),
      ],
    );
    expect(layouts, hasLength(2));
    expect(layouts.first.containsCredit(word('3.0', 265, 130)), isTrue);
    expect(layouts.first.containsGrade(word('A+', 310, 130)), isTrue);
    expect(layouts.first.containsCredit(word('4.0', 170, 130)), isFalse);
    expect(layouts.first.containsGrade(word('A+', 810, 130)), isFalse);
    expect(layouts.last.containsGrade(word('A+', 810, 130)), isTrue);
  });

  test('does not invent a field crop without the table headers', () {
    expect(
      locateOcrTables(
        width: 1000,
        height: 1000,
        fragments: [
          word('누적평점', 50, 100),
          word('4.0', 260, 100),
          word('평점', 305, 100),
        ],
      ),
      isEmpty,
    );
  });
}
