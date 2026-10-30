import 'dart:typed_data';

import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_ocr_import_controller.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/data/grade_ocr_api.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef PdfPicker = Future<({String name, Uint8List bytes})?> Function();

class GradeOcrPage extends StatefulWidget {
  const GradeOcrPage({required this.controller, this.picker, super.key});
  final GradeRegistrationController controller;
  final PdfPicker? picker;
  @override
  State<GradeOcrPage> createState() => _GradeOcrPageState();
}

class _GradeOcrPageState extends State<GradeOcrPage> {
  bool _busy = false;
  GradeOcrImportController? _import;
  bool get _working => _busy || (_import?.busy ?? false);
  @override
  void initState() {
    super.initState();
    _import = widget.controller.createOcrImportController();
    _import?.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _import?.removeListener(_refresh);
    _import?.dispose();
    super.dispose();
  }

  void _finish() {
    if (!_working) Navigator.of(context).pop(_import?.hasChanges ?? false);
  }

  Future<void> _edit(int index) async {
    final importer = _import;
    if (importer == null || _working) return;
    final entry = importer.entries[index];
    if (entry.courses.isEmpty || entry.status != OcrImportStatus.pending) {
      return;
    }
    final edited =
        await showModalBottomSheet<
          ({CourseCatalogItem course, double credit, GradeCode grade})
        >(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => _OcrEntryEditor(entry: entry),
        );
    if (!mounted || edited == null) return;
    importer.edit(
      index,
      course: edited.course,
      credit: edited.credit,
      grade: edited.grade,
    );
  }

  String? _error;
  String? _name;
  Uint8List? _pdf;
  bool _recognized = false;
  List<OcrGradeCandidate> _candidates = const [];

  Future<({String name, Uint8List bytes})?> _pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return null;
    final length = file.lengthSync() ?? await file.length();
    if (length != null && length > 5 * 1024 * 1024) {
      throw const GradeOcrFailure('5MB 이하 PDF를 선택해 주세요.');
    }
    return (name: file.name, bytes: await file.readAsBytes());
  }

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await (widget.picker ?? _pickPdf)();
      if (file == null || !mounted) return;
      if (file.bytes.length < 5 ||
          file.bytes.length > 5 * 1024 * 1024 ||
          String.fromCharCodes(file.bytes.take(5)) != '%PDF-') {
        throw const GradeOcrFailure('5MB 이하의 PDF 파일을 선택해 주세요.');
      }
      setState(() {
        _name = file.name;
        _pdf = file.bytes;
        _recognized = false;
        _candidates = const [];
      });
    } on GradeOcrFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _name = null;
          _pdf = null;
          _recognized = false;
          _candidates = const [];
        });
      }
    } on Object {
      if (mounted) setState(() => _error = '파일을 읽지 못했어요. 다시 선택해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recognize() async {
    final pdf = _pdf;
    if (pdf == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _recognized = false;
      _candidates = const [];
    });
    try {
      final pages = await widget.controller.previewPdf(pdf);
      final candidates = pages
          .expand(
            (page) => extractOcrGradeCandidates(
              page: page.page,
              width: page.width,
              fragments: page.fragments,
              fieldFragments: page.fieldFragments,
            ),
          )
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _recognized = true;
          _candidates = candidates;
        });
        await _import?.prepare(candidates);
      }
    } on GradeOcrFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on Object {
      if (mounted) setState(() => _error = '성적표를 인식하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_working && !(_import?.hasChanges ?? false),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_working) _finish();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('성적표 PDF 인식')),
      bottomNavigationBar: _candidates.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_import != null)
                      WhitespaceWrappedText('등록 완료 ${_import!.savedCount}개'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('ocr-register-selected'),
                        onPressed:
                            _working || (_import?.selectedCount ?? 0) == 0
                            ? null
                            : () => _import!.submitSelected(),
                        child: Text(
                          _working
                              ? '처리 중…'
                              : '선택한 ${_import?.selectedCount ?? 0}개 등록',
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('ocr-finish'),
                      onPressed: _working ? null : _finish,
                      child: const Text('완료'),
                    ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WhitespaceWrappedText(
                '성적표 PDF를 선택해 주세요. 5MB 이하, 최대 5쪽까지 인식할 수 있어요.',
              ),
              const SizedBox(height: 8),
              const WhitespaceWrappedText(
                '인식은 휴대폰에서 처리돼요. 과목과 성적을 확인한 뒤 선택해 등록해 주세요.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const Key('ocr-pick-pdf'),
                onPressed: _working ? null : _choose,
                icon: const Icon(Icons.upload_file),
                label: const Text('PDF 선택'),
              ),
              if (_name != null) ...[
                const SizedBox(height: 12),
                Text(_name!, key: const Key('ocr-filename')),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('ocr-recognize'),
                onPressed: _working || _pdf == null ? null : _recognize,
                child: const Text('인식하기'),
              ),
              if (_working) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                WhitespaceWrappedText(_error!),
              ],
              if (_recognized) ...[
                const SizedBox(height: 24),
                Text('인식 결과', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const WhitespaceWrappedText(
                  '학점과 성적을 확인한 뒤 등록할 과목을 체크해 주세요. 잘못 읽힌 항목은 눌러 수정할 수 있어요.',
                ),
                if (_candidates.isEmpty) ...[
                  const SizedBox(height: 12),
                  const WhitespaceWrappedText(
                    '학기와 학수번호가 함께 인식된 과목이 없어요. 성적표를 확인하고 수동으로 등록해 주세요.',
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  if (_import?.message case final message?) ...[
                    WhitespaceWrappedText(message),
                    const SizedBox(height: 12),
                  ],
                  if (_import == null)
                    const WhitespaceWrappedText('성적 등록은 로그인한 앱에서 사용할 수 있어요.'),
                  if (_import != null)
                    TextButton(
                      key: const Key('ocr-select-ready'),
                      onPressed: _working ? null : _import!.selectReady,
                      child: const Text('등록 가능한 과목 선택'),
                    ),
                  for (var index = 0; index < _candidates.length; index++)
                    _buildEntry(index),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildEntry(int index) {
    final entries = _import?.entries ?? const <OcrImportEntry>[];
    final entry = index < entries.length
        ? entries[index]
        : OcrImportEntry(_candidates[index]);
    final candidate = entry.candidate;
    return Card(
      child: Column(
        children: [
          ListTile(
            key: Key('ocr-candidate-$index'),
            leading: Checkbox(
              key: Key('ocr-select-$index'),
              value: entry.selected,
              onChanged: _working || !entry.canRegister
                  ? null
                  : (value) => _import?.select(index, value ?? false),
            ),
            title: Text(
              entry.course?.name ?? candidate.courseName ?? '과목명 확인 필요',
              key: Key('ocr-course-name-$index'),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${candidate.academicYear}년 · ${candidate.term!.label} · ${entry.course?.code ?? candidate.courseCode}',
                ),
                WhitespaceWrappedText(
                  '학점 ${entry.credit?.toString() ?? '확인 필요'} · 성적 ${entry.grade?.label ?? '확인 필요'}',
                ),
                if (entry.message case final message?)
                  WhitespaceWrappedText(message),
                if (entry.status == OcrImportStatus.saved)
                  const WhitespaceWrappedText('등록 완료'),
              ],
            ),
            trailing:
                entry.status == OcrImportStatus.pending &&
                    entry.courses.isNotEmpty
                ? const Icon(Icons.edit_outlined)
                : null,
            onTap: _working ? null : () => _edit(index),
          ),
          ExpansionTile(
            key: Key('ocr-source-$index'),
            title: const WhitespaceWrappedText('인식 텍스트 확인'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const WhitespaceWrappedText(
                '처음 인식한 텍스트에는 오류가 남아 있을 수 있어요. 위의 학점·성적과 성적표를 비교해 주세요.',
              ),
              const SizedBox(height: 8),
              Text(candidate.source),
            ],
          ),
        ],
      ),
    );
  }
}

class _OcrEntryEditor extends StatefulWidget {
  const _OcrEntryEditor({required this.entry});
  final OcrImportEntry entry;
  @override
  State<_OcrEntryEditor> createState() => _OcrEntryEditorState();
}

class _OcrEntryEditorState extends State<_OcrEntryEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _credit;
  CourseCatalogItem? _course;
  GradeCode? _grade;
  @override
  void initState() {
    super.initState();
    _course = widget.entry.course;
    _grade = widget.entry.grade;
    _credit = TextEditingController(
      text: widget.entry.credit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = <String, CourseCatalogItem>{
      for (final course in [
        ...widget.entry.suggestions,
        ...widget.entry.courses,
      ])
        course.entityId: course,
    }.values.toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhitespaceWrappedText(
                '과목과 성적 확인',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CourseCatalogItem>(
                key: const Key('ocr-edit-course'),
                initialValue: _course,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: const InputDecoration(labelText: '과목'),
                items: options
                    .map(
                      (course) => DropdownMenuItem(
                        value: course,
                        child: Text(
                          '${course.name} (${course.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _course = value;
                  if (_credit.text.isEmpty && value != null) {
                    _credit.text = value.credit.toString();
                  }
                }),
                validator: (value) => value == null ? '과목을 선택해 주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('ocr-edit-credit'),
                controller: _credit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '학점'),
                validator: (value) {
                  final credit = double.tryParse(value?.trim() ?? '');
                  return credit == null ||
                          credit <= 0 ||
                          credit > 30 ||
                          !RegExp(r'^\d{1,2}(\.\d)?$').hasMatch(value!.trim())
                      ? '학점은 0 초과 30 이하, 소수점 한 자리까지 입력해 주세요.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeCode>(
                key: const Key('ocr-edit-grade'),
                initialValue: _grade,
                decoration: const InputDecoration(labelText: '성적'),
                items: GradeCode.values
                    .map(
                      (grade) => DropdownMenuItem(
                        value: grade,
                        child: Text(grade.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _grade = value,
                validator: (value) => value == null ? '성적을 선택해 주세요.' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('ocr-edit-apply'),
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      Navigator.of(context).pop((
                        course: _course!,
                        credit: double.parse(_credit.text.trim()),
                        grade: _grade!,
                      ));
                    }
                  },
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
