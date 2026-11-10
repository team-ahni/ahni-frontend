import 'package:ahni_mobile/features/timetable/domain/timetable.dart';

/// 수강신청 내역에서 찾은 학수번호와 분반. 분반을 읽지 못하면 null이다.
typedef RegisteredSection = ({String code, String? section});

/// 글자 인식이 돌려준 조각 하나와 그 위치.
typedef TextFragment = ({String text, double left, double top, double bottom});

// 학수번호(영문 2~4자 + 숫자 4자리) 뒤에 세 자리 분반이 오면 함께 잡는다.
// 글자 인식이 분반과 과목명을 붙여 읽어도(`001게임`) 분반 뒤가 숫자만 아니면 된다.
// 숫자 자리의 O·I·l은 인식이 0·1을 잘못 읽은 것으로 본다.
final _sectionPattern = RegExp(
  r'(?<![A-Za-z0-9])([A-Z]{2,4})([0-9OIl]{4})(?![0-9])(?:\s*-?\s*([0-9OIl]{3})(?![0-9]))?',
);

String _digits(String value) =>
    value.replaceAll('O', '0').replaceAll('I', '1').replaceAll('l', '1');

/// 수강신청 내역 글에서 학수번호와 분반을 찾는다. 같은 학수번호는 한 번만 담는다.
List<RegisteredSection> parseRegisteredSections(String text) {
  final found = <String, String?>{};
  for (final match in _sectionPattern.allMatches(text)) {
    final code = '${match[1]}${_digits(match[2]!)}';
    final section = match[3] == null ? null : _digits(match[3]!);
    found[code] = found[code] ?? section;
  }
  return [
    for (final MapEntry(:key, :value) in found.entries)
      (code: key, section: value),
  ];
}

/// 글자 조각을 화면의 행 순서대로 이어 붙인다. 표의 한 행에 있는 칸은 한 줄이 된다.
String joinFragmentsByRow(List<TextFragment> fragments) {
  if (fragments.isEmpty) return '';
  double middle(TextFragment f) => (f.top + f.bottom) / 2;
  final sorted = [...fragments]..sort((a, b) => middle(a).compareTo(middle(b)));
  final rows = <List<TextFragment>>[];
  for (final fragment in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    // 같은 행이면 세로 가운데가 글자 높이의 절반 안에 든다.
    final height = fragment.bottom - fragment.top;
    if (row != null &&
        (middle(row.first) - middle(fragment)).abs() < height / 2) {
      row.add(fragment);
    } else {
      rows.add([fragment]);
    }
  }
  return rows
      .map(
        (row) => (row..sort((a, b) => a.left.compareTo(b.left)))
            .map((fragment) => fragment.text)
            .join(' '),
      )
      .join('\n');
}

class TimetableImportPreview {
  const TimetableImportPreview({
    required this.toAdd,
    required this.alreadyAdded,
    required this.notFound,
    this.conflicts = const {},
  });

  /// 시간표에 새로 넣을 분반.
  final List<Lecture> toAdd;

  /// 이미 시간표에 있는 분반.
  final List<Lecture> alreadyAdded;

  /// 이 학기 개설 강의에서 찾지 못했거나 분반을 정할 수 없는 항목. `ITC3410-002`처럼 보인다.
  final List<String> notFound;

  /// 새로 넣을 분반(entityId)마다 시간이 겹치는 기존 시간표 항목.
  /// 서버는 겹치는 강의를 받지 않으므로 바꿀지 뺄지 먼저 정해야 한다.
  final Map<String, List<TimetableEntry>> conflicts;

  bool get isEmpty => toAdd.isEmpty && alreadyAdded.isEmpty && notFound.isEmpty;
}

/// 찾은 학수번호·분반을 이 학기 개설 강의와 맞춘다.
/// 분반을 읽지 못했으면 그 과목의 분반이 하나일 때만 고른다.
TimetableImportPreview matchRegisteredSections(
  List<RegisteredSection> sections,
  List<Lecture> lectures,
  List<TimetableEntry> entries,
) {
  final addedLectureIds = {for (final e in entries) e.lecture.entityId};
  final toAdd = <Lecture>[];
  final alreadyAdded = <Lecture>[];
  final notFound = <String>[];
  for (final (:code, :section) in sections) {
    final offered = lectures.where((lecture) => lecture.courseCode == code);
    final matches = section == null
        ? offered.toList()
        : offered.where((lecture) => lecture.section == section).toList();
    if (matches.length != 1) {
      notFound.add(section == null ? code : '$code-$section');
      continue;
    }
    final lecture = matches.single;
    (addedLectureIds.contains(lecture.entityId) ? alreadyAdded : toAdd).add(
      lecture,
    );
  }
  return TimetableImportPreview(
    toAdd: List.unmodifiable(toAdd),
    alreadyAdded: List.unmodifiable(alreadyAdded),
    notFound: List.unmodifiable(notFound),
    conflicts: {
      for (final lecture in toAdd)
        if (entries.where((e) => lecturesOverlap(e.lecture, lecture)).toList()
            case final overlapping when overlapping.isNotEmpty)
          lecture.entityId: List.unmodifiable(overlapping),
    },
  );
}

/// 같은 요일에 수업 시간이 조금이라도 겹치면 true. 서버의 겹침 판단과 같다.
bool lecturesOverlap(Lecture a, Lecture b) => a.schedules.any(
  (x) => b.schedules.any(
    (y) =>
        x.dayOfWeek == y.dayOfWeek &&
        LectureSchedule.minutes(x.startTime) <
            LectureSchedule.minutes(y.endTime) &&
        LectureSchedule.minutes(y.startTime) <
            LectureSchedule.minutes(x.endTime),
  ),
);

/// 시트에서 정한 결과. 넣을 분반과, 그 분반 대신 뺄 기존 시간표 항목.
class TimetableImportPlan {
  const TimetableImportPlan({required this.add, this.replacing = const {}});

  final List<Lecture> add;

  /// 새 분반(entityId)마다 바꿔서 뺄 기존 항목. 비어 있으면 그냥 넣는다.
  final Map<String, List<TimetableEntry>> replacing;
}
