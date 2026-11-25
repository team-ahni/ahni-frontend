import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/data/graduation_api.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/graduation_fakes.dart';
import '../../support/onboarding_fakes.dart';

Map<String, Object?> policy() => {
  'entityId': 'policy',
  'admissionYear': 2024,
  'majorType': 'PRIMARY',
  'department': {'entityId': 'dept', 'name': '소프트웨어융합공학과'},
  'sourceTitle': '학과 안내',
  'sourceUrl': null,
  'requiredCourses': [
    {
      'entityId': 'assignment',
      'category': 'MAJOR_REQUIRED',
      'course': {'entityId': 'course', 'code': 'CSE101', 'name': '프로그래밍'},
    },
  ],
};
Map<String, Object?> progress() => {
  'requirementEntityId': 'policy',
  'admissionYear': 2024,
  'majorType': 'PRIMARY',
  'department': {'entityId': 'dept', 'name': '소프트웨어융합공학과'},
  'requirementsMet': false,
  'requiredCourses': [
    {
      'entityId': 'assignment',
      'category': 'MAJOR_REQUIRED',
      'course': {'entityId': 'course', 'code': 'CSE101', 'name': '프로그래밍'},
      'completed': false,
    },
  ],
  'credits': {
    for (final key in ['total', 'department', 'general'])
      key: {'required': 30, 'completed': 3, 'remaining': 27, 'met': false},
  },
};

void main() {
  test(
    'foundation is separate and incomplete rules cannot report completion',
    () {
      final p = policy()..['evaluationComplete'] = false;
      final result = progress()..['requirementsMet'] = true;
      final credits = result['credits']! as Map<String, Object?>;
      credits['foundation'] = {
        'required': 15,
        'completed': 3,
        'remaining': 12,
        'met': false,
      };
      final overview = GraduationOverview.fromJson(p, result);
      expect(overview.foundation.required, 15);
      expect(overview.foundation.remaining, 12);
      expect(overview.evaluationComplete, isFalse);
      expect(overview.requirementsMet, isFalse);
      expect(overview.creditsMet, isFalse);
    },
  );

  test(
    'joins policies by identity and sends bearer to both endpoints',
    () async {
      final paths = <String>[];
      final api = HttpGraduationApi(
        baseUri: Uri.parse('http://localhost:8080'),
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer token');
          paths.add(request.url.path);
          return http.Response(
            jsonEncode([
              request.url.path.endsWith('progress') ? progress() : policy(),
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await api.getOverview('token');
      expect(paths.toSet(), {
        '/api/v1/graduation-progress',
        '/api/v1/graduation-requirements',
      });
      expect(result.single.total.remaining, 27);
      expect(result.single.creditsMet, isFalse);
      expect(result.single.sourceTitle, '학과 안내');
      expect(result.single.requiredCourses.single.completed, isFalse);
      expect(result.single.requirementsMet, isFalse);
    },
  );
  test('mismatched major and invalid credits are rejected', () {
    expect(
      () => GraduationOverview.fromJson(
        policy(),
        progress()..['majorType'] = 'MINOR',
      ),
      throwsFormatException,
    );
    expect(
      () => CreditProgress.fromJson({
        'required': -1,
        'completed': 0,
        'remaining': 0,
        'met': false,
      }),
      throwsFormatException,
    );
  });
  test('missing policy is not reported as network failure', () async {
    final api = HttpGraduationApi(
      baseUri: Uri.parse('http://localhost'),
      client: MockClient(
        (_) async =>
            http.Response('{"code":"GRADUATION_REQUIREMENT_NOT_FOUND"}', 404),
      ),
    );
    await expectLater(
      api.getOverview('token'),
      throwsA(
        isA<GraduationApiFailure>().having(
          (e) => e.kind,
          'kind',
          GraduationFailureKind.policyMissing,
        ),
      ),
    );
  });
  test('malformed and unauthorized responses are typed failures', () async {
    for (final status in [200, 401]) {
      final api = HttpGraduationApi(
        baseUri: Uri.parse('http://localhost'),
        client: MockClient((_) async => http.Response('invalid', status)),
      );
      await expectLater(
        api.getOverview('token'),
        throwsA(
          isA<GraduationApiFailure>().having(
            (e) => e.kind,
            'kind',
            status == 401
                ? GraduationFailureKind.unauthorized
                : GraduationFailureKind.recoverable,
          ),
        ),
      );
    }
  });
  test(
    'reset discards an in-flight response from a previous student',
    () async {
      final pending = Completer<List<GraduationOverview>>();
      final controller = GraduationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: FakeGraduationApi()..handler = (_) => pending.future,
      );
      final load = controller.load();
      expect(controller.status, GraduationStatus.loading);
      controller.reset();
      pending.complete([GraduationOverview.fromJson(policy(), progress())]);
      await load;
      expect(controller.status, GraduationStatus.initial);
      expect(controller.overview, isEmpty);
      controller.dispose();
    },
  );
  test('retry reloads after a recoverable failure', () async {
    final api = FakeGraduationApi()
      ..handler = (_) async => throw const GraduationApiFailure(
        GraduationFailureKind.recoverable,
        '연결 오류',
      );
    final controller = GraduationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
    );
    await controller.load();
    expect(controller.message, '연결 오류');
    api.handler = (_) async => [
      GraduationOverview.fromJson(policy(), progress()),
    ];
    await controller.load();
    expect(controller.status, GraduationStatus.ready);
    expect(controller.message, isNull);
    controller.dispose();
  });
}
