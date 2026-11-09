// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:flutter/foundation.dart';

sealed class GradeEditState {
  const GradeEditState();
}

class GradeEditIdle extends GradeEditState {
  const GradeEditIdle();
}

class GradeEditSaving extends GradeEditState {
  const GradeEditSaving();
}

class GradeEditDeleting extends GradeEditState {
  const GradeEditDeleting();
}

class GradeEditSaved extends GradeEditState {
  const GradeEditSaved(this.grade);

  final GradeRecord grade;
}

class GradeEditDeleted extends GradeEditState {
  const GradeEditDeleted();
}

class GradeEditFailure extends GradeEditState {
  const GradeEditFailure(this.message);

  final String message;
}

class GradeEditAuthenticationRequired extends GradeEditState {
  const GradeEditAuthenticationRequired();
}

class GradeEditController extends ChangeNotifier {
  GradeEditController({required AuthGateway auth, required GradeApi api})
    : _auth = auth,
      _api = api;

  final AuthGateway _auth;
  final GradeApi _api;
  GradeEditState _state = const GradeEditIdle();

  GradeEditState get state => _state;

  Future<void> update(String gradeEntityId, GradeUpdate update) async {
    if (_isBusy) return;
    final accessToken = _accessTokenOrRequireAuthentication();
    if (accessToken == null) return;

    _setState(const GradeEditSaving());
    try {
      final grade = await _api.updateGrade(accessToken, gradeEntityId, update);
      _setState(GradeEditSaved(grade));
    } on GradeApiFailure catch (failure) {
      _handleFailure(failure);
    } on Object catch (_) {
      _setState(const GradeEditFailure('성적을 수정하지 못했어요. 다시 시도해 주세요.'));
    }
  }

  Future<void> delete(String gradeEntityId) async {
    if (_isBusy) return;
    final accessToken = _accessTokenOrRequireAuthentication();
    if (accessToken == null) return;

    _setState(const GradeEditDeleting());
    try {
      await _api.deleteGrade(accessToken, gradeEntityId);
      _setState(const GradeEditDeleted());
    } on GradeApiFailure catch (failure) {
      _handleFailure(failure);
    } on Object catch (_) {
      _setState(const GradeEditFailure('성적을 삭제하지 못했어요. 다시 시도해 주세요.'));
    }
  }

  void reset() => _setState(const GradeEditIdle());

  bool get _isBusy => _state is GradeEditSaving || _state is GradeEditDeleting;

  String? _accessTokenOrRequireAuthentication() {
    final accessToken = _auth.currentSession?.accessToken;
    if (accessToken == null) {
      _setState(const GradeEditAuthenticationRequired());
    }
    return accessToken;
  }

  void _handleFailure(GradeApiFailure failure) {
    if (failure.kind == GradeApiFailureKind.unauthorized) {
      _setState(const GradeEditAuthenticationRequired());
      return;
    }
    _setState(GradeEditFailure(failure.userMessage));
  }

  void _setState(GradeEditState next) {
    _state = next;
    notifyListeners();
  }
}
