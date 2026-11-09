import 'package:ahni_mobile/app/app_theme.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:ahni_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';

class AhniApp extends StatelessWidget {
  const AhniApp({
    required this.environment,
    required this.controller,
    required this.gradeController,
    required this.gradeSimulationController,
    required this.graduationController,
    required this.scholarshipController,
    required this.courseController,
    required this.gradeRegistrationController,
    required this.gradeEditController,
    required this.inquiryController,
    this.timetableController,
    this.recommendationController,
    super.key,
  });

  final AppEnvironment environment;
  final OnboardingController controller;
  final GradeListController gradeController;
  final GradeSimulationController gradeSimulationController;
  final GraduationController graduationController;
  final ScholarshipController scholarshipController;
  final CourseCatalogController courseController;
  final GradeRegistrationController gradeRegistrationController;
  final GradeEditController gradeEditController;
  final InquiryController inquiryController;
  final TimetableController? timetableController;
  final CourseRecommendationController? recommendationController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHNI',
      restorationScopeId: 'ahni-${environment.name}',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: OnboardingPage(
        controller: controller,
        gradeController: gradeController,
        gradeSimulationController: gradeSimulationController,
        graduationController: graduationController,
        scholarshipController: scholarshipController,
        courseController: courseController,
        gradeRegistrationController: gradeRegistrationController,
        gradeEditController: gradeEditController,
        inquiryController: inquiryController,
        timetableController: timetableController,
        recommendationController: recommendationController,
      ),
    );
  }
}
