import 'dart:math' as math;

import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';

/// Matches common OCR confusions only in positions where the character is invalid.
List<CourseCatalogItem> positionalOcrMatches(
  OcrGradeCandidate candidate,
  List<CourseCatalogItem> courses,
) {
  final code = candidate.courseCode.trim().toUpperCase();
  if (code.length != 7 || RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(code)) {
    return const [];
  }
  const prefix = {'1': 'IL', '0': 'DO'};
  const suffix = {'I': '1', 'L': '1', 'O': '0', 'D': '0'};
  return courses.where((course) {
    final target = course.code.toUpperCase();
    if (!RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(target)) return false;
    for (var i = 0; i < code.length; i++) {
      final options = (i < 3 ? prefix : suffix)[code[i]] ?? code[i];
      if (!options.contains(target[i])) return false;
    }
    return true;
  }).toList();
}

List<CourseCatalogItem> initialLetterOcrMatches(
  OcrGradeCandidate candidate,
  List<CourseCatalogItem> courses,
) {
  final code = candidate.courseCode.trim().toUpperCase();
  if (!RegExp(r'^[TI][A-Z]{2}[0-9]{4}$').hasMatch(code)) return const [];
  final alternate = (code.startsWith('T') ? 'I' : 'T') + code.substring(1);
  return courses
      .where((course) => course.code.toUpperCase() == alternate)
      .toList();
}

bool matchesOcrCourseName(
  OcrGradeCandidate candidate,
  CourseCatalogItem course,
) {
  String normalize(String name) =>
      name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9가-힣]'), '');
  final recognized = normalize(candidate.courseName ?? '');
  return recognized.isNotEmpty && recognized == normalize(course.name);
}

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
