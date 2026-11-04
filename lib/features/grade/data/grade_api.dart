// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:http/http.dart' as http;

enum GradeApiFailureKind {
  unauthorized,
  studentNotFound,
  validation,
  conflict,
  notFound,
  recoverable,
}

class GradeApiFailure implements Exception {
  const GradeApiFailure(this.kind, this.userMessage);

  final GradeApiFailureKind kind;
  final String userMessage;
}

abstract interface class GradeApi {
  Future<List<GradeRecord>> getGrades(String accessToken);

  Future<GradeSummary> getSummary(String accessToken);

  Future<GradeSimulation> simulateGrades(
    String accessToken,
    List<ExpectedGrade> expectedGrades,
  );

  Future<GradeRecord> registerGrade(
    String accessToken,
    GradeRegistration registration,
  );

  Future<GradeRecord> updateGrade(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  );

  Future<void> deleteGrade(String accessToken, String gradeEntityId);
}

abstract interface class GradeResetApi {
  Future<void> deleteAllGrades(String accessToken);
}

class HttpGradeApi implements GradeApi, GradeResetApi {
  HttpGradeApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<List<GradeRecord>> getGrades(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/grades'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(
        response,
        fallbackMessage: '성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map((item) => GradeRecord.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<GradeSummary> getSummary(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/grades/summary'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(
        response,
        fallbackMessage: '성적 요약을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    }
    try {
      return GradeSummary.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<GradeSimulation> simulateGrades(
    String accessToken,
    List<ExpectedGrade> expectedGrades,
  ) async {
    if (expectedGrades.isEmpty ||
        expectedGrades.length > 50 ||
        expectedGrades.any(
          (grade) => ExpectedGrade.parseCredit(grade.credit.toString()) == null,
        )) {
      throw const GradeApiFailure(
        GradeApiFailureKind.validation,
        '예상 성적과 학점을 확인해 주세요.',
      );
    }
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/grades/simulation'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'expectedGrades': expectedGrades
              .map((grade) => grade.toJson())
              .toList(),
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(
        response,
        fallbackMessage: '예상 평점을 계산하지 못했어요. 다시 시도해 주세요.',
      );
    }
    try {
      return GradeSimulation.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<GradeRecord> registerGrade(
    String accessToken,
    GradeRegistration registration,
  ) async {
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/grades'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(registration.toJson()),
      ),
    );
    if (response.statusCode != 201) {
      throw _failure(response, fallbackMessage: '성적을 등록하지 못했습니다. 다시 시도해 주세요.');
    }
    try {
      return GradeRecord.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<GradeRecord> updateGrade(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  ) async {
    final response = await _request(
      () => _client.put(
        _gradeUri(gradeEntityId),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(update.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(response, fallbackMessage: '성적을 수정하지 못했습니다. 다시 시도해 주세요.');
    }
    try {
      return GradeRecord.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<void> deleteGrade(String accessToken, String gradeEntityId) async {
    final response = await _request(
      () => _client.delete(
        _gradeUri(gradeEntityId),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 204) {
      throw _failure(response, fallbackMessage: '성적을 삭제하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  @override
  Future<void> deleteAllGrades(String accessToken) async {
    final response = await _request(
      () => _client.delete(
        baseUri.resolve('/api/v1/grades'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 204) {
      throw _failure(response, fallbackMessage: '성적을 초기화하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  Uri _gradeUri(String gradeEntityId) {
    return baseUri.resolve(
      '/api/v1/grades/${Uri.encodeComponent(gradeEntityId)}',
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const GradeApiFailure(
        GradeApiFailureKind.recoverable,
        '서버에 연결하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  GradeApiFailure _failure(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final code = _errorCode(response);
    if (response.statusCode == 401) {
      return const GradeApiFailure(
        GradeApiFailureKind.unauthorized,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404 &&
        (code == null || code == 'STUDENT_NOT_FOUND')) {
      return const GradeApiFailure(
        GradeApiFailureKind.studentNotFound,
        '학생 정보를 먼저 등록해 주세요.',
      );
    }
    return switch (code) {
      'CURRICULUM_NOT_AVAILABLE' => const GradeApiFailure(
        GradeApiFailureKind.validation,
        '선택한 연도의 교과과정이 아직 준비되지 않았어요. 수강연도를 확인해 주세요.',
      ),
      'COURSE_NOT_IN_CURRICULUM' => const GradeApiFailure(
        GradeApiFailureKind.validation,
        '선택한 연도의 과목이 아니에요. 수강연도에 맞는 과목을 다시 선택해 주세요.',
      ),
      'COURSE_NOT_FOUND' => const GradeApiFailure(
        GradeApiFailureKind.validation,
        '선택한 과목을 찾을 수 없어요. 과목을 다시 선택해 주세요.',
      ),
      'GRADE_ALREADY_REGISTERED' => const GradeApiFailure(
        GradeApiFailureKind.conflict,
        '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
      ),
      'INVALID_GRADE' || 'INVALID_REQUEST' => const GradeApiFailure(
        GradeApiFailureKind.validation,
        '입력한 성적 정보를 확인해 주세요.',
      ),
      'GRADE_NOT_FOUND' => const GradeApiFailure(
        GradeApiFailureKind.notFound,
        '성적 정보를 찾을 수 없어요. 목록을 새로고침해 주세요.',
      ),
      'GRADE_REPLACEMENT_CONFLICT' => const GradeApiFailure(
        GradeApiFailureKind.conflict,
        '선택한 이전 성적이 다른 재수강 성적에 연결되어 있어요. 성적 목록을 새로고침해 주세요.',
      ),
      _ => GradeApiFailure(GradeApiFailureKind.recoverable, fallbackMessage),
    };
  }

  String? _errorCode(http.Response response) {
    try {
      return _decodeMap(response)['code'] as String?;
    } on Object catch (_) {
      return null;
    }
  }

  Map<String, Object?> _decodeMap(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
  }

  static const _malformedResponse = GradeApiFailure(
    GradeApiFailureKind.recoverable,
    '성적 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
  );
}
