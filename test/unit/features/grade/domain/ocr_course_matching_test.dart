import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_course_matching.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

const course = CourseCatalogItem(
  entityId: 'course-1',
  code: 'CSE101',
  name: '프로그래밍 기초',
  credit: 3,
  category: CourseCategory.major,
);

void main() {
  test('suggests T/I only at the start of a standard course code', () {
    const target = CourseCatalogItem(
      entityId: 'ise',
      code: 'ISE1001',
      name: '공학 기초',
      credit: 3,
      category: CourseCategory.major,
    );
    const candidate = OcrGradeCandidate(
      page: 1,
      source: 'TSE1001',
      courseCode: 'TSE1001',
      courseName: '공학기초',
    );
    const middleError = OcrGradeCandidate(
      page: 1,
      source: 'ITE1001',
      courseCode: 'ITE1001',
    );
    expect(initialLetterOcrMatches(candidate, [target]), [target]);
    expect(initialLetterOcrMatches(middleError, [target]), isEmpty);
    expect(matchesOcrCourseName(candidate, target), isTrue);
    expect(matchesOcrCourseName(middleError, target), isFalse);
  });

  test(
    'matches multiple positional confusions and retains ambiguous options',
    () {
      const candidate = OcrGradeCandidate(
        page: 1,
        source: '10E6O0I',
        courseCode: '10E6O0I',
      );
      const corrected = [
        CourseCatalogItem(
          entityId: 'd',
          code: 'IDE6001',
          name: 'D',
          credit: 3,
          category: CourseCategory.major,
        ),
        CourseCatalogItem(
          entityId: 'o',
          code: 'IOE6001',
          name: 'O',
          credit: 3,
          category: CourseCategory.major,
        ),
      ];

      expect(
        positionalOcrMatches(candidate, [...corrected, course]),
        corrected,
      );
      expect(candidate.courseCode, '10E6O0I');
    },
  );

  test(
    'suggests a one-character code error even when the name is unreadable',
    () {
      const candidate = OcrGradeCandidate(
        page: 1,
        source: 'CSE102 인식 오류',
        courseCode: 'CSE102',
      );
      expect(suggestOcrCourses(candidate, [course]), [course]);
      expect(candidate.courseCode, 'CSE102');
    },
  );

  test('does not suggest a matching name with an unrelated code', () {
    const candidate = OcrGradeCandidate(
      page: 1,
      source: 'ABC999 프로그래밍 기초',
      courseCode: 'ABC999',
    );
    expect(suggestOcrCourses(candidate, [course]), isEmpty);
  });

  test('does not invent courses missing from the selected semester', () {
    const candidate = OcrGradeCandidate(
      page: 1,
      source: 'CSE102',
      courseCode: 'CSE102',
    );
    expect(suggestOcrCourses(candidate, const []), isEmpty);
  });
}
