import 'dart:typed_data';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/course_catalog_item.dart';
import 'package:ahni_mobile/features/grade/domain/grade_registration.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';
import 'package:ahni_mobile/features/grade/domain/grade_update.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/inquiry/data/attachment_picker.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';

import 'onboarding_fakes.dart';
export 'graduation_fakes.dart';
export 'scholarship_fakes.dart';

InquiryController buildTestInquiryController({
  AuthGateway? auth,
  List<Inquiry> inquiries = const [],
}) {
  return InquiryController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: FakeInquiryApi()..results = inquiries,
  );
}

GradeSimulationController buildTestGradeSimulationController({
  AuthGateway? auth,
  GradeApi? api,
}) => GradeSimulationController(
  auth: auth ?? FakeAuthGateway(currentSession: testSession),
  api: api ?? FakeGradeApi(),
);

GradeListController buildTestGradeListController({
  AuthGateway? auth,
  List<GradeRecord> grades = const [],
  GradeSummary summary = testGradeSummary,
}) {
  return GradeListController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: FakeGradeApi()
      ..results = grades
      ..summary = summary,
  );
}

CourseCatalogController buildTestCourseCatalogController({
  AuthGateway? auth,
  List<CourseCatalogItem> courses = const [testCourse],
}) {
  return CourseCatalogController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: FakeCourseApi()..results = courses,
  );
}

GradeRegistrationController buildTestGradeRegistrationController({
  AuthGateway? auth,
  GradeApi? api,
}) {
  return GradeRegistrationController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: api ?? FakeGradeApi(),
  );
}

GradeEditController buildTestGradeEditController({
  AuthGateway? auth,
  GradeApi? api,
}) {
  return GradeEditController(
    auth: auth ?? FakeAuthGateway(currentSession: testSession),
    api: api ?? FakeGradeApi(),
  );
}

class FakeCourseApi implements CourseApi {
  List<CourseCatalogItem> results = const [];
  Object? error;

  @override
  Future<List<CourseCatalogItem>> getCourses(
    String accessToken, {
    required int academicYear,
  }) async {
    if (error case final value?) throw value;
    return results;
  }
}

class FakeGradeApi implements GradeApi {
  Future<GradeSimulation> Function(String, List<ExpectedGrade>)?
  simulationHandler;

  @override
  Future<GradeSimulation> simulateGrades(
    String accessToken,
    List<ExpectedGrade> expectedGrades,
  ) async {
    if (error case final value?) throw value;
    if (simulationHandler case final value?) {
      return value(accessToken, expectedGrades);
    }
    return const GradeSimulation(
      current: testGradeSummary,
      projected: testGradeSummary,
    );
  }

  List<GradeRecord> results = const [];
  GradeSummary summary = testGradeSummary;
  Object? error;
  Future<List<GradeRecord>> Function(String accessToken)? handler;
  Future<GradeSummary> Function(String accessToken)? summaryHandler;
  Future<GradeRecord> Function(
    String accessToken,
    GradeRegistration registration,
  )?
  registerHandler;
  Future<GradeRecord> Function(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  )?
  updateHandler;
  Future<void> Function(String accessToken, String gradeEntityId)?
  deleteHandler;
  String? lastAccessToken;
  GradeRegistration? lastRegistration;
  GradeUpdate? lastUpdate;
  String? lastGradeEntityId;
  int calls = 0;
  int summaryCalls = 0;
  int registerCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<GradeRecord>> getGrades(String accessToken) async {
    calls++;
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    if (handler case final value?) return value(accessToken);
    return results;
  }

  @override
  Future<GradeSummary> getSummary(String accessToken) async {
    summaryCalls++;
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    if (summaryHandler case final value?) return value(accessToken);
    return summary;
  }

  @override
  Future<GradeRecord> registerGrade(
    String accessToken,
    GradeRegistration registration,
  ) async {
    registerCalls++;
    lastAccessToken = accessToken;
    lastRegistration = registration;
    if (error case final value?) throw value;
    if (registerHandler case final value?) {
      return value(accessToken, registration);
    }
    return testGrade;
  }

  @override
  Future<GradeRecord> updateGrade(
    String accessToken,
    String gradeEntityId,
    GradeUpdate update,
  ) async {
    updateCalls++;
    lastAccessToken = accessToken;
    lastGradeEntityId = gradeEntityId;
    lastUpdate = update;
    if (error case final value?) throw value;
    if (updateHandler case final value?) {
      return value(accessToken, gradeEntityId, update);
    }
    return testGrade;
  }

  @override
  Future<void> deleteGrade(String accessToken, String gradeEntityId) async {
    deleteCalls++;
    lastAccessToken = accessToken;
    lastGradeEntityId = gradeEntityId;
    if (error case final value?) throw value;
    if (deleteHandler case final value?) {
      await value(accessToken, gradeEntityId);
    }
  }
}

class FakeInquiryApi implements InquiryApi {
  List<Inquiry> results = const [];
  Object? error;
  Inquiry? createResult;
  InquiryDraft? lastDraft;
  InquiryDraft? lastUpdateDraft;
  String? lastUpdatedInquiryEntityId;
  String? lastDeletedInquiryEntityId;
  String? lastAccessToken;
  int calls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<Inquiry>> getInquiries(String accessToken) async {
    calls++;
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    return results;
  }

  @override
  Future<Inquiry> getInquiry(String accessToken, String inquiryEntityId) async {
    lastAccessToken = accessToken;
    if (error case final value?) throw value;
    return results.firstWhere((inquiry) => inquiry.entityId == inquiryEntityId);
  }

  @override
  Future<Inquiry> createInquiry(String accessToken, InquiryDraft draft) async {
    createCalls++;
    lastAccessToken = accessToken;
    lastDraft = draft;
    if (error case final value?) throw value;
    return createResult ??
        Inquiry(
          entityId: 'inquiry-id-2',
          title: draft.title.trim(),
          content: draft.content.trim(),
          status: 'SUBMITTED',
          answer: null,
          answeredAt: null,
          createdAt: DateTime.utc(2026, 10, 9),
          updatedAt: DateTime.utc(2026, 10, 9),
        );
  }

  @override
  Future<Inquiry> updateInquiry(
    String accessToken,
    String inquiryEntityId,
    InquiryDraft draft,
  ) async {
    updateCalls++;
    lastAccessToken = accessToken;
    lastUpdatedInquiryEntityId = inquiryEntityId;
    lastUpdateDraft = draft;
    if (error case final value?) throw value;
    return Inquiry(
      entityId: inquiryEntityId,
      title: draft.title.trim(),
      content: draft.content.trim(),
      status: 'IN_REVIEW',
      answer: null,
      answeredAt: null,
      createdAt: DateTime.utc(2026, 10, 9),
      updatedAt: DateTime.utc(2026, 10, 10),
    );
  }

  @override
  Future<void> deleteInquiry(String accessToken, String inquiryEntityId) async {
    deleteCalls++;
    lastAccessToken = accessToken;
    lastDeletedInquiryEntityId = inquiryEntityId;
    if (error case final value?) throw value;
  }

  List<InquiryAttachment> attachments = const [];
  Object? attachmentError;
  ({String filename, String contentType, List<int> bytes})? lastUpload;
  String? lastDeletedAttachmentEntityId;

  @override
  Future<List<InquiryAttachment>> getAttachments(
    String accessToken,
    String inquiryEntityId,
  ) async {
    if (attachmentError case final value?) throw value;
    return attachments;
  }

  @override
  Future<InquiryAttachment> uploadAttachment(
    String accessToken,
    String inquiryEntityId, {
    required String filename,
    required String contentType,
    required List<int> bytes,
  }) async {
    if (attachmentError case final value?) throw value;
    lastUpload = (filename: filename, contentType: contentType, bytes: bytes);
    return InquiryAttachment(
      entityId: 'attachment-id-${attachments.length + 1}',
      filename: filename,
      contentType: contentType,
      sizeBytes: bytes.length,
      createdAt: DateTime.utc(2026, 10, 17),
    );
  }

  @override
  Future<void> deleteAttachment(
    String accessToken,
    String inquiryEntityId,
    String attachmentEntityId,
  ) async {
    if (attachmentError case final value?) throw value;
    lastDeletedAttachmentEntityId = attachmentEntityId;
  }
}

class FakeAttachmentPicker implements AttachmentPicker {
  PickedFile? image;
  PickedFile? pdf;

  @override
  Future<PickedFile?> pickImage() async => image;

  @override
  Future<PickedFile?> pickPdf() async => pdf;
}

PickedFile pickedFile(String name, List<int> bytes, {int? length}) {
  return (
    name: name,
    length: length ?? bytes.length,
    read: () async => Uint8List.fromList(bytes),
  );
}

final testGrade = GradeRecord(
  entityId: 'grade-id-1',
  course: const GradeCourse(
    entityId: 'course-id-1',
    code: 'CSE101',
    name: '프로그래밍 기초',
    category: CourseCategory.major,
    department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
  ),
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.aPlus,
  gradePoint: 4.5,
  credit: 3,
  rpl: false,
  replacedGradeEntityId: 'grade-id-0',
  createdAt: DateTime.utc(2026, 9, 15),
  updatedAt: DateTime.utc(2026, 9, 15),
);

const testCourse = CourseCatalogItem(
  entityId: 'course-id-1',
  code: 'CSE101',
  name: '프로그래밍 기초',
  credit: 3,
  category: CourseCategory.major,
  department: GradeDepartment(entityId: 'department-id', name: '소프트웨어융합공학과'),
);

final testPassGrade = GradeRecord(
  entityId: 'grade-id-2',
  course: const GradeCourse(
    entityId: 'course-id-2',
    code: 'GE201',
    name: '의사소통 영어',
    category: CourseCategory.generalEducation,
  ),
  academicYear: 2025,
  term: AcademicTerm.second,
  gradeCode: GradeCode.p,
  gradePoint: null,
  credit: 2,
  rpl: false,
  replacedGradeEntityId: null,
  createdAt: DateTime.utc(2026, 9, 14),
  updatedAt: DateTime.utc(2026, 9, 14),
);

final testRplGrade = GradeRecord(
  entityId: 'grade-id-3',
  course: const GradeCourse(
    entityId: 'course-id-3',
    code: 'RPL001',
    name: '선행학습 인정',
    category: CourseCategory.elective,
  ),
  academicYear: 2025,
  term: AcademicTerm.first,
  gradeCode: null,
  gradePoint: null,
  credit: 1,
  rpl: true,
  replacedGradeEntityId: null,
  createdAt: DateTime.utc(2026, 3, 1),
  updatedAt: DateTime.utc(2026, 3, 1),
);

final testInquiry = Inquiry(
  entityId: 'inquiry-id-1',
  title: '성적 등록 문의',
  content: '2025년 과목이 성적 등록 화면에 보이지 않습니다.',
  status: 'SUBMITTED',
  answer: null,
  answeredAt: null,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
);

const testGradeSummary = GradeSummary(
  gpa: 3.83,
  completedCredits: 42,
  gpaCredits: 36,
  categories: [
    GradeCategorySummary(
      category: CourseCategory.major,
      gpa: 4.02,
      completedCredits: 24,
      gpaCredits: 21,
    ),
    GradeCategorySummary(
      category: CourseCategory.generalEducation,
      gpa: 3.5,
      completedCredits: 12,
      gpaCredits: 9,
    ),
    GradeCategorySummary(
      category: CourseCategory.elective,
      gpa: 3,
      completedCredits: 6,
      gpaCredits: 6,
    ),
  ],
);
