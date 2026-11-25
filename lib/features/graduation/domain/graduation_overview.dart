class CreditProgress {
  const CreditProgress({
    required this.required,
    required this.completed,
    required this.remaining,
    required this.met,
  });
  factory CreditProgress.fromJson(Map<String, Object?> json) => CreditProgress(
    required: _number(json['required']),
    completed: _number(json['completed']),
    remaining: _number(json['remaining']),
    met: json['met']! as bool,
  );
  final double required;
  final double completed;
  final double remaining;
  final bool met;
  static double _number(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      throw const FormatException('Invalid credit progress');
    }
    return value.toDouble();
  }
}

class GraduationOverview {
  const GraduationOverview({
    required this.entityId,
    required this.departmentName,
    required this.majorType,
    required this.admissionYear,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.total,
    required this.department,
    required this.general,
    required this.requiredCourses,
    required this.requirementsMet,
    this.foundation = const CreditProgress(
      required: 0,
      completed: 0,
      remaining: 0,
      met: true,
    ),
    this.evaluationComplete = true,
  });
  factory GraduationOverview.fromJson(
    Map<String, Object?> requirement,
    Map<String, Object?> progress,
  ) {
    final owner = requirement['department']! as Map<String, Object?>;
    final progressOwner = progress['department']! as Map<String, Object?>;
    if (requirement['entityId'] != progress['requirementEntityId'] ||
        owner['entityId'] != progressOwner['entityId'] ||
        requirement['admissionYear'] != progress['admissionYear'] ||
        requirement['majorType'] != progress['majorType']) {
      throw const FormatException('Mismatched graduation policy');
    }
    final type = requirement['majorType']! as String;
    if (!{'PRIMARY', 'DOUBLE_MAJOR', 'MINOR'}.contains(type)) {
      throw const FormatException('Unknown major type');
    }
    final credits = progress['credits']! as Map<String, Object?>;
    final assignments = requirement['requiredCourses']! as List<Object?>;
    final completions = progress['requiredCourses']! as List<Object?>;
    final byId = <String, Map<String, Object?>>{};
    for (final entry in completions) {
      final row = entry! as Map<String, Object?>;
      final id = row['entityId']! as String;
      if (byId.containsKey(id)) {
        throw const FormatException('Duplicate required course');
      }
      byId[id] = row;
    }
    if (assignments.length != completions.length) {
      throw const FormatException('Incomplete required courses');
    }
    final courses = assignments
        .map((entry) {
          final row = entry! as Map<String, Object?>;
          final matched = byId.remove(row['entityId']);
          if (matched == null || matched['category'] != row['category']) {
            throw const FormatException('Mismatched required course');
          }
          final course = row['course']! as Map<String, Object?>;
          final progressCourse = matched['course']! as Map<String, Object?>;
          if (course['entityId'] != progressCourse['entityId']) {
            throw const FormatException('Mismatched course identity');
          }
          return RequiredCourseCompletion.fromJson(matched);
        })
        .toList(growable: false);
    return GraduationOverview(
      entityId: requirement['entityId']! as String,
      departmentName: owner['name']! as String,
      majorType: type,
      admissionYear: requirement['admissionYear']! as int,
      sourceTitle: requirement['sourceTitle']! as String,
      sourceUrl: requirement['sourceUrl'] as String?,
      requiredCourses: List.unmodifiable(courses),
      requirementsMet:
          (progress['requirementsMet']! as bool) &&
          requirement['evaluationComplete'] != false &&
          progress['evaluationComplete'] != false,
      evaluationComplete:
          requirement['evaluationComplete'] != false &&
          progress['evaluationComplete'] != false,
      foundation: credits['foundation'] == null
          ? const CreditProgress(
              required: 0,
              completed: 0,
              remaining: 0,
              met: true,
            )
          : CreditProgress.fromJson(
              credits['foundation']! as Map<String, Object?>,
            ),
      total: CreditProgress.fromJson(credits['total']! as Map<String, Object?>),
      department: CreditProgress.fromJson(
        credits['department']! as Map<String, Object?>,
      ),
      general: CreditProgress.fromJson(
        credits['general']! as Map<String, Object?>,
      ),
    );
  }
  final String entityId;
  final String departmentName;
  final String majorType;
  final int admissionYear;
  final String sourceTitle;
  final String? sourceUrl;
  final CreditProgress total;
  final CreditProgress department;
  final CreditProgress general;
  final List<RequiredCourseCompletion> requiredCourses;
  final bool requirementsMet;
  final CreditProgress foundation;
  final bool evaluationComplete;
  bool get creditsMet =>
      total.met && department.met && foundation.met && general.met;
  String get majorLabel => switch (majorType) {
    'PRIMARY' => '주전공',
    'DOUBLE_MAJOR' => '복수전공',
    _ => '부전공',
  };
}

class RequiredCourseCompletion {
  const RequiredCourseCompletion({
    required this.entityId,
    required this.category,
    required this.courseName,
    required this.courseCode,
    required this.completed,
  });
  factory RequiredCourseCompletion.fromJson(Map<String, Object?> json) {
    final category = json['category']! as String;
    if (!{
      'MAJOR_FOUNDATION',
      'MAJOR_REQUIRED',
      'GENERAL_REQUIRED',
    }.contains(category)) {
      throw const FormatException('Unknown required course category');
    }
    final course = json['course']! as Map<String, Object?>;
    return RequiredCourseCompletion(
      entityId: json['entityId']! as String,
      category: category,
      courseName: course['name']! as String,
      courseCode: course['code']! as String,
      completed: json['completed']! as bool,
    );
  }
  final String entityId;
  final String category;
  final String courseName;
  final String courseCode;
  final bool completed;
  String get categoryLabel => switch (category) {
    'MAJOR_FOUNDATION' => '전공 기초',
    'MAJOR_REQUIRED' => '전공 필수',
    _ => '교양 필수',
  };
}
