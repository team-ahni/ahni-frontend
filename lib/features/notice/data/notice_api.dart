import 'dart:convert';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:http/http.dart' as http;

class PublishedNotice {
  const PublishedNotice({
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final String title;
  final String body;
  final DateTime publishedAt;

  factory PublishedNotice.fromJson(Map<String, Object?> json) =>
      PublishedNotice(
        title: json['title']! as String,
        body: json['body']! as String,
        publishedAt: DateTime.parse(json['publishedAt']! as String),
      );
}

class NoticeAuthenticationRequired implements Exception {
  const NoticeAuthenticationRequired();
}

abstract interface class NoticeApi {
  Future<List<PublishedNotice>> getPublishedNotices();
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
