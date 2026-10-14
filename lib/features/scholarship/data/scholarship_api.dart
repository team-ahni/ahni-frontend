import 'dart:convert';

import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';
import 'package:http/http.dart' as http;

enum ScholarshipFailureKind { unauthorized, recoverable }

class ScholarshipApiFailure implements Exception {
  const ScholarshipApiFailure(this.kind, this.message);
  final ScholarshipFailureKind kind;
  final String message;
}

abstract interface class ScholarshipApi {
  Future<ScholarshipEligibility> getEligibility(String accessToken);
}

class HttpScholarshipApi implements ScholarshipApi {
  HttpScholarshipApi({required this.baseUri, required this.client});
  final Uri baseUri;
  final http.Client client;

  @override
  Future<ScholarshipEligibility> getEligibility(String accessToken) async {
    final http.Response response;
    try {
      response = await client
          .get(
            baseUri.resolve('/api/v1/scholarship-eligibility'),
            headers: {'authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const ScholarshipApiFailure(
        ScholarshipFailureKind.recoverable,
        '서버에 연결하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
    if (response.statusCode == 401) {
      throw const ScholarshipApiFailure(
        ScholarshipFailureKind.unauthorized,
        '다시 로그인해 주세요.',
      );
    }
    if (response.statusCode != 200) throw _unavailable;
    try {
      return ScholarshipEligibility.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>,
      );
    } on FormatException catch (_) {
      throw _unavailable;
    } on TypeError catch (_) {
      throw _unavailable;
    }
  }

  static const _unavailable = ScholarshipApiFailure(
    ScholarshipFailureKind.recoverable,
    '장학 정보를 불러오지 못했어요. 다시 시도해 주세요.',
  );
}
