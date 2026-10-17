// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_attachment_controller.dart';
import 'package:ahni_mobile/features/inquiry/data/attachment_picker.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter/foundation.dart';

sealed class InquiryState {
  const InquiryState();
}

class InquiryInitial extends InquiryState {
  const InquiryInitial();
}

class InquiryLoading extends InquiryState {
  const InquiryLoading();
}

class InquiryReady extends InquiryState {
  const InquiryReady(this.inquiries);

  final List<Inquiry> inquiries;
}

class InquiryEmpty extends InquiryState {
  const InquiryEmpty();
}

class InquiryFailure extends InquiryState {
  const InquiryFailure(this.message);

  final String message;
}

class InquiryAuthenticationRequired extends InquiryState {
  const InquiryAuthenticationRequired();
}

class InquiryController extends ChangeNotifier {
  InquiryController({
    required AuthGateway auth,
    required InquiryApi api,
    AttachmentPicker picker = const FilePickerAttachmentPicker(),
  }) : _auth = auth,
       _api = api,
       _picker = picker;

  final AuthGateway _auth;
  final InquiryApi _api;
  final AttachmentPicker _picker;
  InquiryState _state = const InquiryInitial();
  String? formMessage;
  String? actionMessage;
  bool isSubmitting = false;
  bool isDeleting = false;
  int _generation = 0;

  InquiryState get state => _state;

  Future<void> load({bool force = false}) async {
    if (_state is InquiryLoading) return;
    if (!force && _state is! InquiryInitial) return;
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const InquiryAuthenticationRequired());
      return;
    }

    final requestGeneration = _generation;
    _setState(const InquiryLoading());
    try {
      final result = await _api.getInquiries(session.accessToken);
      if (requestGeneration != _generation) return;
      _setState(
        result.isEmpty
            ? const InquiryEmpty()
            : InquiryReady(List.unmodifiable(result)),
      );
    } on InquiryApiFailure catch (failure) {
      if (requestGeneration != _generation) return;
      if (failure.kind == InquiryApiFailureKind.unauthorized) {
        _setState(const InquiryAuthenticationRequired());
        return;
      }
      _setState(InquiryFailure(failure.userMessage));
    } on Object catch (_) {
      if (requestGeneration != _generation) return;
      _setState(const InquiryFailure('문의 목록을 불러오지 못했어요. 다시 시도해 주세요.'));
    }
  }

  Future<bool> create({required String title, required String content}) async {
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const InquiryAuthenticationRequired());
      return false;
    }
    isSubmitting = true;
    formMessage = null;
    actionMessage = null;
    notifyListeners();
    try {
      final inquiry = await _api.createInquiry(
        session.accessToken,
        InquiryDraft(title: title, content: content),
      );
      final existing = switch (_state) {
        InquiryReady state => state.inquiries,
        _ => const <Inquiry>[],
      };
      _setState(InquiryReady(List.unmodifiable([inquiry, ...existing])));
      return true;
    } on InquiryApiFailure catch (failure) {
      if (failure.kind == InquiryApiFailureKind.unauthorized) {
        isSubmitting = false;
        _setState(const InquiryAuthenticationRequired());
        return false;
      }
      formMessage = failure.userMessage;
      isSubmitting = false;
      notifyListeners();
      return false;
    } on Object catch (_) {
      formMessage = '문의를 등록하지 못했어요. 다시 시도해 주세요.';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<Inquiry?> update({
    required Inquiry inquiry,
    required String title,
    required String content,
  }) async {
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const InquiryAuthenticationRequired());
      return null;
    }
    isSubmitting = true;
    formMessage = null;
    actionMessage = null;
    notifyListeners();
    try {
      final updated = await _api.updateInquiry(
        session.accessToken,
        inquiry.entityId,
        InquiryDraft(title: title, content: content),
      );
      _replaceInquiry(updated);
      return updated;
    } on InquiryApiFailure catch (failure) {
      if (failure.kind == InquiryApiFailureKind.unauthorized) {
        isSubmitting = false;
        _setState(const InquiryAuthenticationRequired());
        return null;
      }
      formMessage = failure.userMessage;
      isSubmitting = false;
      notifyListeners();
      return null;
    } on Object catch (_) {
      formMessage = '문의를 수정하지 못했어요. 다시 시도해 주세요.';
      isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String inquiryEntityId) async {
    final session = _auth.currentSession;
    if (session == null) {
      _setState(const InquiryAuthenticationRequired());
      return false;
    }
    isDeleting = true;
    actionMessage = null;
    notifyListeners();
    try {
      await _api.deleteInquiry(session.accessToken, inquiryEntityId);
      _removeInquiry(inquiryEntityId);
      return true;
    } on InquiryApiFailure catch (failure) {
      if (failure.kind == InquiryApiFailureKind.unauthorized) {
        isDeleting = false;
        _setState(const InquiryAuthenticationRequired());
        return false;
      }
      actionMessage = failure.userMessage;
      isDeleting = false;
      notifyListeners();
      return false;
    } on Object catch (_) {
      actionMessage = '문의를 삭제하지 못했어요. 다시 시도해 주세요.';
      isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> retry() => load(force: true);

  InquiryAttachmentController attachmentsFor(String inquiryEntityId) {
    return InquiryAttachmentController(
      auth: _auth,
      api: _api,
      picker: _picker,
      inquiryEntityId: inquiryEntityId,
    );
  }

  void reset() {
    _generation++;
    formMessage = null;
    actionMessage = null;
    isSubmitting = false;
    isDeleting = false;
    _setState(const InquiryInitial());
  }

  void _setState(InquiryState next) {
    _state = next;
    if (isSubmitting) isSubmitting = false;
    if (isDeleting) isDeleting = false;
    notifyListeners();
  }

  void _replaceInquiry(Inquiry inquiry) {
    final existing = switch (_state) {
      InquiryReady state => state.inquiries,
      _ => const <Inquiry>[],
    };
    final next = existing
        .map((item) => item.entityId == inquiry.entityId ? inquiry : item)
        .toList(growable: false);
    _setState(InquiryReady(List.unmodifiable(next)));
  }

  void _removeInquiry(String inquiryEntityId) {
    final existing = switch (_state) {
      InquiryReady state => state.inquiries,
      _ => const <Inquiry>[],
    };
    final next = existing
        .where((item) => item.entityId != inquiryEntityId)
        .toList(growable: false);
    _setState(next.isEmpty ? const InquiryEmpty() : InquiryReady(next));
  }
}
