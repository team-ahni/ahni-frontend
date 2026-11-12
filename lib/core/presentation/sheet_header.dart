import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';

/// 모든 바텀시트의 머리글: 왼쪽 제목, 오른쪽 닫기(X).
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WhitespaceWrappedText(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // 48pt 터치 영역은 그대로 두고, X 모양을 아래 내용의 오른쪽 끝에 맞춘다.
        Transform.translate(
          offset: const Offset(12, 0),
          child: IconButton(
            key: const Key('sheet-close'),
            tooltip: '닫기',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

/// 시트 아래 여백: 키보드가 열리면 키보드 위, 닫히면 홈 표시줄 위까지 띄운다.
/// (`useSafeArea: true`는 아래쪽 안전 영역을 채우지 않는다.)
double sheetBottomInset(BuildContext context) =>
    MediaQuery.viewInsetsOf(context).bottom +
    MediaQuery.paddingOf(context).bottom;
