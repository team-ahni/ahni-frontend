import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/ahni_palette.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';

/// 화면 위쪽 안내문을 긴 문단 대신 아이콘이 있는 옅은 상자로 보여 준다.
class NoticeCallout extends StatelessWidget {
  const NoticeCallout({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone,
    super.key,
  });

  final String message;
  final IconData icon;

  /// 기본은 강조색 옅은 바탕. 주의가 필요한 안내는 `AhniPalette.amber`처럼 다른 색을 준다.
  final Tone? tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final soft = tone?.soft ?? colorScheme.primaryContainer;
    final ink = tone?.ink ?? colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WhitespaceWrappedText(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurface, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈 화면·오류 화면. 상황에 맞는 표정의 '아니', 짧은 제목, 설명, 다음 동작을 가운데에 둔다.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.mood,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final AhniMood mood;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AhniMascot(mood: mood),
          const SizedBox(height: 16),
          WhitespaceWrappedText(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message case final message?) ...[
            const SizedBox(height: 6),
            WhitespaceWrappedText(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (action case final action?) ...[
            const SizedBox(height: 24),
            action,
          ],
        ],
      ),
    );
  }
}
