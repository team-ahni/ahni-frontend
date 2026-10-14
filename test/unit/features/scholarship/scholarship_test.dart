import 'dart:convert';

import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';
import 'package:ahni_mobile/features/scholarship/data/scholarship_api.dart';
import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/onboarding_fakes.dart';
import '../../../support/scholarship_fakes.dart';

Map<String, Object?> eligibilityJson({List<Object?>? scholarships}) => {
  'admissionYear': 2024,
  'department': {
    'entityId': '00000000-0000-0000-0000-000000000001',
    'name': '소프트웨어융합공학과',
  },
  'gpa': 3.2,
  'completedCredits': 9.0,
  'warningCount': 1,
  'scholarships':
      scholarships ??
      [
        {
          'criteriaEntityId': '00000000-0000-0000-0000-000000000501',
          'name': '성적우수장학금',
          'minGpa': 3.5,
          'minCredits': 12.0,
          'maxWarnings': 0,
          'gpaShortfall': 0.3,
          'creditShortfall': 3.0,
          'excessWarnings': 1,
          'met': false,
        },
        {
          'criteriaEntityId': '00000000-0000-0000-0000-000000000502',
          'name': '생활지원장학금',
          'minGpa': 2.0,
          'minCredits': 6.0,
          'maxWarnings': 1,
          'gpaShortfall': 0.0,
          'creditShortfall': 0.0,
          'excessWarnings': 0,
          'met': true,
        },
      ],
};

void main() {
  group('ScholarshipEligibility', () {
    test('parses the eligibility response and lists unmet conditions', () {
      final eligibility = ScholarshipEligibility.fromJson(eligibilityJson());

      expect(eligibility.departmentName, '소프트웨어융합공학과');
      expect(eligibility.warningCount, 1);
      expect(eligibility.results.first.shortfalls, [
        '평점 +0.30 필요',
        '이수학점 3학점 더 필요',
        '학사경고 허용 횟수를 1회 초과',
      ]);
      expect(eligibility.results.last.met, isTrue);
      expect(eligibility.results.last.shortfalls, isEmpty);
    });

    test('rejects negative or missing values', () {
      final json = eligibilityJson()..['gpa'] = -1;
      expect(
        () => ScholarshipEligibility.fromJson(json),
        throwsFormatException,
      );
      expect(
        () => ScholarshipEligibility.fromJson(
          eligibilityJson()..['warningCount'] = 1.5,
        ),
        throwsFormatException,
      );
    });
  });

  group('HttpScholarshipApi', () {
    HttpScholarshipApi api(http.Response response) => HttpScholarshipApi(
      baseUri: Uri.parse('https://api.example.test'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/scholarship-eligibility');
        expect(request.headers['authorization'], 'Bearer token');
        return response;
      }),
    );

    test('returns parsed eligibility for 200', () async {
      final result = await api(
        http.Response.bytes(utf8.encode(jsonEncode(eligibilityJson())), 200),
      ).getEligibility('token');

      expect(result.results, hasLength(2));
    });

    test('maps 401 to an authentication failure', () async {
      await expectLater(
        api(http.Response('', 401)).getEligibility('token'),
        throwsA(
          isA<ScholarshipApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ScholarshipFailureKind.unauthorized,
          ),
        ),
      );
    });

    test(
      'maps server errors and malformed bodies to recoverable failures',
      () async {
        for (final response in [
          http.Response('{"code":"STUDENT_NOT_FOUND"}', 404),
          http.Response('{"gpa":"x"}', 200),
        ]) {
          await expectLater(
            api(response).getEligibility('token'),
            throwsA(
              isA<ScholarshipApiFailure>().having(
                (failure) => failure.kind,
                'kind',
                ScholarshipFailureKind.recoverable,
              ),
            ),
          );
        }
      },
    );
  });

  group('ScholarshipController', () {
    test('loads eligibility for the signed-in student', () async {
      final api = FakeScholarshipApi()
        ..result = ScholarshipEligibility.fromJson(eligibilityJson());
      final controller = buildTestScholarshipController(api);

      await controller.load();

      expect(controller.status, ScholarshipStatus.ready);
      expect(controller.eligibility?.results, hasLength(2));
    });

    test('requires authentication without a session', () async {
      final controller = ScholarshipController(
        auth: FakeAuthGateway(),
        api: FakeScholarshipApi(),
      );

      await controller.load();

      expect(controller.status, ScholarshipStatus.unauthorized);
    });

    test('exposes a retryable failure message', () async {
      final api = FakeScholarshipApi()
        ..handler = (_) async => throw const ScholarshipApiFailure(
          ScholarshipFailureKind.recoverable,
          '장학 정보를 불러오지 못했어요. 다시 시도해 주세요.',
        );
      final controller = buildTestScholarshipController(api);

      await controller.load();

      expect(controller.status, ScholarshipStatus.failure);
      expect(controller.message, '장학 정보를 불러오지 못했어요. 다시 시도해 주세요.');
      expect(controller.eligibility, isNull);
    });

    test('reset clears the previous student data', () async {
      final controller = buildTestScholarshipController(
        FakeScholarshipApi()
          ..result = ScholarshipEligibility.fromJson(eligibilityJson()),
      );
      await controller.load();

      controller.reset();

      expect(controller.status, ScholarshipStatus.initial);
      expect(controller.eligibility, isNull);
    });
  });
}
