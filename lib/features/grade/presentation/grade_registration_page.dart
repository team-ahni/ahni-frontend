import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_replacement_candidates.dart';
import 'package:ahni_mobile/features/grade/presentation/replacement_grade_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeRegistrationPage extends StatefulWidget {
  const GradeRegistrationPage({
    required this.courseController,
    required this.registrationController,
    required this.onRegistered,
    required this.onAuthenticationRequired,
    this.initialAcademicYear,
    this.availableGrades = const [],
    super.key,
  });

  final CourseCatalogController courseController;
  final GradeRegistrationController registrationController;
  final Future<void> Function(GradeRecord grade) onRegistered;
  final VoidCallback onAuthenticationRequired;
  final int? initialAcademicYear;
  final List<GradeRecord> availableGrades;

  @override
  State<GradeRegistrationPage> createState() => _GradeRegistrationPageState();
}

class _GradeRegistrationPageState extends State<GradeRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _gradeFieldKey = GlobalKey<FormFieldState<GradeCode>>();
  late final TextEditingController _academicYearController;
  final _creditController = TextEditingController();
  CourseCatalogItem? _course;
  AcademicTerm? _term;
  GradeCode? _gradeCode;
  var _rpl = false;
  String? _replacedGradeEntityId;
  var _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _academicYearController = TextEditingController(
      text: (widget.initialAcademicYear ?? DateTime.now().year).toString(),
    );
    widget.courseController.addListener(_refresh);
    widget.registrationController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCourses();
    });
  }

  @override
  void dispose() {
    widget.courseController.removeListener(_refresh);
    widget.registrationController.removeListener(_refresh);
    _academicYearController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _selectCourse() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final year = _academicYearController.text;
    final term = _term;
    final selected = await showModalBottomSheet<CourseCatalogItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CoursePickerSheet(controller: widget.courseController),
    );
    if (selected == null ||
        !mounted ||
        year != _academicYearController.text ||
        term != _term) {
      return;
    }
    setState(() {
      _course = selected;
      _creditController.text = _formatNumber(selected.credit);
      _syncReplacement();
    });
    if (_hasSubmitted) _formKey.currentState?.validate();
  }

  String? _validateYear(String? value) {
    final year = int.tryParse(value?.trim() ?? '');
    if (year == null || year < 2000 || year > DateTime.now().year) {
      return '2000년부터 올해까지의 수강연도를 입력해 주세요.';
    }
    return null;
  }

  void _loadCourses() {
    final year = int.tryParse(_academicYearController.text);
    if (_validateYear(_academicYearController.text) == null &&
        year != null &&
        _term != null) {
      widget.courseController.load(academicYear: year, term: _term!);
    } else {
      widget.courseController.reset();
    }
  }

  void _changeYear(String value) {
    setState(() {
      _course = null;
      _creditController.clear();
      _replacedGradeEntityId = null;
    });
    widget.registrationController.reset();
    _loadCourses();
  }

  String? _validateCredit(String? value) {
    final normalized = value?.trim() ?? '';
    final credit = double.tryParse(normalized);
    if (credit == null || credit <= 0 || credit > 30) {
      return '0보다 크고 30 이하인 학점을 입력해 주세요.';
    }
    if (!RegExp(r'^\d{1,2}(\.\d)?$').hasMatch(normalized)) {
      return '학점은 소수점 첫째 자리까지만 입력해 주세요.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate()) return;
    await widget.registrationController.submit(
      GradeRegistration(
        courseEntityId: _course!.entityId,
        academicYear: int.parse(_academicYearController.text.trim()),
        term: _term!,
        gradeCode: _rpl ? null : _gradeCode,
        credit: double.parse(_creditController.text.trim()),
        rpl: _rpl,
        replacedGradeEntityId: _rpl ? null : _replacedGradeEntityId,
      ),
    );
    if (!mounted) return;
    switch (widget.registrationController.state) {
      case GradeRegistrationSuccess state:
        await widget.onRegistered(state.grade);
      case GradeRegistrationAuthenticationRequired():
        widget.onAuthenticationRequired();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = widget.registrationController.state;
    final isSubmitting = registrationState is GradeRegistrationSubmitting;
    final catalogReady = widget.courseController.state is CourseCatalogReady;
    final message = switch (registrationState) {
      GradeRegistrationFailure state => state.message,
      _ => null,
    };

    return Scaffold(
      key: const Key('grade-registration-page'),
      appBar: AppBar(titleSpacing: 24, title: const Text('성적 등록')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WhitespaceWrappedText(
                      '수강한 과목의 성적을 기록하세요',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    WhitespaceWrappedText(
                      '과목과 학기를 선택하면 성적 이력에 바로 반영돼요.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Material(
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
                            if (message case final value?) ...[
                              _ErrorMessage(message: value),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              key: const Key('academic-year'),
                              controller: _academicYearController,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              textInputAction: TextInputAction.next,
                              onChanged: _changeYear,
                              validator: _validateYear,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: const InputDecoration(
                                labelText: '수강연도',
                                suffixText: '년',
                              ),
                            ),
                            const SizedBox(height: 20),
                            FormField<AcademicTerm>(
                              validator: (_) =>
                                  _term == null ? '수강학기를 선택해 주세요.' : null,
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '수강학기',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final term in AcademicTerm.values)
                                        ChoiceChip(
                                          key: Key('term-${term.apiName}'),
                                          label: Text(term.label),
                                          selected: _term == term,
                                          onSelected: isSubmitting
                                              ? null
                                              : (_) {
                                                  if (_term == term) return;
                                                  setState(() {
                                                    _term = term;
                                                    _course = null;
                                                    _creditController.clear();
                                                    _replacedGradeEntityId =
                                                        null;
                                                  });
                                                  field.didChange(term);
                                                  widget.registrationController
                                                      .reset();
                                                  _loadCourses();
                                                },
                                        ),
                                    ],
                                  ),
                                  if (field.errorText case final error?) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      error,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            FormField<CourseCatalogItem>(
                              validator: (_) =>
                                  _course == null ? '과목을 선택해 주세요.' : null,
                              builder: (field) => InkWell(
                                key: const Key('course-picker'),
                                onTap: isSubmitting || !catalogReady
                                    ? null
                                    : _selectCourse,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: '과목',
                                    errorText: field.errorText,
                                    suffixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                  ),
                                  child: _course == null
                                      ? const WhitespaceWrappedText(
                                          '선택한 연도의 과목을 찾아보세요',
                                        )
                                      : _SelectedCourse(course: _course!),
                                ),
                              ),
                            ),
                            switch (widget.courseController.state) {
                              CourseCatalogLoading() => const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: WhitespaceWrappedText(
                                  '이 학기의 과목을 불러오고 있어요.',
                                ),
                              ),
                              CourseCatalogFailure state => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _ErrorMessage(
                                      message: state.message,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        widget.courseController.retry(),
                                    child: const Text('다시 시도'),
                                  ),
                                ],
                              ),
                              CourseCatalogEmpty() => const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: WhitespaceWrappedText(
                                  '이 학기에 등록된 개설 강의가 없어요.',
                                ),
                              ),
                              CourseCatalogAuthenticationRequired() =>
                                TextButton(
                                  onPressed: widget.onAuthenticationRequired,
                                  child: const Text('다시 로그인해 주세요'),
                                ),
                              CourseCatalogInitial() => const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: WhitespaceWrappedText(
                                  '수강연도와 학기를 먼저 선택해 주세요.',
                                ),
                              ),
                              CourseCatalogReady() => const SizedBox.shrink(),
                            },
                            const SizedBox(height: 20),
                            KeyedSubtree(
                              key: const Key('grade-code'),
                              child: DropdownButtonFormField<GradeCode>(
                                key: _gradeFieldKey,
                                initialValue: _gradeCode,
                                decoration: const InputDecoration(
                                  labelText: '성적 등급',
                                ),
                                items: [
                                  for (final code in GradeCode.values)
                                    DropdownMenuItem(
                                      value: code,
                                      child: Text(code.label),
                                    ),
                                ],
                                onChanged: isSubmitting || _rpl
                                    ? null
                                    : (value) =>
                                          setState(() => _gradeCode = value),
                                validator: (value) => !_rpl && value == null
                                    ? '성적 등급을 선택해 주세요.'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const Key('credit'),
                              controller: _creditController,
                              enabled: !isSubmitting,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d{0,2}(\.\d?)?$'),
                                ),
                              ],
                              textInputAction: TextInputAction.done,
                              validator: _validateCredit,
                              decoration: const InputDecoration(
                                labelText: '이수학점',
                                suffixText: '학점',
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              key: const Key('rpl'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('선행학습 인정(RPL) 과목이에요'),
                              subtitle: const WhitespaceWrappedText(
                                'RPL 과목은 성적 등급을 입력하지 않아요.',
                              ),
                              value: _rpl,
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _rpl = value ?? false;
                                        if (_rpl) {
                                          _gradeCode = null;
                                          _replacedGradeEntityId = null;
                                        }
                                      });
                                      if (_rpl) {
                                        _gradeFieldKey.currentState?.didChange(
                                          null,
                                        );
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            ReplacementGradeField(
                              fieldKey: const Key('replacement-grade'),
                              key: ValueKey(
                                'replacement-${_replacedGradeEntityId ?? 'none'}-${_replacementCandidates.length}',
                              ),
                              candidates: _replacementCandidates,
                              selectedEntityId: _replacedGradeEntityId,
                              enabled: !isSubmitting && !_rpl,
                              onChanged: (value) => setState(
                                () => _replacedGradeEntityId = value,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                key: const Key('register-grade'),
                                onPressed: isSubmitting || !catalogReady
                                    ? null
                                    : _submit,
                                child: isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('성적 등록'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<GradeRecord> get _replacementCandidates {
    final course = _course;
    final year = int.tryParse(_academicYearController.text.trim());
    final term = _term;
    if (course == null || year == null || term == null) return const [];
    return gradeReplacementCandidates(
      grades: widget.availableGrades,
      courseEntityId: course.entityId,
      academicYear: year,
      term: term,
    );
  }

  void _syncReplacement() {
    final selected = _replacedGradeEntityId;
    if (selected == null) return;
    if (!_replacementCandidates.any((grade) => grade.entityId == selected)) {
      _replacedGradeEntityId = null;
    }
  }
}

class _SelectedCourse extends StatelessWidget {
  const _SelectedCourse({required this.course});

  final CourseCatalogItem course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(course.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '${course.code} · ${_formatNumber(course.credit)}학점',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CoursePickerSheet extends StatefulWidget {
  const _CoursePickerSheet({required this.controller});

  final CourseCatalogController controller;

  @override
  State<_CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends State<_CoursePickerSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            WhitespaceWrappedText(
              '과목을 선택하세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('course-search'),
              autofocus: false,
              onChanged: widget.controller.search,
              decoration: const InputDecoration(
                labelText: '과목 검색',
                hintText: '과목명 또는 과목 코드',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return switch (widget.controller.state) {
      CourseCatalogInitial() || CourseCatalogLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      CourseCatalogEmpty() => const Center(
        child: WhitespaceWrappedText('선택할 수 있는 과목이 아직 없어요.'),
      ),
      CourseCatalogFailure state => _CoursePickerMessage(
        message: state.message,
        action: TextButton(
          onPressed: widget.controller.retry,
          child: const Text('다시 시도'),
        ),
      ),
      CourseCatalogAuthenticationRequired() => const _CoursePickerMessage(
        message: '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      ),
      CourseCatalogReady state when state.courses.isEmpty => const Center(
        child: WhitespaceWrappedText('검색한 과목을 찾지 못했어요.'),
      ),
      CourseCatalogReady state => ListView.separated(
        itemCount: state.courses.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final course = state.courses[index];
          return ListTile(
            key: Key('course-option-${course.entityId}'),
            minTileHeight: 56,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(course.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: WhitespaceWrappedText(
                '${course.code} · ${_formatNumber(course.credit)}학점'
                '${course.professorNames.isEmpty ? '' : ' · ${course.professorNames.join(', ')}'}',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pop(course),
          );
        },
      ),
    };
  }
}

class _CoursePickerMessage extends StatelessWidget {
  const _CoursePickerMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WhitespaceWrappedText(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action case final value?) ...[const SizedBox(height: 12), value],
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WhitespaceWrappedText(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
