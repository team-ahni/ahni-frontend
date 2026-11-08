import 'dart:convert';

import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final code in ['CURRICULUM_NOT_AVAILABLE', 'COURSE_NOT_IN_CURRICULUM']) {
    test(
      '$code gives curriculum feedback rather than a missing-student error',
      () async {
        final api = HttpGradeApi(
          baseUri: Uri.parse('https://api.ahni.test'),
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({'code': code}),
              code == 'CURRICULUM_NOT_AVAILABLE' ? 404 : 400,
            ),
          ),
        );
        expect(
          () => api.registerGrade('jwt', _registration),
          throwsA(
            isA<GradeApiFailure>()
                .having(
                  (failure) => failure.kind,
                  'kind',
                  GradeApiFailureKind.validation,
                )
                .having(
                  (failure) => failure.userMessage,
                  'message',
                  contains('연도'),
                ),
          ),
        );
      },
    );
  }
  test(
    'GET /grades sends the bearer token and parses complete records',
    () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/grades');
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'entityId': 'grade-id-1',
                  'course': {
                    'entityId': 'course-id-1',
                    'code': 'CSE101',
                    'name': '프로그래밍 기초',
                    'category': 'MAJOR',
                    'department': {
                      'entityId': 'department-id',
                      'name': '소프트웨어융합공학과',
                    },
                  },
                  'academicYear': 2025,
                  'term': 'SECOND',
                  'gradeCode': 'A_PLUS',
                  'gradePoint': 4.5,
                  'credit': 3.0,
                  'rpl': false,
                  'replacedGradeEntityId': 'grade-id-0',
                  'createdAt': '2026-09-15T01:00:00Z',
                  'updatedAt': '2026-09-15T02:00:00Z',
                },
                {
                  'entityId': 'grade-id-2',
                  'course': {
                    'entityId': 'course-id-2',
                    'code': 'RPL001',
                    'name': '선행학습 인정',
                    'category': 'ELECTIVE',
                    'department': null,
                  },
                  'academicYear': 2025,
                  'term': 'FIRST',
                  'gradeCode': null,
                  'gradePoint': null,
                  'credit': 2,
                  'rpl': true,
                  'replacedGradeEntityId': null,
                  'createdAt': '2026-09-14T01:00:00Z',
                  'updatedAt': '2026-09-14T01:00:00Z',
                },
              ]),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final records = await api.getGrades('jwt');

      expect(records, hasLength(2));
      expect(records.first.course.name, '프로그래밍 기초');
      expect(records.first.course.department?.name, '소프트웨어융합공학과');
      expect(records.first.term, AcademicTerm.second);
      expect(records.first.gradeCode, GradeCode.aPlus);
      expect(records.first.gradePoint, 4.5);
      expect(records.first.credit, 3.0);
      expect(records.first.replacedGradeEntityId, 'grade-id-0');
      expect(records.first.isRetake, isTrue);
      expect(records.last.course.department, isNull);
      expect(records.last.gradeCode, isNull);
      expect(records.last.gradePoint, isNull);
      expect(records.last.rpl, isTrue);
    },
  );

  test('GET /grades/summary parses the policy result', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/grades/summary');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response(
          jsonEncode({
            'gpa': 3.83,
            'completedCredits': 42.0,
            'gpaCredits': 36.0,
            'categories': [
              {
                'category': 'MAJOR',
                'gpa': 4.02,
                'completedCredits': 24.0,
                'gpaCredits': 21.0,
              },
            ],
          }),
          200,
        );
      }),
    );

    final summary = await api.getSummary('jwt');

    expect(summary.gpa, 3.83);
    expect(summary.completedCredits, 42);
    expect(summary.gpaCredits, 36);
    expect(summary.categories.single.category, CourseCategory.major);
    expect(summary.categories.single.gpa, 4.02);
  });

  test('malformed grade responses become a safe recoverable failure', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'entityId': 'grade-id'},
          ]),
          200,
        ),
      ),
    );

    expect(
      () => api.getGrades('jwt'),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.recoverable,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '성적 정보를 확인하지 못했어요. 다시 시도해 주세요.',
            ),
      ),
    );
  });

  test('expired authentication uses a stable sign-in message', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(
      () => api.getGrades('expired-jwt'),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.unauthorized,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '로그인이 만료됐어요. 다시 로그인해 주세요.',
            ),
      ),
    );
  });

  test(
    'POST /grades sends the registration and parses the created grade',
    () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/grades');
          expect(request.headers['authorization'], 'Bearer jwt');
          expect(request.headers['content-type'], 'application/json');
          expect(jsonDecode(request.body), {
            'courseEntityId': 'course-id-1',
            'academicYear': 2025,
            'term': 'SECOND',
            'gradeCode': 'A_PLUS',
            'credit': 3.0,
            'rpl': false,
            'replacedGradeEntityId': 'grade-id-0',
          });
          return http.Response(
            jsonEncode({
              'entityId': 'grade-id-1',
              'course': {
                'entityId': 'course-id-1',
                'code': 'CSE101',
                'name': '프로그래밍 기초',
                'category': 'MAJOR',
                'department': null,
              },
              'academicYear': 2025,
              'term': 'SECOND',
              'gradeCode': 'A_PLUS',
              'gradePoint': 4.5,
              'credit': 3.0,
              'rpl': false,
              'replacedGradeEntityId': 'grade-id-0',
              'createdAt': '2026-09-16T01:00:00Z',
              'updatedAt': '2026-09-16T01:00:00Z',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final grade = await api.registerGrade('jwt', _registration);

      expect(grade.entityId, 'grade-id-1');
      expect(grade.course.code, 'CSE101');
      expect(grade.gradeCode, GradeCode.aPlus);
      expect(grade.replacedGradeEntityId, 'grade-id-0');
    },
  );

  test('duplicate registrations use an actionable conflict message', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'code': 'GRADE_ALREADY_REGISTERED',
              'message': '해당 학기의 과목 성적이 이미 등록되어 있습니다.',
            }),
          ),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => api.registerGrade('jwt', _registration),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.conflict,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
            ),
      ),
    );
  });

  test(
    'PUT /grades/{id} sends editable values and parses the result',
    () async {
      final api = HttpGradeApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/grades/grade-id-1');
          expect(request.headers['authorization'], 'Bearer jwt');
          expect(jsonDecode(request.body), {
            'academicYear': 2024,
            'term': 'WINTER',
            'gradeCode': 'B_PLUS',
            'credit': 2.0,
            'rpl': false,
            'replacedGradeEntityId': 'grade-id-0',
          });
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'entityId': 'grade-id-1',
                'course': {
                  'entityId': 'course-id-1',
                  'code': 'CSE101',
                  'name': '프로그래밍 기초',
                  'category': 'MAJOR',
                  'department': null,
                },
                'academicYear': 2024,
                'term': 'WINTER',
                'gradeCode': 'B_PLUS',
                'gradePoint': 3.5,
                'credit': 2.0,
                'rpl': false,
                'replacedGradeEntityId': 'grade-id-0',
                'createdAt': '2026-09-16T01:00:00Z',
                'updatedAt': '2026-09-16T02:00:00Z',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final grade = await api.updateGrade('jwt', 'grade-id-1', _update);

      expect(grade.academicYear, 2024);
      expect(grade.term, AcademicTerm.winter);
      expect(grade.gradeCode, GradeCode.bPlus);
      expect(grade.credit, 2);
    },
  );

  test('DELETE /grades/{id} accepts an empty 204 response', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/grades/grade-id-1');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response('', 204);
      }),
    );

    await api.deleteGrade('jwt', 'grade-id-1');
  });

  test('missing grades use an actionable refresh message', () async {
    final api = HttpGradeApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'code': 'GRADE_NOT_FOUND',
              'message': '성적을 찾을 수 없습니다.',
            }),
          ),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => api.updateGrade('jwt', 'grade-id-1', _update),
      throwsA(
        isA<GradeApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              GradeApiFailureKind.notFound,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '성적 정보를 찾을 수 없어요. 목록을 새로고침해 주세요.',
            ),
      ),
    );
  });
}

const _registration = GradeRegistration(
  courseEntityId: 'course-id-1',
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.aPlus,
  credit: 3,
  rpl: false,
  replacedGradeEntityId: 'grade-id-0',
);

const _update = GradeUpdate(
  academicYear: 2024,
  term: AcademicTerm.winter,
  gradeCode: GradeCode.bPlus,
  credit: 2,
  rpl: false,
  replacedGradeEntityId: 'grade-id-0',
);
