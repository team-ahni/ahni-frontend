import 'package:ahni_mobile/core/presentation/sheet_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  sheetBottomInset(context),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader('강의 선택'),
                    SizedBox(key: Key('content'), height: 40, width: 9999),
                  ],
                ),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('lines the close icon up with the content edge', (tester) async {
    await openSheet(tester);

    final icon = tester.getRect(find.byIcon(Icons.close));
    final content = tester.getRect(find.byKey(const Key('content')));
    expect(icon.right, content.right);
    // 모양만 옮기고 터치 영역은 48pt 그대로 둔다.
    expect(tester.getSize(find.byKey(const Key('sheet-close'))).width, 48);
  });

  testWidgets('keeps sheet content above the home indicator', (tester) async {
    await openSheet(tester);

    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 844 - 34);
  });

  testWidgets('closes the sheet', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('강의 선택'), findsNothing);
  });
}
