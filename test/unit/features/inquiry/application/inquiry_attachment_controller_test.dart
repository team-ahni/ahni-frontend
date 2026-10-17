import 'dart:convert';

import 'package:ahni_mobile/features/inquiry/application/inquiry_attachment_controller.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/grade_fakes.dart';
import '../../../../support/onboarding_fakes.dart';

const _jpegWithExif = [
  0xFF, 0xD8, //
  0xFF, 0xE1, 0x00, 0x05, 0x47, 0x50, 0x53, // APP1 "GPS"
  0xFF, 0xDA, 0x00, 0x02, 0x01, 0xFF, 0xD9,
];

void main() {
  late FakeInquiryApi api;
  late FakeAttachmentPicker picker;
  late InquiryAttachmentController controller;

  setUp(() {
    api = FakeInquiryApi();
    picker = FakeAttachmentPicker();
    controller = InquiryAttachmentController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: api,
      picker: picker,
      inquiryEntityId: 'inquiry-id-1',
    );
  });

  test('uploads a photo without its EXIF metadata', () async {
    await controller.load();
    picker.image = pickedFile('screen.jpg', _jpegWithExif);

    await controller.add(AttachmentSource.image);

    expect(api.lastUpload?.contentType, 'image/jpeg');
    expect(api.lastUpload?.filename, 'screen.jpg');
    expect(api.lastUpload?.bytes, [
      0xFF, 0xD8, 0xFF, 0xDA, 0x00, 0x02, 0x01, 0xFF, 0xD9, //
    ]);
    expect(controller.attachments.single.filename, 'screen.jpg');
    expect(controller.actionMessage, isNull);
  });

  test(
    'rejects HEIC and oversized files before reading or uploading',
    () async {
      await controller.load();
      picker.image = pickedFile('IMG_0001.HEIC', [1]);
      await controller.add(AttachmentSource.image);
      expect(controller.actionMessage, 'JPG, PNG, PDF 파일만 첨부할 수 있어요.');

      picker.pdf = pickedFile(
        'big.pdf',
        ascii.encode('%PDF-'),
        length: InquiryAttachment.maxSizeBytes + 1,
      );
      await controller.add(AttachmentSource.pdf);
      expect(controller.actionMessage, '5MB 이하 파일만 첨부할 수 있어요.');
      expect(api.lastUpload, isNull);
    },
  );

  test('does nothing when the student cancels the picker', () async {
    await controller.load();

    await controller.add(AttachmentSource.pdf);

    expect(api.lastUpload, isNull);
    expect(controller.actionMessage, isNull);
    expect(controller.isBusy, isFalse);
  });

  test('stops offering uploads at three attachments', () async {
    api.attachments = List.generate(
      3,
      (index) => InquiryAttachment(
        entityId: 'attachment-id-$index',
        filename: 'a$index.pdf',
        contentType: 'application/pdf',
        sizeBytes: 10,
        createdAt: DateTime.utc(2026, 10, 17),
      ),
    );
    await controller.load();
    picker.pdf = pickedFile('d.pdf', ascii.encode('%PDF-'));

    await controller.add(AttachmentSource.pdf);

    expect(controller.canAddMore, isFalse);
    expect(api.lastUpload, isNull);
  });

  test('shows the backend message when the inquiry was answered', () async {
    await controller.load();
    api.attachmentError = const InquiryApiFailure(
      InquiryApiFailureKind.conflict,
      '답변이 등록된 문의는 수정할 수 없어요.',
    );
    picker.pdf = pickedFile('a.pdf', ascii.encode('%PDF-'));

    await controller.add(AttachmentSource.pdf);

    expect(controller.actionMessage, '답변이 등록된 문의는 수정할 수 없어요.');
  });

  test('reports a load failure so the page can retry', () async {
    api.attachmentError = const InquiryApiFailure(
      InquiryApiFailureKind.recoverable,
      '첨부파일을 불러오지 못했어요. 다시 시도해 주세요.',
    );

    await controller.load();

    expect(controller.state, isA<InquiryAttachmentFailure>());
  });
}
