import 'dart:io';

import 'package:ahni_mobile/features/timetable/domain/timetable_import.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class RegistrationScreenshotFailure implements Exception {
  const RegistrationScreenshotFailure(this.message);
  final String message;
}

/// 수강신청 내역 캡처를 골라 기기 안에서 글자를 읽는다. 이미지는 서버로 보내지 않는다.
abstract interface class RegistrationScreenshotReader {
  /// 사진을 고르지 않으면 null, 고르면 행 순서대로 이은 글을 돌려준다.
  Future<String?> pickAndRead();
}

class OnDeviceRegistrationScreenshotReader
    implements RegistrationScreenshotReader {
  const OnDeviceRegistrationScreenshotReader();

  // 성적표 PDF 인식과 같은 기기 내 글자 인식 채널(iOS Vision, Android ML Kit)을 쓴다.
  static const _channel = MethodChannel('ahni/grade_ocr');

  @override
  Future<String?> pickAndRead() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw const RegistrationScreenshotFailure(
        '캡처 인식은 Android와 iPhone에서 사용할 수 있어요.',
      );
    }
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    final directory = await (await getTemporaryDirectory()).createTemp(
      'ahni_registration_',
    );
    try {
      final image = File('${directory.path}/registration.png');
      await image.writeAsBytes(await file.readAsBytes(), flush: true);
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'recognize',
        {
          'path': image.path,
          // iOS는 기본으로 화면을 좌우로 나눠 읽는다. 캡처는 한 표라 전체를 한 번에 읽게 한다.
          // 이미지 크기를 넘는 값은 iOS가 이미지 경계로 자른다.
          'regions': const [
            {'left': 0.0, 'top': 0.0, 'right': 1e7, 'bottom': 1e7},
          ],
        },
      );
      final fragments = result?['fragments'] as List<Object?>?;
      if (fragments == null) {
        throw const RegistrationScreenshotFailure('캡처에서 글자를 읽지 못했어요.');
      }
      return joinFragmentsByRow([
        for (final item in fragments.cast<Map<Object?, Object?>>())
          (
            text: item['text']! as String,
            left: (item['left']! as num).toDouble(),
            top: (item['top']! as num).toDouble(),
            bottom: (item['bottom']! as num).toDouble(),
          ),
      ]);
    } on PlatformException {
      throw const RegistrationScreenshotFailure('캡처에서 글자를 읽지 못했어요.');
    } finally {
      await directory.delete(recursive: true);
    }
  }
}
