import 'dart:math' as math;

import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';

/// A one-character OCR error may produce suggestions, never an automatic match.
List<CourseCatalogItem> suggestOcrCourses(
  OcrGradeCandidate candidate,
  List<CourseCatalogItem> courses,
) {
  String normalize(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final code = normalize(candidate.courseCode);
  if (code.length < 5) return const [];
  final matches = courses.where((course) {
    final courseCode = normalize(course.code);
    return code.length == courseCode.length && _distance(code, courseCode) == 1;
  }).toList()..sort((a, b) => a.code.compareTo(b.code));
  return List.unmodifiable(matches.take(5));
}

int _distance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final next = <int>[i + 1];
    for (var j = 0; j < b.length; j++) {
      next.add(
        math.min(
          math.min(next[j] + 1, previous[j + 1] + 1),
          previous[j] + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1),
        ),
      );
    }
    previous = next;
  }
  return previous.last;
}
