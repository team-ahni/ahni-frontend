import 'dart:convert';

import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'OCR catalog lookup uses course without semester or lecture filters',
    () async {
      final api = HttpCourseApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/courses');
          expect(request.url.queryParameters, isEmpty);
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response(
            jsonEncode([
              {
                'entityId': 'catalog-1',
                'code': 'ABC1001',
                'name': '과거 학기 과목',
                'credit': 3.0,
                'category': 'MAJOR',
                'department': null,
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await api.getCatalog('jwt');
      expect(result.single.name, '과거 학기 과목');
      expect(result.single.professorNames, isEmpty);
    },
  );

  test(
    'GET /lectures/courses sends the selected year, term and bearer token',
    () async {
      final api = HttpCourseApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/lectures/courses');
          expect(request.url.queryParameters['academicYear'], '2024');
          expect(request.url.queryParameters['term'], 'FIRST');
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'entityId': 'course-id-1',
                  'code': 'CSE101',
                  'name': '프로그래밍 기초',
                  'credit': 3.0,
                  'category': 'MAJOR',
                  'professorNames': ['김교수', '이교수'],
                  'department': {
                    'entityId': 'department-id',
                    'name': '소프트웨어융합공학과',
                  },
                },
                {
                  'entityId': 'course-id-2',
                  'code': 'GE101',
                  'name': '대학 글쓰기',
                  'credit': 2,
                  'category': 'GENERAL_EDUCATION',
                  'department': null,
                },
              ]),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final courses = await api.getCourses(
        'jwt',
        academicYear: 2024,
        term: AcademicTerm.first,
      );

      expect(courses, hasLength(2));
      expect(courses.first.entityId, 'course-id-1');
      expect(courses.first.code, 'CSE101');
      expect(courses.first.name, '프로그래밍 기초');
      expect(courses.first.credit, 3.0);
      expect(courses.first.professorNames, ['김교수', '이교수']);
      expect(courses.last.professorNames, isEmpty);
      expect(courses.first.category, CourseCategory.major);
      expect(courses.first.department?.name, '소프트웨어융합공학과');
      expect(courses.last.category, CourseCategory.generalEducation);
      expect(courses.last.department, isNull);
    },
  );

  test('malformed course responses become a recoverable failure', () async {
    final api = HttpCourseApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'entityId': 'course-id'},
          ]),
          200,
        ),
      ),
    );

    expect(
      () => api.getCourses('jwt', academicYear: 2024, term: AcademicTerm.first),
      throwsA(
        isA<CourseApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              CourseApiFailureKind.recoverable,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '과목 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
            ),
      ),
    );
  });

  test('expired authentication uses a stable sign-in message', () async {
    final api = HttpCourseApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    expect(
      () => api.getCourses(
        'expired-jwt',
        academicYear: 2024,
        term: AcademicTerm.first,
      ),
      throwsA(
        isA<CourseApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              CourseApiFailureKind.unauthorized,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '로그인이 만료되었습니다. 다시 로그인해 주세요.',
            ),
      ),
    );
  });
}
