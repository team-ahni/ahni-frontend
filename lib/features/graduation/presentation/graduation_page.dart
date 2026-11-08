import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:flutter/material.dart';

class GraduationPage extends StatefulWidget {
  const GraduationPage({
    required this.controller,
    required this.onAuthenticationRequired,
    required this.bottomNavigationBar,
    super.key,
  });
  final GraduationController controller;
  final VoidCallback onAuthenticationRequired;
  final Widget bottomNavigationBar;
  @override
  State<GraduationPage> createState() => _GraduationPageState();
}

class _GraduationPageState extends State<GraduationPage> {
  String _major = 'ALL';
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
    if (widget.controller.status == GraduationStatus.unauthorized) {
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
    return Scaffold(
      key: const Key('graduation-progress-page'),
      appBar: AppBar(
        title: const Text('졸업 준비'),
        actions: [
          IconButton(
            onPressed: controller.status == GraduationStatus.loading
                ? null
                : controller.load,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const NoticeCallout(
                  icon: Icons.flag_outlined,
                  message: '등록한 성적과 학과 기준을 비교해 봐요. 학교의 최종 졸업 판정과는 다를 수 있어요.',
                ),
                const SizedBox(height: 20),
                if (controller.status == GraduationStatus.loading ||
                    controller.status == GraduationStatus.initial)
                  const Center(child: CircularProgressIndicator()),
                if (controller.status == GraduationStatus.missing ||
                    controller.status == GraduationStatus.failure) ...[
                  WhitespaceWrappedText(
                    controller.message ??
                        '아직 등록된 졸업 기준이 없어요. 학과와 입학연도를 확인해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: const Text('다시 시도'),
                  ),
                ],
                if (controller.overview.length > 1) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final option in [
                        'ALL',
                        ...controller.overview.map((item) => item.majorType),
                      ])
                        ChoiceChip(
                          label: Text(
                            option == 'ALL'
                                ? '전공 전체'
                                : controller.overview
                                      .firstWhere(
                                        (item) => item.majorType == option,
                                      )
                                      .majorLabel,
                          ),
                          selected: _major == option,
                          onSelected: (_) => setState(() => _major = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                for (final item in controller.overview.where(
                  (item) => _major == 'ALL' || item.majorType == _major,
                ))
                  _OverviewCard(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});
  final GraduationOverview item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhitespaceWrappedText(
            '${item.majorLabel} · ${item.departmentName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          WhitespaceWrappedText(
            '${item.admissionYear}년 입학 기준 · ${item.creditsMet ? '학점 기준 충족' : '학점 확인 필요'}',
          ),
          const SizedBox(height: 8),
          WhitespaceWrappedText(
            item.requirementsMet
                ? '등록된 학점·필수과목 기준을 모두 충족했어요.'
                : '남은 학점과 필수과목을 확인해 주세요.',
          ),
          const SizedBox(height: 20),
          _CreditRow(label: '총 학점', credit: item.total),
          _CreditRow(label: '전공 학점', credit: item.department),
          _CreditRow(label: '교양 학점', credit: item.general),
          _RequiredCourses(
            key: ValueKey(item.entityId),
            courses: item.requiredCourses,
          ),
          const Divider(height: 32),
          WhitespaceWrappedText(
            '기준 출처: ${item.sourceTitle}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.sourceUrl case final url?)
            SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _RequiredCourses extends StatefulWidget {
  const _RequiredCourses({required this.courses, super.key});
  final List<RequiredCourseCompletion> courses;
  @override
  State<_RequiredCourses> createState() => _RequiredCoursesState();
}

class _RequiredCoursesState extends State<_RequiredCourses> {
  String _category = 'ALL';
  String _completion = 'ALL';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses
        .where(
          (course) =>
              (_category == 'ALL' || course.category == _category) &&
              (_completion == 'ALL' ||
                  course.completed == (_completion == 'DONE')),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          '필수과목 ${widget.courses.where((course) => course.completed).length}/${widget.courses.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (widget.courses.isEmpty)
          const WhitespaceWrappedText('이 기준에는 필수과목이 등록되어 있지 않아요.'),
        if (widget.courses.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '필수과목 분류'),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('분류 전체')),
              DropdownMenuItem(value: 'MAJOR_FOUNDATION', child: Text('전공 기초')),
              DropdownMenuItem(value: 'MAJOR_REQUIRED', child: Text('전공 필수')),
              DropdownMenuItem(value: 'GENERAL_REQUIRED', child: Text('교양 필수')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final option in const {
                'ALL': '전체',
                'MISSING': '미이수',
                'DONE': '이수',
              }.entries)
                ChoiceChip(
                  label: Text(option.value),
                  selected: _completion == option.key,
                  onSelected: (_) => setState(() => _completion = option.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const WhitespaceWrappedText('선택한 조건에 맞는 과목이 없어요.'),
          for (final course in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WhitespaceWrappedText(
                    course.courseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(course.courseCode),
                      Text(course.categoryLabel),
                      Text(course.completed ? '이수 완료' : '이수 필요'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.label, required this.credit});
  final String label;
  final CreditProgress credit;
  String _format(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${_format(credit.completed)} / ${_format(credit.required)}학점',
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: credit.required == 0
              ? 1
              : (credit.completed / credit.required).clamp(0, 1),
          semanticsLabel:
              '$label · ${credit.met ? "충족" : "${_format(credit.remaining)}학점 남음"}',
        ),
        const SizedBox(height: 8),
        Text(
          credit.met ? '충족' : '${_format(credit.remaining)}학점 남았어요',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
