import 'dart:convert';

import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/recommendation/data/course_recommendation_api.dart';
import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/onboarding_fakes.dart';
import '../../../support/recommendation_fakes.dart';

void main() {
  group('CourseRecommendation', () {
    test('parses majors, reasons, and offered lectures', () {
      final recommendation = CourseRecommendation.fromJson(
        recommendationJson(),
      );

      expect(recommendation.semesterLabel, '3학년 2학기');
      final major = recommendation.majors.first;
      expect(major.majorLabel, '주전공');
      final required = major.courses.first;
      expect(required.reasonLabels, ['졸업 필수', '권장 학기 지남']);
      expect(required.divisionLabel, '전공 필수');
      expect(required.recommendedTermLabel, '3학년 1학기 권장');
      expect(required.lectures.single.section, '001');
      final retake = major.courses.last;
      expect(retake.previousGrade, GradeCode.cPlus);
      expect(retake.reasonLabels, ['재수강 추천 (C+)']);
      expect(retake.recommendedTermLabel, isNull);
      expect(recommendation.majors.last.curriculumAvailable, isFalse);
    });

    test('rejects unknown reasons and empty reason lists', () {
      for (final reasons in [
        ['SOMETHING_ELSE'],
        <String>[],
      ]) {
        final json = recommendationJson();
        final course =
            ((json['majors']! as List).first as Map)['courses'] as List;
        (course.first as Map)['reasons'] = reasons;
        expect(
          () => CourseRecommendation.fromJson(json),
          throwsFormatException,
        );
      }
    });
  });

  group('HttpCourseRecommendationApi', () {
    HttpCourseRecommendationApi api(http.Response response) =>
        HttpCourseRecommendationApi(
          baseUri: Uri.parse('https://api.example.test'),
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/course-recommendations');
            expect(request.url.queryParameters, {
              'academicYear': '2026',
              'term': 'SECOND',
            });
            expect(request.headers['authorization'], 'Bearer token');
            return response;
          }),
        );

    test('returns the parsed recommendation for 200', () async {
      final result = await api(
        http.Response.bytes(utf8.encode(jsonEncode(recommendationJson())), 200),
      ).getRecommendations('token', 2026, 'SECOND');

      expect(result.majors, hasLength(2));
    });

    test('maps 401 to an authentication failure', () async {
      await expectLater(
        api(http.Response('', 401)).getRecommendations('token', 2026, 'SECOND'),
        throwsA(
          isA<CourseRecommendationApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            CourseRecommendationFailureKind.unauthorized,
          ),
        ),
      );
    });

    test('maps errors and malformed bodies to recoverable failures', () async {
      for (final response in [
        http.Response('{"code":"STUDENT_NOT_FOUND"}', 404),
        http.Response('{"majors":"x"}', 200),
      ]) {
        await expectLater(
          api(response).getRecommendations('token', 2026, 'SECOND'),
          throwsA(
            isA<CourseRecommendationApiFailure>().having(
              (failure) => failure.kind,
              'kind',
              CourseRecommendationFailureKind.recoverable,
            ),
          ),
        );
      }
    });
  });

  group('CourseRecommendationController', () {
    test('loads the requested semester', () async {
      final api = FakeCourseRecommendationApi();
      final controller = buildTestRecommendationController(api);

      await controller.load(2026, 'SECOND');

      expect(api.requests, [(2026, 'SECOND')]);
      expect(controller.status, CourseRecommendationStatus.ready);
      expect(controller.recommendation, isNotNull);
    });

    test('requires a session and reports failures', () async {
      final signedOut = CourseRecommendationController(
        auth: FakeAuthGateway(),
        api: FakeCourseRecommendationApi(),
      );
      await signedOut.load(2026, 'FIRST');
      expect(signedOut.status, CourseRecommendationStatus.unauthorized);

      final api = FakeCourseRecommendationApi()
        ..handler = () async => throw const CourseRecommendationApiFailure(
          CourseRecommendationFailureKind.recoverable,
          '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.',
        );
      final controller = buildTestRecommendationController(api);
      await controller.load(2026, 'FIRST');
      expect(controller.status, CourseRecommendationStatus.failure);
      expect(controller.message, '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.');
    });
  });
}
