import 'dart:convert';
import 'dart:typed_data';

import 'package:ahni_mobile/app/app_theme.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/notice/data/notice_api.dart';
import 'package:ahni_mobile/features/notice/presentation/notice_list_page.dart';
import 'package:ahni_mobile/features/notice/presentation/notice_rich_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/whitespace_wrapped_text_finder.dart';

class _NoticeApi implements NoticeApi {
  final notice = PublishedNotice.fromJson({
    'entityId': '11111111-1111-4111-8111-111111111111',
    'title': '사진이 있는 공지',
    'body': '첫 문단\n\n마지막 문단',
    'publishedAt': '2026-11-19T00:00:00Z',
    'bodyJson': {
      'type': 'doc',
      'content': [
        {
          'type': 'paragraph',
          'content': [
            {
              'type': 'text',
              'text': '첫 문단',
              'marks': [
                {'type': 'bold'},
              ],
            },
          ],
        },
        {
          'type': 'image',
          'attrs': {
            'imageId': '22222222-2222-4222-8222-222222222222',
            'alt': '학사 일정',
          },
        },
        {
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': '마지막 문단'},
          ],
        },
      ],
    },
  });
  final requests = <String>[];

  @override
  Future<List<PublishedNotice>> getPublishedNotices() async => [notice];

  @override
  Future<Uint8List> getImage(String noticeId, String imageId) async {
    requests.add('$noticeId/$imageId');
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
  }
}

void main() {
  testWidgets(
    'shows a right thumbnail and preserves paragraphs and image order in detail',
    (tester) async {
      final api = _NoticeApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: NoticeListPage(api: api, onAuthenticationRequired: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final title = findWhitespaceWrappedText('사진이 있는 공지');
      final thumbnail = find.byType(NoticeImageView);
      expect(
        tester.getTopLeft(thumbnail).dx,
        greaterThan(tester.getTopLeft(title).dx),
      );
      expect(tester.widget<NoticeImageView>(thumbnail).thumbnail, isTrue);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(title);
      await tester.pumpAndSettle();

      final detail = find.byKey(const Key('notice-detail-page'));
      final first = find.descendant(
        of: detail,
        matching: findWhitespaceWrappedText('첫 문단'),
      );
      final photo = find.descendant(
        of: detail,
        matching: find.byType(NoticeImageView),
      );
      final last = find.descendant(
        of: detail,
        matching: findWhitespaceWrappedText('마지막 문단'),
      );
      expect(
        tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(photo).dy),
      );
      expect(tester.getTopLeft(photo).dy, lessThan(tester.getTopLeft(last).dy));
      final paragraph = tester.widget<Text>(
        find.descendant(
          of: first,
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && widget.textSpan?.toPlainText() == '첫',
          ),
        ),
      );
      final span = paragraph.textSpan! as TextSpan;
      expect(span.children!.first.style!.fontWeight, FontWeight.bold);
      expect(
        api.requests.every(
          (request) =>
              request ==
              '${api.notice.entityId}/${api.notice.thumbnailImageId}',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('styled words keep format boundaries and explicit newlines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            child: WhitespaceWrappedText.rich('소프트웨어 공지\n다음 문단', [
              TextSpan(
                text: '소프트',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '웨어 공지\n다음 문단'),
            ]),
          ),
        ),
      ),
    );
    final word = find.byWidgetPredicate(
      (widget) => widget is Text && widget.textSpan?.toPlainText() == '소프트웨어',
    );
    final following = find.text('다음', findRichText: true);
    expect(word, findsOneWidget);
    expect(
      tester.getTopLeft(following).dy,
      greaterThan(tester.getTopLeft(word).dy),
    );
    final span = tester.widget<Text>(word).textSpan! as TextSpan;
    expect(span.children!.first.style!.fontWeight, FontWeight.bold);
    expect(span.children!.last.toPlainText(), '웨어');
    expect(tester.takeException(), isNull);
  });
}
