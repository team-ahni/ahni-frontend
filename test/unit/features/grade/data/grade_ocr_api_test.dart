import 'dart:typed_data';

import 'package:ahni_mobile/features/grade/data/grade_ocr_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders small transcript text larger with a bounded image size', () {
    expect(gradeOcrRenderScale(595, 842), 4.5);
    expect(gradeOcrRenderScale(2000, 1000), 2.1);
  });

  test('retains recognized text and each line position', () {
    final row = {
      'text': '자료구조',
      'left': 10,
      'top': 20,
      'right': 110,
      'bottom': 40,
    };
    final page = GradeOcrPageResult.fromNative(2, {
      'text': '자료구조',
      'lines': [row],
      'fragments': [row],
    }, width: 200);
    expect(page.page, 2);
    expect(page.text, '자료구조');
    expect(page.lines.single.text, '자료구조');
    expect(
      [
        page.lines.single.left,
        page.lines.single.top,
        page.lines.single.right,
        page.lines.single.bottom,
      ],
      [10, 20, 110, 40],
    );
    expect(() => page.lines.clear(), throwsUnsupportedError);
  });

  test('unsupported platforms return an actionable message', () async {
    final api = OnDeviceGradeOcrApi();
    await expectLater(
      () => api.preview(Uint8List.fromList('%PDF-'.codeUnits)),
      throwsA(
        isA<GradeOcrFailure>().having(
          (error) => error.message,
          'message',
          contains('Android'),
        ),
      ),
    );
  });
}
