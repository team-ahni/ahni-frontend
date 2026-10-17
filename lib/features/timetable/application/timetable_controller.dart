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
