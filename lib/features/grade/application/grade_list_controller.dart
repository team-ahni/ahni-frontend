// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:flutter/foundation.dart';

sealed class GradeListState {
  const GradeListState();
}

class GradeListInitial extends GradeListState {
  const GradeListInitial();
}

class GradeListLoading extends GradeListState {
  const GradeListLoading();
}

class GradeListReady extends GradeListState {
  const GradeListReady({required this.grades, required this.summary});

  final List<GradeRecord> grades;
  final GradeSummary summary;
}

class GradeListEmpty extends GradeListState {
  const GradeListEmpty();
}

class GradeListFailure extends GradeListState {
  const GradeListFailure(this.message);

  final String message;
}

class GradeListAuthenticationRequired extends GradeListState {
  const GradeListAuthenticationRequired();
}

class GradeListController extends ChangeNotifier {
  GradeListController({required AuthGateway auth, required GradeApi api})
    : _auth = auth,
      _api = api;

  final AuthGateway _auth;
  final GradeApi _api;
  GradeListState _state = const GradeListInitial();
  int _generation = 0;

  GradeListState get state => _state;
  bool get canClearGrades => _api is GradeResetApi && _state is GradeListReady;

  Future<String?> clearGrades() async {
    final api = _api;
    final previous = _state;
    if (api is! GradeResetApi || previous is! GradeListReady) return null;
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const GradeListAuthenticationRequired());
      return null;
    }

    final generation = _generation;
    _setState(const GradeListLoading());
    try {
      await (api as GradeResetApi).deleteAllGrades(session.accessToken);
      if (generation == _generation) _setState(const GradeListEmpty());
      return null;
    } on GradeApiFailure catch (failure) {
      if (generation != _generation) return null;
      if (failure.kind == GradeApiFailureKind.unauthorized) {
        _setState(const GradeListAuthenticationRequired());
        return null;
      }
      _setState(previous);
      return failure.userMessage;
    } on Object {
      if (generation != _generation) return null;
      _setState(previous);
      return '성적을 초기화하지 못했어요. 다시 시도해 주세요.';
    }
  }

  Future<void> load({bool force = false}) async {
    if (_state is GradeListLoading) return;
    if (!force && _state is! GradeListInitial) return;

    final session = _auth.currentSession;
    if (session == null) {
      _setState(const GradeListAuthenticationRequired());
      return;
    }

    final requestGeneration = _generation;
    _setState(const GradeListLoading());
    try {
      final results = await Future.wait<Object>([
        _api.getGrades(session.accessToken),
        _api.getSummary(session.accessToken),
      ]);
      final grades = results[0] as List<GradeRecord>;
      final summary = results[1] as GradeSummary;
      if (requestGeneration != _generation) return;
      _setState(
        grades.isEmpty
            ? const GradeListEmpty()
            : GradeListReady(
                grades: List.unmodifiable(grades),
                summary: summary,
              ),
      );
    } on GradeApiFailure catch (failure) {
      if (requestGeneration != _generation) return;
      if (failure.kind == GradeApiFailureKind.unauthorized) {
        _setState(const GradeListAuthenticationRequired());
        return;
      }
      _setState(GradeListFailure(failure.userMessage));
    } on Object catch (_) {
      if (requestGeneration != _generation) return;
      _setState(const GradeListFailure('성적 목록을 불러오지 못했어요. 다시 시도해 주세요.'));
    }
  }

  Future<void> retry() => load(force: true);

  void reset() {
    _generation++;
    _setState(const GradeListInitial());
  }

  void _setState(GradeListState next) {
    _state = next;
    notifyListeners();
  }
}
