import 'package:ahni_mobile/features/grade/domain/grade_record.dart';

class CourseCatalogItem {
  const CourseCatalogItem({
    required this.entityId,
    required this.code,
    required this.name,
    required this.credit,
    required this.category,
    this.department,
    this.professorNames = const [],
  });

  factory CourseCatalogItem.fromJson(Map<String, Object?> json) {
    final course = GradeCourse.fromJson(json);
    return CourseCatalogItem(
      entityId: course.entityId,
      code: course.code,
      name: course.name,
      credit: (json['credit']! as num).toDouble(),
      category: course.category,
      department: course.department,
      professorNames: List.unmodifiable(
        (json['professorNames'] as List<Object?>? ?? const []).map(
          (name) => name! as String,
        ),
      ),
    );
  }

  final String entityId;
  final String code;
  final String name;
  final double credit;
  final CourseCategory category;
  final GradeDepartment? department;
  final List<String> professorNames;
}
