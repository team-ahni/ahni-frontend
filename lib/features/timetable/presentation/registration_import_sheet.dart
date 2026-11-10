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
              _PreviewGroup(
                title: '추가할 강의 ${preview.toAdd.length}개',
                items: [for (final l in preview.toAdd) _label(l)],
              ),
              _PreviewGroup(
                title: '이미 시간표에 있어요',
                items: [for (final l in preview.alreadyAdded) _label(l)],
              ),
              _PreviewGroup(
                title: '찾지 못했어요',
                note: '이 학기에 없거나 분반을 정할 수 없는 강의예요. 강의 추가에서 직접 골라 주세요.',
                items: preview.notFound,
              ),
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

  static String _label(Lecture lecture) =>
      '${lecture.courseName} · ${lecture.courseCode}-${lecture.section}';
}

class _PreviewGroup extends StatelessWidget {
  const _PreviewGroup({required this.title, required this.items, this.note});

  final String title;
  final List<String> items;
  final String? note;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(title),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: WhitespaceWrappedText(item, style: textTheme.bodyMedium),
            ),
          if (note case final value?)
            WhitespaceWrappedText(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
