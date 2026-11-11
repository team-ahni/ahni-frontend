import 'package:ahni_mobile/core/presentation/confirm_dialog.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';

/// 시간이 겹치는 기존 강의와 새 강의. 확인 창에 `기존 → 새`로 보인다.
typedef TimetableReplacement = ({TimetableEntry existing, Lecture next});

/// 시간표에 넣을 강의가 기존 강의와 겹칠 때 쓰는 공용 확인 창.
/// 강의 추가·변경과 수강신청 내역 가져오기가 같은 창을 써서 같은 상황을 같은 방식으로 묻는다.
/// 앱 공용 확인 창([showConfirmDialog]) 위에 `기존 → 새` 목록을 더한다.
/// true면 바꾸기, false면 다시 선택하기, null이면 창 밖을 눌러 닫은 것이다.
Future<bool?> showTimetableConflictDialog(
  BuildContext context,
  List<TimetableReplacement> replacements,
) => showConfirmDialog(
  context,
  dialogKey: const Key('timetable-conflict-dialog'),
  title: '시간이 겹치는 강의가 있어요',
  message: '바꾸면 겹치는 기존 강의는 시간표에서 빠지고 새 강의가 들어가요.',
  details: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (:existing, :next) in replacements)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: WhitespaceWrappedText(
            '${existing.lecture.courseName} → ${next.courseName}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
    ],
  ),
  cancelLabel: '다시 선택하기',
  confirmLabel: '바꾸기',
  cancelKey: const Key('timetable-conflict-retry'),
  confirmKey: const Key('timetable-conflict-replace'),
);
