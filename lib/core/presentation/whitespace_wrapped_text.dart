import 'package:flutter/widgets.dart';

/// 한글 문장을 글자 중간이 아니라 띄어쓰기에서만 줄바꿈한다.
///
/// 단어마다 `Text`를 따로 두고 `Wrap`으로 배치한다. 단어 폭을 렌더링 엔진이 직접 재므로
/// 자간·글꼴·글자 크기가 바뀌어도 줄 끝 글자가 잘리지 않는다. 보이지 않는 연결 문자(U+2060)를
/// 끼우던 이전 방식은 자간을 줄이면 줄 폭을 실제보다 좁게 계산해 글자가 잘렸다.
/// 한 단어가 한 줄보다 길면 그 단어만 글자 단위로 줄바꿈한다.
class WhitespaceWrappedText extends StatelessWidget {
  const WhitespaceWrappedText(
    this.data, {
    this.style,
    this.textAlign,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  static final _spaces = RegExp(r'[ \t]+');

  @override
  Widget build(BuildContext context) {
    final (wrapAlignment, crossAxisAlignment) = switch (textAlign) {
      TextAlign.center => (WrapAlignment.center, CrossAxisAlignment.center),
      TextAlign.end ||
      TextAlign.right => (WrapAlignment.end, CrossAxisAlignment.end),
      _ => (WrapAlignment.start, CrossAxisAlignment.start),
    };
    return Semantics(
      label: data,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (final line in data.split('\n'))
              _line(
                line.split(_spaces).where((word) => word.isNotEmpty).toList(),
                wrapAlignment,
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(List<String> words, WrapAlignment alignment) {
    // 빈 줄도 한 줄 높이를 차지하게 해 문단 간격을 유지한다.
    if (words.isEmpty) return Text(' ', style: style);
    return Wrap(
      alignment: alignment,
      children: [
        for (var i = 0; i < words.length; i++)
          Text(
            i == words.length - 1 ? words[i] : '${words[i]} ',
            style: style,
            textAlign: textAlign,
          ),
      ],
    );
  }
}
