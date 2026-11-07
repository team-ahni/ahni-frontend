import 'package:flutter/material.dart';

/// 옅은 바탕(`soft`)과 그 위에 읽히는 글자색(`ink`) 한 쌍. 대비는 WCAG AA(4.5:1) 이상이다.
@immutable
class Tone {
  const Tone({required this.soft, required this.ink});

  final Color soft;
  final Color ink;
}

/// 분류를 색으로 구분할 때 쓰는 AHNI 파스텔 색 쌍. 색만으로 뜻을 전하지 않도록 항상 글자와 함께 쓴다.
@immutable
class AhniPalette extends ThemeExtension<AhniPalette> {
  const AhniPalette({
    required this.blue,
    required this.teal,
    required this.amber,
    required this.rose,
    required this.violet,
  });

  static const light = AhniPalette(
    blue: Tone(soft: Color(0xFFE6F0FB), ink: Color(0xFF14529C)),
    teal: Tone(soft: Color(0xFFE2F4F0), ink: Color(0xFF12695A)),
    amber: Tone(soft: Color(0xFFFBF1DD), ink: Color(0xFF8A5A0B)),
    rose: Tone(soft: Color(0xFFFCE9EC), ink: Color(0xFFA3304A)),
    violet: Tone(soft: Color(0xFFEFEAFB), ink: Color(0xFF5B3FA8)),
  );

  static AhniPalette of(BuildContext context) =>
      Theme.of(context).extension<AhniPalette>() ?? light;

  final Tone blue;
  final Tone teal;
  final Tone amber;
  final Tone rose;
  final Tone violet;

  @override
  AhniPalette copyWith() => this;

  // 테마 전환 애니메이션이 없어 보간하지 않는다.
  @override
  AhniPalette lerp(AhniPalette? other, double t) =>
      t < 0.5 ? this : other ?? this;
}
