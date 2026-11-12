import 'package:flutter/material.dart';

/// 저장·제출 버튼 글자. 처리 중이면 글자 앞에 작은 원형 로딩을 붙인다.
/// 글자를 지우지 않아 버튼 폭이 그대로이고 스크린 리더도 무엇을 하는 중인지 읽는다.
class BusyButtonLabel extends StatelessWidget {
  const BusyButtonLabel({required this.isBusy, required this.label, super.key});

  final bool isBusy;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBusy) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label)),
      ],
    );
  }
}
