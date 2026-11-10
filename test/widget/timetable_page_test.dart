import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:ahni_mobile/features/timetable/presentation/timetable_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/onboarding_fakes.dart';
import '../support/timetable_fakes.dart';

void main() {
  testWidgets('weekly view and controls fit a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthGateway(currentSession: testSession);
    final api = FakeTimetableApi()
      ..current = [
        const TimetableEntry(entityId: 'entry-1', lecture: testLecture),
      ];
    final controller = TimetableController(auth: auth, api: api);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: TimetablePage(
          controller: controller,
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('토'), findsOneWidget);
    expect(find.text('일'), findsNothing);
    final grid = tester.getRect(find.byKey(const Key('timetable-week-grid')));
    for (final day in timetableDays.take(6)) {
      final heading = tester.getRect(find.text(day));
      expect(heading.left, greaterThanOrEqualTo(grid.left));
      expect(heading.right, lessThanOrEqualTo(grid.right));
    }
    expect(
      tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where((scrollable) => scrollable.axis == Axis.horizontal),
      isEmpty,
    );
    await tester.tap(find.byTooltip('자료구조 · 09:30–11:00 · 101호'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('강의 추가'));
    await tester.pumpAndSettle();
    expect(find.text('강의 선택'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await auth.dispose();
  });

  testWidgets('lecture blocks start and end exactly on the hour lines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthGateway(currentSession: testSession);
    final controller = TimetableController(
      auth: auth,
      api: FakeTimetableApi()
        ..current = [
          const TimetableEntry(
            entityId: 'entry-1',
            lecture: Lecture(
              entityId: 'lecture-net',
              courseCode: 'ITC3410',
              courseName: '컴퓨터네트워크',
              credit: 3,
              professorName: '김교수',
              section: '001',
              schedules: [
                LectureSchedule(
                  entityId: 'schedule-net',
                  dayOfWeek: 5,
                  startTime: '13:00:00',
                  endTime: '16:00:00',
                  classroom: '9-217',
                ),
              ],
            ),
          ),
        ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TimetablePage(
          controller: controller,
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final block = tester.getRect(
      find.byTooltip('컴퓨터네트워크 · 13:00–16:00 · 9-217'),
    );
    final line13 = tester.getRect(
      find.byKey(const Key('timetable-hour-line-13')),
    );
    final line16 = tester.getRect(
      find.byKey(const Key('timetable-hour-line-16')),
    );
    expect(block.top, moreOrLessEquals(line13.top));
    expect(block.bottom, moreOrLessEquals(line16.top));
    // 격자는 강의와 관계없이 22시까지 그리고, 끝 시각도 숫자로 보인다.
    expect(find.byKey(const Key('timetable-hour-line-22')), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(
      tester.getRect(find.text('22')).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const Key('timetable-week-grid'))).bottom,
      ),
    );

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await auth.dispose();
  });

  testWidgets('adds a lecture and confirms deletion', (tester) async {
    final auth = FakeAuthGateway(currentSession: testSession);
    final controller = TimetableController(auth: auth, api: FakeTimetableApi());
    await tester.pumpWidget(
      MaterialApp(
        home: TimetablePage(
          controller: controller,
          onAuthenticationRequired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.loaded, isTrue);
    expect(controller.entries, isEmpty);
    await tester.tap(find.byTooltip('강의 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('자료구조'));
    await tester.pumpAndSettle();
    expect(controller.entries, hasLength(1));
    await tester.scrollUntilVisible(
      find.byTooltip('강의 삭제'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    // 목록 끝에 걸쳐 보이면 버튼 가운데가 화면 밖일 수 있어 한 번 더 맞춘다.
    await tester.ensureVisible(find.byTooltip('강의 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('강의 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(controller.entries, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await auth.dispose();
  });
}
