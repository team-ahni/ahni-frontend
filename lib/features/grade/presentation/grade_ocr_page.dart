import 'dart:typed_data';

import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
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
  String? _error;
  String? _name;
  Uint8List? _pdf;
  List<GradeOcrPageResult>? _pages;
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
        _pages = null;
        _candidates = const [];
      });
    } on GradeOcrFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _name = null;
          _pdf = null;
          _pages = null;
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
      _pages = null;
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
            ),
          )
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _pages = pages;
          _candidates = candidates;
        });
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('성적표 PDF 인식')),
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
              '인식은 휴대폰에서 처리돼요. 인식 결과는 성적에 자동 저장되지 않아요.',
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('ocr-pick-pdf'),
              onPressed: _busy ? null : _choose,
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
              onPressed: _busy || _pdf == null ? null : _recognize,
              child: const Text('인식하기'),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              WhitespaceWrappedText(_error!),
            ],
            if (_pages != null) ...[
              const SizedBox(height: 24),
              Text('인식 결과', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const WhitespaceWrappedText(
                '인식된 과목을 선택하면 등록 화면에 입력돼요. 누락이나 오류가 있을 수 있으니 원문과 입력값을 꼭 확인해 주세요.',
              ),
              if (_candidates.isEmpty) ...[
                const SizedBox(height: 12),
                const WhitespaceWrappedText(
                  '학기와 과목코드가 함께 인식된 항목이 없어요. 아래 원문을 참고해 직접 입력해 주세요.',
                ),
              ] else ...[
                const SizedBox(height: 12),
                for (var index = 0; index < _candidates.length; index++)
                  Card(
                    child: ListTile(
                      key: Key('ocr-candidate-$index'),
                      title: Text(_candidates[index].source),
                      subtitle: Text(
                        '${_candidates[index].academicYear}년 · ${_candidates[index].term!.label}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pop(_candidates[index]),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Text('인식 원문', style: Theme.of(context).textTheme.titleMedium),
              for (final page in _pages!) ...[
                const SizedBox(height: 16),
                Text('${page.page}쪽'),
                SelectableText(page.text.isEmpty ? '인식된 글자가 없어요.' : page.text),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}
