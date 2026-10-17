import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:http/http.dart' as http;

class TimetableApiFailure implements Exception {
  const TimetableApiFailure(this.message, {this.unauthorized = false});
  final String message;
  final bool unauthorized;
}

abstract interface class TimetableApi {
  Future<List<Lecture>> lectures(String token, int year, String term);
  Future<List<TimetableEntry>> entries(String token, int year, String term);
  Future<void> save(String token, String lectureId, {String? entryId});
  Future<void> delete(String token, String entryId);
}

class HttpTimetableApi implements TimetableApi {
  HttpTimetableApi({required this.baseUri, required this.client});
  final Uri baseUri;
  final http.Client client;

  @override
  Future<List<Lecture>> lectures(String token, int year, String term) async {
    final body = await _request(
      'GET',
      '/api/v1/lectures',
      token,
      year: year,
      term: term,
    );
    return _parse(
      () => (body! as List<Object?>)
          .map((item) => Lecture.fromJson(item! as Map<String, Object?>))
          .toList(),
    );
  }

  @override
  Future<List<TimetableEntry>> entries(
    String token,
    int year,
    String term,
  ) async {
    final body = await _request(
      'GET',
      '/api/v1/timetable',
      token,
      year: year,
      term: term,
    );
    return _parse(
      () => (body! as List<Object?>)
          .map((item) => TimetableEntry.fromJson(item! as Map<String, Object?>))
          .toList(),
    );
  }

  @override
  Future<void> save(String token, String lectureId, {String? entryId}) async {
    await _request(
      entryId == null ? 'POST' : 'PUT',
      '/api/v1/timetable${entryId == null ? '' : '/${Uri.encodeComponent(entryId)}'}',
      token,
      lectureId: lectureId,
    );
  }

  @override
  Future<void> delete(String token, String entryId) async {
    await _request(
      'DELETE',
      '/api/v1/timetable/${Uri.encodeComponent(entryId)}',
      token,
    );
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on Object catch (_) {
      throw const TimetableApiFailure('시간표 정보를 확인하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<Object?> _request(
    String method,
    String path,
    String token, {
    int? year,
    String? term,
    String? lectureId,
  }) async {
    final uri = baseUri
        .resolve(path)
        .replace(
          queryParameters: year == null
              ? null
              : {'academicYear': '$year', 'term': term!},
        );
    final request = http.Request(method, uri);
    request.headers['authorization'] = 'Bearer $token';
    if (lectureId != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode({'lectureEntityId': lectureId});
    }
    late http.Response response;
    try {
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const TimetableApiFailure('서버에 연결하지 못했어요. 다시 시도해 주세요.');
    }
    if (response.statusCode == 401) {
      throw const TimetableApiFailure('로그인이 만료되었어요.', unauthorized: true);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = '시간표를 처리하지 못했어요. 다시 시도해 주세요.';
      try {
        final error =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
        if ([
          'TIMETABLE_CONFLICT',
          'TIMETABLE_NOT_FOUND',
          'LECTURE_NOT_FOUND',
          'STUDENT_NOT_FOUND',
        ].contains(error['code'])) {
          message = error['message']! as String;
        }
      } on Object catch (_) {
        /* Use a safe fallback for malformed errors. */
      }
      throw TimetableApiFailure(message);
    }
    if (response.statusCode == 204) return null;
    return _parse(() => jsonDecode(utf8.decode(response.bodyBytes)));
  }
}
