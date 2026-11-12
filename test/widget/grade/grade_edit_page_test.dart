import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';

void main() {
  testWidgets('shows the current grade values when editing starts', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('프로그래밍 기초'), findsOneWidget);
    expect(find.text('CSE101 · 3학점'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('edit-academic-year')))
          .controller
          ?.text,
      '2025',
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('edit-term-SECOND')))
          .selected,
      isTrue,
    );
    expect(find.text('A+'), findsOneWidget);
    expect(find.text('2024년 1학기 · B0'), findsOneWidget);
  });

  testWidgets('saves changed values and returns the updated grade', (
    tester,
  ) async {
    final api = FakeGradeApi();
    GradeRecord? savedGrade;
    await tester.pumpWidget(
      _testApp(api: api, onSaved: (grade) async => savedGrade = grade),
    );

    await tester.enterText(find.byKey(const Key('edit-academic-year')), '2024');
    await tester.tap(find.byKey(const Key('edit-term-WINTER')));
    await _tapVisible(tester, 'edit-grade-code');
    await tester.pumpAndSettle();
    await tester.tap(find.text('B+').last);
    await tester.enterText(find.byKey(const Key('edit-credit')), '2');
    await _tapVisible(tester, 'edit-replacement-grade');
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택 안 함').last);
    await _tapVisible(tester, 'save-grade');
    await tester.pumpAndSettle();

    expect(api.lastGradeEntityId, 'grade-id-1');
    expect(api.lastUpdate?.academicYear, 2024);
    expect(api.lastUpdate?.term, AcademicTerm.winter);
    expect(api.lastUpdate?.gradeCode, GradeCode.bPlus);
    expect(api.lastUpdate?.credit, 2);
    expect(api.lastUpdate?.replacedGradeEntityId, isNull);
    expect(savedGrade, testGrade);
  });

  testWidgets('deletes only after explicit confirmation', (tester) async {
    final api = FakeGradeApi();
    var deleted = false;
    await tester.pumpWidget(
      _testApp(api: api, onDeleted: () async => deleted = true),
    );

    await _tapVisible(tester, 'delete-grade');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('성적을 삭제할까요?'), findsOneWidget);
    expect(api.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('confirm-delete-grade')));
    await tester.pumpAndSettle();

    expect(api.lastGradeEntityId, 'grade-id-1');
    expect(api.deleteCalls, 1);
    expect(deleted, isTrue);
  });

  testWidgets('keeps changed values when saving fails', (tester) async {
    final api = FakeGradeApi()
      ..error = const GradeApiFailure(
        GradeApiFailureKind.conflict,
        '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
      );
    await tester.pumpWidget(_testApp(api: api));

    await tester.enterText(find.byKey(const Key('edit-academic-year')), '2024');
    // 입력 중인 칸은 커서를 보이려고 화면을 되돌리므로 입력을 마친 뒤 저장을 누른다.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tapVisible(tester, 'save-grade');
    await tester.pumpAndSettle();
    // 안내는 폼 위쪽에 있어 저장 버튼까지 내려간 화면에서는 다시 올려 봐야 한다.
    await tester.ensureVisible(find.text('이미').first);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('edit-academic-year')))
          .controller
          ?.text,
      '2024',
    );
  });

  testWidgets('edit form remains scrollable with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _testApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  FakeGradeApi? api,
  Future<void> Function(GradeRecord grade)? onSaved,
  Future<void> Function()? onDeleted,
}) {
  final resolvedApi = api ?? FakeGradeApi();
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1558A6),
        surface: Colors.white,
      ),
    ),
    home: GradeEditPage(
      grade: testGrade,
      availableGrades: [testGrade, _previousGrade],
      controller: GradeEditController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: resolvedApi,
      ),
      onSaved: onSaved ?? (_) async {},
      onDeleted: onDeleted ?? () async {},
      onAuthenticationRequired: () {},
    ),
  );
}

final _previousGrade = GradeRecord(
  entityId: 'grade-id-0',
  course: testGrade.course,
  academicYear: 2024,
  term: AcademicTerm.first,
  gradeCode: GradeCode.bZero,
  gradePoint: 3,
  credit: 3,
  rpl: false,
  replacedGradeEntityId: null,
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
);

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}
