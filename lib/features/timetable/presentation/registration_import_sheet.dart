import 'package:ahni_mobile/core/presentation/ahni_palette.dart';
import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/timetable/data/registration_screenshot_reader.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable_import.dart';
import 'package:flutter/material.dart';

/// 학교 수강신청 내역을 캡처나 붙여넣기로 받아 이 학기 시간표에 넣을 분반을 고른다.
/// 넣을 분반 목록을 돌려주며 저장은 부르는 쪽이 한다.
class RegistrationImportSheet extends StatefulWidget {
  const RegistrationImportSheet({
    required this.lectures,
    required this.entries,
    required this.reader,
    super.key,
  });

  final List<Lecture> lectures;
  final List<TimetableEntry> entries;
  final RegistrationScreenshotReader reader;

  @override
  State<RegistrationImportSheet> createState() =>
      _RegistrationImportSheetState();
}

class _RegistrationImportSheetState extends State<RegistrationImportSheet> {
  final _pasted = TextEditingController();
  bool _reading = false;
  String? _error;
  TimetableImportPreview? _preview;

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  void _match(String text) {
    final preview = matchRegisteredSections(
      parseRegisteredSections(text),
      widget.lectures,
      widget.entries,
    );
    setState(() {
      _preview = preview.isEmpty ? null : preview;
      _error = preview.isEmpty
          ? '학수번호와 분반을 찾지 못했어요. 수강신청 확인 표가 보이게 다시 시도해 주세요.'
          : null;
    });
  }

  Future<void> _readScreenshot() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final text = await widget.reader.pickAndRead();
      if (text != null && mounted) _match(text);
    } on RegistrationScreenshotFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  /// 겹치는 기존 강의를 새 강의로 바꿔서 모두 넣는다.
  void _addReplacing(TimetableImportPreview preview) => Navigator.pop(
    context,
    TimetableImportPlan(add: preview.toAdd, replacing: preview.conflicts),
  );

  /// 시간표는 그대로 두고 겹치지 않는 강의만 넣는다.
  void _addSkipping(TimetableImportPreview preview) => Navigator.pop(
    context,
    TimetableImportPlan(
      add: [
        for (final lecture in preview.toAdd)
          if (!preview.conflicts.containsKey(lecture.entityId)) lecture,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preview = _preview;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: WhitespaceWrappedText(
                    preview == null ? '수강신청 내역 가져오기' : '찾은 강의',
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (preview == null) ...[
              const SizedBox(height: 8),
              WhitespaceWrappedText(
                '학교 수강신청 확인 화면을 캡처하거나 복사한 내역을 붙여 넣으면, 이 학기 강의를 찾아 한 번에 넣어요. 캡처는 기기 안에서만 읽어요.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                key: const Key('import-registration-screenshot'),
                onPressed: _reading ? null : _readScreenshot,
                icon: _reading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
                label: const Text('캡처 이미지 선택'),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: '또는 복사한 내역 붙여넣기',
                child: TextField(
                  key: const Key('import-registration-text'),
                  controller: _pasted,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'GEE7007  001  디지털 경영  3.0 …',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  key: const Key('import-registration-find'),
                  onPressed: _reading ? null : () => _match(_pasted.text),
                  child: const Text('강의 찾기'),
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                WhitespaceWrappedText(
                  error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              if (preview.toAdd.isNotEmpty) ...[
                FieldLabel('추가할 강의 ${preview.toAdd.length}개'),
                for (final lecture in preview.toAdd)
                  _LectureCard(
                    lecture: lecture,
                    conflicts: preview.conflicts[lecture.entityId] ?? const [],
                  ),
              ],
              if (preview.alreadyAdded.isNotEmpty) ...[
                const SizedBox(height: 8),
                const FieldLabel('이미 시간표에 있어요'),
                for (final lecture in preview.alreadyAdded)
                  _LectureCard(lecture: lecture, alreadyAdded: true),
              ],
              if (preview.notFound.isNotEmpty) ...[
                const SizedBox(height: 8),
                NoticeCallout(
                  key: const Key('import-registration-not-found'),
                  icon: Icons.help_outline_rounded,
                  tone: AhniPalette.of(context).amber,
                  message:
                      '찾지 못했어요: ${preview.notFound.join(', ')}\n'
                      '이 학기에 없거나 분반을 정할 수 없는 강의예요. 강의 추가에서 직접 골라 주세요.',
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              if (preview.conflicts.isEmpty)
                FilledButton(
                  key: const Key('import-registration-confirm'),
                  onPressed: preview.toAdd.isEmpty
                      ? null
                      : () => _addSkipping(preview),
                  child: Text('${preview.toAdd.length}개 시간표에 추가'),
                )
              else
                _ConflictDecision(
                  preview: preview,
                  onReplace: () => _addReplacing(preview),
                  onSkip: () => _addSkipping(preview),
                ),
              const SizedBox(height: 8),
              // 추가 버튼들보다 한 단계 낮은 동작이라 글자 버튼으로 둔다.
              TextButton.icon(
                key: const Key('import-registration-retry'),
                // 붙여 넣은 글은 남겨 둬 고쳐서 다시 찾을 수 있게 한다.
                onPressed: () => setState(() => _preview = null),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 선택하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 시간이 겹치는 강의가 있을 때 결과 화면 안에서 바로 고르게 한다.
/// 빠지는 기존 강의와 들어오는 새 강의를 나란히 보여 주고, 버튼에 결과 개수를 적는다.
class _ConflictDecision extends StatelessWidget {
  const _ConflictDecision({
    required this.preview,
    required this.onReplace,
    required this.onSkip,
  });

  final TimetableImportPreview preview;
  final VoidCallback onReplace;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final amber = AhniPalette.of(context).amber;
    final newLectures = {for (final l in preview.toAdd) l.entityId: l};
    final skipCount = preview.toAdd.length - preview.conflicts.length;
    Widget row(
      String tag,
      Color tagColor,
      Lecture lecture, {
      bool muted = false,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            tag,
            style: textTheme.labelMedium?.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhitespaceWrappedText(
                lecture.courseName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: muted ? colorScheme.onSurfaceVariant : null,
                  decoration: muted ? TextDecoration.lineThrough : null,
                ),
              ),
              WhitespaceWrappedText(
                _schedule(lecture),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
    return Column(
      key: const Key('import-conflict-decision'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: amber.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: amber.ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WhitespaceWrappedText(
                      '시간표의 강의와 ${preview.conflicts.length}개가 겹쳐요',
                      style: textTheme.titleSmall?.copyWith(color: amber.ink),
                    ),
                  ),
                ],
              ),
              for (final MapEntry(key: id, value: olds)
                  in preview.conflicts.entries) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final old in olds) ...[
                        row('빠짐', colorScheme.error, old.lecture, muted: true),
                        const SizedBox(height: 8),
                      ],
                      row('추가', colorScheme.primary, newLectures[id]!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('import-conflict-replace'),
          onPressed: onReplace,
          child: Text('바꿔서 ${preview.toAdd.length}개 추가'),
        ),
        if (skipCount > 0) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('import-conflict-skip'),
            onPressed: onSkip,
            child: Text('겹치는 강의 빼고 $skipCount개 추가'),
          ),
        ],
      ],
    );
  }
}

/// 수강 추천의 과목 카드와 같은 모양. 교수와 시간까지 보여 줘 학교 화면과 대조하게 한다.
/// 분반을 잘못 읽었는데 그 분반도 개설돼 있으면 자동으로는 알 수 없어서다.
class _LectureCard extends StatelessWidget {
  const _LectureCard({
    required this.lecture,
    this.alreadyAdded = false,
    this.conflicts = const [],
  });

  final Lecture lecture;
  final bool alreadyAdded;

  /// 시간이 겹치는 기존 시간표 항목.
  final List<TimetableEntry> conflicts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final teal = AhniPalette.of(context).teal;
    final schedule = _schedule(lecture);
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
      child: Container(
        key: ValueKey('import-lecture-${lecture.entityId}'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 시트 바탕이 흰색이라 카드는 옅은 회색 면으로 구분한다.
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
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
                      style: textTheme.labelMedium?.copyWith(color: teal.ink),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${lecture.courseCode}-${lecture.section} · ${_credit(lecture.credit)}학점',
              style: textTheme.bodySmall,
            ),
            detail(Icons.person_outline_rounded, lecture.professorName),
            detail(Icons.schedule_rounded, schedule),
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
                        '시간이 겹쳐요: ${entry.lecture.courseName}(${_schedule(entry.lecture)})',
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
    );
  }

  static String _credit(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String _schedule(Lecture lecture) => lecture.schedules.isEmpty
    ? '고정시간 없음'
    : lecture.schedules
          .map((s) => '${timetableDays[s.dayOfWeek - 1]} ${s.label}')
          .join(', ');
