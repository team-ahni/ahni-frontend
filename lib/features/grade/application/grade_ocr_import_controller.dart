// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_course_matching.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:flutter/foundation.dart';

enum OcrImportStatus { pending, saved, existing }

class OcrImportEntry {
  OcrImportEntry(this.candidate)
    : credit = candidate.credit,
      grade = candidate.gradeCode;
  final OcrGradeCandidate candidate;
  List<CourseCatalogItem> courses = const [];
  List<CourseCatalogItem> suggestions = const [];
  CourseCatalogItem? course;
  double? credit;
  GradeCode? grade;
  bool selected = false;
  OcrImportStatus status = OcrImportStatus.pending;
  String? message;
  bool get canRegister =>
      status == OcrImportStatus.pending &&
      course != null &&
      candidate.academicYear != null &&
      candidate.academicYear! >= 2000 &&
      candidate.academicYear! <= DateTime.now().year &&
      candidate.term != null &&
      grade != null &&
      credit != null &&
      credit! > 0 &&
      credit! <= 30 &&
      RegExp(r'^\d{1,2}(\.\d)?$').hasMatch(credit.toString());
  String? get key =>
      course == null || candidate.academicYear == null || candidate.term == null
      ? null
      : '${candidate.academicYear}:${candidate.term!.apiName}:${course!.entityId}';
}

/// Uses the existing per-grade endpoint. Successful rows survive partial failure.
class GradeOcrImportController extends ChangeNotifier {
  GradeOcrImportController({
    required AuthGateway auth,
    required CourseCatalogApi courses,
    required GradeApi grades,
  }) : _auth = auth,
       _courses = courses,
       _grades = grades;
  final AuthGateway _auth;
  final CourseCatalogApi _courses;
  final GradeApi _grades;
  List<OcrImportEntry> _entries = [];
  List<OcrImportEntry> get entries => List.unmodifiable(_entries);
  bool busy = false;
  bool hasChanges = false;
  String? message;
  String? _owner;
  bool _disposed = false;
  int _generation = 0;
  Set<String> _existing = {};
  int get selectedCount =>
      _entries.where((e) => e.selected && e.canRegister).length;
  int get savedCount =>
      _entries.where((e) => e.status == OcrImportStatus.saved).length;
  bool _active(int generation) =>
      !_disposed &&
      _generation == generation &&
      _auth.currentSession?.email == _owner;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _recordKey(GradeRecord grade) =>
      '${grade.academicYear}:${grade.term.apiName}:${grade.course.entityId}';

  Future<void> prepare(List<OcrGradeCandidate> candidates) async {
    if (busy) return;
    final generation = ++_generation;
    _owner = _auth.currentSession?.email;
    _entries = candidates.map(OcrImportEntry.new).toList();
    message = null;
    if (_owner == null) {
      message = '로그인한 뒤 성적을 등록해 주세요.';
      _notify();
      return;
    }
    busy = true;
    _notify();
    try {
      _existing = (await _grades.getGrades(_auth.currentSession!.accessToken))
          .map(_recordKey)
          .toSet();
      if (!_active(generation)) return;
      final catalog = await _courses.getCatalog(
        _auth.currentSession!.accessToken,
      );
      if (!_active(generation)) return;
      for (final entry in _entries) {
        final year = entry.candidate.academicYear, term = entry.candidate.term;
        if (year == null ||
            term == null ||
            year < 2000 ||
            year > DateTime.now().year) {
          entry.message = '수강연도와 학기를 확인해 주세요.';
          continue;
        }
        entry.courses = List.unmodifiable(catalog);
        final matches = entry.courses
            .where(
              (c) =>
                  c.code.toUpperCase() ==
                  entry.candidate.courseCode.toUpperCase(),
            )
            .toList();
        if (matches.length == 1) {
          entry.course = matches.single;
        } else {
          entry.suggestions = suggestOcrCourses(entry.candidate, entry.courses);
        }
        if (entry.courses.isEmpty) {
          entry.message = '등록된 과목 자료가 없어요. 잠시 후 다시 확인해 주세요.';
        } else if (entry.course == null) {
          entry.message = '학수번호를 확인하고 과목을 선택해 주세요.';
        } else if (!entry.canRegister) {
          entry.message = '학점과 성적을 확인해 주세요.';
        }
      }
      _markExisting();
    } on GradeApiFailure catch (error) {
      message = error.userMessage;
    } on CourseApiFailure catch (error) {
      message = error.userMessage;
    } on Object {
      message = '과목과 기존 성적을 확인하지 못했어요. 다시 시도해 주세요.';
    } finally {
      if (!_disposed && generation == _generation) {
        if (!_active(generation)) {
          _entries = [];
          message = '로그인 계정이 변경됐어요. 다시 인식해 주세요.';
        }
        busy = false;
        _notify();
      }
    }
  }

  void _markExisting() {
    final seen = <String>{};
    for (final entry in _entries) {
      final key = entry.key;
      if (key == null || entry.status == OcrImportStatus.saved) continue;
      if (_existing.contains(key)) {
        entry.status = OcrImportStatus.existing;
        entry.selected = false;
        entry.message = '이미 등록된 성적이에요.';
      } else if (!seen.add(key)) {
        entry.selected = false;
        entry.course = null;
        entry.message = '같은 과목·학기가 파일에 중복돼 있어요.';
      }
    }
  }

  void select(int index, bool selected) {
    if (!busy &&
        index >= 0 &&
        index < _entries.length &&
        _entries[index].canRegister) {
      _entries[index].selected = selected;
      _notify();
    }
  }

  void selectReady() {
    if (!busy) {
      for (final entry in _entries) {
        entry.selected = entry.canRegister;
      }
      _notify();
    }
  }

  void edit(
    int index, {
    required CourseCatalogItem course,
    required double credit,
    required GradeCode grade,
  }) {
    if (busy ||
        index < 0 ||
        index >= _entries.length ||
        !_entries[index].courses.any((c) => c.entityId == course.entityId)) {
      return;
    }
    final entry = _entries[index];
    if (entry.status != OcrImportStatus.pending) return;
    entry.course = course;
    entry.credit = credit;
    entry.grade = grade;
    entry.message = null;
    entry.selected = false;
    _markExisting();
    _notify();
  }

  Future<void> submitSelected() async {
    if (busy || selectedCount == 0) return;
    final generation = _generation;
    if (!_active(generation) || _owner == null) {
      _entries = [];
      message = '다시 로그인하고 성적표를 인식해 주세요.';
      _notify();
      return;
    }
    busy = true;
    message = null;
    _notify();
    try {
      // Reconcile before retrying: a lost response may have already saved a row.
      _existing = (await _grades.getGrades(_auth.currentSession!.accessToken))
          .map(_recordKey)
          .toSet();
      if (!_active(generation)) return;
      _markExisting();
      for (final entry
          in _entries.where((e) => e.selected && e.canRegister).toList()) {
        if (!_active(generation)) return;
        final registration = GradeRegistration(
          courseEntityId: entry.course!.entityId,
          academicYear: entry.candidate.academicYear!,
          term: entry.candidate.term!,
          gradeCode: entry.grade,
          credit: entry.credit!,
          rpl: false,
          replacedGradeEntityId: null,
        );
        try {
          await _grades.registerGrade(
            _auth.currentSession!.accessToken,
            registration,
          );
          if (!_active(generation)) return;
          entry.status = OcrImportStatus.saved;
          entry.selected = false;
          entry.message = null;
          _existing.add(entry.key!);
          hasChanges = true;
          _notify();
        } on GradeApiFailure catch (error) {
          if (!_active(generation)) return;
          entry.message = error.userMessage;
          if (error.kind == GradeApiFailureKind.unauthorized) {
            message = error.userMessage;
            break;
          }
          if (error.kind == GradeApiFailureKind.recoverable) {
            hasChanges = true;
            message = '저장 여부를 확인하지 못한 항목이 있어요. 다시 등록하면 저장 상태부터 확인해요.';
            break;
          }
        } on Object {
          hasChanges = true;
          entry.message = '저장 여부를 확인하지 못했어요. 다시 시도해 주세요.';
          message = entry.message;
          break;
        }
      }
    } on GradeApiFailure catch (error) {
      message = error.userMessage;
    } on Object {
      message = '기존 성적을 확인하지 못했어요. 네트워크를 확인해 주세요.';
    } finally {
      if (!_disposed && generation == _generation) {
        if (!_active(generation)) {
          _entries = [];
          message = '로그인 계정이 변경됐어요. 다시 인식해 주세요.';
        }
        busy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
