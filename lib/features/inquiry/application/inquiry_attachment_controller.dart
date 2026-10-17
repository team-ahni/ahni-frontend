// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/inquiry/data/attachment_picker.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/image_metadata.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter/foundation.dart';

sealed class InquiryAttachmentState {
  const InquiryAttachmentState();
}

class InquiryAttachmentLoading extends InquiryAttachmentState {
  const InquiryAttachmentLoading();
}

class InquiryAttachmentReady extends InquiryAttachmentState {
  const InquiryAttachmentReady(this.attachments);

  final List<InquiryAttachment> attachments;
}

class InquiryAttachmentFailure extends InquiryAttachmentState {
  const InquiryAttachmentFailure(this.message);

  final String message;
}

enum AttachmentSource { image, pdf }

class InquiryAttachmentController extends ChangeNotifier {
  InquiryAttachmentController({
    required AuthGateway auth,
    required InquiryApi api,
    required AttachmentPicker picker,
    required this.inquiryEntityId,
  }) : _auth = auth,
       _api = api,
       _picker = picker;

  final AuthGateway _auth;
  final InquiryApi _api;
  final AttachmentPicker _picker;
  final String inquiryEntityId;
  InquiryAttachmentState _state = const InquiryAttachmentLoading();
  String? actionMessage;
  bool isBusy = false;
  bool _disposed = false;

  InquiryAttachmentState get state => _state;

  List<InquiryAttachment> get attachments => switch (_state) {
    InquiryAttachmentReady state => state.attachments,
    _ => const [],
  };

  bool get canAddMore =>
      _state is InquiryAttachmentReady &&
      attachments.length < InquiryAttachment.maxCount;

  Future<void> load() async {
    final token = _accessToken();
    if (token == null) return;
    _state = const InquiryAttachmentLoading();
    _notify();
    try {
      final result = await _api.getAttachments(token, inquiryEntityId);
      _state = InquiryAttachmentReady(List.unmodifiable(result));
    } on InquiryApiFailure catch (failure) {
      _state = InquiryAttachmentFailure(failure.userMessage);
    } on Object catch (_) {
      _state = const InquiryAttachmentFailure('첨부파일을 불러오지 못했어요. 다시 시도해 주세요.');
    }
    _notify();
  }

  Future<void> add(AttachmentSource source) async {
    if (isBusy || !canAddMore) return;
    final token = _accessToken();
    if (token == null) return;
    actionMessage = null;
    isBusy = true;
    _notify();
    try {
      final picked = switch (source) {
        AttachmentSource.image => await _picker.pickImage(),
        AttachmentSource.pdf => await _picker.pickPdf(),
      };
      if (picked == null) return;
      final contentType = InquiryAttachment.contentTypeFor(picked.name);
      if (contentType == null) {
        actionMessage = 'JPG, PNG, PDF 파일만 첨부할 수 있어요.';
        return;
      }
      if ((picked.length ?? 0) > InquiryAttachment.maxSizeBytes) {
        actionMessage = '5MB 이하 파일만 첨부할 수 있어요.';
        return;
      }
      final bytes = stripImageMetadata(await picked.read(), contentType);
      if (bytes.length > InquiryAttachment.maxSizeBytes) {
        actionMessage = '5MB 이하 파일만 첨부할 수 있어요.';
        return;
      }
      final uploaded = await _api.uploadAttachment(
        token,
        inquiryEntityId,
        filename: picked.name,
        contentType: contentType,
        bytes: bytes,
      );
      _state = InquiryAttachmentReady(
        List.unmodifiable([...attachments, uploaded]),
      );
    } on FormatException catch (_) {
      actionMessage = '파일을 읽지 못했어요. 다른 파일을 선택해 주세요.';
    } on InquiryApiFailure catch (failure) {
      actionMessage = failure.userMessage;
    } on Object catch (_) {
      actionMessage = '첨부파일을 올리지 못했어요. 다시 시도해 주세요.';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> delete(InquiryAttachment attachment) async {
    if (isBusy) return;
    final token = _accessToken();
    if (token == null) return;
    actionMessage = null;
    isBusy = true;
    _notify();
    try {
      await _api.deleteAttachment(token, inquiryEntityId, attachment.entityId);
      _state = InquiryAttachmentReady(
        List.unmodifiable(
          attachments.where((item) => item.entityId != attachment.entityId),
        ),
      );
    } on InquiryApiFailure catch (failure) {
      actionMessage = failure.userMessage;
    } on Object catch (_) {
      actionMessage = '첨부파일을 삭제하지 못했어요. 다시 시도해 주세요.';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  String? _accessToken() {
    final token = _auth.currentSession?.accessToken;
    if (token == null) {
      _state = const InquiryAttachmentFailure('로그인이 만료되었습니다. 다시 로그인해 주세요.');
      _notify();
    }
    return token;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
