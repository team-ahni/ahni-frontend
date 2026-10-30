import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';
import 'package:flutter_test/flutter_test.dart';

OcrTextLine word(String text, double x, double y, {double width = 40}) =>
    OcrTextLine(text: text, left: x, top: y, right: x + width, bottom: y + 10);

void main() {
  List<OcrTextLine> tableHeader() => [
    word('2024학년도', 50, 70, width: 70),
    word('1학기', 130, 70),
    word('학수번호', 50, 100, width: 60),
    word('학점', 260, 100, width: 30),
    word('평점', 305, 100, width: 25),
  ];

  test('reads credit and grade columns, ignoring numbers in course names', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        ...tableHeader(),
        word('ABC1001', 50, 130, width: 60),
        word('4.0', 170, 130, width: 25),
        word('3.0', 265, 130, width: 25),
        word('A+', 312, 130, width: 15),
        word('P', 400, 130, width: 10),
      ],
    );
    expect(result.single.credit, 3);
    expect(result.single.gradeCode, GradeCode.aPlus);
  });

  test(
    'retains the OCR course name without including credit or grade columns',
    () {
      final result = extractOcrGradeCandidates(
        page: 1,
        width: 1000,
        fragments: [
          ...tableHeader(),
          word('ABC1001', 50, 130, width: 60),
          word('컴퓨터공학기초', 120, 130, width: 70),
          word('1', 195, 130, width: 8),
          word('3.0', 265, 130, width: 25),
          word('A+', 312, 130, width: 15),
          word('전필', 370, 130, width: 30),
        ],
      );
      expect(result.single.courseName, '컴퓨터공학기초 1');
      expect(result.single.courseCode, 'ABC1001');
      expect(result.single.credit, 3);
      expect(result.single.gradeCode, GradeCode.aPlus);
    },
  );

  test('does not invent a name when it was not recognized', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        ...tableHeader(),
        word('ABC1001', 50, 130, width: 60),
        word('3.0', 265, 130, width: 25),
      ],
    );
    expect(result.single.courseName, isNull);
  });

  test('does not borrow the next course grade when a cell is empty', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        ...tableHeader(),
        word('ABC1001', 50, 130, width: 60),
        word('3.0', 265, 133, width: 25),
        word('DEF1002', 50, 144, width: 60),
        word('2.0', 265, 147, width: 25),
        word('B0', 312, 147, width: 15),
      ],
    );
    expect(result.first.gradeCode, isNull);
    expect(result.first.credit, 3);
    expect(result.last.gradeCode, GradeCode.bZero);
    expect(result.last.credit, 2);
  });

  test('uses a clear field reread but leaves conflicting grades empty', () {
    List<OcrTextLine> primary(String grade) => [
      ...tableHeader(),
      word('ABC1001', 50, 130, width: 60),
      word('3.0', 265, 130, width: 25),
      word(grade, 312, 130, width: 15),
    ];
    final fields = [word('A+', 312, 130, width: 15)];
    final improved = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: primary('At'),
      fieldFragments: fields,
    );
    expect(improved.single.gradeCode, GradeCode.aPlus);
    final conflict = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: primary('B0'),
      fieldFragments: fields,
    );
    expect(conflict.single.gradeCode, isNull);
  });

  test('preserves a confused or split code for DB verification', () {
    final result = extractOcrGradeCandidates(
      page: 1,
      width: 1000,
      fragments: [
        ...tableHeader(),
        word('1TC3410', 50, 130, width: 60),
        word('ITC', 50, 150, width: 20),
        word('1201', 72, 150, width: 30),
      ],
    );
    expect(result.map((r) => r.courseCode), ['1TC3410', 'ITC1201']);
  });

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
