import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/grade_ocr_import_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/ocr_grade_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/grade_fakes.dart';
import '../../../../support/onboarding_fakes.dart';

const first = CourseCatalogItem(
  entityId: 'ocr-1',
  code: 'ABC1001',
  name: '예시 과목 1',
  credit: 3,
  category: CourseCategory.major,
);
const second = CourseCatalogItem(
  entityId: 'ocr-2',
  code: 'DEF1002',
  name: '예시 과목 2',
  credit: 2,
  category: CourseCategory.major,
);
OcrGradeCandidate candidate(
  String code, {
  GradeCode? grade = GradeCode.aPlus,
}) => OcrGradeCandidate(
  page: 1,
  source: '예시 인식문',
  courseCode: code,
  academicYear: 2024,
  term: AcademicTerm.first,
  credit: 3,
  gradeCode: grade,
);
GradeRecord record(CourseCatalogItem course) => GradeRecord(
  entityId: 'grade-${course.entityId}',
  course: GradeCourse(
    entityId: course.entityId,
    code: course.code,
    name: course.name,
    category: course.category,
  ),
  academicYear: 2024,
  term: AcademicTerm.first,
  gradeCode: GradeCode.aPlus,
  gradePoint: 4.5,
  credit: 3,
  rpl: false,
  replacedGradeEntityId: null,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  test('catalog matches do not bypass server lecture validation', () async {
    final api = FakeGradeApi()
      ..registerHandler = (_, _) async {
        throw const GradeApiFailure(
          GradeApiFailureKind.validation,
          '선택한 연도와 학기에 개설되지 않은 과목입니다.',
        );
      };
    final controller = GradeOcrImportController(
      auth: FakeAuthGateway(currentSession: testSession),
      courses: _Courses(),
      grades: api,
    );
    await controller.prepare([candidate('ABC1001')]);
    controller.selectReady();
    await controller.submitSelected();
    expect(api.registerCalls, 1);
    expect(controller.savedCount, 0);
    expect(controller.hasChanges, isFalse);
    expect(controller.entries.single.status, OcrImportStatus.pending);
    expect(controller.entries.single.message, '선택한 연도와 학기에 개설되지 않은 과목입니다.');
  });

  test(
    'one catalog lookup resolves the same course across historical semesters',
    () async {
      final api = FakeGradeApi();
      final courses = _Courses();
      final controller = GradeOcrImportController(
        auth: FakeAuthGateway(currentSession: testSession),
        courses: courses,
        grades: api,
      );
      await controller.prepare([
        candidate('ABC1001'),
        const OcrGradeCandidate(
          page: 1,
          source: '예시',
          courseCode: 'ABC1001',
          academicYear: 2023,
          term: AcademicTerm.second,
          credit: 3,
          gradeCode: GradeCode.bZero,
        ),
      ]);
      expect(courses.calls, 1);
      expect(controller.entries.every((entry) => entry.canRegister), isTrue);
      controller.selectReady();
      await controller.submitSelected();
      expect(api.registerCalls, 2);
      expect(api.lastRegistration!.academicYear, 2023);
      expect(api.lastRegistration!.term, AcademicTerm.second);
    },
  );

  test('only explicitly selected complete rows are submitted', () async {
    final api = FakeGradeApi();
    final courses = _Courses();
    final controller = GradeOcrImportController(
      auth: FakeAuthGateway(currentSession: testSession),
      courses: courses,
      grades: api,
    );
    await controller.prepare([
      candidate('ABC1001'),
      candidate('DEF1002', grade: null),
    ]);
    expect(courses.calls, 1);
    await controller.submitSelected();
    expect(api.registerCalls, 0);
    controller.selectReady();
    expect(controller.selectedCount, 1);
    await controller.submitSelected();
    expect(api.lastRegistration!.courseEntityId, first.entityId);
    expect(api.lastRegistration!.academicYear, 2024);
    expect(api.lastRegistration!.gradeCode, GradeCode.aPlus);
    expect(controller.savedCount, 1);
    expect(controller.entries.last.status, OcrImportStatus.pending);
    expect(controller.hasChanges, isTrue);
  });
  test(
    'a selected OCR typo must be matched by the user before registration',
    () async {
      final api = FakeGradeApi();
      final controller = GradeOcrImportController(
        auth: FakeAuthGateway(currentSession: testSession),
        courses: _Courses(),
        grades: api,
      );
      await controller.prepare([candidate('ABC1002')]);
      expect(controller.entries.single.course, isNull);
      expect(controller.entries.single.suggestions, [first]);
      controller.selectReady();
      await controller.submitSelected();
      expect(api.registerCalls, 0);
      controller.edit(0, course: first, credit: 2.5, grade: GradeCode.bZero);
      controller.select(0, true);
      await controller.submitSelected();
      expect(api.lastRegistration!.credit, 2.5);
      expect(api.lastRegistration!.gradeCode, GradeCode.bZero);
    },
  );
  test(
    'existing records and duplicate PDF rows are not posted twice',
    () async {
      final api = FakeGradeApi()..results = [record(first)];
      final controller = GradeOcrImportController(
        auth: FakeAuthGateway(currentSession: testSession),
        courses: _Courses(),
        grades: api,
      );
      await controller.prepare([
        candidate('ABC1001'),
        candidate('DEF1002'),
        candidate('DEF1002'),
      ]);
      expect(controller.entries.first.status, OcrImportStatus.existing);
      controller.selectReady();
      expect(controller.selectedCount, 1);
      await controller.submitSelected();
      expect(api.registerCalls, 1);
      expect(api.lastRegistration!.courseEntityId, second.entityId);
    },
  );
  test(
    'successful rows are retained when another row fails and is retried',
    () async {
      final api = FakeGradeApi();
      final sent = <String>[];
      var failSecond = true;
      api.registerHandler = (_, registration) async {
        sent.add(registration.courseEntityId);
        if (registration.courseEntityId == second.entityId && failSecond) {
          throw const GradeApiFailure(
            GradeApiFailureKind.validation,
            '성적을 확인해 주세요.',
          );
        }
        return record(
          registration.courseEntityId == first.entityId ? first : second,
        );
      };
      final controller = GradeOcrImportController(
        auth: FakeAuthGateway(currentSession: testSession),
        courses: _Courses(),
        grades: api,
      );
      await controller.prepare([candidate('ABC1001'), candidate('DEF1002')]);
      controller.selectReady();
      await controller.submitSelected();
      expect(controller.savedCount, 1);
      expect(controller.entries.last.message, isNotNull);
      failSecond = false;
      await controller.submitSelected();
      expect(sent, [first.entityId, second.entityId, second.entityId]);
      expect(controller.savedCount, 2);
    },
  );
  test('reconciles a saved row after losing the POST response', () async {
    final api = FakeGradeApi();
    api.registerHandler = (_, registration) async {
      api.results = [record(first)];
      throw const GradeApiFailure(
        GradeApiFailureKind.recoverable,
        '응답을 받지 못했어요.',
      );
    };
    final controller = GradeOcrImportController(
      auth: FakeAuthGateway(currentSession: testSession),
      courses: _Courses(),
      grades: api,
    );
    await controller.prepare([candidate('ABC1001')]);
    controller.selectReady();
    await controller.submitSelected();
    expect(api.registerCalls, 1);
    expect(controller.hasChanges, isTrue);
    await controller.submitSelected();
    expect(api.registerCalls, 1);
    expect(controller.entries.single.status, OcrImportStatus.existing);
  });
  test('cannot register rows when the course catalog is empty', () async {
    final api = FakeGradeApi();
    final courses = _Courses()..results = [];
    final controller = GradeOcrImportController(
      auth: FakeAuthGateway(currentSession: testSession),
      courses: courses,
      grades: api,
    );
    await controller.prepare([candidate('ABC1001')]);
    controller.selectReady();
    await controller.submitSelected();
    expect(api.registerCalls, 0);
    expect(controller.entries.single.message, contains('과목 자료'));
  });
  test(
    'drops account-scoped state if the user changes during lookup',
    () async {
      final auth = FakeAuthGateway(currentSession: testSession);
      final pending = Completer<List<CourseCatalogItem>>();
      final courses = _Courses()..handler = () => pending.future;
      final api = FakeGradeApi();
      final controller = GradeOcrImportController(
        auth: auth,
        courses: courses,
        grades: api,
      );
      final loading = controller.prepare([candidate('ABC1001')]);
      await Future<void>.delayed(Duration.zero);
      auth.currentSession = const AuthSession(
        accessToken: 'another-token',
        email: 'other@example.test',
      );
      pending.complete([first]);
      await loading;
      expect(controller.entries, isEmpty);
      expect(controller.busy, isFalse);
      controller.select(0, true);
      await controller.submitSelected();
      expect(api.registerCalls, 0);
    },
  );
  test(
    'ignores repeated registration taps while a request is in flight',
    () async {
      final pending = Completer<GradeRecord>();
      final api = FakeGradeApi()..registerHandler = (_, _) => pending.future;
      final controller = GradeOcrImportController(
        auth: FakeAuthGateway(currentSession: testSession),
        courses: _Courses(),
        grades: api,
      );
      await controller.prepare([candidate('ABC1001')]);
      controller.selectReady();
      final saving = controller.submitSelected();
      await Future<void>.delayed(Duration.zero);
      await controller.submitSelected();
      expect(api.registerCalls, 1);
      pending.complete(record(first));
      await saving;
      expect(controller.savedCount, 1);
    },
  );
}

class _Courses implements CourseCatalogApi {
  int calls = 0;
  List<CourseCatalogItem> results = [first, second];
  Future<List<CourseCatalogItem>> Function()? handler;
  @override
  Future<List<CourseCatalogItem>> getCatalog(String accessToken) async {
    calls++;
    return handler == null ? results : await handler!();
  }
}
