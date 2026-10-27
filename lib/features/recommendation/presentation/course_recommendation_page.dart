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
    super.key,
  });
  final CourseRecommendationController controller;
  final int academicYear;
  final String term;
  final VoidCallback onAuthenticationRequired;

  @override
  State<CourseRecommendationPage> createState() =>
      _CourseRecommendationPageState();
}

class _CourseRecommendationPageState extends State<CourseRecommendationPage> {
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
                const WhitespaceWrappedText(
                  '등록한 성적과 공개된 교과과정으로 들으면 좋은 과목을 골라 봤어요. 선수과목, 정원, 수강신청 자격은 확인하지 않으니 학교 안내를 함께 확인해 주세요.',
                ),
                const SizedBox(height: 24),
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
    WhitespaceWrappedText(
      '성적 기준 ${recommendation.semesterLabel}로 계산했어요.',
      key: const Key('recommendation-semester'),
      style: Theme.of(context).textTheme.bodySmall,
    ),
    if (!recommendation.lectureDataAvailable) ...[
      const SizedBox(height: 8),
      const WhitespaceWrappedText(
        key: Key('recommendation-no-lectures'),
        '이 학기 개설 강의 정보가 아직 없어서 교과과정 기준으로만 추천했어요.',
      ),
    ],
    const SizedBox(height: 16),
    if (recommendation.majors.isEmpty)
      const WhitespaceWrappedText(
        key: Key('recommendation-no-major'),
        '등록된 전공이 없어요. 내 정보에서 전공을 등록해 주세요.',
      ),
    for (final major in recommendation.majors) _MajorSection(major: major),
  ];
}

class _MajorSection extends StatelessWidget {
  const _MajorSection({required this.major});
  final MajorRecommendation major;

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
            const WhitespaceWrappedText('이 학기 교과과정이 아직 공개되지 않아 추천할 수 없어요.')
          else if (major.courses.isEmpty)
            const WhitespaceWrappedText('지금 추천할 과목이 없어요.'),
          for (final course in major.courses) _CourseCard(course: course),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final RecommendedCourse course;

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
                for (final label in course.reasonLabels)
                  Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            for (final lecture in course.lectures)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: WhitespaceWrappedText(
                  '${lecture.section}분반 · ${lecture.professorName} · ${_schedule(lecture)}',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
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
