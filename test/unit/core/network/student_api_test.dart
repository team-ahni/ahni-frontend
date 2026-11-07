import 'dart:convert';

import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const profileJson = {
    'studentEntityId': 'student-id',
    'email': 'student@inha.edu',
    'nickname': '인하',
    'primaryDepartment': {'entityId': 'department-id', 'name': '소프트웨어융합공학과'},
    'doubleMajorDepartment': {'entityId': 'double-major-id', 'name': '금융투자학과'},
    'minorDepartment': {'entityId': 'minor-id', 'name': '산업경영학과'},
    'admissionYear': 2024,
    'enrollmentStatus': 'ENROLLED',
    'accountStatus': 'ACTIVE',
  };

  test(
    'GET /students/me sends the bearer token and parses the profile',
    () async {
      final api = HttpStudentApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/students/me');
          expect(request.headers['authorization'], 'Bearer jwt');
          return http.Response.bytes(
            utf8.encode(jsonEncode(profileJson)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final profile = await api.getProfile('jwt');

      expect(profile.email, 'student@inha.edu');
      expect(profile.primaryDepartment.name, '소프트웨어융합공학과');
      expect(profile.doubleMajorDepartment?.name, '금융투자학과');
      expect(profile.minorDepartment?.name, '산업경영학과');
    },
  );

  test('STUDENT_NOT_FOUND is exposed as the registration transition', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'STUDENT_NOT_FOUND',
            'message': 'internal detail',
          }),
          404,
        ),
      ),
    );

    expect(
      () => api.getProfile('jwt'),
      throwsA(
        isA<StudentApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          StudentApiFailureKind.studentNotFound,
        ),
      ),
    );
  });

  test('POST /students/me sends the contract payload and parses 201', () async {
    late Map<String, Object?> requestBody;
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/students/me');
        expect(request.headers['authorization'], 'Bearer jwt');
        expect(request.headers['content-type'], contains('application/json'));
        return http.Response.bytes(
          utf8.encode(jsonEncode(profileJson)),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final profile = await api.registerProfile(
      'jwt',
      const StudentRegistration(
        primaryDepartmentEntityId: 'department-id',
        doubleMajorDepartmentEntityId: 'double-major-id',
        minorDepartmentEntityId: 'minor-id',
        admissionYear: 2024,
        enrollmentStatus: 'ENROLLED',
        nickname: '인하',
      ),
    );

    expect(requestBody, {
      'primaryDepartmentEntityId': 'department-id',
      'doubleMajorDepartmentEntityId': 'double-major-id',
      'minorDepartmentEntityId': 'minor-id',
      'admissionYear': 2024,
      'enrollmentStatus': 'ENROLLED',
      'nickname': '인하',
    });
    expect(profile.studentEntityId, 'student-id');
  });

  test('registration omits unselected optional majors', () {
    const registration = StudentRegistration(
      primaryDepartmentEntityId: 'department-id',
      admissionYear: 2024,
      enrollmentStatus: 'ENROLLED',
    );

    expect(registration.toJson(), {
      'primaryDepartmentEntityId': 'department-id',
      'admissionYear': 2024,
      'enrollmentStatus': 'ENROLLED',
    });
  });

  test('PUT /students/me/majors sends the complete major selection', () async {
    late Map<String, Object?> requestBody;
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/students/me/majors');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response.bytes(
          utf8.encode(jsonEncode(profileJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final profile = await api.replaceMajors(
      'jwt',
      const StudentMajorUpdate(
        primaryDepartmentEntityId: 'department-id',
        minorDepartmentEntityId: 'minor-id',
      ),
    );

    expect(requestBody, {
      'primaryDepartmentEntityId': 'department-id',
      'minorDepartmentEntityId': 'minor-id',
    });
    expect(profile.minorDepartment?.entityId, 'minor-id');
  });

  test('duplicate major departments use safe Korean copy', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'DUPLICATE_MAJOR_DEPARTMENT',
            'message': 'internal detail',
          }),
          400,
        ),
      ),
    );

    expect(
      () => api.replaceMajors(
        'jwt',
        const StudentMajorUpdate(
          primaryDepartmentEntityId: 'same-id',
          minorDepartmentEntityId: 'same-id',
        ),
      ),
      throwsA(
        isA<StudentApiFailure>().having(
          (failure) => failure.userMessage,
          'userMessage',
          '같은 학과를 여러 전공으로 선택할 수 없어요.',
        ),
      ),
    );
  });

  test('stable registration errors use safe Korean copy', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'DEPARTMENT_NOT_FOUND',
            'message': 'database row was missing',
          }),
          404,
        ),
      ),
    );

    expect(
      () => api.registerProfile(
        'jwt',
        const StudentRegistration(
          primaryDepartmentEntityId: 'missing',
          admissionYear: 2024,
          enrollmentStatus: 'ENROLLED',
        ),
      ),
      throwsA(
        isA<StudentApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              StudentApiFailureKind.validation,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '학과 정보를 다시 선택해 주세요.',
            ),
      ),
    );
  });

  test('registered email conflict explains how to recover', () async {
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'STUDENT_EMAIL_ALREADY_REGISTERED',
            'message': 'internal detail',
          }),
          409,
        ),
      ),
    );

    expect(
      () => api.registerProfile(
        'jwt',
        const StudentRegistration(
          primaryDepartmentEntityId: 'department-id',
          admissionYear: 2024,
          enrollmentStatus: 'ENROLLED',
        ),
      ),
      throwsA(
        isA<StudentApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              StudentApiFailureKind.emailAlreadyRegistered,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '이 이메일로 등록된 학생 정보가 이미 있어요.\n'
                  '계정을 다시 만들었다면 기존 정보 연결을 요청해 주세요.',
            ),
      ),
    );
  });

  test('requests relinking with the bearer token and maps failures', () async {
    late http.Request sent;
    var status = 202;
    final api = HttpStudentApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        sent = request;
        return status == 202
            ? http.Response('{"status":"PENDING"}', 202)
            : http.Response(
                jsonEncode({
                  'code': 'STUDENT_NOT_FOUND',
                  'message': 'internal detail',
                }),
                status,
              );
      }),
    );

    await api.requestRelink('jwt');
    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/v1/students/me/relink-requests');
    expect(sent.headers['authorization'], 'Bearer jwt');

    status = 404;
    expect(
      () => api.requestRelink('jwt'),
      throwsA(
        isA<StudentApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          StudentApiFailureKind.studentNotFound,
        ),
      ),
    );
  });
}
