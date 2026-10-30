import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_edit_page.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_registration_page.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_simulation_page.dart';
import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';
import 'package:ahni_mobile/features/scholarship/presentation/scholarship_page.dart';
import 'package:flutter/material.dart';

class GradeListPage extends StatefulWidget {
  const GradeListPage({
    required this.controller,
    required this.simulationController,
    required this.courseController,
    required this.registrationController,
    required this.editController,
    required this.scholarshipController,
    required this.onAuthenticationRequired,
    this.bottomNavigationBar,
    super.key,
  });

  final GradeListController controller;
  final GradeSimulationController simulationController;
  final CourseCatalogController courseController;
  final GradeRegistrationController registrationController;
  final GradeEditController editController;
  final ScholarshipController scholarshipController;
  final VoidCallback onAuthenticationRequired;
  final Widget? bottomNavigationBar;

  @override
  State<GradeListPage> createState() => _GradeListPageState();
}

class _GradeListPageState extends State<GradeListPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  @override
  void didUpdateWidget(covariant GradeListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openSimulation() async {
    widget.simulationController.reset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => GradeSimulationPage(
          controller: widget.simulationController,
          onAuthenticationRequired: () {
            if (routeContext.mounted) Navigator.of(routeContext).pop();
            widget.onAuthenticationRequired();
          },
        ),
      ),
    );
  }

  Future<void> _openScholarship() async {
    widget.scholarshipController.reset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => ScholarshipPage(
          controller: widget.scholarshipController,
          onAuthenticationRequired: () {
            if (routeContext.mounted) Navigator.of(routeContext).pop();
            widget.onAuthenticationRequired();
          },
        ),
      ),
    );
  }

  Future<void> _openRegistration() async {
    widget.registrationController.reset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (registrationContext) => GradeRegistrationPage(
          courseController: widget.courseController,
          registrationController: widget.registrationController,
          availableGrades: _availableGrades,
          onOcrImported: () async {
            await widget.controller.retry();
            if (registrationContext.mounted) {
              Navigator.of(registrationContext).pop();
            }
          },
          onRegistered: (_) async {
            await widget.controller.retry();
            if (registrationContext.mounted) {
              Navigator.of(registrationContext).pop();
            }
          },
          onAuthenticationRequired: () {
            if (registrationContext.mounted) {
              Navigator.of(registrationContext).pop();
            }
            widget.onAuthenticationRequired();
          },
        ),
      ),
    );
  }

  Future<void> _openEdit(GradeRecord grade) async {
    widget.editController.reset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (editContext) => GradeEditPage(
          grade: grade,
          availableGrades: _availableGrades,
          controller: widget.editController,
          onSaved: (_) => _refreshAndClose(editContext),
          onDeleted: () => _refreshAndClose(editContext),
          onAuthenticationRequired: () {
            if (editContext.mounted) Navigator.of(editContext).pop();
            widget.onAuthenticationRequired();
          },
        ),
      ),
    );
  }

  Future<void> _refreshAndClose(BuildContext routeContext) async {
    await widget.controller.retry();
    if (routeContext.mounted) Navigator.of(routeContext).pop();
  }

  List<GradeRecord> get _availableGrades => switch (widget.controller.state) {
    GradeListReady state => state.grades,
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('grade-list-page'),
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text('성적'),
        actions: [
          IconButton(
            key: const Key('open-grade-simulation'),
            tooltip: '평점 시뮬레이션',
            onPressed:
                widget.controller.state is GradeListAuthenticationRequired
                ? null
                : _openSimulation,
            icon: const Icon(Icons.calculate_outlined),
          ),
          IconButton(
            key: const Key('open-scholarship'),
            tooltip: '장학요건',
            onPressed:
                widget.controller.state is GradeListAuthenticationRequired
                ? null
                : _openScholarship,
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          TextButton(
            key: const Key('open-grade-registration'),
            onPressed: _openRegistration,
            child: const Text('등록'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: SafeArea(
        top: false,
        child: switch (widget.controller.state) {
          GradeListInitial() || GradeListLoading() => const _LoadingView(),
          GradeListReady state => _GradeList(
            grades: state.grades,
            summary: state.summary,
            onGradeSelected: _openEdit,
          ),
          GradeListEmpty() => _EmptyView(onRegister: _openRegistration),
          GradeListFailure state => _FailureView(
            message: state.message,
            onRetry: widget.controller.retry,
          ),
          GradeListAuthenticationRequired() => _AuthenticationRequiredView(
            onReturnToLogin: widget.onAuthenticationRequired,
          ),
        },
      ),
    );
  }
}

class _GradeList extends StatelessWidget {
  const _GradeList({
    required this.grades,
    required this.summary,
    required this.onGradeSelected,
  });

  final List<GradeRecord> grades;
  final GradeSummary summary;
  final ValueChanged<GradeRecord> onGradeSelected;

  @override
  Widget build(BuildContext context) {
    final groups = _groupGrades(grades);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhitespaceWrappedText(
                '학기별 성적을 확인하세요',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              WhitespaceWrappedText(
                '입력한 성적을 최신 학기부터 모아 보여드려요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _GradeSummaryCard(summary: summary),
              const SizedBox(height: 24),
              for (var index = 0; index < groups.length; index++) ...[
                _GradeTermSection(
                  group: groups[index],
                  onGradeSelected: onGradeSelected,
                ),
                if (index != groups.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeSummaryCard extends StatelessWidget {
  const _GradeSummaryCard({required this.summary});

  final GradeSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label:
          '전체 평점 ${_formatGpa(summary.gpa)}, 이수 ${_formatNumber(summary.completedCredits)}학점, 평점 반영 ${_formatNumber(summary.gpaCredits)}학점',
      child: Container(
        key: const Key('grade-summary'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '전체 성적',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              _formatGpa(summary.gpa),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            WhitespaceWrappedText(
              '평점 반영 ${_formatNumber(summary.gpaCredits)}학점 · 이수 ${_formatNumber(summary.completedCredits)}학점',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            if (summary.categories.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  for (final category in summary.categories)
                    _CategorySummary(summary: category),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({required this.summary});

  final GradeCategorySummary summary;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return SizedBox(
      width: 124,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryLabel(summary.category),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            _formatGpa(summary.gpa),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(
            '${_formatNumber(summary.completedCredits)}학점 이수',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _GradeTermSection extends StatelessWidget {
  const _GradeTermSection({required this.group, required this.onGradeSelected});

  final _GradeGroup group;
  final ValueChanged<GradeRecord> onGradeSelected;

  @override
  Widget build(BuildContext context) {
    final title = '${group.academicYear}년 ${group.term.label}';
    return Semantics(
      label: '$title 성적',
      container: true,
      child: Material(
        key: Key('grade-term-${group.academicYear}-${group.term.apiName}'),
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.onSurface
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              for (var index = 0; index < group.grades.length; index++) ...[
                _GradeRow(
                  grade: group.grades[index],
                  onTap: () => onGradeSelected(group.grades[index]),
                ),
                if (index != group.grades.length - 1) const Divider(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade, required this.onTap});

  final GradeRecord grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      grade.course.code,
      '${_formatNumber(grade.credit)}학점',
      if (grade.isRetake) '재수강',
    ].join(' · ');
    final semantics = [
      grade.course.name,
      metadata,
      '성적 ${grade.gradeLabel}',
      if (grade.gradePoint case final point?) '평점 ${_formatNumber(point)}',
    ].join(', ');

    return Semantics(
      label: semantics,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        key: Key('grade-row-${grade.entityId}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.course.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade.gradeLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (grade.gradePoint case final point?) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatNumber(point)}점',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          WhitespaceWrappedText('성적을 불러오는 중이에요…'),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.school_outlined,
      title: '아직 등록된 성적이 없어요',
      message: '성적을 등록하면 학기별 이력을 여기서 확인할 수 있어요.',
      action: FilledButton(
        key: const Key('open-grade-registration-empty'),
        onPressed: onRegister,
        child: const Text('성적 등록'),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: '성적을 불러오지 못했어요',
      message: message,
      action: FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
    );
  }
}

class _AuthenticationRequiredView extends StatelessWidget {
  const _AuthenticationRequiredView({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.lock_outline_rounded,
      title: '다시 로그인이 필요해요',
      message: '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      action: FilledButton(
        onPressed: onReturnToLogin,
        child: const Text('로그인으로 돌아가기'),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 360),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  WhitespaceWrappedText(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  WhitespaceWrappedText(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (action case final value?) ...[
                    const SizedBox(height: 24),
                    value,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeGroup {
  const _GradeGroup({
    required this.academicYear,
    required this.term,
    required this.grades,
  });

  final int academicYear;
  final AcademicTerm term;
  final List<GradeRecord> grades;
}

List<_GradeGroup> _groupGrades(List<GradeRecord> grades) {
  final grouped = <(int, AcademicTerm), List<GradeRecord>>{};
  for (final grade in grades) {
    grouped.putIfAbsent((grade.academicYear, grade.term), () => []).add(grade);
  }
  return grouped.entries
      .map(
        (entry) => _GradeGroup(
          academicYear: entry.key.$1,
          term: entry.key.$2,
          grades: entry.value,
        ),
      )
      .toList(growable: false);
}

String _formatNumber(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String _formatGpa(double value) => value.toStringAsFixed(2);

String _categoryLabel(CourseCategory category) => switch (category) {
  CourseCategory.major => '전공',
  CourseCategory.generalEducation => '교양',
  CourseCategory.elective => '일반선택',
};
