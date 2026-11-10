import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';

/// 시간이 겹치는 기존 강의와 새 강의. 확인 창에 `기존 → 새`로 보인다.
typedef TimetableReplacement = ({TimetableEntry existing, Lecture next});

/// 시간표에 넣을 강의가 기존 강의와 겹칠 때 쓰는 공용 확인 창.
/// 강의 추가·변경과 수강신청 내역 가져오기가 같은 창을 써서 같은 상황을 같은 방식으로 묻는다.
/// true면 바꾸기, false면 다시 선택하기, null이면 창 밖을 눌러 닫은 것이다.
Future<bool?> showTimetableConflictDialog(
  BuildContext context,
  List<TimetableReplacement> replacements,
) => showDialog<bool>(
  context: context,
  builder: (context) => _TimetableConflictDialog(replacements: replacements),
);

class _TimetableConflictDialog extends StatelessWidget {
  const _TimetableConflictDialog({required this.replacements});

  final List<TimetableReplacement> replacements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      key: const Key('timetable-conflict-dialog'),
      title: const Text('시간이 겹치는 강의가 있어요'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhitespaceWrappedText(
            '바꾸면 겹치는 기존 강의는 시간표에서 빠지고 새 강의가 들어가요.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final (:existing, :next) in replacements)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: WhitespaceWrappedText(
                '${existing.lecture.courseName} → ${next.courseName}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      actions: [
        // 큰 글자에서 한쪽만 줄이 바뀌어도 두 버튼 높이를 맞춘다.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('timetable-conflict-retry'),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('다시 선택하기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('timetable-conflict-replace'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('바꾸기'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
