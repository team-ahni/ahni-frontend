import 'dart:typed_data';

/// Removes location and other embedded metadata before an image leaves the
/// device. Throws [FormatException] when the image structure is not
/// recognized, so metadata is never uploaded by accident.
Uint8List stripImageMetadata(Uint8List bytes, String contentType) {
  return switch (contentType) {
    'image/jpeg' => _stripJpeg(bytes),
    'image/png' => _stripPng(bytes),
    _ => bytes,
  };
}

// APP1 holds EXIF (including GPS) and XMP; APP13 holds IPTC.
// ponytail: EXIF orientation is removed too, so a rotated camera photo may
// appear sideways. Re-encode the image if that becomes a support issue.
const _droppedJpegMarkers = {0xE1, 0xED};

Uint8List _stripJpeg(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    throw const FormatException('JPEG 형식이 아닙니다.');
  }
  final output = BytesBuilder(copy: false)..add(bytes.sublist(0, 2));
  var offset = 2;
  while (true) {
    if (offset + 4 > bytes.length || bytes[offset] != 0xFF) {
      throw const FormatException('JPEG 구조를 확인할 수 없습니다.');
    }
    final marker = bytes[offset + 1];
    if (marker == 0xDA) break; // Start of scan: the rest is image data.
    final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
    final end = offset + 2 + length;
    if (length < 2 || end > bytes.length) {
      throw const FormatException('JPEG 구조를 확인할 수 없습니다.');
    }
    if (!_droppedJpegMarkers.contains(marker)) {
      output.add(bytes.sublist(offset, end));
    }
    offset = end;
  }
  output.add(bytes.sublist(offset));
  return output.takeBytes();
}

const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const _droppedPngChunks = {'eXIf', 'tEXt', 'iTXt', 'zTXt'};

Uint8List _stripPng(Uint8List bytes) {
  if (bytes.length < 8 ||
      !List.generate(
        8,
        (index) => bytes[index] == _pngSignature[index],
      ).every((matches) => matches)) {
    throw const FormatException('PNG 형식이 아닙니다.');
  }
  final data = ByteData.sublistView(bytes);
  final output = BytesBuilder(copy: false)..add(bytes.sublist(0, 8));
  var offset = 8;
  while (offset < bytes.length) {
    if (offset + 12 > bytes.length) {
      throw const FormatException('PNG 구조를 확인할 수 없습니다.');
    }
    final length = data.getUint32(offset);
    final end = offset + 12 + length;
    if (end > bytes.length) {
      throw const FormatException('PNG 구조를 확인할 수 없습니다.');
    }
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (!_droppedPngChunks.contains(type)) {
      output.add(bytes.sublist(offset, end));
    }
    offset = end;
    if (type == 'IEND') break;
  }
  return output.takeBytes();
}
