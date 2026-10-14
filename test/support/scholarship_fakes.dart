import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';
import 'package:ahni_mobile/features/scholarship/data/scholarship_api.dart';
import 'package:ahni_mobile/features/scholarship/domain/scholarship_eligibility.dart';

import 'onboarding_fakes.dart';

ScholarshipController buildTestScholarshipController([
  FakeScholarshipApi? api,
]) => ScholarshipController(
  auth: FakeAuthGateway(currentSession: testSession),
  api: api ?? FakeScholarshipApi(),
);

class FakeScholarshipApi implements ScholarshipApi {
  ScholarshipEligibility result = const ScholarshipEligibility(
    admissionYear: 2024,
    departmentName: '소프트웨어융합공학과',
    gpa: 0,
    completedCredits: 0,
    warningCount: 0,
    results: [],
  );
  Future<ScholarshipEligibility> Function(String)? handler;
  @override
  Future<ScholarshipEligibility> getEligibility(String token) async =>
      handler == null ? result : handler!(token);
}
