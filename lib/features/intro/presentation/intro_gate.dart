import 'package:ahni_mobile/features/intro/data/intro_store.dart';
import 'package:ahni_mobile/features/intro/presentation/intro_page.dart';
import 'package:flutter/material.dart';

/// 처음 실행이면 앱 소개를 먼저 보여 주고, 다 보면 [child](로그인 흐름)로 넘어간다.
class IntroGate extends StatefulWidget {
  const IntroGate({required this.store, required this.child, super.key});

  final IntroStore store;
  final Widget child;

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  /// 저장소를 읽기 전에는 null. 그동안 빈 화면을 잠깐 보인다.
  bool? _seen;

  @override
  void initState() {
    super.initState();
    widget.store.isSeen().then((seen) {
      if (mounted) setState(() => _seen = seen);
    });
  }

  void _finish() {
    widget.store.markSeen();
    setState(() => _seen = true);
  }

  @override
  Widget build(BuildContext context) => switch (_seen) {
    null => const Scaffold(),
    false => IntroPage(onDone: _finish),
    true => widget.child,
  };
}
