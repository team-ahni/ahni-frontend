// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

enum InquiryApiFailureKind {
  unauthorized,
  studentNotFound,
  validation,
  notFound,
  conflict,
  recoverable,
}

class InquiryApiFailure implements Exception {
  const InquiryApiFailure(this.kind, this.userMessage);

  final InquiryApiFailureKind kind;
  final String userMessage;
}

abstract interface class InquiryApi {
  Future<List<Inquiry>> getInquiries(String accessToken);

  Future<Inquiry> getInquiry(String accessToken, String inquiryEntityId);

  Future<Inquiry> createInquiry(String accessToken, InquiryDraft draft);

  Future<Inquiry> updateInquiry(
    String accessToken,
    String inquiryEntityId,
    InquiryDraft draft,
  );

  Future<void> deleteInquiry(String accessToken, String inquiryEntityId);

  Future<List<InquiryAttachment>> getAttachments(
    String accessToken,
    String inquiryEntityId,
  );

  Future<InquiryAttachment> uploadAttachment(
    String accessToken,
    String inquiryEntityId, {
    required String filename,
    required String contentType,
    required List<int> bytes,
  });

  Future<void> deleteAttachment(
    String accessToken,
    String inquiryEntityId,
    String attachmentEntityId,
  );
}

class HttpInquiryApi implements InquiryApi {
  HttpInquiryApi({required this.baseUri, required http.Client client})
    : _client = client;

  final Uri baseUri;
  final http.Client _client;

  @override
  Future<List<Inquiry>> getInquiries(String accessToken) async {
    final response = await _request(
      () => _client.get(
        baseUri.resolve('/api/v1/inquiries'),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(
        response,
        fallbackMessage: '문의 목록을 불러오지 못했어요. 다시 시도해 주세요.',
      );
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map((item) => Inquiry.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<Inquiry> getInquiry(String accessToken, String inquiryEntityId) async {
    final response = await _request(
      () => _client.get(
        _inquiryUri(inquiryEntityId),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(response, fallbackMessage: '문의를 불러오지 못했어요. 다시 시도해 주세요.');
    }
    try {
      return Inquiry.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<Inquiry> createInquiry(String accessToken, InquiryDraft draft) async {
    final response = await _request(
      () => _client.post(
        baseUri.resolve('/api/v1/inquiries'),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );
    if (response.statusCode != 201) {
      throw _failure(response, fallbackMessage: '문의를 등록하지 못했어요. 다시 시도해 주세요.');
    }
    try {
      return Inquiry.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<Inquiry> updateInquiry(
    String accessToken,
    String inquiryEntityId,
    InquiryDraft draft,
  ) async {
    final response = await _request(
      () => _client.put(
        _inquiryUri(inquiryEntityId),
        headers: {
          'authorization': 'Bearer $accessToken',
          'content-type': 'application/json',
        },
        body: jsonEncode(draft.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(response, fallbackMessage: '문의를 수정하지 못했어요. 다시 시도해 주세요.');
    }
    try {
      return Inquiry.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<void> deleteInquiry(String accessToken, String inquiryEntityId) async {
    final response = await _request(
      () => _client.delete(
        _inquiryUri(inquiryEntityId),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 204) {
      throw _failure(response, fallbackMessage: '문의를 삭제하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Future<List<InquiryAttachment>> getAttachments(
    String accessToken,
    String inquiryEntityId,
  ) async {
    final response = await _request(
      () => _client.get(
        _attachmentsUri(inquiryEntityId),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 200) {
      throw _failure(response, fallbackMessage: '첨부파일을 불러오지 못했어요. 다시 시도해 주세요.');
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
      return body
          .map(
            (item) => InquiryAttachment.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false);
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<InquiryAttachment> uploadAttachment(
    String accessToken,
    String inquiryEntityId, {
    required String filename,
    required String contentType,
    required List<int> bytes,
  }) async {
    final response = await _request(() async {
      // 백엔드가 파트의 Content-Type까지 검증하므로 반드시 지정한다.
      final request =
          http.MultipartRequest('POST', _attachmentsUri(inquiryEntityId))
            ..headers['authorization'] = 'Bearer $accessToken'
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: filename,
                contentType: MediaType.parse(contentType),
              ),
            );
      return http.Response.fromStream(await _client.send(request));
    });
    if (response.statusCode != 201) {
      throw _failure(response, fallbackMessage: '첨부파일을 올리지 못했어요. 다시 시도해 주세요.');
    }
    try {
      return InquiryAttachment.fromJson(_decodeMap(response));
    } on FormatException catch (_) {
      throw _malformedResponse;
    } on TypeError catch (_) {
      throw _malformedResponse;
    }
  }

  @override
  Future<void> deleteAttachment(
    String accessToken,
    String inquiryEntityId,
    String attachmentEntityId,
  ) async {
    final response = await _request(
      () => _client.delete(
        baseUri.resolve(
          '${_attachmentsUri(inquiryEntityId).path}/'
          '${Uri.encodeComponent(attachmentEntityId)}',
        ),
        headers: {'authorization': 'Bearer $accessToken'},
      ),
    );
    if (response.statusCode != 204) {
      throw _failure(response, fallbackMessage: '첨부파일을 삭제하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Uri _attachmentsUri(String inquiryEntityId) {
    return baseUri.resolve(
      '/api/v1/inquiries/${Uri.encodeComponent(inquiryEntityId)}/attachments',
    );
  }

  Uri _inquiryUri(String inquiryEntityId) {
    return baseUri.resolve(
      '/api/v1/inquiries/${Uri.encodeComponent(inquiryEntityId)}',
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on Exception catch (_) {
      throw const InquiryApiFailure(
        InquiryApiFailureKind.recoverable,
        '서버에 연결하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
      );
    }
  }

  InquiryApiFailure _failure(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final code = _errorCode(response);
    if (response.statusCode == 401) {
      return const InquiryApiFailure(
        InquiryApiFailureKind.unauthorized,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    if (response.statusCode == 404 && code == 'STUDENT_NOT_FOUND') {
      return const InquiryApiFailure(
        InquiryApiFailureKind.studentNotFound,
        '학생 정보를 먼저 등록해 주세요.',
      );
    }
    return switch (code) {
      'INQUIRY_NOT_FOUND' => const InquiryApiFailure(
        InquiryApiFailureKind.notFound,
        '문의를 찾을 수 없어요. 목록을 새로고침해 주세요.',
      ),
      'INVALID_INQUIRY' || 'INVALID_REQUEST' => const InquiryApiFailure(
        InquiryApiFailureKind.validation,
        '제목과 내용을 확인해 주세요.',
      ),
      'INQUIRY_UPDATE_CONFLICT' => const InquiryApiFailure(
        InquiryApiFailureKind.conflict,
        '답변이 등록된 문의는 수정할 수 없어요.',
      ),
      'INQUIRY_ATTACHMENT_NOT_FOUND' => const InquiryApiFailure(
        InquiryApiFailureKind.notFound,
        '첨부파일을 찾을 수 없어요. 새로고침해 주세요.',
      ),
      'INVALID_INQUIRY_ATTACHMENT' ||
      'UNSUPPORTED_INQUIRY_ATTACHMENT_TYPE' => const InquiryApiFailure(
        InquiryApiFailureKind.validation,
        'JPG, PNG, PDF 파일만 첨부할 수 있어요.',
      ),
      'INQUIRY_ATTACHMENT_TOO_LARGE' => const InquiryApiFailure(
        InquiryApiFailureKind.validation,
        '5MB 이하 파일만 첨부할 수 있어요.',
      ),
      'INQUIRY_ATTACHMENT_LIMIT_EXCEEDED' => const InquiryApiFailure(
        InquiryApiFailureKind.conflict,
        '첨부파일은 3개까지 올릴 수 있어요.',
      ),
      _ => InquiryApiFailure(
        InquiryApiFailureKind.recoverable,
        fallbackMessage,
      ),
    };
  }

  String? _errorCode(http.Response response) {
    try {
      return _decodeMap(response)['code'] as String?;
    } on Object catch (_) {
      return null;
    }
  }

  Map<String, Object?> _decodeMap(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
  }

  static const _malformedResponse = InquiryApiFailure(
    InquiryApiFailureKind.recoverable,
    '문의 정보를 확인하지 못했어요. 다시 시도해 주세요.',
  );
}
