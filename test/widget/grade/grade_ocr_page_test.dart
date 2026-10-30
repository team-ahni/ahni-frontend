import 'dart:typed_data';

import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_ocr_api.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_ocr_page.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';

void main() {
  GradeOcrPageResult registrationPage({bool includeGrade = true}) {
    OcrTextLine word(String text, double x) =>
        OcrTextLine(text: text, left: x, top: 100, right: x + 40, bottom: 110);
    return GradeOcrPageResult(
      1,
      '전체 인식문은 표시하지 않음',
      width: 1000,
      fragments: [
        const OcrTextLine(
          text: '2024학년도 1학기',
          left: 50,
          top: 70,
          right: 200,
          bottom: 80,
        ),
        word('ABC1001', 50),
        word('OCR 임시 과목명', 110),
        word('3.0', 200),
        if (includeGrade) word('A+', 300),
      ],
    );
  }

  const course = CourseCatalogItem(
    entityId: 'ocr-course',
    code: 'ABC1001',
    name: '예시 과목',
    credit: 3,
    category: CourseCategory.major,
  );

  testWidgets('registers selected rows and reports changes when finishing', (
    tester,
  ) async {
    final grades = FakeGradeApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: grades,
      catalogApi: FakeCourseApi()..results = [course],
      ocrApi: _OcrApi(pages: [registrationPage()]),
    );
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Object>(
                  MaterialPageRoute(
                    builder: (_) => GradeOcrPage(
                      controller: controller,
                      picker: () async => (
                        name: '예시.pdf',
                        bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('시작'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-pick-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-recognize')));
    await tester.pumpAndSettle();
    expect(grades.registerCalls, 0);
    expect(
      tester.widget<Text>(find.byKey(const Key('ocr-course-name-0'))).data,
      '예시 과목',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('ocr-register-selected')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('ocr-select-0')));
    await tester.tap(find.byKey(const Key('ocr-select-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-register-selected')));
    await tester.pumpAndSettle();
    expect(grades.registerCalls, 1);
    expect(grades.lastRegistration!.courseEntityId, course.entityId);
    expect(grades.lastRegistration!.gradeCode, GradeCode.aPlus);
    expect(find.text('전체 인식문은 표시하지 않음'), findsNothing);
    expect(find.byKey(const Key('ocr-full-source')), findsNothing);
    await tester.tap(find.byKey(const Key('ocr-finish')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('시작'), findsOneWidget);
  });

  testWidgets('requires a missing grade to be edited before selecting a row', (
    tester,
  ) async {
    final grades = FakeGradeApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: grades,
      catalogApi: FakeCourseApi()..results = [course],
      ocrApi: _OcrApi(pages: [registrationPage(includeGrade: false)]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GradeOcrPage(
          controller: controller,
          picker: () async =>
              (name: '예시.pdf', bytes: Uint8List.fromList('%PDF-1.7'.codeUnits)),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ocr-pick-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-recognize')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('ocr-select-0'))).onChanged,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('ocr-candidate-0')));
    await tester.tap(find.byKey(const Key('ocr-candidate-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-edit-grade')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A+').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-edit-apply')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('ocr-select-0'))).onChanged,
      isNotNull,
    );
    expect(grades.registerCalls, 0);
  });

  testWidgets('shows each course credit and grade with missing values marked', (
    tester,
  ) async {
    OcrTextLine word(String text, double x, double y) =>
        OcrTextLine(text: text, left: x, top: y, right: x + 40, bottom: y + 10);
    final api = _OcrApi(
      pages: [
        GradeOcrPageResult(
          1,
          '예시 원문',
          width: 1000,
          fragments: [
            word('2024학년도', 50, 70),
            word('1학기', 150, 70),
            word('학수번호', 50, 90),
            word('학점', 200, 90),
            word('평점', 300, 90),
            word('ABC1001', 50, 120),
            word('자료구조', 110, 120),
            word('3.0', 200, 120),
            word('At', 300, 120),
            word('DEF1002', 50, 150),
          ],
          fieldFragments: [word('A+', 300, 120)],
        ),
      ],
    );
    final grades = FakeGradeApi();
    final controller = GradeRegistrationController(
      auth: FakeAuthGateway(currentSession: testSession),
      api: grades,
      ocrApi: api,
      catalogApi: FakeCourseApi(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GradeOcrPage(
          controller: controller,
          picker: () async =>
              (name: '예시.pdf', bytes: Uint8List.fromList('%PDF-1.7'.codeUnits)),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ocr-pick-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-recognize')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('ocr-course-name-0'))).data,
      '자료구조',
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is WhitespaceWrappedText && w.data == '학점 3.0 · 성적 A+',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is WhitespaceWrappedText && w.data == '학점 확인 필요 · 성적 확인 필요',
      ),
      findsOneWidget,
    );
    expect(grades.lastRegistration, isNull);
    expect(find.text('ABC1001 자료구조 3.0 At'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('ocr-source-0')));
    await tester.tap(find.byKey(const Key('ocr-source-0')));
    await tester.pumpAndSettle();
    expect(find.text('ABC1001 자료구조 3.0 At'), findsOneWidget);
  });
  testWidgets('selects a PDF without exposing full OCR text or saving grades', (
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
    expect(find.byKey(const Key('ocr-full-source')), findsNothing);
    expect(find.text('자료구조 A+'), findsNothing);
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
  _OcrApi({this.pages = const [GradeOcrPageResult(1, '자료구조 A+')]});
  final List<GradeOcrPageResult> pages;
  bool called = false;
  @override
  Future<List<GradeOcrPageResult>> preview(Uint8List pdf) async {
    called = true;
    return pages;
  }
}
