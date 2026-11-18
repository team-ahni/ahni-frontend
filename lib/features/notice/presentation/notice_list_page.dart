import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/notice/data/notice_api.dart';
import 'package:flutter/material.dart';

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({
    required this.api,
    required this.onAuthenticationRequired,
    super.key,
  });

  final NoticeApi api;
  final VoidCallback onAuthenticationRequired;

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  late Future<List<PublishedNotice>> _notices;

  @override
  void initState() {
    super.initState();
    _notices = widget.api.getPublishedNotices();
  }

  void _retry() {
    final notices = widget.api.getPublishedNotices();
    setState(() {
      _notices = notices;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('notice-list-page'),
    appBar: AppBar(title: const Text('공지사항')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FutureBuilder<List<PublishedNotice>>(
            future: _notices,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator(
                  semanticsLabel: '공지사항 불러오는 중',
                );
              }
              if (snapshot.error is NoticeAuthenticationRequired) {
                return EmptyStateView(
                  mood: AhniMood.oops,
                  title: '다시 로그인해 주세요',
                  action: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAuthenticationRequired();
                    },
                    child: const Text('로그인으로 돌아가기'),
                  ),
                );
              }
              if (snapshot.hasError) {
                return LoadFailureView(
                  title: '공지사항을 불러오지 못했어요',
                  onRetry: _retry,
                );
              }

              final notices = snapshot.requireData;
              if (notices.isEmpty) {
                return const EmptyStateView(
                  mood: AhniMood.curious,
                  title: '아직 공지사항이 없어요',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: notices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _NoticeRow(notice: notices[index]),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final PublishedNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = notice.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => _NoticeDetailPage(notice: notice)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhitespaceWrappedText(
                notice.title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _PublicationDate(notice.publishedAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeDetailPage extends StatelessWidget {
  const _NoticeDetailPage({required this.notice});

  final PublishedNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('notice-detail-page'),
      appBar: AppBar(title: const Text('공지사항')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WhitespaceWrappedText(
                  notice.title,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                _PublicationDate(notice.publishedAt),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                WhitespaceWrappedText(
                  notice.body,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicationDate extends StatelessWidget {
  const _PublicationDate(this.publishedAt);

  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = publishedAt.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return Text(
      '${date.year}.$month.$day $hour:$minute',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
