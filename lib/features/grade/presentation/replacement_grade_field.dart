import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/material.dart';

class ReplacementGradeField extends StatelessWidget {
  const ReplacementGradeField({
    required this.fieldKey,
    required this.candidates,
    required this.selectedEntityId,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final Key fieldKey;
  final List<GradeRecord> candidates;
  final String? selectedEntityId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: '재수강 이전 성적 (선택)',
          child: DropdownButtonFormField<String>(
            key: fieldKey,
            isExpanded: true,
            initialValue: selectedEntityId ?? '',
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem(value: '', child: Text('선택 안 함')),
              if (selectedEntityId != null &&
                  !candidates.any(
                    (grade) => grade.entityId == selectedEntityId,
                  ))
                DropdownMenuItem(
                  value: selectedEntityId,
                  child: const Text('연결된 이전 성적'),
                ),
              for (final grade in candidates)
                DropdownMenuItem(
                  value: grade.entityId,
                  child: Text(
                    '${grade.academicYear}년 ${grade.term.label} · ${grade.gradeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled && candidates.isNotEmpty
                ? (value) =>
                      onChanged(value == null || value.isEmpty ? null : value)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const WhitespaceWrappedText('같은 과목을 다시 수강했다면 대체할 이전 성적을 선택해 주세요.'),
      ],
    );
  }
}
