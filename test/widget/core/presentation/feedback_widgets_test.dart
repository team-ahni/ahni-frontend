import 'package:ahni_mobile/core/presentation/app_message.dart';
import 'package:ahni_mobile/core/presentation/busy_button_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the label next to the spinner while busy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FilledButton(
          onPressed: null,
          child: BusyButtonLabel(isBusy: true, label: '저장'),
        ),
      ),
    );

    expect(find.text('저장'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows only the label when idle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FilledButton(
          onPressed: null,
          child: BusyButtonLabel(isBusy: false, label: '저장'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a new app message replaces the one on screen', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    showAppMessage(context, '첫 알림');
    await tester.pumpAndSettle();
    showAppMessage(context, '둘째 알림');
    await tester.pumpAndSettle();

    expect(find.text('첫 알림'), findsNothing);
    expect(find.text('둘째 알림'), findsOneWidget);
  });
}
