import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/recommendation/data/course_recommendation_api.dart';
import 'package:ahni_mobile/features/recommendation/domain/course_recommendation.dart';

import 'onboarding_fakes.dart';

Map<String, Object?> recommendationJson({
  bool lectureDataAvailable = true,
  List<Object?>? majors,
}) => {
  'academicYear': 2026,
  'term': 'SECOND',
  'semesterNumber': 6,
  'lectureDataAvailable': lectureDataAvailable,
  'majors':
      majors ??
      [
        {
          'majorType': 'PRIMARY',
          'department': {
            'entityId': '00000000-0000-0000-0000-000000000001',
            'name': '소프트웨어융합공학과',
          },
          'curriculumAvailable': true,
          'courses': [
            {
              'course': {
                'entityId': '00000000-0000-0000-0000-000000000101',
                'code': 'ITC3410',
                'name': '컴퓨터네트워크',
                'credit': 3.0,
                'category': 'MAJOR',
                'department': null,
              },
              'division': 'MAJOR_REQUIRED',
              'recommendedYear': 3,
              'recommendedTerm': 'FIRST',
              'reasons': ['GRADUATION_REQUIRED', 'OVERDUE'],
              'previousGradeCode': null,
              'lectures': [
                {
                  'entityId': '00000000-0000-0000-0000-000000000901',
                  'courseEntityId': '00000000-0000-0000-0000-000000000101',
                  'courseCode': 'ITC3410',
                  'courseName': '컴퓨터네트워크',
                  'credit': 3.0,
                  'professorName': '김교수',
                  'academicYear': 2026,
                  'term': 'SECOND',
                  'section': '001',
                  'schedules': [
                    {
                      'entityId': '00000000-0000-0000-0000-000000000902',
                      'dayOfWeek': 2,
                      'startTime': '09:00:00',
                      'endTime': '10:30:00',
                      'classroom': null,
                    },
                  ],
                },
              ],
            },
            {
              'course': {
                'entityId': '00000000-0000-0000-0000-000000000102',
                'code': 'ITC1201',
                'name': '컴퓨터공학기초',
                'credit': 3.0,
                'category': 'MAJOR',
                'department': null,
              },
              'division': 'MAJOR_ELECTIVE',
              'recommendedYear': null,
              'recommendedTerm': null,
              'reasons': ['RETAKE'],
              'previousGradeCode': 'C_PLUS',
              'lectures': [],
            },
          ],
        },
        {
          'majorType': 'DOUBLE_MAJOR',
          'department': {
            'entityId': '00000000-0000-0000-0000-000000000002',
            'name': '컴퓨터공학과',
          },
          'curriculumAvailable': false,
          'courses': [],
        },
      ],
};

CourseRecommendationController buildTestRecommendationController([
  FakeCourseRecommendationApi? api,
]) => CourseRecommendationController(
  auth: FakeAuthGateway(currentSession: testSession),
  api: api ?? FakeCourseRecommendationApi(),
);

class FakeCourseRecommendationApi implements CourseRecommendationApi {
  CourseRecommendation result = CourseRecommendation.fromJson(
    recommendationJson(),
  );
  Future<CourseRecommendation> Function()? handler;
  final requests = <(int, String)>[];

  @override
  Future<CourseRecommendation> getRecommendations(
    String accessToken,
    int academicYear,
    String term,
  ) async {
    requests.add((academicYear, term));
    return handler == null ? result : handler!();
  }
}
