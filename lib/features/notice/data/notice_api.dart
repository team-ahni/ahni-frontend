import 'dart:convert';
import 'dart:typed_data';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:http/http.dart' as http;

class PublishedNotice {
  const PublishedNotice({
    required this.title,
    required this.body,
    required this.publishedAt,
    this.entityId,
    this.bodyJson,
  });

  final String title;
  final String body;
  final DateTime publishedAt;
  final String? entityId;
  final NoticeContentNode? bodyJson;

  String? get thumbnailImageId => bodyJson?.firstImageId;

  factory PublishedNotice.fromJson(Map<String, Object?> json) =>
      PublishedNotice(
        entityId: json['entityId'] as String?,
        bodyJson: json['bodyJson'] == null
            ? null
            : NoticeContentNode.fromJson(
                json['bodyJson']! as Map<String, Object?>,
              ),
        title: json['title']! as String,
        body: json['body']! as String,
        publishedAt: DateTime.parse(json['publishedAt']! as String),
      );
}

class NoticeContentNode {
  const NoticeContentNode({
    required this.type,
    this.text,
    this.attrs = const {},
    this.content = const [],
    this.marks = const [],
  });

  final String type;
  final String? text;
  final Map<String, Object?> attrs;
  final List<NoticeContentNode> content;
  final List<String> marks;

  String? get firstImageId {
    if (type == 'image') return attrs['imageId'] as String?;
    for (final child in content) {
      final imageId = child.firstImageId;
      if (imageId != null) return imageId;
    }
    return null;
  }

  factory NoticeContentNode.fromJson(Map<String, Object?> json) =>
      NoticeContentNode(
        type: json['type']! as String,
        text: json['text'] as String?,
        attrs: (json['attrs'] as Map<String, Object?>?) ?? const {},
        content: [
          for (final child in (json['content'] as List<Object?>?) ?? const [])
            NoticeContentNode.fromJson(child! as Map<String, Object?>),
        ],
        marks: [
          for (final mark in (json['marks'] as List<Object?>?) ?? const [])
            (mark! as Map<String, Object?>)['type']! as String,
        ],
      );
}

class NoticeAuthenticationRequired implements Exception {
  const NoticeAuthenticationRequired();
}

abstract interface class NoticeApi {
  Future<List<PublishedNotice>> getPublishedNotices();
  Future<Uint8List> getImage(String noticeId, String imageId);
}

class HttpNoticeApi implements NoticeApi {
  const HttpNoticeApi({
    required this.auth,
    required this.baseUri,
    required this.client,
  });

  final AuthGateway auth;
  final Uri baseUri;
  final http.Client client;

  @override
  Future<Uint8List> getImage(String noticeId, String imageId) async {
    final session = auth.currentSession;
    if (session == null) throw const NoticeAuthenticationRequired();
    final response = await client
        .get(
          baseUri.resolve(
            '/api/v1/notices/${Uri.encodeComponent(noticeId)}/images/${Uri.encodeComponent(imageId)}',
          ),
          headers: {'authorization': 'Bearer ${session.accessToken}'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 ||
        auth.currentSession?.email != session.email) {
      throw const NoticeAuthenticationRequired();
    }
    if (response.statusCode != 200) {
      throw http.ClientException('Could not fetch notice image.');
    }
    return response.bodyBytes;
  }

  @override
  Future<List<PublishedNotice>> getPublishedNotices() async {
    final session = auth.currentSession;
    if (session == null) throw const NoticeAuthenticationRequired();

    final response = await client
        .get(
          baseUri.resolve('/api/v1/notices'),
          headers: {'authorization': 'Bearer ${session.accessToken}'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401 ||
        auth.currentSession?.email != session.email) {
      throw const NoticeAuthenticationRequired();
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Could not fetch notices.',
        response.request?.url,
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<Object?>;
    return [
      for (final entry in data)
        PublishedNotice.fromJson(entry as Map<String, Object?>),
    ];
  }
}
