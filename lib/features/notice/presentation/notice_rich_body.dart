import 'dart:typed_data';

import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/notice/data/notice_api.dart';
import 'package:flutter/material.dart';

class NoticeRichBody extends StatelessWidget {
  const NoticeRichBody({required this.notice, required this.api, super.key});

  final PublishedNotice notice;
  final NoticeApi api;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final node in notice.bodyJson!.content)
        _NoticeBlock(node: node, noticeId: notice.entityId, api: api),
    ],
  );
}

class _NoticeBlock extends StatelessWidget {
  const _NoticeBlock({
    required this.node,
    required this.noticeId,
    required this.api,
  });

  final NoticeContentNode node;
  final String? noticeId;
  final NoticeApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (node.type == 'image') {
      final imageId = node.attrs['imageId'] as String?;
      if (noticeId == null || imageId == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: NoticeImageView(
          api: api,
          noticeId: noticeId!,
          imageId: imageId,
          alt: node.attrs['alt'] as String? ?? '공지 사진',
        ),
      );
    }
    if (node.type == 'bulletList' || node.type == 'orderedList') {
      final start = node.attrs['start'] as int? ?? 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < node.content.length; index++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    node.type == 'orderedList' ? '${start + index}.' : '•',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  child: _NoticeBlock(
                    node: node.content[index],
                    noticeId: noticeId,
                    api: api,
                  ),
                ),
              ],
            ),
        ],
      );
    }
    if (node.type == 'listItem') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in node.content)
            _NoticeBlock(node: child, noticeId: noticeId, api: api),
        ],
      );
    }
    final style = node.type == 'heading'
        ? (node.attrs['level'] == 3
              ? theme.textTheme.titleMedium
              : theme.textTheme.titleLarge)
        : theme.textTheme.bodyLarge;
    if (node.content.isEmpty) return const SizedBox(height: 16);
    final hasMarks = node.content.any((child) => child.marks.isNotEmpty);
    final text = node.content
        .map((child) => child.type == 'hardBreak' ? '\n' : child.text ?? '')
        .join();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: hasMarks
          ? WhitespaceWrappedText.rich(text, [
              for (final child in node.content)
                TextSpan(
                  text: child.type == 'hardBreak' ? '\n' : child.text,
                  style: TextStyle(
                    fontWeight: child.marks.contains('bold')
                        ? FontWeight.bold
                        : null,
                    fontStyle: child.marks.contains('italic')
                        ? FontStyle.italic
                        : null,
                  ),
                ),
            ], style: style)
          : WhitespaceWrappedText(text, style: style),
    );
  }
}

class NoticeImageView extends StatefulWidget {
  const NoticeImageView({
    required this.api,
    required this.noticeId,
    required this.imageId,
    this.alt = '공지 사진',
    this.thumbnail = false,
    super.key,
  });

  final NoticeApi api;
  final String noticeId;
  final String imageId;
  final String alt;
  final bool thumbnail;

  @override
  State<NoticeImageView> createState() => _NoticeImageViewState();
}

class _NoticeImageViewState extends State<NoticeImageView> {
  late Future<Uint8List> _image;

  @override
  void initState() {
    super.initState();
    _image = widget.api.getImage(widget.noticeId, widget.imageId);
  }

  @override
  void didUpdateWidget(NoticeImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noticeId != oldWidget.noticeId ||
        widget.imageId != oldWidget.imageId ||
        widget.api != oldWidget.api) {
      _image = widget.api.getImage(widget.noticeId, widget.imageId);
    }
  }

  Widget _failure() => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: IconButton(
        tooltip: '사진 다시 불러오기',
        onPressed: () {
          final image = widget.api.getImage(widget.noticeId, widget.imageId);
          setState(() {
            _image = image;
          });
        },
        icon: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: widget.thumbnail ? 72 : double.infinity,
      child: FutureBuilder<Uint8List>(
        future: _image,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SizedBox(
              height: widget.thumbnail ? 72 : 120,
              child: _failure(),
            );
          }
          if (!snapshot.hasData) {
            return SizedBox(
              height: widget.thumbnail ? 72 : 120,
              child: const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: '공지 사진 불러오는 중',
                ),
              ),
            );
          }
          return Image.memory(
            snapshot.requireData,
            height: widget.thumbnail ? 72 : null,
            fit: widget.thumbnail ? BoxFit.cover : BoxFit.fitWidth,
            semanticLabel: widget.alt,
            errorBuilder: (_, _, _) => SizedBox(
              height: widget.thumbnail ? 72 : 120,
              child: _failure(),
            ),
          );
        },
      ),
    ),
  );
}
