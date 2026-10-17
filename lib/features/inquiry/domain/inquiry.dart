class Inquiry {
  const Inquiry({
    required this.entityId,
    required this.title,
    required this.content,
    required this.status,
    required this.answer,
    required this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, Object?> json) {
    return Inquiry(
      entityId: json['entityId']! as String,
      title: json['title']! as String,
      content: json['content']! as String,
      status: json['status']! as String,
      answer: json['answer'] as String?,
      answeredAt: _optionalDateTime(json['answeredAt']),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }

  final String entityId;
  final String title;
  final String content;
  final String status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get statusLabel {
    return switch (status) {
      'SUBMITTED' => '접수됨',
      'IN_REVIEW' => '확인 중',
      'ANSWERED' => '답변 완료',
      'CLOSED' => '종료',
      _ => '확인 필요',
    };
  }

  bool get canEdit => status == 'SUBMITTED' || status == 'IN_REVIEW';

  static DateTime? _optionalDateTime(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}

class InquiryDraft {
  const InquiryDraft({required this.title, required this.content});

  final String title;
  final String content;

  Map<String, Object> toJson() {
    return {'title': title.trim(), 'content': content.trim()};
  }
}

class InquiryAttachment {
  const InquiryAttachment({
    required this.entityId,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory InquiryAttachment.fromJson(Map<String, Object?> json) {
    return InquiryAttachment(
      entityId: json['entityId']! as String,
      filename: json['filename']! as String,
      contentType: json['contentType']! as String,
      sizeBytes: json['sizeBytes']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  static const maxCount = 3;
  static const maxSizeBytes = 5 * 1024 * 1024;

  final String entityId;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;

  String get typeLabel {
    return switch (contentType) {
      'image/jpeg' => 'JPG',
      'image/png' => 'PNG',
      'application/pdf' => 'PDF',
      _ => '파일',
    };
  }

  String get sizeLabel {
    return sizeBytes < 1024 * 1024
        ? '${(sizeBytes / 1024).round().clamp(1, 1024)}KB'
        : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Returns the backend-accepted content type for [filename], or null.
  static String? contentTypeFor(String filename) {
    final dot = filename.lastIndexOf('.');
    final extension = dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => null,
    };
  }
}
