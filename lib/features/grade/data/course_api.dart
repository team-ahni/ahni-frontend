// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:http/http.dart' as http;

enum CourseApiFailureKind { unauthorized, recoverable }

class CourseApiFailure implements Exception {
  const CourseApiFailure(this.kind, this.userMessage);

  final CourseApiFailureKind kind;
  final String userMessage;
}

abstract interface class CourseApi {
  Future<List<CourseCatalogItem>> getCourses(
    String accessToken, {
    required int academicYear,
    required AcademicTerm term,
  });
}

abstract interface class CourseCatalogApi {
  Future<List<CourseCatalogItem>> getCatalog(String accessToken);
}

class HttpCourseApi implements CourseApi, CourseCatalogApi {
  HttpCourseApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<List<CourseCatalogItem>> getCourses(
    String accessToken, {
    required int academicYear,
    required AcademicTerm term,
  }) async {
    final response = await _request(
      () => _client.get(
        baseUri
            .resolve('/api/v1/lectures/courses')
            .replace(
              queryParameters: {
                'academicYear': '$academicYear',
                'term': term.apiName,
              },
            ),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map(
            (item) => CourseCatalogItem.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<List<CourseCatalogItem>> getCatalog(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/courses'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map(
            (item) => CourseCatalogItem.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false);
    } on FormatException {
      throw _malformedResponse;
    } on TypeError {
      throw _malformedResponse;
    }
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const CourseApiFailure(
        CourseApiFailureKind.recoverable,
        '서버에 연결하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  CourseApiFailure _failure(http.Response response) {
    if (response.statusCode == 401) {
      return const CourseApiFailure(
        CourseApiFailureKind.unauthorized,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    return const CourseApiFailure(
      CourseApiFailureKind.recoverable,
      '과목 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
    );
  }

  static const _malformedResponse = CourseApiFailure(
    CourseApiFailureKind.recoverable,
    '과목 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
  );
}
