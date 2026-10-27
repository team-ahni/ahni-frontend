import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/recommendation/presentation/course_recommendation_page.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({
    required this.controller,
    required this.onAuthenticationRequired,
    this.recommendationController,
    this.bottomNavigationBar,
    super.key,
  });
  final TimetableController controller;
  final CourseRecommendationController? recommendationController;
  final VoidCallback onAuthenticationRequired;
  final Widget? bottomNavigationBar;

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  TimetableController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.loaded) controller.load();
    });
  }

  void _refresh() {
    if (!mounted) return;
    if (controller.unauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthenticationRequired();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _choose({TimetableEntry? entry}) async {
    final lecture = await showModalBottomSheet<Lecture>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LecturePicker(
        lectures: controller.lectures,
        selectedIds: controller.entries
            .where((item) => item.entityId != entry?.entityId)
            .map((item) => item.lecture.entityId)
            .toSet(),
      ),
    );
    if (lecture == null || !mounted) return;
    await controller.save(lecture, entryId: entry?.entityId);
  }

  Future<void> _openRecommendation(
    CourseRecommendationController recommendationController,
  ) async {
    recommendationController.reset();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => CourseRecommendationPage(
          controller: recommendationController,
          academicYear: controller.year,
          term: controller.term,
          onAuthenticationRequired: () {
            if (routeContext.mounted) Navigator.of(routeContext).pop();
            widget.onAuthenticationRequired();
          },
        ),
      ),
    );
  }

  Future<void> _delete(TimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('강의 삭제'),
        content: WhitespaceWrappedText(
          '${entry.lecture.courseName} 강의를 시간표에서 삭제할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await controller.delete(entry.entityId);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = controller.loading || controller.busy;
    final recommendationController = widget.recommendationController;
    final regularTerm =
        controller.term == 'FIRST' || controller.term == 'SECOND';
    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표'),
        actions: [
          if (recommendationController != null)
            IconButton(
              key: const Key('open-course-recommendation'),
              // 권장 학기가 정규학기 기준이라 계절학기에는 추천하지 않는다.
              tooltip: regularTerm ? '수강 추천' : '수강 추천은 정규학기만 가능해요',
              onPressed: disabled || !regularTerm
                  ? null
                  : () => _openRecommendation(recommendationController),
              icon: const Icon(Icons.lightbulb_outline),
            ),
          IconButton(
            tooltip: '새로고침',
            onPressed: disabled ? null : controller.load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '강의 추가',
            onPressed: disabled || !controller.loaded ? null : () => _choose(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('year-${controller.year}'),
                    initialValue: controller.year,
                    decoration: const InputDecoration(labelText: '연도'),
                    items: [
                      for (
                        var year = 2000;
                        year <= DateTime.now().year + 1;
                        year++
                      )
                        DropdownMenuItem(value: year, child: Text('$year년')),
                    ],
                    onChanged: disabled
                        ? null
                        : (year) => controller.load(academicYear: year),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('term-${controller.term}'),
                    initialValue: controller.term,
                    decoration: const InputDecoration(labelText: '학기'),
                    items: [
                      for (final term in timetableTerms.entries)
                        DropdownMenuItem(
                          value: term.key,
                          child: Text(term.value),
                        ),
                    ],
                    onChanged: disabled
                        ? null
                        : (term) => controller.load(academicTerm: term),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (controller.loading || controller.busy)
              const LinearProgressIndicator(),
            if (controller.message case final message?) ...[
              WhitespaceWrappedText(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton.icon(
                onPressed: disabled ? null : controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
            if (controller.loaded) ...[
              _WeekGrid(entries: controller.entries),
              const SizedBox(height: 24),
              if (controller.entries.isEmpty)
                const WhitespaceWrappedText('등록된 강의가 없어요.'),
              for (final entry in controller.entries) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.lecture.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${entry.lecture.professorName} · ${entry.lecture.section}분반 · ${entry.lecture.credit}학점',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '강의 변경',
                        onPressed: disabled
                            ? null
                            : () => _choose(entry: entry),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: '강의 삭제',
                        onPressed: disabled ? null : () => _delete(entry),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const Divider(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LecturePicker extends StatefulWidget {
  const _LecturePicker({required this.lectures, required this.selectedIds});
  final List<Lecture> lectures;
  final Set<String> selectedIds;
  @override
  State<_LecturePicker> createState() => _LecturePickerState();
}

class _LecturePickerState extends State<_LecturePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = widget.lectures
        .where(
          (lecture) =>
              '${lecture.courseName} ${lecture.courseCode} ${lecture.professorName}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '강의 선택',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '과목명·코드·교수 검색',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: WhitespaceWrappedText('선택할 수 있는 강의가 없어요.'),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final lecture = results[index];
                        final selected = widget.selectedIds.contains(
                          lecture.entityId,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(lecture.courseName),
                          subtitle: Text(
                            '${lecture.courseCode} · ${lecture.section}분반 · ${lecture.professorName}\n'
                            '${lecture.schedules.map((s) => '${timetableDays[s.dayOfWeek - 1]} ${s.label} ${s.classroom ?? ''}').join('\n')}',
                          ),
                          trailing: selected
                              ? const Icon(Icons.check)
                              : const Icon(Icons.add),
                          enabled: !selected,
                          onTap: () => Navigator.pop(context, lecture),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.entries});
  final List<TimetableEntry> entries;

  @override
  Widget build(BuildContext context) {
    final schedules = entries
        .expand((entry) => entry.lecture.schedules)
        .toList();
    final start = schedules.fold(
      9 * 60,
      (value, s) => LectureSchedule.minutes(s.startTime) < value
          ? LectureSchedule.minutes(s.startTime)
          : value,
    );
    final end = schedules.fold(
      18 * 60,
      (value, s) => LectureSchedule.minutes(s.endTime) > value
          ? LectureSchedule.minutes(s.endTime)
          : value,
    );
    final firstHour = start ~/ 60;
    final lastHour = (end + 59) ~/ 60;
    final days = schedules.any((s) => s.dayOfWeek == 7) ? 7 : 6;
    const hourHeight = 64.0;
    final height = (lastHour - firstHour) * hourHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        const timeWidth = 32.0;
        final dayWidth = (constraints.maxWidth - timeWidth) / days;
        return SizedBox(
          key: const Key('timetable-week-grid'),
          width: constraints.maxWidth,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: timeWidth),
                  for (var day = 0; day < days; day++)
                    SizedBox(
                      width: dayWidth,
                      height: 36,
                      child: Center(child: Text(timetableDays[day])),
                    ),
                ],
              ),
              SizedBox(
                height: height,
                child: Stack(
                  children: [
                    for (var day = 0; day <= days; day++)
                      Positioned(
                        left: timeWidth + day * dayWidth - 1,
                        top: 0,
                        bottom: 0,
                        child: VerticalDivider(width: 1, thickness: 1),
                      ),
                    for (var hour = firstHour; hour < lastHour; hour++)
                      Positioned(
                        top: (hour - firstHour) * hourHeight,
                        left: 0,
                        right: 0,
                        child: Row(
                          children: [
                            SizedBox(
                              width: timeWidth,
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider(height: 1)),
                          ],
                        ),
                      ),
                    for (final entry in entries)
                      for (final s in entry.lecture.schedules)
                        Positioned(
                          top:
                              (LectureSchedule.minutes(s.startTime) -
                                  firstHour * 60) *
                              hourHeight /
                              60,
                          left: timeWidth + (s.dayOfWeek - 1) * dayWidth + 1,
                          width: dayWidth - 2,
                          height:
                              (LectureSchedule.minutes(s.endTime) -
                                  LectureSchedule.minutes(s.startTime)) *
                              hourHeight /
                              60,
                          child: Tooltip(
                            message:
                                '${entry.lecture.courseName} · ${s.label} · ${s.classroom ?? ''}',
                            child: Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: WhitespaceWrappedText(
                                      entry.lecture.courseName,
                                    ),
                                    content: WhitespaceWrappedText(
                                      '${entry.lecture.professorName} · ${entry.lecture.section}분반\n'
                                      '${timetableDays[s.dayOfWeek - 1]}요일 ${s.label}\n'
                                      '${s.classroom ?? '강의실 미정'}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('닫기'),
                                      ),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: ClipRect(
                                    child: Text(
                                      entry.lecture.courseName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.clip,
                                      semanticsLabel:
                                          '${entry.lecture.courseName} ${s.label} ${s.classroom ?? ''}',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
