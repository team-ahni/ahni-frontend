import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:flutter/material.dart';

class GradeSimulationPage extends StatefulWidget {
  const GradeSimulationPage({
    required this.controller,
    required this.onAuthenticationRequired,
    super.key,
  });

  final GradeSimulationController controller;
  final VoidCallback onAuthenticationRequired;

  @override
  State<GradeSimulationPage> createState() => _GradeSimulationPageState();
}

class _GradeSimulationPageState extends State<GradeSimulationPage> {
  final _formKey = GlobalKey<FormState>();
  final _rows = [_ExpectedGradeDraft(0)];
  var _nextId = 1;

  @override
  void dispose() {
    for (final row in _rows) {
      row.credit.dispose();
    }
    widget.controller.reset();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.submit(
      _rows
          .map(
            (row) => ExpectedGrade(
              category: row.category,
              credit: ExpectedGrade.parseCredit(row.credit.text)!,
              gradeCode: row.gradeCode!,
            ),
          )
          .toList(),
    );
  }

  void _change(VoidCallback update) {
    widget.controller.reset();
    setState(update);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final busy = state is GradeSimulationSubmitting;
      return Scaffold(
        key: const Key('grade-simulation-page'),
        appBar: AppBar(title: const Text('평점 시뮬레이션'), titleSpacing: 24),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WhitespaceWrappedText(
                        '예상 성적으로 평점을 미리 계산해 봐요',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      WhitespaceWrappedText(
                        '기존 성적에 앞으로 받을 성적을 더해 계산해요. 실제 성적은 바뀌지 않아요.',
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < _rows.length;
                                index++
                              ) ...[
                                if (index != 0) const Divider(height: 32),
                                _row(_rows[index], index, busy),
                              ],
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                key: const Key('add-expected-grade'),
                                onPressed: busy || _rows.length >= 50
                                    ? null
                                    : () => _change(
                                        () => _rows.add(
                                          _ExpectedGradeDraft(_nextId++),
                                        ),
                                      ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(44, 48),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('예상 과목 추가'),
                              ),
                              if (_rows.length >= 50)
                                const WhitespaceWrappedText(
                                  '한 번에 최대 50과목까지 계산할 수 있어요.',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      WhitespaceWrappedText(
                        '4.5점 만점으로 계산해요. P·NP는 평점에서 제외하고 F는 0점으로 포함해요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      if (state is GradeSimulationFailure) ...[
                        Semantics(
                          liveRegion: true,
                          child: WhitespaceWrappedText(
                            state.message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (state is GradeSimulationAuthenticationRequired)
                        FilledButton(
                          onPressed: widget.onAuthenticationRequired,
                          child: const Text('로그인으로 돌아가기'),
                        )
                      else
                        FilledButton(
                          key: const Key('calculate-gpa'),
                          onPressed: busy ? null : _calculate,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 52),
                          ),
                          child: busy
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('계산 중…'),
                                  ],
                                )
                              : Text(
                                  state is GradeSimulationFailure
                                      ? '다시 계산'
                                      : '예상 평점 계산',
                                ),
                        ),
                      if (state is GradeSimulationReady) ...[
                        const SizedBox(height: 24),
                        _SimulationResult(result: state.result),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _row(_ExpectedGradeDraft row, int index, bool busy) => Column(
    key: ValueKey(row.id),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: WhitespaceWrappedText(
              '예상 과목 ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_rows.length > 1)
            IconButton(
              tooltip: '예상 과목 ${index + 1} 제거',
              onPressed: busy
                  ? null
                  : () {
                      _change(() => _rows.remove(row));
                      row.credit.dispose();
                    },
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
        ],
      ),
      const SizedBox(height: 12),
      LabeledField(
        label: '과목 분류',
        child: DropdownButtonFormField<CourseCategory>(
          key: Key('expected-category-${row.id}'),
          initialValue: row.category,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: CourseCategory.values
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(switch (category) {
                    CourseCategory.major => '전공',
                    CourseCategory.generalEducation => '교양',
                    CourseCategory.elective => '일반선택',
                  }),
                ),
              )
              .toList(),
          onChanged: busy
              ? null
              : (category) {
                  if (category != null) _change(() => row.category = category);
                },
        ),
      ),
      const SizedBox(height: 16),
      LabeledField(
        label: '학점',
        child: TextFormField(
          key: Key('expected-credit-${row.id}'),
          controller: row.credit,
          enabled: !busy,
          style: const TextStyle(fontSize: 16),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '예: 3 또는 1.5'),
          validator: (value) => ExpectedGrade.parseCredit(value ?? '') == null
              ? '학점은 0 초과 30 이하, 소수점 한 자리까지 입력해 주세요.'
              : null,
          errorBuilder: (_, message) => WhitespaceWrappedText(message),
          onChanged: (_) => widget.controller.reset(),
          onFieldSubmitted: (_) => _calculate(),
        ),
      ),
      const SizedBox(height: 16),
      LabeledField(
        label: '예상 등급',
        child: DropdownButtonFormField<GradeCode>(
          key: Key('expected-code-${row.id}'),
          initialValue: row.gradeCode,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: GradeCode.values
              .map(
                (grade) =>
                    DropdownMenuItem(value: grade, child: Text(grade.label)),
              )
              .toList(),
          onChanged: busy
              ? null
              : (grade) => _change(() => row.gradeCode = grade),
          validator: (grade) => grade == null ? '예상 등급을 선택해 주세요.' : null,
          errorBuilder: (_, message) => WhitespaceWrappedText(message),
        ),
      ),
    ],
  );
}

class _ExpectedGradeDraft {
  _ExpectedGradeDraft(this.id);
  final int id;
  final credit = TextEditingController();
  CourseCategory category = CourseCategory.major;
  GradeCode? gradeCode;
}

class _SimulationResult extends StatelessWidget {
  const _SimulationResult({required this.result});
  final GradeSimulation result;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      key: const Key('simulation-result'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _metric(context, '현재 평점', result.current.gpa),
              _metric(context, '예상 평점', result.projected.gpa),
            ],
          ),
          const SizedBox(height: 16),
          WhitespaceWrappedText(
            '이수학점 ${result.current.completedCredits.toStringAsFixed(1)} → ${result.projected.completedCredits.toStringAsFixed(1)}학점',
          ),
          const SizedBox(height: 8),
          const WhitespaceWrappedText('실제 성적은 바뀌지 않아요.'),
        ],
      ),
    ),
  );

  Widget _metric(BuildContext context, String label, double value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Text(
        value.toStringAsFixed(2),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}
