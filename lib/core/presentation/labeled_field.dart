import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';

/// 입력창 위에 이름을 두는 공용 틀. 이름이 항상 보여 입력 중에도 무엇을 적는 칸인지 알 수 있다.
///
/// Flutter 입력창은 라벨을 박스 안이나 테두리 위에만 그리므로 라벨을 밖으로 빼서 함께 묶는다.
/// 글자 입력칸은 이름을 바로 앞에서 읽고, 안내 문구도 함께 읽힌다. 안에 버튼이 있는
/// 입력칸(비밀번호 보기)은 MergeSemantics로 합치면 Flutter 단언이 깨져 합치지 않는다.
/// 드롭다운처럼 값을 고르기 전엔 읽을 글이 없는 입력은 이름과 합쳐 "성적 등급, 버튼"처럼 읽게 한다.
class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [FieldLabel(label), child],
    );
    return child is TextField || child is TextFormField
        ? column
        : MergeSemantics(child: column);
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

/// 입력 아래 오류 문구. 라벨(`FieldLabel`)과 칸 테두리와 같은 왼쪽 선에 둔다.
/// 칩 묶음처럼 입력칸이 없는 입력의 오류도 이것으로 보인다.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: WhitespaceWrappedText(
        message,
        style:
            theme.inputDecorationTheme.errorStyle ??
            theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}

/// Material 3 입력칸이 내용과 오류 문구 앞에 더하는 틈. Flutter 내부 값이라 테마로 못 바꾼다.
const double _materialInputGap = 4;

/// 글자 입력칸·드롭다운의 `errorBuilder`. 오류가 있을 수 있는 칸에는 모두 단다.
///
/// Flutter는 오류 문구를 칸 안 글자 시작선(안쪽 여백 + 4)에 그리고 이 위치는 테마로 못 바꾼다.
/// 그만큼 왼쪽으로 당겨 라벨·칸 테두리와 같은 선에 맞춘다. 읽기 순서와 알림은 Flutter가 그대로 처리한다.
Widget fieldErrorBuilder(BuildContext context, String errorText) {
  final padding =
      Theme.of(context).inputDecorationTheme.contentPadding
          ?.resolve(Directionality.of(context)) ??
      EdgeInsets.zero;
  return Transform.translate(
    offset: Offset(-(padding.left + _materialInputGap), 0),
    child: FieldErrorText(errorText),
  );
}
