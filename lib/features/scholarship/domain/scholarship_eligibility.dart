class ScholarshipEligibility {
  const ScholarshipEligibility({
    required this.admissionYear,
    required this.departmentName,
    required this.gpa,
    required this.completedCredits,
    required this.warningCount,
    required this.results,
  });

  factory ScholarshipEligibility.fromJson(Map<String, Object?> json) {
    final department = json['department']! as Map<String, Object?>;
    return ScholarshipEligibility(
      admissionYear: json['admissionYear']! as int,
      departmentName: department['name']! as String,
      gpa: _number(json['gpa']),
      completedCredits: _number(json['completedCredits']),
      warningCount: _count(json['warningCount']),
      results: List.unmodifiable(
        (json['scholarships']! as List<Object?>).map(
          (item) => ScholarshipResult.fromJson(item! as Map<String, Object?>),
        ),
      ),
    );
  }

  final int admissionYear;
  final String departmentName;
  final double gpa;
  final double completedCredits;
  final int warningCount;
  final List<ScholarshipResult> results;
}

class ScholarshipResult {
  const ScholarshipResult({
    required this.criteriaEntityId,
    required this.name,
    required this.minGpa,
    required this.minCredits,
    required this.maxWarnings,
    required this.gpaShortfall,
    required this.creditShortfall,
    required this.excessWarnings,
    required this.met,
  });

  factory ScholarshipResult.fromJson(Map<String, Object?> json) =>
      ScholarshipResult(
        criteriaEntityId: json['criteriaEntityId']! as String,
        name: json['name']! as String,
        minGpa: _number(json['minGpa']),
        minCredits: _number(json['minCredits']),
        maxWarnings: _count(json['maxWarnings']),
        gpaShortfall: _number(json['gpaShortfall']),
        creditShortfall: _number(json['creditShortfall']),
        excessWarnings: _count(json['excessWarnings']),
        met: json['met']! as bool,
      );

  final String criteriaEntityId;
  final String name;
  final double minGpa;
  final double minCredits;
  final int maxWarnings;
  final double gpaShortfall;
  final double creditShortfall;
  final int excessWarnings;
  final bool met;

  /// 미충족 항목마다 달성까지 필요한 조건을 한 줄씩 돌려준다.
  List<String> get shortfalls => [
    if (gpaShortfall > 0) '평점 +${gpaShortfall.toStringAsFixed(2)} 필요',
    if (creditShortfall > 0) '이수학점 ${_credit(creditShortfall)}학점 더 필요',
    if (excessWarnings > 0) '학사경고 허용 횟수를 $excessWarnings회 초과',
  ];
}

String _credit(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

double _number(Object? value) {
  if (value is! num || !value.isFinite || value < 0) {
    throw const FormatException('Invalid scholarship value');
  }
  return value.toDouble();
}

int _count(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Invalid scholarship count');
  }
  return value;
}
