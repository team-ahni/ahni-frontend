import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// [length] is null when the platform could not report it. [read] loads the
/// bytes, so callers can reject oversized files without reading them.
typedef PickedFile = ({
  String name,
  int? length,
  Future<Uint8List> Function() read,
});

abstract interface class AttachmentPicker {
  /// Returns null when the student cancels the picker.
  Future<PickedFile?> pickImage();

  Future<PickedFile?> pickPdf();
}

/// Uses the system photo picker and document picker, which need no storage
/// permission on supported iOS and Android versions.
class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker();

  @override
  Future<PickedFile?> pickImage() => _pick(FileType.image, null);

  @override
  Future<PickedFile?> pickPdf() => _pick(FileType.custom, const ['pdf']);

  Future<PickedFile?> _pick(FileType type, List<String>? extensions) async {
    final file = await FilePicker.pickFile(
      type: type,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    return (
      name: file.name,
      length: file.lengthSync() ?? await file.length(),
      read: file.readAsBytes,
    );
  }
}
