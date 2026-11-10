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
    required this.addedLectureIds,
    required this.reader,
    super.key,
  });

  final List<Lecture> lectures;
  final Set<String> addedLectureIds;
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
      widget.addedLectureIds,
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
                    '수강신청 내역 가져오기',
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
            if (preview != null) ...[
              const SizedBox(height: 24),
              if (preview.toAdd.isNotEmpty) ...[
                FieldLabel('추가할 강의 ${preview.toAdd.length}개'),
                for (final lecture in preview.toAdd)
                  _LectureCard(lecture: lecture),
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
              FilledButton(
                key: const Key('import-registration-confirm'),
                onPressed: preview.toAdd.isEmpty
                    ? null
                    : () => Navigator.pop(context, preview.toAdd),
                child: Text('${preview.toAdd.length}개 시간표에 추가'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 수강 추천의 과목 카드와 같은 모양. 교수와 시간까지 보여 줘 학교 화면과 대조하게 한다.
/// 분반을 잘못 읽었는데 그 분반도 개설돼 있으면 자동으로는 알 수 없어서다.
class _LectureCard extends StatelessWidget {
  const _LectureCard({required this.lecture, this.alreadyAdded = false});

  final Lecture lecture;
  final bool alreadyAdded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final teal = AhniPalette.of(context).teal;
    final schedule = lecture.schedules.isEmpty
        ? '고정시간 없음'
        : lecture.schedules
              .map((s) => '${timetableDays[s.dayOfWeek - 1]} ${s.label}')
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
          ],
        ),
      ),
    );
  }

  static String _credit(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
