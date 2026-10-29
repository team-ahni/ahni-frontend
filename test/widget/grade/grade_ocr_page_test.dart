import 'dart:typed_data';

import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_ocr_api.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_ocr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';

void main() {
  testWidgets('selects a PDF and shows OCR text without saving grades', (
    tester,
  ) async {
    final api = _OcrApi();
    final grades = FakeGradeApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: grades,
      ocrApi: api,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GradeOcrPage(
          controller: controller,
          picker: () async => (
            name: '성적표.pdf',
            bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ocr-pick-pdf')));
    await tester.pumpAndSettle();
    expect(find.text('성적표.pdf'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ocr-recognize')));
    await tester.pumpAndSettle();
    expect(find.text('자료구조 A+'), findsOneWidget);
    expect(grades.lastRegistration, isNull);
    expect(api.called, isTrue);
  });
  testWidgets('rejects non-PDF data before upload', (tester) async {
    final api = _OcrApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: FakeGradeApi(),
      ocrApi: api,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GradeOcrPage(
          controller: controller,
          picker: () async => (
            name: 'bad.pdf',
            bytes: Uint8List.fromList('not-a-pdf'.codeUnits),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ocr-pick-pdf')));
    await tester.pumpAndSettle();
    expect(api.called, isFalse);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('ocr-recognize')))
          .onPressed,
      isNull,
    );
  });
}

class _OcrApi implements GradeOcrApi {
  bool called = false;
  @override
  Future<List<GradeOcrPageResult>> preview(Uint8List pdf) async {
    called = true;
    return const [GradeOcrPageResult(1, '자료구조 A+')];
  }
}
