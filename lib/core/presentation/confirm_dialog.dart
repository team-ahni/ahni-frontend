import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';

/// 앱의 모든 확인 창. 제목은 질문으로 쓰고, 같은 폭의 두 버튼을 한 줄에 둔다.
/// 왼쪽은 물러서는 동작(취소·다시 선택하기), 오른쪽은 진행하는 동작이다.
/// 지우는 동작이면 [destructive]로 진행 버튼을 위험 색으로 칠한다.
/// true면 진행, false면 물러서기, null이면 창 밖을 눌러 닫은 것이다.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  Widget? details,
  String cancelLabel = '취소',
  bool destructive = false,
  Key? dialogKey,
  Key? confirmKey,
  Key? cancelKey,
}) => showDialog<bool>(
  context: context,
  builder: (context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: dialogKey,
      title: WhitespaceWrappedText(title),
      content: message == null && details == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message case final text?)
                  WhitespaceWrappedText(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (message != null && details != null)
                  const SizedBox(height: 12),
                ?details,
              ],
            ),
      actions: [
        // 큰 글자에서 한쪽만 줄이 바뀌어도 두 버튼 높이를 맞춘다.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OutlinedButton(
                  key: cancelKey,
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: confirmKey,
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  },
);
