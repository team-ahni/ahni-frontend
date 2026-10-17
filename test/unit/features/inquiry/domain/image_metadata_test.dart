import 'dart:convert';
import 'dart:typed_data';

import 'package:ahni_mobile/features/inquiry/domain/image_metadata.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _jpegSegment(int marker, List<int> payload) {
  final length = payload.length + 2;
  return [0xFF, marker, length >> 8, length & 0xFF, ...payload];
}

List<int> _pngChunk(String type, List<int> data) {
  final length = data.length;
  return [
    length >> 24,
    (length >> 16) & 0xFF,
    (length >> 8) & 0xFF,
    length & 0xFF,
    ...ascii.encode(type),
    ...data,
    0, 0, 0, 0, // CRC is copied as-is, not validated here.
  ];
}

void main() {
  group('JPEG', () {
    final app0 = _jpegSegment(0xE0, ascii.encode('JFIF\u0000'));
    final exif = _jpegSegment(0xE1, ascii.encode('Exif\u0000\u0000GPS'));
    final iptc = _jpegSegment(0xED, ascii.encode('Photoshop'));
    final quantization = _jpegSegment(0xDB, [1, 2, 3]);
    final scan = [0xFF, 0xDA, 0x00, 0x02, 9, 9, 0xFF, 0xD9];

    test('removes EXIF/XMP and IPTC segments and keeps image data', () {
      final input = Uint8List.fromList([
        0xFF,
        0xD8,
        ...app0,
        ...exif,
        ...iptc,
        ...quantization,
        ...scan,
      ]);

      final output = stripImageMetadata(input, 'image/jpeg');

      expect(output, [0xFF, 0xD8, ...app0, ...quantization, ...scan]);
      expect(ascii.decode(output, allowInvalid: true), isNot(contains('GPS')));
    });

    test('rejects a truncated segment instead of uploading metadata', () {
      final input = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x10, 0x00, 1]);

      expect(
        () => stripImageMetadata(input, 'image/jpeg'),
        throwsFormatException,
      );
    });
  });

  group('PNG', () {
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    final header = _pngChunk('IHDR', List.filled(13, 1));
    final data = _pngChunk('IDAT', [7, 7, 7]);
    final end = _pngChunk('IEND', const []);

    test('removes eXIf and text chunks', () {
      final input = Uint8List.fromList([
        ...signature,
        ...header,
        ..._pngChunk('eXIf', ascii.encode('GPS')),
        ..._pngChunk('tEXt', ascii.encode('Author')),
        ...data,
        ...end,
      ]);

      expect(stripImageMetadata(input, 'image/png'), [
        ...signature,
        ...header,
        ...data,
        ...end,
      ]);
    });

    test('rejects a file without the PNG signature', () {
      expect(
        () => stripImageMetadata(Uint8List.fromList([1, 2, 3]), 'image/png'),
        throwsFormatException,
      );
    });
  });

  test('leaves PDF bytes untouched', () {
    final input = Uint8List.fromList(ascii.encode('%PDF-1.7'));

    expect(stripImageMetadata(input, 'application/pdf'), same(input));
  });

  test('maps only backend-accepted extensions to content types', () {
    expect(InquiryAttachment.contentTypeFor('scan.JPG'), 'image/jpeg');
    expect(InquiryAttachment.contentTypeFor('a.jpeg'), 'image/jpeg');
    expect(InquiryAttachment.contentTypeFor('a.png'), 'image/png');
    expect(InquiryAttachment.contentTypeFor('a.pdf'), 'application/pdf');
    expect(InquiryAttachment.contentTypeFor('IMG_0001.HEIC'), isNull);
    expect(InquiryAttachment.contentTypeFor('noextension'), isNull);
  });
}
