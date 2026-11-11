import 'package:ahni_mobile/core/format/credit.dart';
import 'package:ahni_mobile/core/presentation/ahni_palette.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';

/// 시간표에 넣을 강의를 보여 주는 공용 카드. 수강 추천의 과목 카드와 같은 모양이다.
/// 강의 선택 시트와 수강신청 내역 가져오기가 함께 써서 같은 강의를 같은 모양으로 보인다.
/// 교수·시간·강의실까지 보여 줘 학교 화면과 대조하게 하고, 겹치는 기존 강의를 미리 알린다.
class LectureCard extends StatelessWidget {
  const LectureCard({
    required this.lecture,
    this.alreadyAdded = false,
    this.conflicts = const [],
    this.onTap,
    super.key,
  });

  final Lecture lecture;
  final bool alreadyAdded;

  /// 있으면 카드 전체를 눌러 고를 수 있다.
  final VoidCallback? onTap;

  /// 시간이 겹치는 기존 시간표 항목.
  final List<TimetableEntry> conflicts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final teal = AhniPalette.of(context).teal;
    final schedule = lecture.scheduleSummary;
    final classrooms = {for (final s in lecture.schedules) ?s.classroom}
        .join(', ');
    Widget detail(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: WhitespaceWrappedText(text, style: textTheme.bodySmall),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // 시트 바탕이 흰색이라 카드는 옅은 회색 면으로 구분한다.
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: WhitespaceWrappedText(
                        lecture.courseName,
                        style: textTheme.titleSmall,
                      ),
                    ),
                    if (alreadyAdded)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: teal.soft,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '이미 있음',
                          style: textTheme.labelMedium?.copyWith(
                            color: teal.ink,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${lecture.courseCode}-${lecture.section} · ${formatCredit(lecture.credit)}학점',
                  style: textTheme.bodySmall,
                ),
                detail(Icons.person_outline_rounded, lecture.professorName),
                detail(Icons.schedule_rounded, schedule),
                if (classrooms.isNotEmpty)
                  detail(Icons.place_outlined, classrooms),
                for (final entry in conflicts)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AhniPalette.of(context).amber.ink,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: WhitespaceWrappedText(
                            '시간이 겹쳐요: ${entry.lecture.courseName}(${entry.lecture.scheduleSummary})',
                            style: textTheme.bodySmall?.copyWith(
                              color: AhniPalette.of(context).amber.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
