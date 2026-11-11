import 'package:ahni_mobile/core/presentation/friendly_states.dart';
import 'package:ahni_mobile/core/presentation/labeled_field.dart';
import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/info_group.dart';
import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/presentation/grade_list_page.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/inquiry/presentation/inquiry_page.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/recommendation/application/course_recommendation_controller.dart';
import 'package:ahni_mobile/features/timetable/presentation/timetable_page.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/presentation/graduation_page.dart';
import 'package:ahni_mobile/features/scholarship/application/scholarship_controller.dart';

part 'onboarding_auth_views.dart';
part 'onboarding_portal_views.dart';
part 'onboarding_registration_view.dart';
part 'onboarding_shared_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
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
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  String? _portalStudentId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final state = widget.controller.state;
    final studentId = switch (state) {
      ProfileReady state => state.profile.studentEntityId,
      MajorEditing state => state.profile.studentEntityId,
      _ => null,
    };
    if (_portalStudentId != studentId) {
      _portalStudentId = studentId;
      widget.gradeController.reset();
      widget.gradeSimulationController.reset();
      widget.graduationController.reset();
      widget.scholarshipController.reset();
      widget.courseController.reset();
      widget.gradeRegistrationController.reset();
      widget.gradeEditController.reset();
      widget.inquiryController.reset();
      widget.timetableController?.reset();
      widget.recommendationController?.reset();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.controller.state) {
      AuthenticationRequired state => _AuthenticationView(
        controller: widget.controller,
        state: state,
      ),
      EmailVerificationPending state => _EmailVerificationPendingView(
        state: state,
        onResend: widget.controller.resendConfirmation,
        onReturnToLogin: widget.controller.returnToAuthentication,
      ),
      PasswordRecoveryRequired state => _PasswordRecoveryView(
        controller: widget.controller,
        state: state,
      ),
      ProfileLoading() => const _LoadingView(),
      RegistrationRequired state => _RegistrationView(
        controller: widget.controller,
        state: state,
      ),
      ProfileReady state => _StudentPortalView(
        onboardingController: widget.controller,
        gradeController: widget.gradeController,
        gradeSimulationController: widget.gradeSimulationController,
        graduationController: widget.graduationController,
        scholarshipController: widget.scholarshipController,
        courseController: widget.courseController,
        gradeRegistrationController: widget.gradeRegistrationController,
        gradeEditController: widget.gradeEditController,
        inquiryController: widget.inquiryController,
        timetableController: widget.timetableController,
        recommendationController: widget.recommendationController,
        profileState: state,
      ),
      MajorEditing state => _MajorEditingView(
        controller: widget.controller,
        state: state,
      ),
      RetryableFailure state => _RetryView(
        message: state.message,
        onRetry: widget.controller.retry,
      ),
    };
  }
}
