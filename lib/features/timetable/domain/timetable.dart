class LectureSchedule {
  const LectureSchedule({
    required this.entityId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroom,
  });

  factory LectureSchedule.fromJson(Map<String, Object?> json) {
    final day = json['dayOfWeek']! as int;
    final start = json['startTime']! as String;
    final end = json['endTime']! as String;
    if (day < 1 || day > 7 || minutes(start) >= minutes(end)) {
      throw const FormatException('Invalid schedule');
    }
    return LectureSchedule(
      entityId: json['entityId']! as String,
      dayOfWeek: day,
      startTime: start,
      endTime: end,
      classroom: json['classroom'] as String?,
    );
  }

  final String entityId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? classroom;

  static int minutes(String time) {
    final match = RegExp(r'^(\d{2}):(\d{2})(?::00)?$').firstMatch(time);
    if (match == null) throw const FormatException('Invalid time');
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) throw const FormatException('Invalid time');
    return hour * 60 + minute;
  }

  String get label => '${startTime.substring(0, 5)}–${endTime.substring(0, 5)}';
}

class Lecture {
  const Lecture({
    required this.entityId,
    required this.courseCode,
    required this.courseName,
    required this.credit,
    required this.professorName,
    required this.section,
    required this.schedules,
  });

  factory Lecture.fromJson(Map<String, Object?> json) {
    return Lecture(
      entityId: json['entityId']! as String,
      courseCode: json['courseCode']! as String,
      courseName: json['courseName']! as String,
      credit: (json['credit']! as num).toDouble(),
      professorName: json['professorName']! as String,
      section: json['section']! as String,
      schedules: List.unmodifiable(
        (json['schedules']! as List<Object?>).map(
          (item) => LectureSchedule.fromJson(item! as Map<String, Object?>),
        ),
      ),
    );
  }

  final String entityId;
  final String courseCode;
  final String courseName;
  final double credit;
  final String professorName;
  final String section;
  final List<LectureSchedule> schedules;
}

class TimetableEntry {
  const TimetableEntry({required this.entityId, required this.lecture});

  factory TimetableEntry.fromJson(Map<String, Object?> json) => TimetableEntry(
    entityId: json['entityId']! as String,
    lecture: Lecture.fromJson(json['lecture']! as Map<String, Object?>),
  );

  final String entityId;
  final Lecture lecture;
}

const timetableTerms = {
  'FIRST': '1학기',
  'SUMMER': '여름학기',
  'SECOND': '2학기',
  'WINTER': '겨울학기',
};
const timetableDays = ['월', '화', '수', '목', '금', '토', '일'];
