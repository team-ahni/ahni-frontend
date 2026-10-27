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
import 'package:flutter/services.dart';
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
    const accent = Color(0xFF1558A6);
    const accentSoft = Color(0xFFEAF2FC);
    const canvas = Color(0xFFF7F8FA);
    const primaryText = Color(0xFF18202A);
    const secondaryText = Color(0xFF5B6470);
    const divider = Color(0xFFDDE2E8);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: Colors.white,
        ).copyWith(
          primary: accent,
          onPrimary: Colors.white,
          primaryContainer: accentSoft,
          onPrimaryContainer: primaryText,
          onSurface: primaryText,
          onSurfaceVariant: secondaryText,
          outline: divider,
          surfaceContainerLowest: Colors.white,
          surfaceContainer: canvas,
          surfaceContainerHighest: const Color(0xFFEEF1F4),
        );

    return MaterialApp(
      title: 'AHNI',
      restorationScopeId: 'ahni-${environment.name}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: canvas,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: primaryText,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: -0.3,
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            letterSpacing: -0.3,
          ),
          bodyLarge: TextStyle(color: secondaryText, fontSize: 16, height: 1.5),
          bodySmall: TextStyle(
            color: secondaryText,
            fontSize: 14,
            height: 20 / 14,
          ),
          titleMedium: TextStyle(
            color: primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: canvas,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ),
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
