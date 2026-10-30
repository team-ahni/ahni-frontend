// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/application/grade_ocr_import_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_ocr_api.dart';

import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/foundation.dart';

sealed class GradeRegistrationState {
  const GradeRegistrationState();
}

class GradeRegistrationIdle extends GradeRegistrationState {
  const GradeRegistrationIdle();
}

class GradeRegistrationSubmitting extends GradeRegistrationState {
  const GradeRegistrationSubmitting();
}

class GradeRegistrationSuccess extends GradeRegistrationState {
  const GradeRegistrationSuccess(this.grade);

  final GradeRecord grade;
}

class GradeRegistrationFailure extends GradeRegistrationState {
  const GradeRegistrationFailure(this.message);

  final String message;
}

class GradeRegistrationAuthenticationRequired extends GradeRegistrationState {
  const GradeRegistrationAuthenticationRequired();
}

class GradeRegistrationController extends ChangeNotifier {
  GradeRegistrationController({
    required AuthGateway auth,
    required GradeApi api,
    GradeOcrApi? ocrApi,
    CourseCatalogApi? catalogApi,
  }) : _auth = auth,
       _api = api,
       _ocrApi = ocrApi,
       _catalogApi = catalogApi;

  final AuthGateway _auth;
  final GradeApi _api;
  final GradeOcrApi? _ocrApi;
  final CourseCatalogApi? _catalogApi;
  GradeOcrImportController? createOcrImportController() => _catalogApi == null
      ? null
      : GradeOcrImportController(
          auth: _auth,
          courses: _catalogApi,
          grades: _api,
        );
  GradeRegistrationState _state = const GradeRegistrationIdle();

  GradeRegistrationState get state => _state;

  Future<List<GradeOcrPageResult>> previewPdf(Uint8List pdf) async {
    final ocr = _ocrApi;
    if (ocr == null) throw const GradeOcrFailure('OCR을 사용할 수 없어요.');
    return ocr.preview(pdf);
  }

  Future<void> submit(GradeRegistration registration) async {
    if (_state is GradeRegistrationSubmitting) return;
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const GradeRegistrationAuthenticationRequired());
      return;
    }

    _setState(const GradeRegistrationSubmitting());
    try {
      final grade = await _api.registerGrade(session.accessToken, registration);
      _setState(GradeRegistrationSuccess(grade));
    } on GradeApiFailure catch (failure) {
      if (failure.kind == GradeApiFailureKind.unauthorized) {
        _setState(const GradeRegistrationAuthenticationRequired());
        return;
      }
      _setState(GradeRegistrationFailure(failure.userMessage));
    } on Object catch (_) {
      _setState(const GradeRegistrationFailure('성적을 등록하지 못했습니다. 다시 시도해 주세요.'));
    }
  }

  void reset() => _setState(const GradeRegistrationIdle());

  void _setState(GradeRegistrationState next) {
    _state = next;
    notifyListeners();
  }
}
