import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/scholarship/data/scholarship_api.dart';
import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';
import 'package:flutter/foundation.dart';

enum ScholarshipStatus { initial, loading, ready, failure, unauthorized }

class ScholarshipController extends ChangeNotifier {
  ScholarshipController({required this.auth, required this.api});
  final AuthGateway auth;
  final ScholarshipApi api;
  ScholarshipStatus status = ScholarshipStatus.initial;
  ScholarshipEligibility? eligibility;
  String? message;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || status == ScholarshipStatus.loading) return;
    final session = auth.currentSession;
    if (session == null) {
      eligibility = null;
      message = null;
      status = ScholarshipStatus.unauthorized;
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    status = ScholarshipStatus.loading;
    eligibility = null;
    message = null;
    notifyListeners();
    try {
      final result = await api.getEligibility(session.accessToken);
      if (_disposed || generation != _generation) return;
      eligibility = result;
      status = ScholarshipStatus.ready;
    } on ScholarshipApiFailure catch (failure) {
      if (_disposed || generation != _generation) return;
      status = failure.kind == ScholarshipFailureKind.unauthorized
          ? ScholarshipStatus.unauthorized
          : ScholarshipStatus.failure;
      message = failure.message;
    } on Object catch (_) {
      if (_disposed || generation != _generation) return;
      status = ScholarshipStatus.failure;
      message = '장학 정보를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  void reset() {
    _generation++;
    eligibility = null;
    message = null;
    status = ScholarshipStatus.initial;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
