import 'dart:math' as math;

import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';

/// A detected table's credit/grade columns, in rendered page coordinates.
class OcrTableLayout {
  const OcrTableLayout({
    required this.top,
    required this.bottom,
    required this.creditLeft,
    required this.divider,
    required this.gradeRight,
    required this.column,
  });
  final double top;
  final double bottom;
  final double creditLeft;
  final double divider;
  final double gradeRight;
  final int column;
  bool containsCredit(OcrTextLine part) =>
      _centerX(part) >= creditLeft && _centerX(part) < divider;
  bool containsGrade(OcrTextLine part) =>
      _centerX(part) >= divider && _centerX(part) <= gradeRight;
}

List<OcrTableLayout> locateOcrTables({
  required double width,
  required double height,
  required Iterable<OcrTextLine> fragments,
}) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return const [];
  }
  final parts = fragments
      .where(
        (p) =>
            p.left.isFinite &&
            p.right.isFinite &&
            p.top.isFinite &&
            p.bottom.isFinite &&
            p.right > p.left &&
            p.bottom > p.top,
      )
      .toList();
  String label(OcrTextLine p) => p.text.replaceAll(RegExp(r'\s+'), '');
  final result = <OcrTableLayout>[];
  for (var column = 0; column < 2; column++) {
    final left = column * width / 2;
    final right = left + width / 2;
    final local = parts
        .where((p) => _centerX(p) >= left && _centerX(p) < right)
        .toList();
    final anchors = local.where((p) => label(p) == '학수번호').toList()
      ..sort((a, b) => a.top.compareTo(b.top));
    for (final anchor in anchors) {
      bool sameHeader(OcrTextLine part) =>
          (_centerY(part) - _centerY(anchor)).abs() <=
          math.max(part.bottom - part.top, anchor.bottom - anchor.top) * 1.2;
      final credits = local
          .where(
            (p) =>
                label(p) == '학점' &&
                _centerX(p) > _centerX(anchor) &&
                sameHeader(p),
          )
          .toList();
      final grades = local
          .where((p) => label(p) == '평점' && sameHeader(p))
          .toList();
      if (credits.length != 1 || grades.length != 1) continue;
      final credit = credits.single, grade = grades.single;
      final distance = _centerX(grade) - _centerX(credit);
      if (distance <= 0 || distance > width * 0.1) continue;
      final top = math.min(anchor.top, math.min(credit.top, grade.top));
      final nextHeaders = anchors
          .where((p) => p.top > anchor.top + (anchor.bottom - anchor.top))
          .toList();
      final bottom = nextHeaders.isEmpty ? height : nextHeaders.first.top;
      result.add(
        OcrTableLayout(
          top: top,
          bottom: bottom,
          creditLeft: math.max(left, _centerX(credit) - distance * 0.65),
          divider: (_centerX(credit) + _centerX(grade)) / 2,
          gradeRight: math.min(right, _centerX(grade) + distance * 0.65),
          column: column,
        ),
      );
    }
  }
  return List.unmodifiable(result);
}

double _centerX(OcrTextLine p) => (p.left + p.right) / 2;
double _centerY(OcrTextLine p) => (p.top + p.bottom) / 2;
