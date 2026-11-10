import 'package:flutter/material.dart';

/// 입력창 위에 이름을 두는 공용 틀. 이름이 항상 보여 입력 중에도 무엇을 적는 칸인지 알 수 있다.
///
/// Flutter 입력창은 라벨을 박스 안이나 테두리 위에만 그리므로 라벨을 밖으로 빼서 함께 묶는다.
/// 스크린 리더는 이름을 입력창 바로 앞에서 읽는다. 안에 버튼이 있는 입력창(비밀번호 보기,
/// 드롭다운)은 MergeSemantics로 합치면 Flutter 단언이 깨져 합치지 않는다.
class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [FieldLabel(label), child],
    );
  }
}

/// 입력 묶음 위 이름. 칩 묶음처럼 `LabeledField`로 감쌀 수 없는 입력에도 같은 모양으로 쓴다.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
