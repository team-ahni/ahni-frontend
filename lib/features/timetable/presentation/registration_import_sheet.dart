import 'package:ahni_mobile/core/presentation/ahni_palette.dart';
import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/sheet_header.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/timetable/data/registration_screenshot_reader.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable_import.dart';
import 'package:ahni_mobile/features/timetable/presentation/lecture_card.dart';
import 'package:ahni_mobile/features/timetable/presentation/timetable_conflict_dialog.dart';
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

  /// 겹치는 강의가 없으면 바로 넣고, 있으면 확인 창에서 바꿔서 넣을지 다시 고를지 묻는다.
  Future<void> _confirm(TimetableImportPreview preview) async {
    final conflicts = preview.conflicts;
    if (conflicts.isEmpty) {
      Navigator.pop(context, TimetableImportPlan(add: preview.toAdd));
      return;
    }
    final next = {for (final l in preview.toAdd) l.entityId: l};
    final replace = await showTimetableConflictDialog(context, [
      for (final MapEntry(key: id, value: olds) in conflicts.entries)
        for (final existing in olds) (existing: existing, next: next[id]!),
    ]);
    if (!mounted || replace == null) return;
    if (replace) {
      Navigator.pop(
        context,
        TimetableImportPlan(add: preview.toAdd, replacing: conflicts),
      );
    } else {
      // 다시 선택하기: 붙여 넣은 글은 남겨 두고 입력 단계로 돌아간다.
      setState(() => _preview = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preview = _preview;
    return Padding(
      padding: EdgeInsets.only(bottom: sheetBottomInset(context)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(preview == null ? '수강신청 내역 가져오기' : '찾은 강의'),
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
                ErrorNotice(error),
              ],
            ] else ...[
              const SizedBox(height: 16),
              if (preview.toAdd.isNotEmpty) ...[
                FieldLabel('추가할 강의 ${preview.toAdd.length}개'),
                for (final lecture in preview.toAdd)
                  LectureCard(
                    key: ValueKey('import-lecture-${lecture.entityId}'),
                    lecture: lecture,
                    conflicts: preview.conflicts[lecture.entityId] ?? const [],
                  ),
              ],
              if (preview.alreadyAdded.isNotEmpty) ...[
                const SizedBox(height: 8),
                const FieldLabel('이미 시간표에 있어요'),
                for (final lecture in preview.alreadyAdded)
                  LectureCard(
                    key: ValueKey('import-lecture-${lecture.entityId}'),
                    lecture: lecture,
                    alreadyAdded: true,
                  ),
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
                    : () => _confirm(preview),
                child: Text('${preview.toAdd.length}개 시간표에 추가'),
              ),
              const SizedBox(height: 8),
              // 추가 버튼보다 한 단계 낮은 동작이라 글자 버튼으로 둔다.
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
