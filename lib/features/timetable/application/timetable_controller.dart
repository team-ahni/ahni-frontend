import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/timetable/data/timetable_api.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/foundation.dart';

class TimetableController extends ChangeNotifier {
  TimetableController({required this.auth, required this.api});
  final AuthGateway auth;
  final TimetableApi api;
  int year = DateTime.now().year;
  String term = DateTime.now().month >= 7 ? 'SECOND' : 'FIRST';
  List<TimetableEntry> entries = const [];
  List<Lecture> lectures = const [];
  bool loading = false;
  bool busy = false;
  bool unauthorized = false;
  bool loaded = false;
  String? message;
  int _generation = 0;

  Future<void> load({int? academicYear, String? academicTerm}) async {
    if (busy) return;
    if (academicYear != null) year = academicYear;
    if (academicTerm != null) term = academicTerm;
    final generation = ++_generation;
    final session = auth.currentSession;
    entries = const [];
    lectures = const [];
    message = null;
    unauthorized = session == null;
    loading = session != null;
    loaded = false;
    notifyListeners();
    if (session == null) return;
    try {
      final nextEntries = await api.entries(session.accessToken, year, term);
      final nextLectures = await api.lectures(session.accessToken, year, term);
      if (generation != _generation ||
          auth.currentSession?.email != session.email) {
        return;
      }
      entries = List.unmodifiable(nextEntries);
      lectures = List.unmodifiable(nextLectures);
      loaded = true;
    } on TimetableApiFailure catch (failure) {
      if (generation != _generation) return;
      message = failure.message;
      unauthorized = failure.unauthorized;
    } on Object catch (_) {
      if (generation != _generation) return;
      message = '시간표를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    if (generation != _generation) return;
    loading = false;
    notifyListeners();
  }

  Future<bool> save(Lecture lecture, {String? entryId}) =>
      _mutate((token) => api.save(token, lecture.entityId, entryId: entryId));

  /// 여러 분반을 차례로 넣고 시간표는 마지막에 한 번만 다시 불러온다.
  /// 넣지 못한 분반과 그 이유를 돌려준다. 로그인이 만료되면 나머지는 넣지 않는다.
  Future<List<({Lecture lecture, String message})>> saveAll(
    List<Lecture> lectures,
  ) async {
    final failures = <({Lecture lecture, String message})>[];
    final added = await _mutate((token) async {
      for (final lecture in lectures) {
        try {
          await api.save(token, lecture.entityId);
        } on TimetableApiFailure catch (failure) {
          if (failure.unauthorized) rethrow;
          failures.add((lecture: lecture, message: failure.message));
        }
      }
    });
    if (added) return failures;
    // 중간에 멈췄으면 결과를 알 수 없는 나머지도 실패로 알린다.
    final failed = {for (final f in failures) f.lecture.entityId};
    return [
      ...failures,
      for (final lecture in lectures)
        if (!failed.contains(lecture.entityId))
          (lecture: lecture, message: message ?? '시간표에 추가하지 못했어요. 다시 시도해 주세요.'),
    ];
  }

  Future<bool> delete(String entryId) =>
      _mutate((token) => api.delete(token, entryId));

  Future<bool> _mutate(Future<void> Function(String) action) async {
    if (busy || loading) return false;
    final session = auth.currentSession;
    if (session == null) {
      unauthorized = true;
      notifyListeners();
      return false;
    }
    final generation = _generation;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await action(session.accessToken);
      if (generation != _generation ||
          auth.currentSession?.email != session.email) {
        return false;
      }
      busy = false;
      await load();
      return loaded;
    } on TimetableApiFailure catch (failure) {
      if (generation != _generation) return false;
      message = failure.message;
      unauthorized = failure.unauthorized;
    } on Object catch (_) {
      if (generation != _generation) return false;
      message = '시간표를 변경하지 못했어요. 다시 시도해 주세요.';
    }
    if (generation != _generation) return false;
    busy = false;
    notifyListeners();
    return false;
  }

  void reset() {
    _generation++;
    entries = const [];
    lectures = const [];
    loaded = loading = busy = unauthorized = false;
    message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
