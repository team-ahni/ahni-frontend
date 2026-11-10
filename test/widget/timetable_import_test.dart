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

void main() {
  Future<FakeTimetableApi> open(
    WidgetTester tester, {
    RegistrationScreenshotReader? reader,
    TimetableApiFailure? failure,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeTimetableApi()
      ..failure = failure
      ..offered = [_network];
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
    // 학교 화면과 대조할 수 있게 교수와 시간까지 보인다.
    expect(
      findWhitespaceWrappedText('컴퓨터네트워크 · ITC3410-002 · 교수가 · 화 09:00–10:30'),
      findsOneWidget,
    );
    expect(find.text('찾지 못했어요'), findsOneWidget);
    expect(findWhitespaceWrappedText('ITC9999-001'), findsOneWidget);

    await confirm(tester);

    expect(api.savedLectureIds, ['lecture-net']);
    expect(find.text('강의 1개를 시간표에 넣었어요.'), findsOneWidget);
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
}
