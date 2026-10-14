import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';
import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';
import 'package:flutter/material.dart';

class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({
    required this.controller,
    required this.onAuthenticationRequired,
    super.key,
  });
  final ScholarshipController controller;
  final VoidCallback onAuthenticationRequired;
  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load();
    });
  }

  void _changed() {
    if (!mounted) return;
    if (widget.controller.status == ScholarshipStatus.unauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthenticationRequired();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final eligibility = controller.eligibility;
    return Scaffold(
      key: const Key('scholarship-page'),
      appBar: AppBar(
        title: const Text('장학요건'),
        actions: [
          IconButton(
            onPressed: controller.status == ScholarshipStatus.loading
                ? null
                : controller.load,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const WhitespaceWrappedText(
                  '등록한 성적을 주전공 학과의 장학 기준과 비교해 봐요. 학교의 실제 장학 선발 결과와는 다를 수 있어요.',
                ),
                const SizedBox(height: 24),
                if (controller.status == ScholarshipStatus.loading ||
                    controller.status == ScholarshipStatus.initial)
                  const Center(child: CircularProgressIndicator()),
                if (controller.status == ScholarshipStatus.failure) ...[
                  WhitespaceWrappedText(
                    controller.message ?? '장학 정보를 불러오지 못했어요. 다시 시도해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: const Text('다시 시도'),
                  ),
                ],
                if (eligibility != null) ...[
                  _SummaryCard(eligibility: eligibility),
                  const SizedBox(height: 20),
                  if (eligibility.results.isEmpty)
                    const WhitespaceWrappedText(
                      key: Key('scholarship-empty'),
                      '아직 등록된 장학 기준이 없어요. 내 정보의 문의사항으로 관리자에게 알려 주세요.',
                    ),
                  for (final result in eligibility.results)
                    _ResultCard(result: result),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.eligibility});
  final ScholarshipEligibility eligibility;
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('scholarship-summary'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WhitespaceWrappedText(
          '${eligibility.departmentName} · ${eligibility.admissionYear}년 입학 기준',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text('누적 평점 ${eligibility.gpa.toStringAsFixed(2)}'),
            Text('이수 ${_credit(eligibility.completedCredits)}학점'),
            Text('학사경고 ${eligibility.warningCount}회'),
          ],
        ),
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ScholarshipResult result;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        key: ValueKey('scholarship-${result.criteriaEntityId}'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: WhitespaceWrappedText(
                    result.name,
                    style: textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  container: true,
                  label: result.met ? '기준 충족' : '기준 미충족',
                  excludeSemantics: true,
                  child: Chip(
                    avatar: Icon(
                      result.met
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                    ),
                    label: Text(result.met ? '충족' : '미충족'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WhitespaceWrappedText(
              '평점 ${result.minGpa.toStringAsFixed(2)} 이상 · ${_credit(result.minCredits)}학점 이상 · 학사경고 ${result.maxWarnings}회 이하',
              style: textTheme.bodySmall,
            ),
            if (!result.met) ...[
              const SizedBox(height: 12),
              for (final shortfall in result.shortfalls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: WhitespaceWrappedText(shortfall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _credit(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();
