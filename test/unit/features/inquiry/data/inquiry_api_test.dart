import 'dart:convert';

import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const draft = InquiryDraft(title: ' 수정 문의 ', content: ' 수정 내용입니다. ');

  test(
    'PUT /inquiries/{id} sends trimmed values and parses the result',
    () async {
      final api = HttpInquiryApi(
        baseUri: Uri.parse('https://api.ahni.test'),
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/inquiries/inquiry-id-1');
          expect(request.headers['authorization'], 'Bearer jwt');
          expect(jsonDecode(request.body), {
            'title': '수정 문의',
            'content': '수정 내용입니다.',
          });
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'entityId': 'inquiry-id-1',
                'title': '수정 문의',
                'content': '수정 내용입니다.',
                'status': 'IN_REVIEW',
                'answer': null,
                'answeredAt': null,
                'createdAt': '2026-10-09T00:00:00Z',
                'updatedAt': '2026-10-10T00:00:00Z',
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final inquiry = await api.updateInquiry('jwt', 'inquiry-id-1', draft);

      expect(inquiry.title, '수정 문의');
      expect(inquiry.content, '수정 내용입니다.');
      expect(inquiry.status, 'IN_REVIEW');
    },
  );

  test('DELETE /inquiries/{id} accepts an empty 204 response', () async {
    final api = HttpInquiryApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/inquiries/inquiry-id-1');
        expect(request.headers['authorization'], 'Bearer jwt');
        return http.Response('', 204);
      }),
    );

    await api.deleteInquiry('jwt', 'inquiry-id-1');
  });

  test('answered inquiry update conflict uses a specific message', () async {
    final api = HttpInquiryApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'code': 'INQUIRY_UPDATE_CONFLICT',
              'message': '답변이 등록된 문의는 수정할 수 없습니다.',
            }),
          ),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => api.updateInquiry('jwt', 'inquiry-id-1', draft),
      throwsA(
        isA<InquiryApiFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              InquiryApiFailureKind.conflict,
            )
            .having(
              (failure) => failure.userMessage,
              'userMessage',
              '답변이 등록된 문의는 수정할 수 없어요.',
            ),
      ),
    );
  });

  group('attachments', () {
    HttpInquiryApi apiWith(MockClientHandler handler) => HttpInquiryApi(
      baseUri: Uri.parse('https://api.ahni.test'),
      client: MockClient(handler),
    );

    test('POST uploads a multipart file part with its content type', () async {
      final api = apiWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/inquiries/inquiry-id-1/attachments');
        expect(request.headers['authorization'], 'Bearer jwt');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        final body = latin1.decode(request.bodyBytes);
        expect(body, contains('name="file"; filename="screen.png"'));
        expect(body, contains('content-type: image/png'));
        return http.Response(
          jsonEncode({
            'entityId': 'attachment-id-1',
            'filename': 'screen.png',
            'contentType': 'image/png',
            'sizeBytes': 3,
            'createdAt': '2026-10-17T00:00:00Z',
          }),
          201,
        );
      });

      final attachment = await api.uploadAttachment(
        'jwt',
        'inquiry-id-1',
        filename: 'screen.png',
        contentType: 'image/png',
        bytes: [1, 2, 3],
      );

      expect(attachment.entityId, 'attachment-id-1');
      expect(attachment.typeLabel, 'PNG');
    });

    test('GET lists attachments without a trailing slash', () async {
      final api = apiWith((request) async {
        expect(request.url.path, '/api/v1/inquiries/inquiry-id-1/attachments');
        return http.Response(
          jsonEncode([
            {
              'entityId': 'attachment-id-1',
              'filename': 'report.pdf',
              'contentType': 'application/pdf',
              'sizeBytes': 2097152,
              'createdAt': '2026-10-17T00:00:00Z',
            },
          ]),
          200,
        );
      });

      final attachments = await api.getAttachments('jwt', 'inquiry-id-1');

      expect(attachments.single.sizeLabel, '2.0MB');
    });

    test('DELETE targets the attachment under its inquiry', () async {
      final api = apiWith((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.path,
          '/api/v1/inquiries/inquiry-id-1/attachments/attachment-id-1',
        );
        return http.Response('', 204);
      });

      await api.deleteAttachment('jwt', 'inquiry-id-1', 'attachment-id-1');
    });

    test('maps attachment error codes to student messages', () async {
      Future<InquiryApiFailure> failureFor(int status, String code) async {
        final api = apiWith(
          (_) async => http.Response(jsonEncode({'code': code}), status),
        );
        try {
          await api.uploadAttachment(
            'jwt',
            'inquiry-id-1',
            filename: 'a.png',
            contentType: 'image/png',
            bytes: [1],
          );
        } on InquiryApiFailure catch (failure) {
          return failure;
        }
        fail('expected a failure');
      }

      expect(
        (await failureFor(
          415,
          'UNSUPPORTED_INQUIRY_ATTACHMENT_TYPE',
        )).userMessage,
        'JPG, PNG, PDF 파일만 첨부할 수 있어요.',
      );
      expect(
        (await failureFor(413, 'INQUIRY_ATTACHMENT_TOO_LARGE')).userMessage,
        '5MB 이하 파일만 첨부할 수 있어요.',
      );
      expect(
        (await failureFor(
          409,
          'INQUIRY_ATTACHMENT_LIMIT_EXCEEDED',
        )).userMessage,
        '첨부파일은 3개까지 올릴 수 있어요.',
      );
      expect(
        (await failureFor(503, 'INQUIRY_ATTACHMENT_STORAGE_UNAVAILABLE')).kind,
        InquiryApiFailureKind.recoverable,
      );
    });
  });
}
