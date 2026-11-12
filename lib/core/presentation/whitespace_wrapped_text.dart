import 'package:flutter/widgets.dart';

/// 한글 문장을 글자 중간이 아니라 띄어쓰기에서만 줄바꿈한다.
///
/// 단어마다 `Text`를 따로 두고 `Wrap`으로 배치한다. 단어 폭을 렌더링 엔진이 직접 재므로
/// 자간·글꼴·글자 크기가 바뀌어도 줄 끝 글자가 잘리지 않는다. 보이지 않는 연결 문자(U+2060)를
/// 끼우던 이전 방식은 자간을 줄이면 줄 폭을 실제보다 좁게 계산해 글자가 잘렸다.
///
/// 띄어쓰기는 단어 끝에 붙이지 않고 `Wrap.spacing`으로 둔다. 실제 기기 글꼴은 단어 끝 공백의
/// 폭을 0으로 재서 줄 마지막 단어가 앞 단어에 붙고, 줄마다 남는 공백 때문에 가운데 정렬도 어긋났다.
///
/// 단어마다 같은 줄 높이(strut)를 강제해, 글꼴이 다른 영문·문장부호 단어도 기준선이 맞는다.
///
/// 가운데 정렬 글은 줄 수는 그대로 두고 줄 길이를 고르게 나눈다(CSS `text-wrap: balance`).
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
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final space = _measure(' ', resolved, scaler);
    return Semantics(
      label: data,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            for (final line in data.split('\n'))
              _Line(
                words: line
                    .split(_spaces)
                    .where((word) => word.isNotEmpty)
                    .toList(),
                style: style,
                resolved: resolved,
                scaler: scaler,
                space: space,
                alignment: wrapAlignment,
                balance: textAlign == TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// 공백 한 칸이나 단어 하나의 실제 폭. 공백은 두 글자 사이에 끼운 차이로 재야 0이 되지 않는다.
double _measure(String text, TextStyle style, TextScaler scaler) {
  double width(String value) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final result = painter.width;
    painter.dispose();
    return result;
  }

  return text == ' ' ? width('가 가') - width('가가') : width(text);
}

class _Line extends StatelessWidget {
  const _Line({
    required this.words,
    required this.style,
    required this.resolved,
    required this.scaler,
    required this.space,
    required this.alignment,
    required this.balance,
  });

  final List<String> words;
  final TextStyle? style;
  final TextStyle resolved;
  final TextScaler scaler;
  final double space;
  final WrapAlignment alignment;
  final bool balance;

  @override
  Widget build(BuildContext context) {
    // 빈 줄도 한 줄 높이를 차지하게 해 문단 간격을 유지한다.
    if (words.isEmpty) return Text(' ', style: style);
    // 영문·문장부호가 섞인 단어는 다른 글꼴로 그려져 줄 높이와 기준선이 달라진다. 단어를
    // 상자 위쪽에 맞춰 놓으면 높낮이가 어긋나므로, 모든 단어에 같은 줄 높이를 강제해 기준선을 맞춘다.
    final strut = StrutStyle.fromTextStyle(resolved, forceStrutHeight: true);
    final wrap = Wrap(
      alignment: alignment,
      spacing: space,
      children: [
        for (final word in words) Text(word, style: style, strutStyle: strut),
      ],
    );
    if (!balance || words.length < 2) return wrap;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return wrap;
        final widths = [
          for (final word in words)
            _measure(word, resolved, scaler).ceilToDouble(),
        ];
        final width = _balancedWidth(widths, constraints.maxWidth);
        return width == null ? wrap : SizedBox(width: width, child: wrap);
      },
    );
  }

  /// 줄 수를 늘리지 않는 가장 좁은 폭. 이미 한 줄이면 null(그대로 둔다).
  double? _balancedWidth(List<double> widths, double maxWidth) {
    int lines(double limit) {
      var count = 1;
      var used = 0.0;
      for (final width in widths) {
        final next = used == 0 ? width : used + space + width;
        if (next > limit && used > 0) {
          count++;
          used = width;
        } else {
          used = next;
        }
      }
      return count;
    }

    final target = lines(maxWidth);
    if (target < 2) return null;
    var low = widths.reduce((a, b) => a > b ? a : b);
    var high = maxWidth;
    // 렌더링 폭과 잰 폭의 반올림 차이로 한 줄이 더 생기지 않게 여유를 둔다.
    for (var i = 0; i < 20 && high - low > 0.5; i++) {
      final middle = (low + high) / 2;
      if (lines(middle) <= target) {
        high = middle;
      } else {
        low = middle;
      }
    }
    return (high + 2).clamp(0, maxWidth).toDouble();
  }
}
