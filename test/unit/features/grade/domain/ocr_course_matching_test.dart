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
