// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/foundation.dart';

sealed class CourseCatalogState {
  const CourseCatalogState();
}

class CourseCatalogInitial extends CourseCatalogState {
  const CourseCatalogInitial();
}

class CourseCatalogLoading extends CourseCatalogState {
  const CourseCatalogLoading();
}

class CourseCatalogReady extends CourseCatalogState {
  const CourseCatalogReady({required this.courses, required this.query});

  final List<CourseCatalogItem> courses;
  final String query;
}

class CourseCatalogEmpty extends CourseCatalogState {
  const CourseCatalogEmpty();
}

class CourseCatalogFailure extends CourseCatalogState {
  const CourseCatalogFailure(this.message);

  final String message;
}

class CourseCatalogAuthenticationRequired extends CourseCatalogState {
  const CourseCatalogAuthenticationRequired();
}

class CourseCatalogController extends ChangeNotifier {
  CourseCatalogController({required AuthGateway auth, required CourseApi api})
    : _auth = auth,
      _api = api;

  final AuthGateway _auth;
  final CourseApi _api;
  CourseCatalogState _state = const CourseCatalogInitial();
  List<CourseCatalogItem> _allCourses = const [];
  int _generation = 0;
  int? _academicYear;
  AcademicTerm? _term;

  CourseCatalogState get state => _state;

  Future<void> load({
    required int academicYear,
    AcademicTerm term = AcademicTerm.first,
    bool force = false,
  }) async {
    if (!force &&
        _academicYear == academicYear &&
        _term == term &&
        _state is! CourseCatalogInitial) {
      return;
    }
    _academicYear = academicYear;
    _term = term;
    _allCourses = const [];
    final requestGeneration = ++_generation;

    final session = _auth.currentSession;
    if (session == null) {
      _setState(const CourseCatalogAuthenticationRequired());
      return;
    }

    _setState(const CourseCatalogLoading());
    try {
      final courses = await _api.getCourses(
        session.accessToken,
        academicYear: academicYear,
        term: term,
      );
      if (requestGeneration != _generation) return;
      _allCourses = List.unmodifiable(courses);
      _setState(
        courses.isEmpty
            ? const CourseCatalogEmpty()
            : CourseCatalogReady(courses: _allCourses, query: ''),
      );
    } on CourseApiFailure catch (failure) {
      if (requestGeneration != _generation) return;
      if (failure.kind == CourseApiFailureKind.unauthorized) {
        _setState(const CourseCatalogAuthenticationRequired());
        return;
      }
      _setState(CourseCatalogFailure(failure.userMessage));
    } on Object catch (_) {
      if (requestGeneration != _generation) return;
      _setState(const CourseCatalogFailure('과목 목록을 불러오지 못했습니다. 다시 시도해 주세요.'));
    }
  }

  void search(String query) {
    if (_state is! CourseCatalogReady || _allCourses.isEmpty) return;
    final normalizedQuery = query.trim().toLowerCase();
    final courses = normalizedQuery.isEmpty
        ? _allCourses
        : _allCourses
              .where(
                (course) =>
                    course.code.toLowerCase().contains(normalizedQuery) ||
                    course.name.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);
    _setState(
      CourseCatalogReady(
        courses: List.unmodifiable(courses),
        query: normalizedQuery,
      ),
    );
  }

  Future<void> retry() async {
    final year = _academicYear;
    if (year != null && _term != null) {
      await load(academicYear: year, term: _term!, force: true);
    }
  }

  void reset() {
    _generation++;
    _academicYear = null;
    _term = null;
    _allCourses = const [];
    _setState(const CourseCatalogInitial());
  }

  void _setState(CourseCatalogState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
