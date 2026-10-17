import 'dart:convert';

import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:ahni_mobile/features/inquiry/presentation/inquiry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/grade_fakes.dart';
import '../support/onboarding_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

Inquiry _inquiry({String status = 'SUBMITTED'}) => Inquiry(
  entityId: 'inquiry-id-1',
  title: '성적 등록 문의',
  content: '과목이 보이지 않습니다.',
  status: status,
  answer: null,
  answeredAt: null,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
);

final _attachment = InquiryAttachment(
  entityId: 'attachment-id-1',
  filename: 'grade-screen.png',
  contentType: 'image/png',
  sizeBytes: 182044,
  createdAt: DateTime.utc(2026, 10, 17),
);

void main() {
  late FakeInquiryApi api;
  late FakeAttachmentPicker picker;

  setUp(() {
    api = FakeInquiryApi();
    picker = FakeAttachmentPicker();
  });

  Future<void> pumpDetail(WidgetTester tester, Inquiry inquiry) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InquiryDetailPage(
          controller: InquiryController(
            auth: FakeAuthGateway(currentSession: testSession),
            api: api,
            picker: picker,
          ),
          inquiry: inquiry,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('student attaches a PDF and deletes an attachment', (
    tester,
  ) async {
    api.attachments = [_attachment];
    picker.pdf = pickedFile('transcript.pdf', ascii.encode('%PDF-1.7'));
    await pumpDetail(tester, _inquiry());

    expect(find.text('첨부파일 1/3'), findsOneWidget);
    expect(find.text('grade-screen.png'), findsOneWidget);
    expect(find.text('PNG · 178KB'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('add-pdf-attachment')));
    await tester.tap(find.byKey(const Key('add-pdf-attachment')));
    await tester.pumpAndSettle();

    expect(api.lastUpload?.contentType, 'application/pdf');
    expect(find.text('transcript.pdf'), findsOneWidget);
    expect(find.text('첨부파일 2/3'), findsOneWidget);

    await tester.tap(find.byTooltip('grade-screen.png 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-attachment')));
    await tester.pumpAndSettle();

    expect(api.lastDeletedAttachmentEntityId, 'attachment-id-1');
    expect(find.text('grade-screen.png'), findsNothing);
  });

  testWidgets('answered inquiries show attachments read-only', (tester) async {
    api.attachments = [_attachment];
    await pumpDetail(tester, _inquiry(status: 'ANSWERED'));

    expect(find.text('grade-screen.png'), findsOneWidget);
    expect(find.byKey(const Key('add-image-attachment')), findsNothing);
    expect(find.byTooltip('grade-screen.png 삭제'), findsNothing);
  });

  testWidgets('shows empty, error, and retry states', (tester) async {
    api.attachmentError = const InquiryApiFailure(
      InquiryApiFailureKind.recoverable,
      '첨부파일을 불러오지 못했어요. 다시 시도해 주세요.',
    );
    await pumpDetail(tester, _inquiry());

    expect(
      findWhitespaceWrappedText('첨부파일을 불러오지 못했어요. 다시 시도해 주세요.'),
      findsOneWidget,
    );

    api.attachmentError = null;
    await tester.ensureVisible(find.text('첨부파일 다시 불러오기'));
    await tester.tap(find.text('첨부파일 다시 불러오기'));
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('첨부파일이 없어요.'), findsOneWidget);
  });
}
