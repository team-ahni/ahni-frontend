import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/confirm_dialog.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_replacement_candidates.dart';
import 'package:ahni_mobile/features/grade/presentation/replacement_grade_field.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:ahni_mobile/core/presentation/busy_button_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeEditPage extends StatefulWidget {
  const GradeEditPage({
    required this.grade,
    required this.controller,
    required this.onSaved,
    required this.onDeleted,
    required this.onAuthenticationRequired,
    this.availableGrades = const [],
    super.key,
  });

  final GradeRecord grade;
  final GradeEditController controller;
  final Future<void> Function(GradeRecord grade) onSaved;
  final Future<void> Function() onDeleted;
  final VoidCallback onAuthenticationRequired;
  final List<GradeRecord> availableGrades;

  @override
  State<GradeEditPage> createState() => _GradeEditPageState();
}

class _GradeEditPageState extends State<GradeEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _gradeFieldKey = GlobalKey<FormFieldState<GradeCode>>();
  late final TextEditingController _academicYearController;
  late final TextEditingController _creditController;
  late AcademicTerm _term;
  GradeCode? _gradeCode;
  late bool _rpl;
  String? _replacedGradeEntityId;

  @override
  void initState() {
    super.initState();
    _academicYearController = TextEditingController(
      text: widget.grade.academicYear.toString(),
    );
    _creditController = TextEditingController(
      text: _formatNumber(widget.grade.credit),
    );
    _term = widget.grade.term;
    _gradeCode = widget.grade.gradeCode;
    _rpl = widget.grade.rpl;
    _replacedGradeEntityId = widget.grade.replacedGradeEntityId;
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _academicYearController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.update(
      widget.grade.entityId,
      GradeUpdate(
        academicYear: int.parse(_academicYearController.text.trim()),
        term: _term,
        gradeCode: _rpl ? null : _gradeCode,
        credit: double.parse(_creditController.text.trim()),
        rpl: _rpl,
        replacedGradeEntityId: _rpl ? null : _replacedGradeEntityId,
      ),
    );
    if (!mounted) return;
    switch (widget.controller.state) {
      case GradeEditSaved state:
        await widget.onSaved(state.grade);
      case GradeEditAuthenticationRequired():
        widget.onAuthenticationRequired();
      default:
        break;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '성적을 삭제할까요?',
      message: '${widget.grade.course.name} 성적은 삭제 후 다시 등록해야 해요.',
      confirmLabel: '삭제',
      destructive: true,
      confirmKey: const Key('confirm-delete-grade'),
      cancelKey: const Key('cancel-delete-grade'),
    );
    if (confirmed != true || !mounted) return;

    await widget.controller.delete(widget.grade.entityId);
    if (!mounted) return;
    switch (widget.controller.state) {
      case GradeEditDeleted():
        await widget.onDeleted();
      case GradeEditAuthenticationRequired():
        widget.onAuthenticationRequired();
      default:
        break;
    }
  }

  String? _validateYear(String? value) {
    final year = int.tryParse(value?.trim() ?? '');
    if (year == null || year < 2000) {
      return '2000년 이후의 수강연도를 입력해 주세요.';
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final isBusy = state is GradeEditSaving || state is GradeEditDeleting;
    final message = switch (state) {
      GradeEditFailure state => state.message,
      _ => null,
    };

    return Scaffold(
      key: const Key('grade-edit-page'),
      appBar: AppBar(titleSpacing: 24, title: const Text('성적 수정')),
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
                      '등록한 성적을 고칠 수 있어요',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    WhitespaceWrappedText(
                      '과목은 그대로 두고 학기와 성적 정보만 변경할 수 있어요.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message case final value?) ...[
                              ErrorNotice(value),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              '과목',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.grade.course.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.grade.course.code} · ${_formatNumber(widget.grade.credit)}학점',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            LabeledField(
                              label: '수강연도',
                              child: TextFormField(
                                key: const Key('edit-academic-year'),
                                controller: _academicYearController,
                                enabled: !isBusy,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(_syncReplacement),
                                errorBuilder: fieldErrorBuilder,
                                validator: _validateYear,
                                decoration: const InputDecoration(
                                  suffixText: '년',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const FieldLabel('수강학기'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final term in AcademicTerm.values)
                                  ChoiceChip(
                                    key: Key('edit-term-${term.apiName}'),
                                    label: Text(term.label),
                                    selected: _term == term,
                                    onSelected: isBusy
                                        ? null
                                        : (_) => setState(() {
                                            _term = term;
                                            _syncReplacement();
                                          }),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            KeyedSubtree(
                              key: const Key('edit-grade-code'),
                              child: LabeledField(
                                label: '성적 등급',
                                child: DropdownButtonFormField<GradeCode>(
                                  isExpanded: true,
                                  key: _gradeFieldKey,
                                  initialValue: _gradeCode,
                                  decoration: const InputDecoration(),
                                  items: [
                                    for (final code in GradeCode.values)
                                      DropdownMenuItem(
                                        value: code,
                                        child: Text(code.label),
                                      ),
                                  ],
                                  onChanged: isBusy || _rpl
                                      ? null
                                      : (value) =>
                                            setState(() => _gradeCode = value),
                                  errorBuilder: fieldErrorBuilder,
                                  validator: (value) => !_rpl && value == null
                                      ? '성적 등급을 선택해 주세요.'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            LabeledField(
                              label: '이수학점',
                              child: TextFormField(
                                key: const Key('edit-credit'),
                                controller: _creditController,
                                enabled: !isBusy,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d{0,2}(\.\d?)?$'),
                                  ),
                                ],
                                errorBuilder: fieldErrorBuilder,
                                validator: _validateCredit,
                                decoration: const InputDecoration(
                                  suffixText: '학점',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              key: const Key('edit-rpl'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('선행학습 인정(RPL) 과목이에요'),
                              subtitle: const WhitespaceWrappedText(
                                'RPL 과목은 성적 등급을 입력하지 않아요.',
                              ),
                              value: _rpl,
                              onChanged: isBusy
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
                              fieldKey: const Key('edit-replacement-grade'),
                              key: ValueKey(
                                'edit-replacement-${_replacedGradeEntityId ?? 'none'}-${_replacementCandidates.length}',
                              ),
                              candidates: _replacementCandidates,
                              selectedEntityId: _replacedGradeEntityId,
                              enabled: !isBusy && !_rpl,
                              onChanged: (value) => setState(
                                () => _replacedGradeEntityId = value,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                key: const Key('save-grade'),
                                onPressed: isBusy ? null : _save,
                                child: BusyButtonLabel(
                                  isBusy: state is GradeEditSaving,
                                  label: '변경사항 저장',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                key: const Key('delete-grade'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .error,
                                ),
                                onPressed: isBusy ? null : _confirmDelete,
                                child: BusyButtonLabel(
                                  isBusy: state is GradeEditDeleting,
                                  label: '성적 삭제',
                                ),
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
    final year = int.tryParse(_academicYearController.text.trim());
    if (year == null) return const [];
    return gradeReplacementCandidates(
      grades: widget.availableGrades,
      courseEntityId: widget.grade.course.entityId,
      academicYear: year,
      term: _term,
      currentGradeEntityId: widget.grade.entityId,
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

String _formatNumber(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
