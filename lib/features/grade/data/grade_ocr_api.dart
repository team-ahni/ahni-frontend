import 'dart:io';
import 'dart:math' as math;

import 'package:ahni_mobile/features/grade/domain/ocr_text_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class GradeOcrFailure implements Exception {
  const GradeOcrFailure(this.message);
  final String message;
}

class GradeOcrPageResult {
  const GradeOcrPageResult(
    this.page,
    this.text, {
    this.lines = const [],
    this.fragments = const [],
    this.width = 0,
  });

  factory GradeOcrPageResult.fromNative(
    int page,
    Map<Object?, Object?> result, {
    required double width,
  }) {
    List<OcrTextLine> parse(Object? value) => (value as List<Object?>)
        .map((item) {
          final row = item as Map<Object?, Object?>;
          double coordinate(String key) => (row[key] as num).toDouble();
          return OcrTextLine(
            text: row['text'] as String,
            left: coordinate('left'),
            top: coordinate('top'),
            right: coordinate('right'),
            bottom: coordinate('bottom'),
          );
        })
        .toList(growable: false);
    return GradeOcrPageResult(
      page,
      result['text'] as String,
      lines: List.unmodifiable(parse(result['lines'])),
      fragments: List.unmodifiable(parse(result['fragments'])),
      width: width,
    );
  }
  final int page;
  final String text;
  final List<OcrTextLine> lines;
  final List<OcrTextLine> fragments;
  final double width;
}

abstract interface class GradeOcrApi {
  Future<List<GradeOcrPageResult>> preview(Uint8List pdf);
}

/// Render small transcript text larger while bounding the decoded image size.
@visibleForTesting
double gradeOcrRenderScale(double width, double height) =>
    math.min(3.5, 3500 / math.max(width, height));

/// Processes each page sequentially on the device; no transcript is uploaded.
class OnDeviceGradeOcrApi implements GradeOcrApi {
  @override
  Future<List<GradeOcrPageResult>> preview(Uint8List pdf) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw const GradeOcrFailure('PDF 인식은 Android와 iPhone에서 사용할 수 있어요.');
    }
    PdfDocument? document;
    const channel = MethodChannel('ahni/grade_ocr');
    Directory? temporaryDirectory;
    try {
      temporaryDirectory = await (await getTemporaryDirectory()).createTemp(
        'ahni_ocr_',
      );
      final pdfFile = File('${temporaryDirectory.path}/transcript.pdf');
      await pdfFile.writeAsBytes(pdf, flush: true);
      document = await PdfDocument.openFile(pdfFile.path);
      if (document.pagesCount < 1 || document.pagesCount > 5) {
        throw const GradeOcrFailure('1~5쪽 PDF 파일을 선택해 주세요.');
      }
      final results = <GradeOcrPageResult>[];
      for (var index = 1; index <= document.pagesCount; index++) {
        final page = await document.getPage(index);
        try {
          final scale = gradeOcrRenderScale(page.width, page.height);
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (image == null) throw const GradeOcrFailure('PDF 페이지를 읽지 못했어요.');
          final file = File('${temporaryDirectory.path}/page.png');
          await file.writeAsBytes(image.bytes, flush: true);
          try {
            final result = await channel.invokeMapMethod<Object?, Object?>(
              'recognize',
              {'path': file.path},
            );
            if (result == null) throw const GradeOcrFailure('PDF를 인식하지 못했어요.');
            results.add(
              GradeOcrPageResult.fromNative(
                index,
                result,
                width: (image.width ?? (page.width * scale).round()).toDouble(),
              ),
            );
          } finally {
            if (await file.exists()) await file.delete();
          }
        } finally {
          await page.close();
        }
      }
      return List.unmodifiable(results);
    } on GradeOcrFailure {
      rethrow;
    } on Object {
      throw const GradeOcrFailure('PDF를 인식하지 못했어요. 비밀번호가 없는 PDF인지 확인해 주세요.');
    } finally {
      try {
        await document?.close();
      } finally {
        if (temporaryDirectory != null && await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      }
    }
  }
}
