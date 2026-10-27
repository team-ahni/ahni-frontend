import 'dart:convert';

import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';
import 'package:http/http.dart' as http;

enum CourseRecommendationFailureKind { unauthorized, recoverable }

class CourseRecommendationApiFailure implements Exception {
  const CourseRecommendationApiFailure(this.kind, this.message);
  final CourseRecommendationFailureKind kind;
  final String message;
}

abstract interface class CourseRecommendationApi {
  Future<CourseRecommendation> getRecommendations(
    String accessToken,
    int academicYear,
    String term,
  );
}

class HttpCourseRecommendationApi implements CourseRecommendationApi {
  HttpCourseRecommendationApi({required this.baseUri, required this.client});
  final Uri baseUri;
  final http.Client client;

  @override
  Future<CourseRecommendation> getRecommendations(
    String accessToken,
    int academicYear,
    String term,
  ) async {
    final http.Response response;
    try {
      response = await client
          .get(
            baseUri
                .resolve('/api/v1/course-recommendations')
                .replace(
                  queryParameters: {
                    'academicYear': '$academicYear',
                    'term': term,
                  },
                ),
            headers: {'authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const CourseRecommendationApiFailure(
        CourseRecommendationFailureKind.recoverable,
        '서버에 연결하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
    if (response.statusCode == 401) {
      throw const CourseRecommendationApiFailure(
        CourseRecommendationFailureKind.unauthorized,
        '다시 로그인해 주세요.',
      );
    }
    if (response.statusCode != 200) throw _unavailable;
    try {
      return CourseRecommendation.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>,
      );
    } on FormatException catch (_) {
      throw _unavailable;
    } on TypeError catch (_) {
      throw _unavailable;
    }
  }

  static const _unavailable = CourseRecommendationApiFailure(
    CourseRecommendationFailureKind.recoverable,
    '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.',
  );
}
