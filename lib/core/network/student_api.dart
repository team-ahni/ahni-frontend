// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Department {
  const Department({required this.entityId, required this.name});

  factory Department.fromJson(Map<String, Object?> json) {
    return Department(
      entityId: json['entityId']! as String,
      name: json['name']! as String,
    );
  }

  final String entityId;
  final String name;
}

class StudentProfile {
  const StudentProfile({
    required this.studentEntityId,
    required this.email,
    required this.nickname,
    required this.primaryDepartment,
    this.doubleMajorDepartment,
    this.minorDepartment,
    required this.admissionYear,
    required this.enrollmentStatus,
    required this.accountStatus,
  });

  factory StudentProfile.fromJson(Map<String, Object?> json) {
    return StudentProfile(
      studentEntityId: json['studentEntityId']! as String,
      email: json['email']! as String,
      nickname: json['nickname'] as String?,
      primaryDepartment: Department.fromJson(
        json['primaryDepartment']! as Map<String, Object?>,
      ),
      doubleMajorDepartment: _optionalDepartment(json['doubleMajorDepartment']),
      minorDepartment: _optionalDepartment(json['minorDepartment']),
      admissionYear: json['admissionYear']! as int,
      enrollmentStatus: json['enrollmentStatus']! as String,
      accountStatus: json['accountStatus']! as String,
    );
  }

  final String studentEntityId;
  final String email;
  final String? nickname;
  final Department primaryDepartment;
  final Department? doubleMajorDepartment;
  final Department? minorDepartment;
  final int admissionYear;
  final String enrollmentStatus;
  final String accountStatus;

  static Department? _optionalDepartment(Object? value) {
    return value == null
        ? null
        : Department.fromJson(value as Map<String, Object?>);
  }
}

class StudentRegistration {
  const StudentRegistration({
    required this.primaryDepartmentEntityId,
    this.doubleMajorDepartmentEntityId,
    this.minorDepartmentEntityId,
    required this.admissionYear,
    required this.enrollmentStatus,
    this.nickname,
  });

  final String primaryDepartmentEntityId;
  final String? doubleMajorDepartmentEntityId;
  final String? minorDepartmentEntityId;
  final int admissionYear;
  final String enrollmentStatus;
  final String? nickname;

  Map<String, Object> toJson() {
    return {
      'primaryDepartmentEntityId': primaryDepartmentEntityId,
      'doubleMajorDepartmentEntityId': ?doubleMajorDepartmentEntityId,
      'minorDepartmentEntityId': ?minorDepartmentEntityId,
      'admissionYear': admissionYear,
      'enrollmentStatus': enrollmentStatus,
      if (nickname case final value? when value.trim().isNotEmpty)
        'nickname': value.trim(),
    };
  }
}

class StudentMajorUpdate {
  const StudentMajorUpdate({
    required this.primaryDepartmentEntityId,
    this.doubleMajorDepartmentEntityId,
    this.minorDepartmentEntityId,
  });

  final String primaryDepartmentEntityId;
  final String? doubleMajorDepartmentEntityId;
  final String? minorDepartmentEntityId;

  Map<String, Object> toJson() {
    return {
      'primaryDepartmentEntityId': primaryDepartmentEntityId,
      'doubleMajorDepartmentEntityId': ?doubleMajorDepartmentEntityId,
      'minorDepartmentEntityId': ?minorDepartmentEntityId,
    };
  }
}

enum StudentApiFailureKind {
  studentNotFound,
  emailAlreadyRegistered,
  unauthorized,
  validation,
  recoverable,
}

class StudentApiFailure implements Exception {
  const StudentApiFailure(this.kind, this.userMessage);

  final StudentApiFailureKind kind;
  final String userMessage;
}

abstract interface class StudentApi {
  Future<StudentProfile> getProfile(String accessToken);

  Future<List<Department>> getDepartments();

  Future<StudentProfile> registerProfile(
    String accessToken,
    StudentRegistration registration,
  );

  Future<StudentProfile> replaceMajors(
    String accessToken,
    StudentMajorUpdate update,
  );

  /// 같은 이메일의 기존 프로필을 이 계정에 연결해 달라고 요청한다. 관리자가 승인해야 연결된다.
  Future<void> requestRelink(String accessToken);
}

class HttpStudentApi implements StudentApi {
  HttpStudentApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<StudentProfile> getProfile(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/students/me'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    return _decodeProfile(response);
  }

  @override
  Future<List<Department>> getDepartments() async {
    final response = await _request(
      () => _client.get(baseUri.resolve('/api/v1/departments')),
    );
    if (response.statusCode != 200) throw _failure(response);
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map((item) => Department.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<StudentProfile> registerProfile(
    String accessToken,
    StudentRegistration registration,
  ) async {
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/students/me'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(registration.toJson()),
      ),
    );
    if (response.statusCode != 201) throw _failure(response);
    return _decodeProfile(response);
  }

  @override
  Future<StudentProfile> replaceMajors(
    String accessToken,
    StudentMajorUpdate update,
  ) async {
    final response = await _request(
      () => _client.put(
        baseUri.resolve('/api/v1/students/me/majors'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(update.toJson()),
      ),
    );
    if (response.statusCode != 200) throw _failure(response);
    return _decodeProfile(response);
  }

  @override
  Future<void> requestRelink(String accessToken) async {
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/students/me/relink-requests'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 202) throw _failure(response);
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const StudentApiFailure(
        StudentApiFailureKind.recoverable,
        '서버에 연결하지 못했어요.\n네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  StudentProfile _decodeProfile(http.Response response) {
    try {
      return StudentProfile.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  StudentApiFailure _failure(http.Response response) {
    final code = _errorCode(response);
    if (response.statusCode == 401) {
      return const StudentApiFailure(
        StudentApiFailureKind.unauthorized,
        '로그인이 만료됐어요. 다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404 && code == 'STUDENT_NOT_FOUND') {
      return const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      );
    }
    if (response.statusCode == 409 &&
        code == 'STUDENT_EMAIL_ALREADY_REGISTERED') {
      return const StudentApiFailure(
        StudentApiFailureKind.emailAlreadyRegistered,
        '이 이메일로 등록된 학생 정보가 이미 있어요.\n'
        '계정을 다시 만들었다면 기존 정보 연결을 요청해 주세요.',
      );
    }
    if (response.statusCode >= 500) {
      return const StudentApiFailure(
        StudentApiFailureKind.recoverable,
        '서버 응답이 지연되고 있어요.\n잠시 후 다시 시도해 주세요.',
      );
    }
    return StudentApiFailure(StudentApiFailureKind.validation, switch (code) {
      'DEPARTMENT_NOT_FOUND' => '학과 정보를 다시 선택해 주세요.',
      'STUDENT_ALREADY_REGISTERED' => '이미 등록된 학생입니다. 다시 불러와 주세요.',
      'INVALID_ENROLLMENT_STATUS' => '재학 또는 휴학 상태를 선택해 주세요.',
      'DUPLICATE_MAJOR_DEPARTMENT' => '같은 학과를 여러 전공으로 선택할 수 없어요.',
      _ => '입력한 정보를 확인해 주세요.',
    });
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

  static const _malformedResponse = StudentApiFailure(
    StudentApiFailureKind.recoverable,
    '서버 응답을 확인하지 못했어요.\n다시 시도해 주세요.',
  );
}
