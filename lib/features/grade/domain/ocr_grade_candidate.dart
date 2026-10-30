import 'dart:math' as math;

import 'package:ahni_mobile/features/grade/domain/ocr_table_layout.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';

/// OCR suggestions must always be reviewed before they can be registered.
class OcrGradeCandidate {
  const OcrGradeCandidate({
    required this.page,
    required this.source,
    required this.courseCode,
    this.courseName,
    this.academicYear,
    this.term,
    this.credit,
    this.gradeCode,
  });

  final int page;
  final String source;
  final String courseCode;
  final String? courseName;
  final int? academicYear;
  final AcademicTerm? term;
  final double? credit;
  final GradeCode? gradeCode;
}

/// Anchors each historical row on its course code, then reads only the detected
/// credit/grade columns inside that row. Ambiguous values stay empty for review.
List<OcrGradeCandidate> extractOcrGradeCandidates({
  required int page,
  required double width,
  required Iterable<OcrTextLine> fragments,
  Iterable<OcrTextLine> fieldFragments = const [],
}) {
  if (!width.isFinite || width <= 0) return const [];
  final parts = fragments.where(_validPart).toList();
  final refined = fieldFragments.where(_validPart).toList();
  if (parts.isEmpty) return const [];
  final height = parts.map((p) => p.bottom).reduce(math.max) + 1;
  final tables = locateOcrTables(
    width: width,
    height: height,
    fragments: parts,
  );
  final candidates = <OcrGradeCandidate>[];
  for (var column = 0; column < 2; column++) {
    bool inColumn(OcrTextLine p) =>
        _x(p) >= column * width / 2 &&
        _x(p) < (column + 1) * width / 2 &&
        p.right - p.left < width * 0.5;
    final local = parts.where(inColumn).toList();
    final localFields = refined.where(inColumn).toList();
    final headings = _groupRows(local);
    final anchors = _codeAnchors(local)
      ..sort((a, b) => _y(a.bounds).compareTo(_y(b.bounds)));
    for (var index = 0; index < anchors.length; index++) {
      final anchor = anchors[index];
      final center = _y(anchor.bounds),
          rowHeight = anchor.bounds.bottom - anchor.bounds.top;
      int? year;
      AcademicTerm? term;
      double? yearHeadingCenter;
      double? yearHeadingHeight;
      for (final heading in headings) {
        if (_y(heading.first) >= center) break;
        final value = heading
            .map((p) => p.text)
            .join()
            .replaceAll(RegExp(r'\s+'), '');
        final yearMatch = RegExp(r'(20\d{2})학년도').firstMatch(value);
        if (yearMatch != null) {
          year = int.tryParse(yearMatch.group(1)!);
          term = _parseTerm(value);
          yearHeadingCenter = _y(heading.first);
          yearHeadingHeight = heading.first.bottom - heading.first.top;
        } else if (year != null &&
            term == null &&
            yearHeadingCenter != null &&
            _y(heading.first) - yearHeadingCenter <= yearHeadingHeight! * 2) {
          term = _parseTerm(value);
        }
        if (value.contains('금학기') && value.contains('수강')) {
          year = null;
          term = null;
        }
      }
      if (year == null || term == null) continue;
      final previous = index > 0
          ? _y(anchors[index - 1].bounds)
          : double.negativeInfinity;
      final next = index + 1 < anchors.length
          ? _y(anchors[index + 1].bounds)
          : double.infinity;
      // Two codes on the same baseline are ambiguous; don't reuse one grade.
      if (center - previous < rowHeight * 0.6 ||
          next - center < rowHeight * 0.6) {
        continue;
      }
      final top = math.max(center - rowHeight, (previous + center) / 2);
      final bottom = math.min(center + rowHeight, (next + center) / 2);
      bool inRow(OcrTextLine p) => _y(p) >= top && _y(p) < bottom;
      final row = local.where(inRow).toList()
        ..sort((a, b) => a.left.compareTo(b.left));
      final fieldRow = localFields.where(inRow).toList();
      final layouts = tables
          .where(
            (t) => t.column == column && t.top < center && t.bottom > center,
          )
          .toList();
      final layout = layouts.isEmpty ? null : layouts.last;
      Iterable<OcrTextLine> cell(List<OcrTextLine> values, bool grade) =>
          layout == null
          ? values.where((p) => p.left >= anchor.bounds.right)
          : values.where(grade ? layout.containsGrade : layout.containsCredit);
      final primaryGrade = _readGrade(cell(row, true));
      final refinedGrade = layout == null
          ? null
          : _readGrade(cell(fieldRow, true));
      final primaryCredit = _readCredit(cell(row, false));
      final refinedCredit = layout == null
          ? null
          : _readCredit(cell(fieldRow, false));
      final grade =
          primaryGrade != null &&
              refinedGrade != null &&
              primaryGrade != refinedGrade
          ? null
          : refinedGrade ?? primaryGrade;
      final credit =
          primaryCredit != null &&
              refinedCredit != null &&
              primaryCredit != refinedCredit
          ? null
          : refinedCredit ?? primaryCredit;
      candidates.add(
        OcrGradeCandidate(
          page: page,
          source: row.map((p) => p.text.trim()).join(' '),
          courseCode: anchor.code,
          courseName: _readCourseName(row, anchor, layout),
          academicYear: year,
          term: term,
          credit: credit,
          gradeCode: grade,
        ),
      );
    }
  }
  return List.unmodifiable(candidates);
}

String? _readCourseName(
  List<OcrTextLine> row,
  _CodeAnchor anchor,
  OcrTableLayout? layout,
) {
  final afterCode = row.where((p) => p.left >= anchor.bounds.right).toList();
  final double end;
  if (layout != null) {
    end = layout.creditLeft;
  } else {
    final cells = afterCode.where(
      (p) =>
          RegExp(r'^\d{1,2}\.\d$').hasMatch(p.text.trim()) ||
          _parseGrade(p.text.trim()) != null,
    );
    end = cells.isEmpty ? double.infinity : cells.first.left;
  }
  final name = afterCode
      .where((p) => _x(p) < end)
      .map((p) => p.text.trim())
      .join(' ')
      .trim();
  return name.isEmpty ? null : name;
}

bool _validPart(OcrTextLine p) =>
    p.text.trim().isNotEmpty &&
    p.left.isFinite &&
    p.right.isFinite &&
    p.top.isFinite &&
    p.bottom.isFinite &&
    p.right > p.left &&
    p.bottom > p.top;
double _x(OcrTextLine p) => (p.left + p.right) / 2;
double _y(OcrTextLine p) => (p.top + p.bottom) / 2;

List<List<OcrTextLine>> _groupRows(List<OcrTextLine> parts) {
  final sorted = parts.toList()..sort((a, b) => _y(a).compareTo(_y(b)));
  final rows = <List<OcrTextLine>>[];
  for (final part in sorted) {
    if (rows.isNotEmpty &&
        (_y(rows.last.first) - _y(part)).abs() <=
            math.min(
                  rows.last.first.bottom - rows.last.first.top,
                  part.bottom - part.top,
                ) *
                0.6) {
      rows.last.add(part);
    } else {
      rows.add([part]);
    }
  }
  for (final row in rows) {
    row.sort((a, b) => a.left.compareTo(b.left));
  }
  return rows;
}

class _CodeAnchor {
  const _CodeAnchor(this.code, this.bounds);
  final String code;
  final OcrTextLine bounds;
}

List<_CodeAnchor> _codeAnchors(List<OcrTextLine> parts) {
  // Preserve likely I/1 and O/0 errors for DB suggestions; never silently
  // replace a recognized course code with a different course.
  final pattern = RegExp(r'^[A-Z01]{2,5}[0-9O]{3,5}$');
  bool isCode(String s) =>
      pattern.hasMatch(s) &&
      RegExp(r'[A-Z]').hasMatch(s) &&
      RegExp(r'\d').allMatches(s).length >= 3;
  final result = <_CodeAnchor>[];
  final used = <OcrTextLine>{};
  for (final part in parts) {
    if (used.contains(part)) continue;
    final code = part.text.trim().toUpperCase();
    if (isCode(code)) {
      result.add(_CodeAnchor(code, part));
      continue;
    }
    if (!RegExp(r'^[A-Z01]{2,5}$').hasMatch(code)) continue;
    final suffix = parts
        .where(
          (p) =>
              p.left >= part.right &&
              p.left - part.right <= (part.bottom - part.top) * 1.2 &&
              (_y(p) - _y(part)).abs() < (part.bottom - part.top) * 0.6 &&
              RegExp(r'^[0-9O]{3,5}$').hasMatch(p.text.trim()),
        )
        .toList();
    if (suffix.length != 1) continue;
    final other = suffix.single;
    final combined = code + other.text.trim();
    if (!isCode(combined)) continue;
    used.add(other);
    result.add(
      _CodeAnchor(
        combined,
        OcrTextLine(
          text: combined,
          left: part.left,
          top: math.min(part.top, other.top),
          right: other.right,
          bottom: math.max(part.bottom, other.bottom),
        ),
      ),
    );
  }
  return result;
}

List<String> _cellValues(Iterable<OcrTextLine> parts) {
  final row = parts.toList()..sort((a, b) => a.left.compareTo(b.left));
  final values = row.map((p) => p.text.trim()).toList();
  if (row.length > 1 && row.length <= 3) {
    var adjacent = true;
    for (var i = 1; i < row.length; i++) {
      if (row[i].left - row[i - 1].right >
          math.max(
                row[i].bottom - row[i].top,
                row[i - 1].bottom - row[i - 1].top,
              ) *
              0.65) {
        adjacent = false;
      }
    }
    if (adjacent) values.add(values.join());
  }
  return values;
}

GradeCode? _readGrade(Iterable<OcrTextLine> parts) {
  final values = _cellValues(parts)
      .map(_parseGrade)
      .whereType<GradeCode>()
      .toSet();
  return values.length == 1 ? values.single : null;
}

double? _readCredit(Iterable<OcrTextLine> parts) {
  final values = _cellValues(parts)
      .where((v) => RegExp(r'^\d{1,2}\.\d$').hasMatch(v))
      .map(double.parse)
      .where((v) => v > 0 && v <= 30)
      .toSet();
  return values.length == 1 ? values.single : null;
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
