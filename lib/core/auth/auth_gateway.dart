import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.email});

  final String accessToken;
  final String email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.userMessage);

  final String userMessage;
}

abstract interface class AuthGateway {
  AuthSession? get currentSession;

  Stream<AuthSession> get signedInSessions;

  Stream<AuthSession> get passwordRecoverySessions;

  Future<AuthSession?> signIn(String email, String password);

  Future<AuthSession?> signUp(String email, String password);

  Future<void> resendSignUpConfirmation(String email);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updatePassword(String password);

  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Stream<AuthSession> get signedInSessions => _client.auth.onAuthStateChange
      .where(
        (state) =>
            state.event == AuthChangeEvent.signedIn && state.session != null,
      )
      .map((state) => _mapSession(state.session)!);

  @override
  Stream<AuthSession> get passwordRecoverySessions => _client
      .auth
      .onAuthStateChange
      .where(
        (state) =>
            state.event == AuthChangeEvent.passwordRecovery &&
            state.session != null,
      )
      .map((state) => _mapSession(state.session)!);

  @override
  Future<AuthSession?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _mapSession(response.session);
    } on AuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<AuthSession?> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'com.ahni.mobile://login-callback/',
      );
      return _mapSession(response.session);
    } on AuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<void> resendSignUpConfirmation(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.ahni.mobile://login-callback/',
      );
    } on AuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  static AuthSession? _mapSession(Session? session) {
    if (session == null) return null;
    return AuthSession(
      accessToken: session.accessToken,
      email: session.user.email ?? '',
    );
  }

  static String _safeAuthMessage(String? code) {
    return switch (code) {
      'invalid_credentials' => '이메일 또는 비밀번호를 확인해 주세요.',
      'email_not_confirmed' => '인증 메일의 링크를 먼저 확인해 주세요.',
      'user_already_exists' => '이미 가입된 이메일입니다. 로그인해 주세요.',
      'weak_password' => '비밀번호를 더 길고 안전하게 입력해 주세요.',
      'email_address_invalid' => '올바른 학교 이메일을 입력해 주세요.',
      'over_email_send_rate_limit' => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
      _ => '인증을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
    };
  }
}

class SecureSupabaseStorage extends LocalStorage {
  SecureSupabaseStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() {
    return _storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() {
    return _storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() {
    return _storage.delete(key: supabasePersistSessionKey);
  }
}
