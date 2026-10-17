import 'dart:async';

import 'package:ahni_mobile/features/timetable/data/timetable_api.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';

const testLecture = Lecture(
  entityId: 'lecture-1',
  courseCode: 'TEST101',
  courseName: '자료구조',
  credit: 3,
  professorName: '김교수',
  section: '001',
  schedules: [
    LectureSchedule(
      entityId: 'schedule-1',
      dayOfWeek: 1,
      startTime: '09:30:00',
      endTime: '11:00:00',
      classroom: '101호',
    ),
  ],
);

class FakeTimetableApi implements TimetableApi {
  List<TimetableEntry> current = [];
  TimetableApiFailure? failure;
  Completer<List<TimetableEntry>>? pending;
  @override
  Future<List<Lecture>> lectures(String token, int year, String term) async => [
    testLecture,
  ];
  @override
  Future<List<TimetableEntry>> entries(
    String token,
    int year,
    String term,
  ) async => pending != null ? pending!.future : List.of(current);
  @override
  Future<void> save(String token, String lectureId, {String? entryId}) async {
    if (failure != null) throw failure!;
    current = [
      TimetableEntry(entityId: entryId ?? 'entry-1', lecture: testLecture),
    ];
  }

  @override
  Future<void> delete(String token, String entryId) async {
    if (failure != null) throw failure!;
    current = [];
  }
}
