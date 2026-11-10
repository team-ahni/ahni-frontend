import 'package:ahni_mobile/features/timetable/domain/timetable.dart';
import 'package:ahni_mobile/features/timetable/domain/timetable_import.dart';
import 'package:flutter_test/flutter_test.dart';

Lecture _lecture(String code, String section) => Lecture(
  entityId: '$code-$section',
  courseCode: code,
  courseName: code,
  credit: 3,
  professorName: '교수',
  section: section,
  schedules: const [],
);

void main() {
  test(
    'reads code and section from text copied from the registration page',
    () {
      // 수강신청 확인 표를 복사하면 탭으로 칸이 나뉜다. 익명화한 예시다.
      const pasted =
          'GEE7007\t001\t디지털 경영\t3.0\t교양선택\t교수가\t경영학과\n'
          'ITC3410\t002\t컴퓨터네트워크\t3.0\t전공필수\t교수나\t소프트웨어융합공학과\n';

      expect(parseRegisteredSections(pasted), [
        (code: 'GEE7007', section: '001'),
        (code: 'ITC3410', section: '002'),
      ]);
    },
  );

  test('reads sections glued to the course name and fixes O and I digits', () {
    expect(
      parseRegisteredSections(
        'GEE7010 001게임 기획\nITC34I0 OO2컴퓨터네트워크\n학번 12345678',
      ),
      [(code: 'GEE7010', section: '001'), (code: 'ITC3410', section: '002')],
    );
  });

  test('keeps a code without a readable section and ignores duplicates', () {
    expect(parseRegisteredSections('ITC4603 데이터분석\nITC4603 001 데이터분석'), [
      (code: 'ITC4603', section: '001'),
    ]);
    expect(parseRegisteredSections('ITC4603 데이터분석'), [
      (code: 'ITC4603', section: null),
    ]);
  });

  test('joins screenshot fragments row by row before reading them', () {
    final text = joinFragmentsByRow([
      (text: '001', left: 189, top: 584, bottom: 604),
      (text: 'GEE7007', left: 82, top: 584, bottom: 604),
      (text: '002컴퓨터네트워크', left: 189, top: 709, bottom: 729),
      (text: 'ITC3410', left: 82, top: 705, bottom: 725),
    ]);

    expect(text, 'GEE7007 001\nITC3410 002컴퓨터네트워크');
    expect(parseRegisteredSections(text), [
      (code: 'GEE7007', section: '001'),
      (code: 'ITC3410', section: '002'),
    ]);
  });

  test('matches offered sections and sorts out added and unknown ones', () {
    final lectures = [
      _lecture('GEE7007', '001'),
      _lecture('ITC3410', '001'),
      _lecture('ITC3410', '002'),
      _lecture('ITC4603', '001'),
    ];

    final preview = matchRegisteredSections(
      [
        (code: 'GEE7007', section: '001'),
        (code: 'ITC3410', section: '002'),
        (code: 'ITC4603', section: null),
        (code: 'ITC3410', section: null),
        (code: 'ITC9999', section: '001'),
      ],
      lectures,
      {'GEE7007-001'},
    );

    expect(preview.alreadyAdded.map((l) => l.entityId), ['GEE7007-001']);
    expect(preview.toAdd.map((l) => l.entityId), [
      'ITC3410-002',
      'ITC4603-001',
    ]);
    // 분반이 여럿인데 분반을 못 읽은 과목과 개설되지 않은 과목은 직접 확인하게 한다.
    expect(preview.notFound, ['ITC3410', 'ITC9999-001']);
  });
}
