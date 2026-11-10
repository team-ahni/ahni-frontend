import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/data/registration_screenshot_reader.dart';
import 'package:ahni_mobile/features/timetable/data/timetable_api.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:ahni_mobile/features/timetable/presentation/timetable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/timetable_fakes.dart';
import '../support/whitespace_wrapped_text_finder.dart';

class _FakeReader implements RegistrationScreenshotReader {
  _FakeReader(this.text);
  final String? text;
  @override
  Future<String?> pickAndRead() async => text;
}

// 실제 학수번호 형식(영문 + 숫자 4자리)의 개설 강의.
const _network = Lecture(
  entityId: 'lecture-net',
  courseCode: 'ITC3410',
  courseName: '컴퓨터네트워크',
  credit: 3,
  professorName: '교수가',
  section: '002',
  schedules: [
    LectureSchedule(
      entityId: 'schedule-net',
      dayOfWeek: 2,
      startTime: '09:00:00',
      endTime: '10:30:00',
      classroom: null,
    ),
  ],
);

// 시간표에 있는 testLecture(월 09:30–11:00)와 시간이 겹치는 개설 강의.
const _overlapping = Lecture(
  entityId: 'lecture-sec',
  courseCode: 'ITC4609',
  courseName: '컴퓨터보안',
  credit: 3,
  professorName: '교수다',
  section: '001',
  schedules: [
    LectureSchedule(
      entityId: 'schedule-sec',
      dayOfWeek: 1,
      startTime: '10:00:00',
      endTime: '11:30:00',
      classroom: null,
    ),
  ],
);

void main() {
  Future<FakeTimetableApi> open(
    WidgetTester tester, {
    RegistrationScreenshotReader? reader,
    TimetableApiFailure? failure,
    List<TimetableEntry> current = const [],
    List<Lecture> offered = const [_network],
    Set<String> rejected = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeTimetableApi()
      ..failure = failure
      ..current = [...current]
      ..offered = offered
      ..rejectedLectureIds = rejected;
    await tester.pumpWidget(
      MaterialApp(
        home: TimetablePage(
          controller: TimetableController(
            auth: FakeAuthGateway(currentSession: testSession),
            api: api,
          ),
          onAuthenticationRequired: () {},
          screenshotReader: reader ?? _FakeReader(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-registration')));
    await tester.pumpAndSettle();
    return api;
  }

  Future<void> confirm(WidgetTester tester) async {
    final button = find.byKey(const Key('import-registration-confirm'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('adds every section found in pasted registration text', (
    tester,
  ) async {
    final api = await open(tester);

    // 익명화한 수강신청 확인 표 복사본. 두 번째 과목은 이 학기에 없다.
    await tester.enterText(
      find.byKey(const Key('import-registration-text')),
      'ITC3410\t002\t컴퓨터네트워크\t3.0\t전공필수\t교수가\n'
      'ITC9999\t001\t없는 과목\t3.0\t전공선택\t교수나',
    );
    await tester.tap(find.byKey(const Key('import-registration-find')));
    await tester.pumpAndSettle();

    expect(find.text('추가할 강의 1개'), findsOneWidget);
    // 결과 단계에서는 입력란 없이 찾은 강의만 보인다.
    expect(findWhitespaceWrappedText('찾은 강의'), findsOneWidget);
    expect(find.byKey(const Key('import-registration-text')), findsNothing);
    // 학교 화면과 대조할 수 있게 카드에 분반·교수·시간까지 보인다.
    final card = find.byKey(const ValueKey('import-lecture-lecture-net'));
    expect(card, findsOneWidget);
    for (final text in ['컴퓨터네트워크', '교수가', '화 09:00–10:30']) {
      expect(
        find.descendant(of: card, matching: findWhitespaceWrappedText(text)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: card, matching: find.text('ITC3410-002 · 3학점')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('import-registration-not-found')),
        matching: findWhitespaceWrappedText(
          '찾지 못했어요: ITC9999-001\n이 학기에 없거나 분반을 정할 수 없는 강의예요. 강의 추가에서 직접 골라 주세요.',
        ),
      ),
      findsOneWidget,
    );

    await confirm(tester);

    expect(api.savedLectureIds, ['lecture-net']);
    expect(find.text('강의 1개를 시간표에 넣었어요.'), findsOneWidget);
  });

  testWidgets('goes back to choosing input and keeps the pasted text', (
    tester,
  ) async {
    await open(tester);
    const pasted = 'ITC3410 002 컴퓨터네트워크';
    await tester.enterText(
      find.byKey(const Key('import-registration-text')),
      pasted,
    );
    await tester.tap(find.byKey(const Key('import-registration-find')));
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('import-registration-retry'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(findWhitespaceWrappedText('수강신청 내역 가져오기'), findsOneWidget);
    expect(find.byKey(const Key('import-registration-confirm')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('import-registration-text')))
          .controller
          ?.text,
      pasted,
    );
  });

  testWidgets('reads a screenshot and adds the matched section', (
    tester,
  ) async {
    final api = await open(tester, reader: _FakeReader('ITC3410 002컴퓨터네트워크'));

    await tester.tap(find.byKey(const Key('import-registration-screenshot')));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(api.savedLectureIds, ['lecture-net']);
  });

  testWidgets('explains when nothing can be found', (tester) async {
    await open(tester);

    await tester.enterText(
      find.byKey(const Key('import-registration-text')),
      '수강신청 내역이 아닌 글',
    );
    await tester.tap(find.byKey(const Key('import-registration-find')));
    await tester.pumpAndSettle();

    expect(
      findWhitespaceWrappedText(
        '학수번호와 분반을 찾지 못했어요. 수강신청 확인 표가 보이게 다시 시도해 주세요.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('import-registration-confirm')), findsNothing);
  });

  testWidgets('reports sections the server refused', (tester) async {
    await open(
      tester,
      failure: const TimetableApiFailure('같은 시간에 이미 다른 강의가 있어요.'),
    );

    await tester.enterText(
      find.byKey(const Key('import-registration-text')),
      'ITC3410 002 컴퓨터네트워크',
    );
    await tester.tap(find.byKey(const Key('import-registration-find')));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(
      find.text('0개를 넣었고 1개는 넣지 못했어요. 컴퓨터네트워크: 같은 시간에 이미 다른 강의가 있어요.'),
      findsOneWidget,
    );
  });

  Future<void> findOverlapping(
    WidgetTester tester, {
    String text = 'ITC4609 001 컴퓨터보안',
  }) async {
    await tester.enterText(
      find.byKey(const Key('import-registration-text')),
      text,
    );
    await tester.tap(find.byKey(const Key('import-registration-find')));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final button = find.byKey(Key(key));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  const existing = TimetableEntry(entityId: 'entry-old', lecture: testLecture);

  testWidgets('shows what gets replaced and replaces it in one tap', (
    tester,
  ) async {
    final api = await open(
      tester,
      current: [existing],
      offered: [_overlapping],
    );
    await findOverlapping(tester);

    expect(
      findWhitespaceWrappedText('시간이 겹쳐요: 자료구조(월 09:30–11:00)'),
      findsOneWidget,
    );
    // 대화상자 없이 결과 화면에서 빠질 강의와 들어올 강의를 보고 바로 고른다.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('import-registration-confirm')), findsNothing);
    final decision = find.byKey(const Key('import-conflict-decision'));
    expect(
      find.descendant(of: decision, matching: find.text('빠짐')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: decision, matching: find.text('바꿔서 1개 추가')),
      findsOneWidget,
    );
    // 겹치지 않는 강의가 없으면 빼고 추가할 것도 없어 버튼을 보이지 않는다.
    expect(find.byKey(const Key('import-conflict-skip')), findsNothing);

    await tapKey(tester, 'import-conflict-replace');

    expect(api.deletedEntryIds, ['entry-old']);
    expect(api.savedLectureIds, ['lecture-sec']);
    expect(find.text('강의 1개를 시간표에 넣었어요.'), findsOneWidget);
  });

  testWidgets('adds only the lectures that do not overlap when skipping', (
    tester,
  ) async {
    final api = await open(
      tester,
      current: [existing],
      offered: [_overlapping, _network],
    );
    await findOverlapping(
      tester,
      text: 'ITC4609 001 컴퓨터보안\nITC3410 002 컴퓨터네트워크',
    );

    expect(find.text('겹치는 강의 빼고 1개 추가'), findsOneWidget);
    await tapKey(tester, 'import-conflict-skip');

    expect(api.deletedEntryIds, isEmpty);
    expect(api.savedLectureIds, ['lecture-net']);
  });

  testWidgets('puts the old lecture back when the replacement is refused', (
    tester,
  ) async {
    final api = await open(
      tester,
      current: [existing],
      offered: [_overlapping],
      rejected: {'lecture-sec'},
    );
    await findOverlapping(tester);
    await tapKey(tester, 'import-conflict-replace');

    expect(api.deletedEntryIds, ['entry-old']);
    // 새 강의를 넣지 못해 뺐던 기존 강의를 다시 넣었다.
    expect(api.savedLectureIds, ['lecture-1']);
    expect(find.text('0개를 넣었고 1개는 넣지 못했어요. 컴퓨터보안: 시간이 겹칩니다.'), findsOneWidget);
  });
}
