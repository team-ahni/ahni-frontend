import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';

/// OCR suggestions must always be reviewed before they can be registered.
class OcrGradeCandidate {
  const OcrGradeCandidate({
    required this.page,
    required this.source,
    required this.courseCode,
    this.academicYear,
    this.term,
    this.credit,
    this.gradeCode,
  });

  final int page;
  final String source;
  final String courseCode;
  final int? academicYear;
  final AcademicTerm? term;
  final double? credit;
  final GradeCode? gradeCode;
}

/// Groups OCR words by location without mixing the left and right columns.
/// Only a clearly recognized course code makes a row a candidate. Other
/// fields are suggestions; the original page text remains available for review.
List<OcrGradeCandidate> extractOcrGradeCandidates({
  required int page,
  required double width,
  required Iterable<OcrTextLine> fragments,
}) {
  if (!width.isFinite || width <= 0) return const [];
  final columns = <List<OcrTextLine>>[[], []];
  for (final fragment in fragments) {
    if (fragment.text.trim().isEmpty ||
        !fragment.left.isFinite ||
        !fragment.top.isFinite ||
        !fragment.right.isFinite ||
        !fragment.bottom.isFinite ||
        fragment.bottom <= fragment.top ||
        fragment.right <= fragment.left) {
      continue;
    }
    // Ignore a fragment crossing the column boundary rather than merging
    // unrelated historical and in-progress courses.
    if (fragment.left < width / 2 && fragment.right > width / 2) continue;
    columns[fragment.left >= width / 2 ? 1 : 0].add(fragment);
  }

  final candidates = <OcrGradeCandidate>[];
  final codePattern = RegExp(r'^[A-Z]{2,5}\d{3,5}$');
  final yearPattern = RegExp(r'(20\d{2})학년도');
  for (final column in columns) {
    column.sort((a, b) => a.top.compareTo(b.top));
    final rows = <List<OcrTextLine>>[];
    for (final part in column) {
      if (rows.isEmpty) {
        rows.add([part]);
        continue;
      }
      final row = rows.last;
      final center = (row.first.top + row.first.bottom) / 2;
      final partCenter = (part.top + part.bottom) / 2;
      final allowed = (row.first.bottom - row.first.top) * 0.55;
      if ((partCenter - center).abs() <= allowed) {
        row.add(part);
      } else {
        rows.add([part]);
      }
    }
    int? academicYear;
    AcademicTerm? term;
    for (final row in rows) {
      row.sort((a, b) => a.left.compareTo(b.left));
      final source = row.map((part) => part.text.trim()).join(' ');
      final compact = source.replaceAll(RegExp(r'\s+'), '');
      final yearMatch = yearPattern.firstMatch(compact);
      if (yearMatch != null) {
        academicYear = int.tryParse(yearMatch.group(1)!);
        term = _parseTerm(compact);
        continue;
      }
      // An in-progress course table must not inherit a prior semester.
      if (compact.contains('금학기수강')) {
        academicYear = null;
        term = null;
        continue;
      }
      final codes = row
          .map((part) => part.text.trim().toUpperCase())
          .where((value) => codePattern.hasMatch(value))
          .toList();
      if (codes.length != 1 || academicYear == null || term == null) continue;
      final gradeValues = row
          .map((part) => _parseGrade(part.text.trim()))
          .whereType<GradeCode>()
          .toSet();
      final creditValues = row
          .map((part) => part.text.trim())
          .where((value) => RegExp(r'^\d{1,2}\.\d$').hasMatch(value))
          .map(double.parse)
          .where((value) => value > 0 && value <= 30)
          .toSet();
      candidates.add(
        OcrGradeCandidate(
          page: page,
          source: source,
          courseCode: codes.single,
          academicYear: academicYear,
          term: term,
          credit: creditValues.length == 1 ? creditValues.single : null,
          gradeCode: gradeValues.length == 1 ? gradeValues.single : null,
        ),
      );
    }
  }
  return List.unmodifiable(candidates);
}

AcademicTerm? _parseTerm(String value) {
  if (value.contains('여름학기') || value.contains('하계학기')) {
    return AcademicTerm.summer;
  }
  if (value.contains('겨울학기') || value.contains('동계학기')) {
    return AcademicTerm.winter;
  }
  if (value.contains('1학기')) return AcademicTerm.first;
  if (value.contains('2학기')) return AcademicTerm.second;
  return null;
}

GradeCode? _parseGrade(String value) {
  final normalized = value.toUpperCase();
  for (final grade in GradeCode.values) {
    if (grade.label == normalized) return grade;
  }
  return null;
}
