import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 아띠의 표정. 화면 상황에 맞는 하나를 고른다.
enum AhniMood {
  /// 처음 만날 때, 아직 아무것도 없을 때.
  hello,

  /// 무언가 필요하다고 알려 줄 때.
  curious,

  /// 불러오기 실패나 로그인 만료처럼 일이 꼬였을 때.
  oops,

  /// 무언가를 마쳤을 때. 두 팔을 들고 뛰어오른다.
  cheer,
}

/// AHNI 캐릭터 '아띠'(순우리말로 '친구'). INHA를 뒤집은 AHNI처럼 학생 쪽에서 학교를 보는 친구로,
/// 머리에 학기마다 자라는 새싹이 달려 있다.
///
/// 외부 그림 파일 없이 그리므로 어떤 크기에서도 선명하고 패키지가 필요 없다.
/// 장식이라 스크린 리더에는 읽히지 않는다. 뜻은 옆의 제목·설명 글이 전한다.
class AhniMascot extends StatelessWidget {
  const AhniMascot({this.mood = AhniMood.hello, this.size = 104, super.key});

  final AhniMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AhniPainter(mood)),
      ),
    );
  }
}

/// 캐릭터 그림 전용 색. 몸은 AHNI 파랑(`AppColors.accent`)보다 한 단계 밝혀 친근하게 보이게 한다.
abstract final class _Ink {
  static const body = Color(0xFF3F7FD0);
  static const bodyShade = Color(0xFF2F69B5);
  static const belly = Color(0xFFDCEAFA);
  static const eye = Color(0xFF18202A);
  static const cheek = Color(0xFFF6A9B8);
  static const leaf = Color(0xFF34A88C);
  static const leafShade = Color(0xFF238A72);
  static const shadow = Color(0x1A18202A);
  static const sparkle = Color(0xFFF2B23A);
}

class _AhniPainter extends CustomPainter {
  const _AhniPainter(this.mood);

  final AhniMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    // 100×100 격자에서 그리고 실제 크기로 늘린다.
    canvas.scale(size.width / 100, size.height / 100);
    _shadow(canvas);
    if (mood == AhniMood.cheer) {
      // 뛰어오른 모습: 그림자는 그대로 두고 몸만 올린다.
      canvas.save();
      canvas.translate(0, -5);
      _figure(canvas);
      canvas.restore();
      _sparkles(canvas);
    } else {
      _figure(canvas);
    }
  }

  void _shadow(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTRB(26, 89, 74, 97),
      Paint()..color = _Ink.shadow,
    );
  }

  void _figure(Canvas canvas) {
    _sprout(canvas);
    _arms(canvas);
    final body = RRect.fromLTRBAndCorners(
      20,
      30,
      80,
      90,
      topLeft: const Radius.circular(30),
      topRight: const Radius.circular(30),
      bottomLeft: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
    );
    canvas.drawRRect(body, Paint()..color = _Ink.body);
    // 아래쪽 옅은 배. 몸 안에서만 보이게 자른다.
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawOval(
      const Rect.fromLTRB(30, 62, 70, 100),
      Paint()..color = _Ink.belly,
    );
    canvas.restore();
    _face(canvas);
  }

  void _sprout(Canvas canvas) {
    final stem = Paint()
      ..color = _Ink.leafShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(50, 31)
        ..quadraticBezierTo(49, 24, 51, 18),
      stem,
    );
    _leaf(canvas, const Offset(51, 18), -0.55, 13);
    _leaf(canvas, const Offset(51, 19), math.pi + 0.45, 10);
  }

  void _leaf(Canvas canvas, Offset base, double angle, double length) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -length * 0.45, length, 0)
      ..quadraticBezierTo(length * 0.5, length * 0.45, 0, 0);
    canvas.drawPath(path, Paint()..color = _Ink.leaf);
    canvas.restore();
  }

  void _arms(Canvas canvas) {
    final arm = Paint()
      ..color = _Ink.bodyShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final (left, right) = switch (mood) {
      AhniMood.hello => (
        (const Offset(22, 66), const Offset(16, 74)),
        (const Offset(78, 58), const Offset(88, 46)),
      ),
      // 턱을 괴듯 몸 앞으로 올린 팔.
      AhniMood.curious => (
        (const Offset(22, 66), const Offset(16, 74)),
        (const Offset(78, 66), const Offset(70, 72)),
      ),
      AhniMood.oops => (
        (const Offset(22, 66), const Offset(16, 74)),
        (const Offset(78, 66), const Offset(84, 74)),
      ),
      AhniMood.cheer => (
        (const Offset(22, 58), const Offset(12, 46)),
        (const Offset(78, 58), const Offset(88, 46)),
      ),
    };
    canvas.drawLine(left.$1, left.$2, arm);
    canvas.drawLine(right.$1, right.$2, arm);
  }

  void _face(Canvas canvas) {
    final eye = Paint()..color = _Ink.eye;
    final line = Paint()
      ..color = _Ink.eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final cheek = Paint()..color = _Ink.cheek.withValues(alpha: 0.85);
    canvas.drawOval(const Rect.fromLTRB(28, 56, 37, 61), cheek);
    canvas.drawOval(const Rect.fromLTRB(63, 56, 72, 61), cheek);

    switch (mood) {
      case AhniMood.hello:
        _openEyes(canvas, eye, const Offset(0, 0));
        canvas.drawArc(
          const Rect.fromLTRB(45, 56, 55, 63),
          0.2,
          math.pi - 0.4,
          false,
          line,
        );
      case AhniMood.curious:
        // 위쪽을 올려다보는 눈과 작은 입.
        _openEyes(canvas, eye, const Offset(1.5, -2));
        canvas.drawCircle(const Offset(50, 61), 2, eye);
        _question(canvas);
      case AhniMood.oops:
        // 안쪽이 올라간 걱정 눈썹과 물결 입, 땀 한 방울.
        canvas.drawLine(const Offset(35, 49), const Offset(41, 46.5), line);
        canvas.drawLine(const Offset(65, 49), const Offset(59, 46.5), line);
        _openEyes(canvas, eye, const Offset(0, 2));
        canvas.drawPath(
          Path()
            ..moveTo(45, 62)
            ..quadraticBezierTo(47.5, 59.5, 50, 62)
            ..quadraticBezierTo(52.5, 64.5, 55, 62),
          line,
        );
        _sweat(canvas);
      case AhniMood.cheer:
        // 웃어서 감긴 눈과 크게 벌린 입.
        canvas.drawArc(
          const Rect.fromLTRB(35, 48, 43, 55),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          line,
        );
        canvas.drawArc(
          const Rect.fromLTRB(57, 48, 65, 55),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(45, 58)
            ..quadraticBezierTo(50, 67, 55, 58)
            ..close(),
          eye,
        );
    }
  }

  void _openEyes(Canvas canvas, Paint eye, Offset look) {
    for (final x in [39.0, 61.0]) {
      final center = Offset(x, 53) + look;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 6, height: 7.5),
        eye,
      );
      canvas.drawCircle(
        center + const Offset(1.2, -1.6),
        1.3,
        Paint()..color = Colors.white,
      );
    }
  }

  void _question(Canvas canvas) {
    final mark = Paint()
      ..color = _Ink.bodyShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(80, 22)
        ..quadraticBezierTo(80, 15, 86, 15)
        ..quadraticBezierTo(92, 15, 92, 21)
        ..quadraticBezierTo(92, 25, 86, 27)
        ..lineTo(86, 30),
      mark,
    );
    canvas.drawCircle(
      const Offset(86, 36),
      1.8,
      Paint()..color = _Ink.bodyShade,
    );
  }

  void _sweat(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(88, 30)
        ..quadraticBezierTo(83, 38, 88, 40)
        ..quadraticBezierTo(93, 38, 88, 30)
        ..close(),
      Paint()..color = const Color(0xFF5FA8E8),
    );
  }

  void _sparkles(Canvas canvas) {
    final paint = Paint()..color = _Ink.sparkle;
    for (final (center, r) in [
      (const Offset(14, 30), 4.5),
      (const Offset(88, 22), 5.5),
      (const Offset(84, 50), 3.0),
    ]) {
      final path = Path()..moveTo(center.dx, center.dy - r);
      path.quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy);
      path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r);
      path.quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy);
      path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AhniPainter oldDelegate) => oldDelegate.mood != mood;
}
