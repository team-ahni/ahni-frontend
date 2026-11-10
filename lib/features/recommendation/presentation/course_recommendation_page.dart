import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/ahni_palette.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:flutter/material.dart';

class CourseRecommendationPage extends StatefulWidget {
  const CourseRecommendationPage({
    required this.controller,
    required this.academicYear,
    required this.term,
    required this.onAuthenticationRequired,
    this.onAddLecture,
    this.addedLectureIds = const {},
    super.key,
  });
  final CourseRecommendationController controller;
  final int academicYear;
  final String term;
  final VoidCallback onAuthenticationRequired;

  /// 분반을 시간표에 바로 넣는다. 넣었는지와, 넣지 못했으면 보여 줄 문구를 돌려준다.
  /// 넣지 않았고 문구도 없으면 사용자가 확인 창에서 다시 고르기로 한 것이다.
  /// 없으면 추가 버튼을 그리지 않는다.
  final Future<({bool added, String? message})> Function(Lecture lecture)?
  onAddLecture;

  /// 이미 시간표에 있는 분반. 이 분반은 '추가됨'으로 보인다.
  final Set<String> addedLectureIds;

  @override
  State<CourseRecommendationPage> createState() =>
      _CourseRecommendationPageState();
}

class _CourseRecommendationPageState extends State<CourseRecommendationPage> {
  late final Set<String> _added = {...widget.addedLectureIds};
  String? _adding;

  Future<void> _add(Lecture lecture) async {
    final onAdd = widget.onAddLecture;
    if (onAdd == null || _adding != null) return;
    setState(() => _adding = lecture.entityId);
    final (:added, :message) = await onAdd(lecture);
    if (!mounted) return;
    setState(() {
      _adding = null;
      if (added) _added.add(lecture.entityId);
    });
    final text = added
        ? '${lecture.courseName} ${lecture.section}분반을 시간표에 추가했어요.'
        : message;
    if (text == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() => widget.controller.load(widget.academicYear, widget.term);

  void _changed() {
    if (!mounted) return;
    if (widget.controller.status == CourseRecommendationStatus.unauthorized) {
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
    final recommendation = controller.recommendation;
    final loading =
        controller.status == CourseRecommendationStatus.loading ||
        controller.status == CourseRecommendationStatus.initial;
    return Scaffold(
      key: const Key('course-recommendation-page'),
      appBar: AppBar(
        title: Text(
          '${widget.academicYear}년 ${timetableTerms[widget.term]} 수강 추천',
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const NoticeCallout(
                  icon: Icons.lightbulb_outline_rounded,
                  message: '등록한 성적과 공개된 교과과정으로 들으면 좋은 과목을 골라 봤어요. 선수과목, 정원, 수강신청 자격은 확인하지 않으니 학교 안내를 함께 확인해 주세요.',
                ),
                const SizedBox(height: 20),
                if (loading) const Center(child: CircularProgressIndicator()),
                if (controller.status ==
                    CourseRecommendationStatus.failure) ...[
                  WhitespaceWrappedText(
                    controller.message ?? '수강 추천을 불러오지 못했어요. 다시 시도해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _load, child: const Text('다시 시도')),
                ],
                if (recommendation != null)
                  ..._recommendationSections(context, recommendation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _recommendationSections(
    BuildContext context,
    CourseRecommendation recommendation,
  ) => [
    Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: WhitespaceWrappedText(
          '성적 기준 ${recommendation.semesterLabel}로 계산했어요.',
          key: const Key('recommendation-semester'),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    if (!recommendation.lectureDataAvailable) ...[
      const SizedBox(height: 8),
      NoticeCallout(
        key: const Key('recommendation-no-lectures'),
        icon: Icons.event_note_outlined,
        tone: AhniPalette.of(context).amber,
        message: '이 학기 개설 강의 정보가 아직 없어서 교과과정 기준으로만 추천했어요.',
      ),
    ],
    // 인하대 재수강에 관한 규정 제3조 ③·제5조 ④. 앱 기록과 학교 기록이 다를 수 있어 거르지 않고 안내만 한다.
    if (recommendation.hasRetake) ...[
      const SizedBox(height: 8),
      NoticeCallout(
        key: const Key('recommendation-retake-limit'),
        icon: Icons.replay_rounded,
        tone: AhniPalette.of(context).violet,
        message: '재수강은 학기당 8학점(최대 2과목), 졸업까지 24학점까지 신청할 수 있고 최고 성적은 A0예요.',
      ),
    ],
    const SizedBox(height: 16),
    if (recommendation.majors.isEmpty)
      const EmptyStateView(
        key: Key('recommendation-no-major'),
        mood: AhniMood.curious,
        title: '등록된 전공이 없어요',
        message: '내 정보에서 전공을 등록하면 맞춤 추천을 받을 수 있어요.',
      ),
    for (final major in recommendation.majors)
      _MajorSection(
        major: major,
        lectureAction: widget.onAddLecture == null
            ? null
            : (added: _added, adding: _adding, onAdd: _add),
      ),
  ];
}

class _MajorSection extends StatelessWidget {
  const _MajorSection({required this.major, required this.lectureAction});
  final MajorRecommendation major;
  final _LectureAction? lectureAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: WhitespaceWrappedText(
              '${major.majorLabel} · ${major.departmentName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          if (!major.curriculumAvailable)
            const NoticeCallout(
              icon: Icons.hourglass_empty_rounded,
              message: '이 학기 교과과정이 아직 공개되지 않아 추천할 수 없어요.',
            )
          else if (major.courses.isEmpty)
            NoticeCallout(
              icon: Icons.check_circle_outline_rounded,
              tone: AhniPalette.of(context).teal,
              message: '지금 추천할 과목이 없어요.',
            ),
          for (final course in major.courses)
            _CourseCard(course: course, lectureAction: lectureAction),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.lectureAction});
  final RecommendedCourse course;
  final _LectureAction? lectureAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final termLabel = course.recommendedTermLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: ValueKey('recommendation-${course.courseEntityId}'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(course.name, style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              [
                course.code,
                course.divisionLabel,
                '${_credit(course.credit)}학점',
                ?termLabel,
              ].join(' · '),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (index, label) in course.reasonLabels.indexed)
                  _ReasonChip(reason: course.reasons[index], label: label),
              ],
            ),
            for (final lecture in course.lectures)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: WhitespaceWrappedText(
                        '${lecture.section}분반 · ${lecture.professorName} · ${_schedule(lecture)}',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    if (lectureAction case final action?)
                      _AddLectureButton(lecture: lecture, action: action),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 분반 추가에 필요한 화면 상태. 이미 넣은 분반, 지금 넣는 중인 분반, 넣는 동작.
typedef _LectureAction = ({
  Set<String> added,
  String? adding,
  Future<void> Function(Lecture lecture) onAdd,
});

class _AddLectureButton extends StatelessWidget {
  const _AddLectureButton({required this.lecture, required this.action});
  final Lecture lecture;
  final _LectureAction action;

  @override
  Widget build(BuildContext context) {
    final added = action.added.contains(lecture.entityId);
    final adding = action.adding == lecture.entityId;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        key: ValueKey('add-lecture-${lecture.entityId}'),
        // 다른 분반을 넣는 중에는 기다리게 해 요청이 겹치지 않게 한다.
        onPressed: added || action.adding != null
            ? null
            : () => action.onAdd(lecture),
        icon: adding
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(added ? Icons.check_rounded : Icons.add_rounded, size: 18),
        label: Text(added ? '추가됨' : '추가'),
      ),
    );
  }
}

String _schedule(Lecture lecture) => lecture.schedules.isEmpty
    ? '고정시간 없음'
    : lecture.schedules
          .map(
            (schedule) =>
                '${timetableDays[schedule.dayOfWeek - 1]} ${schedule.label}',
          )
          .join(', ');

String _credit(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();

/// 추천 이유마다 색을 달리해 훑어보기 쉽게 한다. 뜻은 항상 글자로도 전한다.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.reason, required this.label});

  final String reason;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AhniPalette.of(context);
    final tone = switch (reason) {
      'GRADUATION_REQUIRED' => palette.rose,
      'OVERDUE' => palette.amber,
      'RECOMMENDED_NOW' => palette.blue,
      _ => palette.violet,
    };
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: tone.soft,
      labelStyle: Theme.of(context).chipTheme.labelStyle
          ?.copyWith(color: tone.ink),
    );
  }
}
