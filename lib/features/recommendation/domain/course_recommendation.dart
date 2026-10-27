import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';

class CourseRecommendation {
  const CourseRecommendation({
    required this.academicYear,
    required this.term,
    required this.semesterNumber,
    required this.lectureDataAvailable,
    required this.majors,
  });

  factory CourseRecommendation.fromJson(Map<String, Object?> json) {
    final semesterNumber = json['semesterNumber']! as int;
    if (semesterNumber < 1) {
      throw const FormatException('Invalid semester number');
    }
    return CourseRecommendation(
      academicYear: json['academicYear']! as int,
      term: json['term']! as String,
      semesterNumber: semesterNumber,
      lectureDataAvailable: json['lectureDataAvailable']! as bool,
      majors: List.unmodifiable(
        (json['majors']! as List<Object?>).map(
          (item) => MajorRecommendation.fromJson(item! as Map<String, Object?>),
        ),
      ),
    );
  }

  final int academicYear;
  final String term;
  final int semesterNumber;
  final bool lectureDataAvailable;
  final List<MajorRecommendation> majors;

  /// 추천 학기가 몇 학년 몇 학기에 해당하는지 (성적이 있는 정규학기 기준).
  String get semesterLabel =>
      '${(semesterNumber + 1) ~/ 2}학년 ${semesterNumber.isOdd ? 1 : 2}학기';
}

class MajorRecommendation {
  const MajorRecommendation({
    required this.majorType,
    required this.departmentName,
    required this.curriculumAvailable,
    required this.courses,
  });

  factory MajorRecommendation.fromJson(Map<String, Object?> json) {
    final majorType = json['majorType']! as String;
    if (!{'PRIMARY', 'DOUBLE_MAJOR', 'MINOR'}.contains(majorType)) {
      throw const FormatException('Unknown major type');
    }
    final department = json['department']! as Map<String, Object?>;
    return MajorRecommendation(
      majorType: majorType,
      departmentName: department['name']! as String,
      curriculumAvailable: json['curriculumAvailable']! as bool,
      courses: List.unmodifiable(
        (json['courses']! as List<Object?>).map(
          (item) => RecommendedCourse.fromJson(item! as Map<String, Object?>),
        ),
      ),
    );
  }

  final String majorType;
  final String departmentName;
  final bool curriculumAvailable;
  final List<RecommendedCourse> courses;

  String get majorLabel => switch (majorType) {
    'PRIMARY' => '주전공',
    'DOUBLE_MAJOR' => '복수전공',
    _ => '부전공',
  };
}

class RecommendedCourse {
  const RecommendedCourse({
    required this.courseEntityId,
    required this.code,
    required this.name,
    required this.credit,
    required this.division,
    required this.recommendedYear,
    required this.recommendedTerm,
    required this.reasons,
    required this.previousGrade,
    required this.lectures,
  });

  factory RecommendedCourse.fromJson(Map<String, Object?> json) {
    final course = json['course']! as Map<String, Object?>;
    final reasons = (json['reasons']! as List<Object?>).cast<String>();
    if (reasons.isEmpty ||
        reasons.any((reason) => !_reasons.contains(reason))) {
      throw const FormatException('Unknown recommendation reason');
    }
    final previousGrade = json['previousGradeCode'] as String?;
    return RecommendedCourse(
      courseEntityId: course['entityId']! as String,
      code: course['code']! as String,
      name: course['name']! as String,
      credit: (course['credit']! as num).toDouble(),
      division: json['division']! as String,
      recommendedYear: json['recommendedYear'] as int?,
      recommendedTerm: json['recommendedTerm'] as String?,
      reasons: List.unmodifiable(reasons),
      previousGrade: previousGrade == null
          ? null
          : GradeCode.fromApiName(previousGrade),
      lectures: List.unmodifiable(
        (json['lectures']! as List<Object?>).map(
          (item) => Lecture.fromJson(item! as Map<String, Object?>),
        ),
      ),
    );
  }

  static const _reasons = {
    'GRADUATION_REQUIRED',
    'OVERDUE',
    'RECOMMENDED_NOW',
    'RETAKE',
  };

  final String courseEntityId;
  final String code;
  final String name;
  final double credit;
  final String division;
  final int? recommendedYear;
  final String? recommendedTerm;
  final List<String> reasons;
  final GradeCode? previousGrade;
  final List<Lecture> lectures;

  List<String> get reasonLabels => [
    for (final reason in reasons)
      switch (reason) {
        'GRADUATION_REQUIRED' => '졸업 필수',
        'OVERDUE' => '권장 학기 지남',
        'RECOMMENDED_NOW' => '이번 학기 권장',
        _ => '재수강 추천 (${previousGrade?.label ?? '-'})',
      },
  ];

  String get divisionLabel => switch (division) {
    'MAJOR_REQUIRED' => '전공 필수',
    'MAJOR_ELECTIVE' => '전공 선택',
    'MAJOR_FOUNDATION' => '전공 기초',
    'GENERAL_REQUIRED' => '교양 필수',
    'GENERAL_ELECTIVE' => '교양 선택',
    _ => '일반 선택',
  };

  String? get recommendedTermLabel {
    final year = recommendedYear;
    if (year == null) return null;
    return switch (recommendedTerm) {
      'FIRST' => '$year학년 1학기 권장',
      'SECOND' => '$year학년 2학기 권장',
      _ => '$year학년 권장',
    };
  }
}
