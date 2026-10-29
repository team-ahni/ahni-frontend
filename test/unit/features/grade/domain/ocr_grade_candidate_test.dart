import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';
import 'package:flutter_test/flutter_test.dart';

OcrTextLine word(String text, double x, double y, {double width = 40}) =>
    OcrTextLine(text: text, left: x, top: y, right: x + width, bottom: y + 10);

void main() {
  test(
    'groups left-column semester rows without importing in-progress courses',
    () {
      final result = extractOcrGradeCandidates(
        page: 1,
        width: 1000,
        fragments: [
          word('2024학년도', 80, 100),
          word('1학기', 150, 100),
          word('ABC1001', 50, 130),
          word('자료구조', 110, 130),
          word('3.0', 260, 130),
          word('A+', 300, 130),
          word('금학기', 570, 115),
          word('수강', 630, 115),
          word('XYZ1001', 540, 130),
          word('현재강의', 610, 130),
          word('3.0', 770, 130),
          word('2025학년도', 80, 200),
          word('2학기', 150, 200),
          word('DEF2002', 50, 230),
          word('운영체제', 110, 230),
          word('3.0', 260, 230),
          word('B0', 300, 230),
        ],
      );
      expect(result.map((row) => row.courseCode), ['ABC1001', 'DEF2002']);
      expect(result.first.academicYear, 2024);
      expect(result.first.term, AcademicTerm.first);
      expect(result.first.credit, 3.0);
      expect(result.first.gradeCode, GradeCode.aPlus);
      expect(result.last.term, AcademicTerm.second);
      expect(result.last.gradeCode, GradeCode.bZero);
    },
  );

  test('leaves ambiguous grades and credits blank for review', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        word('2024학년도', 80, 100),
        word('1학기', 150, 100),
        word('ABC1001', 50, 130),
        word('2.0', 200, 130),
        word('3.0', 250, 130),
        word('A+', 300, 130),
        word('B0', 350, 130),
      ],
    );
    expect(result.single.credit, isNull);
    expect(result.single.gradeCode, isNull);
  });

  test('never assigns courses with no clear semester', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        word('ABC1001', 50, 130),
        word('3.0', 200, 130),
        word('A+', 300, 130),
      ],
    );
    expect(result, isEmpty);
  });
}
