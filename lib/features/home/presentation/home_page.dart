import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: const Text('AHNI'),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final title = constraints.maxWidth < 400
                          ? '학사 생활을 위한\n준비를 시작해요.'
                          : '학사 생활을 위한 준비를 시작해요.';

                      return Text(title, style: textTheme.headlineMedium);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '개발 환경이 준비됐어요.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text('환경: ${environment.name}', style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
