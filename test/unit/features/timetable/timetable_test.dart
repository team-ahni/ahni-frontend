import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/data/timetable_api.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/onboarding_fakes.dart';
import '../../../support/timetable_fakes.dart';

void main() {
  test('parses instructor text without a professor entity', () {
    final lecture = Lecture.fromJson({
      'entityId': 'lecture-1',
      'courseCode': 'TEST101',
      'courseName': '자료구조',
      'credit': 3,
      'professorName': '남춘성,이우형',
      'section': '001',
      'schedules': <Object?>[],
    });
    expect(lecture.professorName, '남춘성,이우형');
  });

  test('parses minute precision and rejects malformed times', () {
    expect(LectureSchedule.minutes('09:30:00'), 570);
    expect(() => LectureSchedule.minutes('25:00'), throwsFormatException);
    expect(() => LectureSchedule.minutes('09:30:01'), throwsFormatException);
  });

  test('API sends token and selected semester', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters, {
        'academicYear': '2026',
        'term': 'SECOND',
      });
      expect(request.headers['authorization'], 'Bearer token');
      return http.Response('[]', 200);
    });
    final api = HttpTimetableApi(
      baseUri: Uri.parse('http://localhost:8080'),
      client: client,
    );
    expect(await api.entries('token', 2026, 'SECOND'), isEmpty);
    client.close();
  });

  test('API preserves server conflict message', () async {
    final client = MockClient((request) async {
      expect(jsonDecode(request.body), {'lectureEntityId': 'lecture-1'});
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'code': 'TIMETABLE_CONFLICT',
            'message': '자료구조 강의와 시간이 겹칩니다.',
          }),
        ),
        409,
      );
    });
    final api = HttpTimetableApi(
      baseUri: Uri.parse('http://localhost:8080'),
      client: client,
    );
    await expectLater(
      api.save('token', 'lecture-1'),
      throwsA(
        isA<TimetableApiFailure>().having(
          (e) => e.message,
          'message',
          contains('자료구조'),
        ),
      ),
    );
    client.close();
  });

  test('create and delete refresh persisted entries', () async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final controller = TimetableController(auth: auth, api: FakeTimetableApi());
    await controller.load();
    expect(await controller.save(testLecture), isTrue);
    expect(controller.entries.single.lecture.courseName, '자료구조');
    expect(await controller.delete('entry-1'), isTrue);
    expect(controller.entries, isEmpty);
    controller.dispose();
    await auth.dispose();
  });

  test('conflict preserves current entries', () async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeTimetableApi()
      ..current = [
        const TimetableEntry(entityId: 'entry-1', lecture: testLecture),
      ]
      ..failure = const TimetableApiFailure('시간이 겹칩니다.');
    final controller = TimetableController(auth: auth, api: api);
    await controller.load();
    expect(await controller.save(testLecture), isFalse);
    expect(controller.entries, hasLength(1));
    expect(controller.message, contains('겹칩니다'));
    controller.dispose();
    await auth.dispose();
  });

  test('reset prevents late responses restoring account data', () async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final pending = Completer<List<TimetableEntry>>();
    final controller = TimetableController(
      auth: auth,
      api: FakeTimetableApi()..pending = pending,
    );
    final request = controller.load();
    controller.reset();
    pending.complete([
      const TimetableEntry(entityId: 'entry-1', lecture: testLecture),
    ]);
    await request;
    expect(controller.entries, isEmpty);
    expect(controller.loaded, isFalse);
    controller.dispose();
    await auth.dispose();
  });
}
