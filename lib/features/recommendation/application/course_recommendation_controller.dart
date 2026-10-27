import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/recommendation/data/course_recommendation_api.dart';
import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';
import 'package:flutter/foundation.dart';

enum CourseRecommendationStatus {
  initial,
  loading,
  ready,
  failure,
  unauthorized,
}

class CourseRecommendationController extends ChangeNotifier {
  CourseRecommendationController({required this.auth, required this.api});
  final AuthGateway auth;
  final CourseRecommendationApi api;
  CourseRecommendationStatus status = CourseRecommendationStatus.initial;
  CourseRecommendation? recommendation;
  String? message;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load(int academicYear, String term) async {
    if (_disposed) return;
    final session = auth.currentSession;
    if (session == null) {
      recommendation = null;
      message = null;
      status = CourseRecommendationStatus.unauthorized;
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    status = CourseRecommendationStatus.loading;
    recommendation = null;
    message = null;
    notifyListeners();
    try {
      final result = await api.getRecommendations(
        session.accessToken,
        academicYear,
        term,
      );
      if (_disposed || generation != _generation) return;
      recommendation = result;
      status = CourseRecommendationStatus.ready;
    } on CourseRecommendationApiFailure catch (failure) {
      if (_disposed || generation != _generation) return;
      status = failure.kind == CourseRecommendationFailureKind.unauthorized
          ? CourseRecommendationStatus.unauthorized
          : CourseRecommendationStatus.failure;
      message = failure.message;
    } on Object catch (_) {
      if (_disposed || generation != _generation) return;
      status = CourseRecommendationStatus.failure;
      message = '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  void reset() {
    _generation++;
    recommendation = null;
    message = null;
    status = CourseRecommendationStatus.initial;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
