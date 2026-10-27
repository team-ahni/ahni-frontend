import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grade_fakes.dart';
import '../../support/onboarding_fakes.dart';

void main() {
  testWidgets('changing the academic year clears selected course and credit', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _tapKey(tester, 'term-FIRST');
    await _selectCourse(tester);
    expect(find.text('프로그래밍 기초'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('academic-year')));
    await tester.enterText(find.byKey(const Key('academic-year')), '2024');
    await tester.pumpAndSettle();
    expect(find.text('프로그래밍 기초'), findsNothing);
    final credit = tester.widget<TextFormField>(
      find.byKey(const Key('credit')),
    );
    expect(credit.controller!.text, isEmpty);
  });
  testWidgets('changing the term clears the selected course', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _tapKey(tester, 'term-FIRST');
    await _selectCourse(tester);
    expect(find.text('프로그래밍 기초'), findsOneWidget);
    await _tapKey(tester, 'term-SECOND');
    await tester.pumpAndSettle();
    expect(find.text('프로그래밍 기초'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('credit')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('clears the year field focus when opening course search', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _tapKey(tester, 'term-SECOND');
    await tester.ensureVisible(find.byKey(const Key('academic-year')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('academic-year')));
    await tester.pump();
    final yearField = tester.widget<TextFormField>(
      find.byKey(const Key('academic-year')),
    );
    final editable = tester.state<EditableTextState>(
      find.descendant(
        of: find.byKey(const Key('academic-year')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(yearField.controller, isNotNull);
    await _tapKey(tester, 'course-picker');
    await tester.pumpAndSettle();
    expect(editable.widget.focusNode.hasFocus, isFalse);
    expect(find.byKey(const Key('course-search')), findsOneWidget);
  });

  testWidgets('shows all instructors for the offered course', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _tapKey(tester, 'term-SECOND');
    await _tapKey(tester, 'course-picker');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is WhitespaceWrappedText &&
            widget.data == 'CSE101 · 3학점 · 김교수, 이교수',
      ),
      findsOneWidget,
    );
  });

  testWidgets('registers a selected course and returns the created grade', (
    tester,
  ) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final gradeApi = FakeGradeApi();
    GradeRecord? registeredGrade;
    await tester.pumpWidget(
      _testApp(
        auth: auth,
        gradeApi: gradeApi,
        onRegistered: (grade) async => registeredGrade = grade,
      ),
    );
    await tester.pumpAndSettle();

    await _tapKey(tester, 'term-SECOND');
    await _selectCourse(tester);
    await _tapKey(tester, 'grade-code');
    await tester.pumpAndSettle();
    await tester.tap(find.text('A+').last);
    await _tapKey(tester, 'replacement-grade');
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024년 1학기 · B0').last);
    await _tapKey(tester, 'register-grade');
    await tester.pumpAndSettle();

    final registration = gradeApi.lastRegistration!;
    expect(registration.courseEntityId, 'course-id-1');
    expect(registration.academicYear, 2025);
    expect(registration.term, AcademicTerm.second);
    expect(registration.gradeCode, GradeCode.aPlus);
    expect(registration.credit, 3);
    expect(registration.rpl, isFalse);
    expect(registration.replacedGradeEntityId, 'grade-id-0');
    expect(registeredGrade, testGrade);
  });

  testWidgets('requires a term before loading courses', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(
      tester.widget<InkWell>(find.byKey(const Key('course-picker'))).onTap,
      isNull,
    );
    await _tapKey(tester, 'term-FIRST');
    await tester.pumpAndSettle();
    await _selectCourse(tester);
    expect(find.text('프로그래밍 기초'), findsOneWidget);
  });

  testWidgets('RPL registration does not require a grade code', (tester) async {
    final gradeApi = FakeGradeApi();
    await tester.pumpWidget(_testApp(gradeApi: gradeApi));
    await tester.pumpAndSettle();

    await _tapKey(tester, 'term-FIRST');
    await _selectCourse(tester);
    await _tapKey(tester, 'rpl');
    await _tapKey(tester, 'register-grade');
    await tester.pumpAndSettle();

    expect(gradeApi.lastRegistration?.rpl, isTrue);
    expect(gradeApi.lastRegistration?.gradeCode, isNull);
    expect(find.text('성적 등급을 선택해 주세요.'), findsNothing);
  });

  testWidgets('server failure keeps entered values and shows safe feedback', (
    tester,
  ) async {
    final gradeApi = FakeGradeApi()
      ..error = const GradeApiFailure(
        GradeApiFailureKind.conflict,
        '이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.',
      );
    await tester.pumpWidget(_testApp(gradeApi: gradeApi));
    await tester.pumpAndSettle();

    await _tapKey(tester, 'term-SECOND');
    await _selectCourse(tester);
    await _tapKey(tester, 'grade-code');
    await tester.pumpAndSettle();
    await tester.tap(find.text('A+').last);
    await _tapKey(tester, 'register-grade');
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('이미 등록된 과목이에요. 수강연도와 학기를 확인해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('프로그래밍 기초'), findsOneWidget);
    expect(find.text('A+'), findsOneWidget);
  });

  testWidgets('registration form remains scrollable with large text', (
    tester,
  ) async {
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

Future<void> _selectCourse(WidgetTester tester) async {
  await _tapKey(tester, 'course-picker');
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('course-search')), 'CSE');
  await tester.pump();
  await tester.tap(find.byKey(const Key('course-option-course-id-1')));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Widget _testApp({
  FakeAuthGateway? auth,
  FakeGradeApi? gradeApi,
  Future<void> Function(GradeRecord grade)? onRegistered,
}) {
  final resolvedAuth = auth ?? FakeAuthGateway(currentSession: testSession);
  final resolvedGradeApi = gradeApi ?? FakeGradeApi();
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1558A6),
        surface: Colors.white,
      ),
    ),
    home: GradeRegistrationPage(
      courseController: CourseCatalogController(
        auth: resolvedAuth,
        api: _FakeCourseApi()..results = const [_course],
      ),
      registrationController: GradeRegistrationController(
        auth: resolvedAuth,
        api: resolvedGradeApi,
      ),
      initialAcademicYear: 2025,
      availableGrades: [_previousGrade],
      onRegistered: onRegistered ?? (_) async {},
      onAuthenticationRequired: () {},
    ),
  );
}

class _FakeCourseApi implements CourseApi {
  List<CourseCatalogItem> results = const [];

  @override
  Future<List<CourseCatalogItem>> getCourses(
    String accessToken, {
    required int academicYear,
    required AcademicTerm term,
  }) async {
    return results;
  }
}

const _course = CourseCatalogItem(
  entityId: 'course-id-1',
  code: 'CSE101',
  name: '프로그래밍 기초',
  credit: 3,
  category: CourseCategory.major,
  professorNames: ['김교수', '이교수'],
  department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
);

final _previousGrade = GradeRecord(
  entityId: 'grade-id-0',
  course: const GradeCourse(
    entityId: 'course-id-1',
    code: 'CSE101',
    name: '프로그래밍 기초',
    category: CourseCategory.major,
  ),
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
