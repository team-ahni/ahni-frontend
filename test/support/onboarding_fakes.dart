import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/core/network/student_api.dart';

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.currentSession});

  final _signedInSessions = StreamController<AuthSession>.broadcast(sync: true);
  final _passwordRecoverySessions = StreamController<AuthSession>.broadcast(
    sync: true,
  );

  @override
  AuthSession? currentSession;

  AuthSession? signInResult;
  AuthSession? signUpResult;
  Object? signInError;
  Object? signUpError;
  Object? resendError;
  Object? passwordResetError;
  Object? updatePasswordError;
  Future<void> Function(String email)? resendHandler;
  String? lastResendEmail;
  String? lastPasswordResetEmail;
  String? lastUpdatedPassword;
  var signOutCalls = 0;

  @override
  Stream<AuthSession> get signedInSessions => _signedInSessions.stream;

  @override
  Stream<AuthSession> get passwordRecoverySessions =>
      _passwordRecoverySessions.stream;

  void emitSignedIn(AuthSession session) {
    currentSession = session;
    _signedInSessions.add(session);
  }

  void emitPasswordRecovery(AuthSession session) {
    currentSession = session;
    _passwordRecoverySessions.add(session);
  }

  Future<void> dispose() async {
    await _signedInSessions.close();
    await _passwordRecoverySessions.close();
  }

  @override
  Future<AuthSession?> signIn(String email, String password) async {
    if (signInError case final error?) throw error;
    return currentSession = signInResult;
  }

  @override
  Future<AuthSession?> signUp(String email, String password) async {
    if (signUpError case final error?) throw error;
    return currentSession = signUpResult;
  }

  @override
  Future<void> resendSignUpConfirmation(String email) async {
    lastResendEmail = email;
    if (resendError case final error?) throw error;
    await resendHandler?.call(email);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastPasswordResetEmail = email;
    if (passwordResetError case final error?) throw error;
  }

  @override
  Future<void> updatePassword(String password) async {
    lastUpdatedPassword = password;
    if (updatePasswordError case final error?) throw error;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentSession = null;
  }
}

class FakeStudentApi implements StudentApi {
  Future<StudentProfile> Function(String accessToken)? getProfileHandler;
  Future<List<Department>> Function()? getDepartmentsHandler;
  Future<StudentProfile> Function(
    String accessToken,
    StudentRegistration registration,
  )?
  registerProfileHandler;
  Future<StudentProfile> Function(
    String accessToken,
    StudentMajorUpdate update,
  )?
  replaceMajorsHandler;

  Future<void> Function(String accessToken)? requestRelinkHandler;
  int relinkRequests = 0;

  StudentRegistration? lastRegistration;
  StudentMajorUpdate? lastMajorUpdate;

  @override
  Future<List<Department>> getDepartments() {
    return getDepartmentsHandler?.call() ?? Future.value(const []);
  }

  @override
  Future<StudentProfile> getProfile(String accessToken) {
    return getProfileHandler?.call(accessToken) ??
        Future.error(
          const StudentApiFailure(
            StudentApiFailureKind.studentNotFound,
            '학생 정보를 등록해 주세요.',
          ),
        );
  }

  @override
  Future<StudentProfile> registerProfile(
    String accessToken,
    StudentRegistration registration,
  ) {
    lastRegistration = registration;
    final handler = registerProfileHandler;
    if (handler == null) throw StateError('registerProfileHandler is required');
    return handler(accessToken, registration);
  }

  @override
  Future<void> requestRelink(String accessToken) {
    relinkRequests++;
    return requestRelinkHandler?.call(accessToken) ?? Future.value();
  }

  @override
  Future<StudentProfile> replaceMajors(
    String accessToken,
    StudentMajorUpdate update,
  ) {
    lastMajorUpdate = update;
    final handler = replaceMajorsHandler;
    if (handler == null) throw StateError('replaceMajorsHandler is required');
    return handler(accessToken, update);
  }
}

const testSession = AuthSession(
  accessToken: 'test-jwt',
  email: 'student@inha.edu',
);

const testDepartment = Department(
  entityId: '00000000-0000-0000-0000-000000000001',
  name: '소프트웨어융합공학과',
);

const testDoubleMajorDepartment = Department(
  entityId: '00000000-0000-0000-0000-000000000002',
  name: '금융투자학과',
);

const testMinorDepartment = Department(
  entityId: '00000000-0000-0000-0000-000000000003',
  name: '산업경영학과',
);

const testProfile = StudentProfile(
  studentEntityId: '00000000-0000-0000-0000-000000000020',
  email: 'student@inha.edu',
  nickname: '인하',
  primaryDepartment: testDepartment,
  admissionYear: 2024,
  enrollmentStatus: 'ENROLLED',
  accountStatus: 'ACTIVE',
);

const testProfileWithMajors = StudentProfile(
  studentEntityId: '00000000-0000-0000-0000-000000000020',
  email: 'student@inha.edu',
  nickname: '인하',
  primaryDepartment: testDepartment,
  doubleMajorDepartment: testDoubleMajorDepartment,
  minorDepartment: testMinorDepartment,
  admissionYear: 2024,
  enrollmentStatus: 'ENROLLED',
  accountStatus: 'ACTIVE',
);
