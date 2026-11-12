import 'package:ahni_mobile/app/app_theme.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget field) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: LabeledField(label: '학교 이메일', child: field),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double firstErrorWordLeft(WidgetTester tester) => tester
      .getTopLeft(
        find
            .descendant(
              of: find.byType(FieldErrorText),
              matching: find.byType(Text),
            )
            .first,
      )
      .dx;

  testWidgets('text field error starts on the label line', (tester) async {
    await pump(
      tester,
      TextFormField(
        errorBuilder: fieldErrorBuilder,
        forceErrorText: '인하대학교 이메일(@inha.edu)을 입력해 주세요.',
      ),
    );

    expect(
      firstErrorWordLeft(tester),
      tester.getTopLeft(find.text('학교 이메일')).dx,
    );
  });

  testWidgets('dropdown error starts on the label line', (tester) async {
    await pump(
      tester,
      DropdownButtonFormField<int>(
        errorBuilder: fieldErrorBuilder,
        forceErrorText: '성적을 선택해 주세요.',
        items: const [DropdownMenuItem(value: 1, child: Text('A+'))],
        onChanged: (_) {},
      ),
    );

    expect(
      firstErrorWordLeft(tester),
      tester.getTopLeft(find.text('학교 이메일')).dx,
    );
  });
}
