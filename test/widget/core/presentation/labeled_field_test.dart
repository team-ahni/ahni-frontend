import 'package:ahni_mobile/app/app_theme.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows the name above the box and reads it right before the field',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: LabeledField(
              label: '학교 이메일',
              child: TextField(
                decoration: InputDecoration(hintText: 'student@inha.edu'),
              ),
            ),
          ),
        ),
      );

      final labelBottom = tester.getBottomLeft(find.text('학교 이메일')).dy;
      final fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
      expect(labelBottom, lessThanOrEqualTo(fieldTop));
      expect(find.bySemanticsLabel('학교 이메일'), findsOneWidget);
      semantics.dispose();
    },
  );
}
