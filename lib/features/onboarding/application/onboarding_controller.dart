// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:flutter/foundation.dart';

sealed class OnboardingState {
  const OnboardingState();
}

class ProfileLoading extends OnboardingState {
  const ProfileLoading();
}

class AuthenticationRequired extends OnboardingState {
  const AuthenticationRequired({
    this.message,
    this.isSubmitting = false,
    this.isError = false,
  });

  final String? message;
  final bool isSubmitting;
  final bool isError;
}

class EmailVerificationPending extends OnboardingState {
  const EmailVerificationPending({
    required this.email,
    this.message,
    this.isSubmitting = false,
    this.isError = false,
  });

  final String email;
  final String? message;
  final bool isSubmitting;
  final bool isError;
}

class PasswordRecoveryRequired extends OnboardingState {
  const PasswordRecoveryRequired({
    this.message,
    this.isSubmitting = false,
    this.isError = false,
  });

  final String? message;
  final bool isSubmitting;
  final bool isError;
}

/// 다시 만든 계정이 기존 프로필과 이메일이 겹칠 때의 재연결 요청 단계.
enum RelinkStage { unavailable, available, submitting, requested }

class RegistrationRequired extends OnboardingState {
  const RegistrationRequired({
    required this.departments,
    this.message,
    this.isSubmitting = false,
    this.relinkStage = RelinkStage.unavailable,
  });

  final List<Department> departments;
  final String? message;
  final bool isSubmitting;
  final RelinkStage relinkStage;
}

class ProfileReady extends OnboardingState {
  const ProfileReady(
    this.profile, {
    this.message,
    this.isLoadingMajors = false,
  });

  final StudentProfile profile;
  final String? message;
  final bool isLoadingMajors;
}

class MajorEditing extends OnboardingState {
  const MajorEditing({
    required this.profile,
    required this.departments,
    this.message,
    this.isSubmitting = false,
  });

  final StudentProfile profile;
  final List<Department> departments;
  final String? message;
  final bool isSubmitting;
}

class RetryableFailure extends OnboardingState {
  const RetryableFailure(this.message);

  final String message;
}

class OnboardingController extends ChangeNotifier {
  OnboardingController({required AuthGateway auth, required StudentApi api})
    : _auth = auth,
      _api = api;

  final AuthGateway _auth;
  final StudentApi _api;
  OnboardingState _state = const ProfileLoading();
  StreamSubscription<AuthSession>? _signedInSubscription;
  StreamSubscription<AuthSession>? _passwordRecoverySubscription;
  bool _initialized = false;

  OnboardingState get state => _state;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _signedInSubscription = _auth.signedInSessions.listen(
      (session) => unawaited(_loadProfile(session)),
      onError: (Object _) {
        _setState(const RetryableFailure('이메일 인증 상태를 확인하지 못했어요. 다시 시도해 주세요.'));
      },
    );
    _passwordRecoverySubscription = _auth.passwordRecoverySessions.listen(
      (_) => _setState(const PasswordRecoveryRequired()),
      onError: (Object _) {
        _setState(
          const AuthenticationRequired(
            message: '비밀번호 재설정 링크를 확인하지 못했어요. 다시 시도해 주세요.',
            isError: true,
          ),
        );
      },
    );
    await _routeSession();
  }

  Future<void> retry() => _routeSession();

  void clearAuthenticationFeedback() {
    final current = _state;
    if (current is AuthenticationRequired && current.message != null) {
      _setState(const AuthenticationRequired());
    }
  }

  Future<void> signIn(String email, String password) async {
    _setState(const AuthenticationRequired(isSubmitting: true));
    try {
      final session = await _auth.signIn(email.trim(), password);
      if (session == null) {
        _setState(
          const AuthenticationRequired(
            message: '로그인을 완료하지 못했어요. 다시 시도해 주세요.',
            isError: true,
          ),
        );
        return;
      }
      await _loadProfile(session);
    } on AuthFailure catch (failure) {
      _setState(
        AuthenticationRequired(message: failure.userMessage, isError: true),
      );
    } on Object catch (_) {
      _setState(
        const AuthenticationRequired(
          message: '인증을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
          isError: true,
        ),
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    _setState(const AuthenticationRequired(isSubmitting: true));
    try {
      final normalizedEmail = email.trim();
      final session = await _auth.signUp(normalizedEmail, password);
      if (session == null) {
        _setState(EmailVerificationPending(email: normalizedEmail));
        return;
      }
      await _loadProfile(session);
    } on AuthFailure catch (failure) {
      _setState(
        AuthenticationRequired(message: failure.userMessage, isError: true),
      );
    } on Object catch (_) {
      _setState(
        const AuthenticationRequired(
          message: '계정을 만들지 못했어요. 잠시 후 다시 시도해 주세요.',
          isError: true,
        ),
      );
    }
  }

  Future<void> resendConfirmation() async {
    final current = _state;
    if (current is! EmailVerificationPending || current.isSubmitting) return;
    _setState(
      EmailVerificationPending(email: current.email, isSubmitting: true),
    );
    try {
      await _auth.resendSignUpConfirmation(current.email);
      _completeResend(current.email, '인증 메일을 다시 보냈어요.');
    } on AuthFailure catch (failure) {
      _completeResend(current.email, failure.userMessage, isError: true);
    } on Object catch (_) {
      _completeResend(
        current.email,
        '인증 메일을 다시 보내지 못했어요. 잠시 후 다시 시도해 주세요.',
        isError: true,
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    _setState(const AuthenticationRequired(isSubmitting: true));
    try {
      await _auth.sendPasswordResetEmail(normalizedEmail);
      _setState(
        const AuthenticationRequired(
          message: '비밀번호 재설정 메일을 보냈어요. 메일함을 확인해 주세요.',
        ),
      );
    } on AuthFailure catch (failure) {
      _setState(
        AuthenticationRequired(message: failure.userMessage, isError: true),
      );
    } on Object catch (_) {
      _setState(
        const AuthenticationRequired(
          message: '비밀번호 재설정 메일을 보내지 못했어요. 잠시 후 다시 시도해 주세요.',
          isError: true,
        ),
      );
    }
  }

  Future<void> updatePassword(String password) async {
    final current = _state;
    if (current is! PasswordRecoveryRequired || current.isSubmitting) return;
    _setState(const PasswordRecoveryRequired(isSubmitting: true));
    try {
      await _auth.updatePassword(password);
      await _auth.signOut();
      _setState(
        const AuthenticationRequired(message: '비밀번호를 변경했어요. 새 비밀번호로 로그인해 주세요.'),
      );
    } on AuthFailure catch (failure) {
      _setState(
        PasswordRecoveryRequired(message: failure.userMessage, isError: true),
      );
    } on Object catch (_) {
      _setState(
        const PasswordRecoveryRequired(
          message: '비밀번호를 변경하지 못했어요. 잠시 후 다시 시도해 주세요.',
          isError: true,
        ),
      );
    }
  }

  Future<void> cancelPasswordRecovery() async {
    await _auth.signOut();
    _setState(const AuthenticationRequired());
  }

  Future<void> registerProfile(StudentRegistration registration) async {
    final previous = _state;
    if (previous is! RegistrationRequired) return;
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const AuthenticationRequired());
      return;
    }
    _setState(
      RegistrationRequired(
        departments: previous.departments,
        isSubmitting: true,
      ),
    );
    try {
      final profile = await _api.registerProfile(
        session.accessToken,
        registration,
      );
      _setState(ProfileReady(profile));
    } on StudentApiFailure catch (failure) {
      if (failure.kind == StudentApiFailureKind.unauthorized) {
        await _returnToAuthentication();
        return;
      }
      _setState(
        RegistrationRequired(
          departments: previous.departments,
          message: failure.userMessage,
          relinkStage:
              failure.kind == StudentApiFailureKind.emailAlreadyRegistered
              ? RelinkStage.available
              : RelinkStage.unavailable,
        ),
      );
    } on Object catch (_) {
      _setState(
        RegistrationRequired(
          departments: previous.departments,
          message: '학생 정보를 등록하지 못했어요. 다시 시도해 주세요.',
        ),
      );
    }
  }

  Future<void> requestRelink() async {
    final previous = _state;
    if (previous is! RegistrationRequired ||
        previous.relinkStage != RelinkStage.available) {
      return;
    }
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const AuthenticationRequired());
      return;
    }
    _setState(
      RegistrationRequired(
        departments: previous.departments,
        message: previous.message,
        relinkStage: RelinkStage.submitting,
      ),
    );
    try {
      await _api.requestRelink(session.accessToken);
      _setState(
        RegistrationRequired(
          departments: previous.departments,
          relinkStage: RelinkStage.requested,
        ),
      );
    } on StudentApiFailure catch (failure) {
      if (failure.kind == StudentApiFailureKind.unauthorized) {
        await _returnToAuthentication();
        return;
      }
      _setState(
        RegistrationRequired(
          departments: previous.departments,
          message: '기존 정보 연결을 요청하지 못했어요. 다시 시도해 주세요.',
          relinkStage: RelinkStage.available,
        ),
      );
    } on Object catch (_) {
      _setState(
        RegistrationRequired(
          departments: previous.departments,
          message: '기존 정보 연결을 요청하지 못했어요. 다시 시도해 주세요.',
          relinkStage: RelinkStage.available,
        ),
      );
    }
  }

  Future<void> startMajorEditing() async {
    final previous = _state;
    if (previous is! ProfileReady || previous.isLoadingMajors) return;
    _setState(ProfileReady(previous.profile, isLoadingMajors: true));
    try {
      final departments = await _api.getDepartments();
      if (departments.isEmpty) {
        _setState(
          ProfileReady(
            previous.profile,
            message: '학과 목록을 불러오지 못했어요. 다시 시도해 주세요.',
          ),
        );
        return;
      }
      _setState(
        MajorEditing(profile: previous.profile, departments: departments),
      );
    } on StudentApiFailure catch (failure) {
      _setState(ProfileReady(previous.profile, message: failure.userMessage));
    } on Object catch (_) {
      _setState(
        ProfileReady(
          previous.profile,
          message: '학과 목록을 불러오지 못했어요. 다시 시도해 주세요.',
        ),
      );
    }
  }

  Future<void> updateMajors(StudentMajorUpdate update) async {
    final previous = _state;
    if (previous is! MajorEditing || previous.isSubmitting) return;
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const AuthenticationRequired());
      return;
    }
    _setState(
      MajorEditing(
        profile: previous.profile,
        departments: previous.departments,
        isSubmitting: true,
      ),
    );
    try {
      final profile = await _api.replaceMajors(session.accessToken, update);
      _setState(ProfileReady(profile));
    } on StudentApiFailure catch (failure) {
      if (failure.kind == StudentApiFailureKind.unauthorized) {
        await _returnToAuthentication();
        return;
      }
      _setState(
        MajorEditing(
          profile: previous.profile,
          departments: previous.departments,
          message: failure.userMessage,
        ),
      );
    } on Object catch (_) {
      _setState(
        MajorEditing(
          profile: previous.profile,
          departments: previous.departments,
          message: '전공 정보를 저장하지 못했어요. 다시 시도해 주세요.',
        ),
      );
    }
  }

  void cancelMajorEditing() {
    final current = _state;
    if (current is MajorEditing && !current.isSubmitting) {
      _setState(ProfileReady(current.profile));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _setState(const AuthenticationRequired());
  }

  void returnToAuthentication() {
    _setState(const AuthenticationRequired());
  }

  Future<void> _routeSession() async {
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const AuthenticationRequired());
      return;
    }
    await _loadProfile(session);
  }

  Future<void> _loadProfile(AuthSession session) async {
    _setState(const ProfileLoading());
    try {
      _setState(ProfileReady(await _api.getProfile(session.accessToken)));
    } on StudentApiFailure catch (failure) {
      switch (failure.kind) {
        case StudentApiFailureKind.studentNotFound:
          await _loadRegistration();
          return;
        case StudentApiFailureKind.unauthorized:
          await _returnToAuthentication();
          return;
        case StudentApiFailureKind.emailAlreadyRegistered:
        case StudentApiFailureKind.validation:
        case StudentApiFailureKind.recoverable:
          _setState(RetryableFailure(failure.userMessage));
          return;
      }
    } on Object catch (_) {
      _setState(const RetryableFailure('학생 정보를 불러오지 못했어요.\n다시 시도해 주세요.'));
    }
  }

  Future<void> _loadRegistration() async {
    try {
      final departments = await _api.getDepartments();
      if (departments.isEmpty) {
        _setState(const RetryableFailure('학과 목록을 불러오지 못했어요.\n다시 시도해 주세요.'));
        return;
      }
      _setState(RegistrationRequired(departments: departments));
    } on StudentApiFailure catch (failure) {
      _setState(RetryableFailure(failure.userMessage));
    } on Object catch (_) {
      _setState(const RetryableFailure('학과 목록을 불러오지 못했어요.\n다시 시도해 주세요.'));
    }
  }

  Future<void> _returnToAuthentication() async {
    await _auth.signOut();
    _setState(
      const AuthenticationRequired(
        message: '로그인이 만료됐어요. 다시 로그인해 주세요.',
        isError: true,
      ),
    );
  }

  void _completeResend(String email, String message, {bool isError = false}) {
    final current = _state;
    if (current is! EmailVerificationPending || current.email != email) return;
    _setState(
      EmailVerificationPending(
        email: email,
        message: message,
        isError: isError,
      ),
    );
  }

  void _setState(OnboardingState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    final subscription = _signedInSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    final passwordRecoverySubscription = _passwordRecoverySubscription;
    if (passwordRecoverySubscription != null) {
      unawaited(passwordRecoverySubscription.cancel());
    }
    super.dispose();
  }
}
