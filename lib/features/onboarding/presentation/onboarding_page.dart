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
import 'package:ahni_mobile/features/timetable/presentation/timetable_page.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/presentation/graduation_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.controller,
    required this.gradeController,
    required this.gradeSimulationController,
    required this.graduationController,
    required this.courseController,
    required this.gradeRegistrationController,
    required this.gradeEditController,
    required this.inquiryController,
    this.timetableController,
    super.key,
  });

  final OnboardingController controller;
  final GradeListController gradeController;
  final GradeSimulationController gradeSimulationController;
  final GraduationController graduationController;
  final CourseCatalogController courseController;
  final GradeRegistrationController gradeRegistrationController;
  final GradeEditController gradeEditController;
  final InquiryController inquiryController;
  final TimetableController? timetableController;

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
      widget.courseController.reset();
      widget.gradeRegistrationController.reset();
      widget.gradeEditController.reset();
      widget.inquiryController.reset();
      widget.timetableController?.reset();
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
        courseController: widget.courseController,
        gradeRegistrationController: widget.gradeRegistrationController,
        gradeEditController: widget.gradeEditController,
        inquiryController: widget.inquiryController,
        timetableController: widget.timetableController,
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

class _EmailVerificationPendingView extends StatelessWidget {
  const _EmailVerificationPendingView({
    required this.state,
    required this.onResend,
    required this.onReturnToLogin,
  });

  final EmailVerificationPending state;
  final Future<void> Function() onResend;
  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhitespaceWrappedText(
            '이메일을 확인해 주세요',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          WhitespaceWrappedText(
            '인증 링크를 다음 이메일로 보냈어요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                WhitespaceWrappedText(
                  '메일의 링크를 확인한 뒤 로그인해 주세요.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                WhitespaceWrappedText(
                  '인증 메일이 오지 않으면 입력한 주소와 스팸함을 확인해 주세요. '
                  '이미 가입한 계정이 있다면 로그인해 주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.message case final message?) ...[
                  const SizedBox(height: 16),
                  _StatusMessage(message: message, isError: state.isError),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onReturnToLogin,
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('resend-confirmation'),
                    onPressed: state.isSubmitting ? null : onResend,
                    child: WhitespaceWrappedText(
                      state.isSubmitting ? '다시 보내는 중…' : '인증 메일 다시 보내기',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRecoveryView extends StatefulWidget {
  const _PasswordRecoveryView({required this.controller, required this.state});

  final OnboardingController controller;
  final PasswordRecoveryRequired state;

  @override
  State<_PasswordRecoveryView> createState() => _PasswordRecoveryViewState();
}

class _PasswordRecoveryViewState extends State<_PasswordRecoveryView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return '비밀번호를 6자 이상 입력해 주세요.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.updatePassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    return _PageScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '새 비밀번호를 설정해 주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              '앞으로 로그인할 때 사용할 비밀번호를 입력해 주세요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(
                      message: message,
                      isError: widget.state.isError,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('new-password'),
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: '새 비밀번호',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: isSubmitting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('update-password'),
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: '비밀번호 변경',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : widget.controller.cancelPasswordRecovery,
                      child: const Text('로그인으로 돌아가기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticationView extends StatefulWidget {
  const _AuthenticationView({required this.controller, required this.state});

  final OnboardingController controller;
  final AuthenticationRequired state;

  @override
  State<_AuthenticationView> createState() => _AuthenticationViewState();
}

class _AuthenticationViewState extends State<_AuthenticationView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  var _isSignUp = false;
  var _obscurePassword = true;
  String? _passwordResetEmailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[^@\s]+@inha\.edu$').hasMatch(email)) {
      return '인하대학교 이메일(@inha.edu)을 입력해 주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return '비밀번호를 6자 이상 입력해 주세요.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp) {
      await widget.controller.signUp(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await widget.controller.signIn(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  Future<void> _requestPasswordReset() async {
    final error = _validateEmail(_emailController.text);
    if (error != null) {
      setState(() => _passwordResetEmailError = error);
      return;
    }
    await widget.controller.requestPasswordReset(_emailController.text);
  }

  void _selectMode(bool isSignUp) {
    if (_isSignUp == isSignUp) return;
    setState(() {
      _isSignUp = isSignUp;
      _emailController.clear();
      _passwordController.clear();
      _passwordResetEmailError = null;
      _formKey = GlobalKey<FormState>();
    });
    widget.controller.clearAuthenticationFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    final description = _isSignUp
        ? '학교 이메일로 가입한 뒤 학생 정보를 등록할 수 있어요.'
        : '학교 이메일로 로그인하면 내 학사 정보를 편하게 확인할 수 있어요.';
    return _PageScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '학사 준비, 함께 이어가요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('auth-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthModeSwitch(
                    isSignUp: _isSignUp,
                    isEnabled: !isSubmitting,
                    onChanged: _selectMode,
                  ),
                  const SizedBox(height: 24),
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(
                      message: message,
                      isError: widget.state.isError,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('auth-email'),
                    controller: _emailController,
                    enabled: !isSubmitting,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    forceErrorText: _passwordResetEmailError,
                    onChanged: (_) {
                      if (_passwordResetEmailError != null) {
                        setState(() => _passwordResetEmailError = null);
                      }
                    },
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: '학교 이메일',
                      hintText: 'student@inha.edu',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('auth-password'),
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    obscureText: _obscurePassword,
                    autofillHints: _isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: isSubmitting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('password-reset'),
                        onPressed: isSubmitting ? null : _requestPasswordReset,
                        child: const Text('비밀번호를 잊으셨나요?'),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: _isSignUp ? '계정 만들기' : '로그인',
                      ),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    WhitespaceWrappedText(
                      '가입하면 학교 이메일로 인증 링크를 보내드려요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView({required this.controller, required this.state});

  final OnboardingController controller;
  final RegistrationRequired state;

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _admissionYearController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _departmentId;
  String? _doubleMajorDepartmentId;
  String? _minorDepartmentId;
  String _enrollmentStatus = 'ENROLLED';

  @override
  void dispose() {
    _admissionYearController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String? _validateAdmissionYear(String? value) {
    final year = int.tryParse(value ?? '');
    if (year == null || year < 2000 || year > DateTime.now().year) {
      return '2000년부터 현재 연도 사이로 입력해 주세요.';
    }
    return null;
  }

  String? _validateDepartment(String? value, {required bool isRequired}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return '주전공 학과를 선택해 주세요.';
    }
    if (value == null || value.isEmpty) return null;
    final selected = [
      _departmentId,
      _doubleMajorDepartmentId,
      _minorDepartmentId,
    ];
    if (selected.where((departmentId) => departmentId == value).length > 1) {
      return '같은 학과를 여러 전공으로 선택할 수 없어요.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.registerProfile(
      StudentRegistration(
        primaryDepartmentEntityId: _departmentId!,
        doubleMajorDepartmentEntityId: _doubleMajorDepartmentId,
        minorDepartmentEntityId: _minorDepartmentId,
        admissionYear: int.parse(_admissionYearController.text),
        enrollmentStatus: _enrollmentStatus,
        nickname: _nicknameController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    return _PageScaffold(
      title: '학생 정보',
      action: IconButton(
        onPressed: isSubmitting ? null : widget.controller.signOut,
        tooltip: '로그아웃',
        icon: const Icon(Icons.logout_rounded, size: 20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '학생 정보를 알려주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              '전공, 입학연도와 학적 상태는 맞춤 학사 안내에 사용해요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('registration-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(message: message, isError: true),
                    const SizedBox(height: 16),
                  ],
                  Text('기본 정보', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _DepartmentField(
                    fieldKey: const Key('department-field'),
                    label: '주전공 학과',
                    departments: widget.state.departments,
                    value: _departmentId,
                    isEnabled: !isSubmitting,
                    isRequired: true,
                    onChanged: (value) => setState(() => _departmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: true),
                  ),
                  const SizedBox(height: 16),
                  _DepartmentField(
                    fieldKey: const Key('double-major-department-field'),
                    label: '복수전공 학과 (선택)',
                    departments: widget.state.departments,
                    value: _doubleMajorDepartmentId,
                    isEnabled: !isSubmitting,
                    onChanged: (value) =>
                        setState(() => _doubleMajorDepartmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: false),
                  ),
                  const SizedBox(height: 16),
                  _DepartmentField(
                    fieldKey: const Key('minor-department-field'),
                    label: '부전공 학과 (선택)',
                    departments: widget.state.departments,
                    value: _minorDepartmentId,
                    isEnabled: !isSubmitting,
                    onChanged: (value) =>
                        setState(() => _minorDepartmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: false),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('admission-year'),
                    controller: _admissionYearController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateAdmissionYear,
                    decoration: const InputDecoration(
                      labelText: '입학연도',
                      hintText: '2024',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('nickname'),
                    controller: _nicknameController,
                    enabled: !isSubmitting,
                    maxLength: 100,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                    decoration: const InputDecoration(labelText: '닉네임 (선택)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재 학적 상태',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ValueSegmentedControl(
                    key: const Key('enrollment-status-segments'),
                    value: _enrollmentStatus,
                    isEnabled: !isSubmitting,
                    options: const {'ENROLLED': '재학', 'LEAVE': '휴학'},
                    onChanged: (value) =>
                        setState(() => _enrollmentStatus = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: '학생 정보 등록',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentPortalView extends StatefulWidget {
  const _StudentPortalView({
    required this.onboardingController,
    required this.gradeController,
    required this.gradeSimulationController,
    required this.graduationController,
    required this.courseController,
    required this.gradeRegistrationController,
    required this.gradeEditController,
    required this.inquiryController,
    required this.timetableController,
    required this.profileState,
  });

  final OnboardingController onboardingController;
  final GradeListController gradeController;
  final GradeSimulationController gradeSimulationController;
  final GraduationController graduationController;
  final CourseCatalogController courseController;
  final GradeRegistrationController gradeRegistrationController;
  final GradeEditController gradeEditController;
  final InquiryController inquiryController;
  final TimetableController? timetableController;
  final ProfileReady profileState;

  @override
  State<_StudentPortalView> createState() => _StudentPortalViewState();
}

class _StudentPortalViewState extends State<_StudentPortalView> {
  var _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final navigationBar = NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.grading_outlined),
          selectedIcon: Icon(Icons.grading_rounded),
          label: '성적',
        ),
        const NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: '졸업',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: '내 정보',
        ),
        if (widget.timetableController != null)
          const NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: '시간표',
          ),
      ],
    );

    if (_selectedIndex == 0) {
      return GradeListPage(
        controller: widget.gradeController,
        simulationController: widget.gradeSimulationController,
        courseController: widget.courseController,
        registrationController: widget.gradeRegistrationController,
        editController: widget.gradeEditController,
        onAuthenticationRequired: widget.onboardingController.signOut,
        bottomNavigationBar: navigationBar,
      );
    }
    if (_selectedIndex == 1) {
      return GraduationPage(
        controller: widget.graduationController,
        onAuthenticationRequired: widget.onboardingController.signOut,
        bottomNavigationBar: navigationBar,
      );
    }
    final timetableController = widget.timetableController;
    if (_selectedIndex == 3 && timetableController != null) {
      return TimetablePage(
        controller: timetableController,
        onAuthenticationRequired: widget.onboardingController.signOut,
        bottomNavigationBar: navigationBar,
      );
    }
    return _ProfileView(
      controller: widget.onboardingController,
      inquiryController: widget.inquiryController,
      state: widget.profileState,
      bottomNavigationBar: navigationBar,
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.controller,
    required this.inquiryController,
    required this.state,
    required this.bottomNavigationBar,
  });

  final OnboardingController controller;
  final InquiryController inquiryController;
  final ProfileReady state;
  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final displayName = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : profile.email.split('@').first;
    final enrollmentLabel = switch (profile.enrollmentStatus) {
      'ENROLLED' => '재학',
      'LEAVE' => '휴학',
      'GRADUATED' => '졸업',
      'WITHDRAWN' => '제적',
      _ => '확인 필요',
    };
    return _PageScaffold(
      maxWidth: 560,
      title: '내 정보',
      bottomNavigationBar: bottomNavigationBar,
      action: IconButton(
        onPressed: controller.signOut,
        tooltip: '로그아웃',
        icon: const Icon(Icons.logout_rounded, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('profile-summary'),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.primaryDepartment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(label: enrollmentLabel),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (state.message case final message?) ...[
            _StatusMessage(message: message, isError: true),
            const SizedBox(height: 16),
          ],
          _SectionCard(
            key: const Key('major-information-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '전공 정보',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: state.isLoadingMajors
                          ? null
                          : controller.startMajorEditing,
                      child: _ButtonLabel(
                        isLoading: state.isLoadingMajors,
                        label: '전공 수정',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileField(
                  label: '주전공',
                  value: profile.primaryDepartment.name,
                ),
                const Divider(height: 32),
                _ProfileField(
                  label: '복수전공',
                  value: profile.doubleMajorDepartment?.name ?? '선택 안 함',
                ),
                const Divider(height: 32),
                _ProfileField(
                  label: '부전공',
                  value: profile.minorDepartment?.name ?? '선택 안 함',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            key: const Key('student-information-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('학생 정보', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                _ProfileField(label: '학교 이메일', value: profile.email),
                const Divider(height: 32),
                _ProfileField(
                  label: '입학연도',
                  value: '${profile.admissionYear}년',
                ),
                const Divider(height: 32),
                _ProfileField(label: '학적 상태', value: enrollmentLabel),
                const Divider(height: 32),
                _ProfileField(
                  label: '계정 상태',
                  value: profile.accountStatus == 'ACTIVE' ? '활성' : '이용 제한',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            key: const Key('support-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지원', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                WhitespaceWrappedText('학사 정보 이용 중 확인이 필요한 내용을 문의할 수 있어요.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('open-inquiries'),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => InquiryPage(
                          controller: inquiryController,
                          onAuthenticationRequired: controller.signOut,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('문의사항'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MajorEditingView extends StatefulWidget {
  const _MajorEditingView({required this.controller, required this.state});

  final OnboardingController controller;
  final MajorEditing state;

  @override
  State<_MajorEditingView> createState() => _MajorEditingViewState();
}

class _MajorEditingViewState extends State<_MajorEditingView> {
  final _formKey = GlobalKey<FormState>();
  late String? _primaryDepartmentId;
  late String? _doubleMajorDepartmentId;
  late String? _minorDepartmentId;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile;
    _primaryDepartmentId = profile.primaryDepartment.entityId;
    _doubleMajorDepartmentId = profile.doubleMajorDepartment?.entityId;
    _minorDepartmentId = profile.minorDepartment?.entityId;
  }

  List<Department> get _departments {
    final profile = widget.state.profile;
    final currentDepartments = <Department>[
      profile.primaryDepartment,
      ?profile.doubleMajorDepartment,
      ?profile.minorDepartment,
    ];
    return {
      for (final department in [
        ...widget.state.departments,
        ...currentDepartments,
      ])
        department.entityId: department,
    }.values.toList(growable: false);
  }

  String? _validateDepartment(String? value, {required bool isRequired}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return '주전공 학과를 선택해 주세요.';
    }
    if (value == null || value.isEmpty) return null;
    final selected = [
      _primaryDepartmentId,
      _doubleMajorDepartmentId,
      _minorDepartmentId,
    ];
    if (selected.where((departmentId) => departmentId == value).length > 1) {
      return '같은 학과를 여러 전공으로 선택할 수 없어요.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.updateMajors(
      StudentMajorUpdate(
        primaryDepartmentEntityId: _primaryDepartmentId!,
        doubleMajorDepartmentEntityId: _doubleMajorDepartmentId,
        minorDepartmentEntityId: _minorDepartmentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    return _PageScaffold(
      title: '전공 정보',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '전공 정보를 수정해 주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              '현재 이수 중인 전공을 기준으로 학사 안내를 제공해요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('major-editing-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(message: message, isError: true),
                    const SizedBox(height: 16),
                  ],
                  _DepartmentField(
                    fieldKey: const Key('department-field'),
                    label: '주전공 학과',
                    departments: _departments,
                    value: _primaryDepartmentId,
                    isEnabled: !isSubmitting,
                    isRequired: true,
                    onChanged: (value) =>
                        setState(() => _primaryDepartmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: true),
                  ),
                  const SizedBox(height: 16),
                  _DepartmentField(
                    fieldKey: const Key('double-major-department-field'),
                    label: '복수전공 학과 (선택)',
                    departments: _departments,
                    value: _doubleMajorDepartmentId,
                    isEnabled: !isSubmitting,
                    onChanged: (value) =>
                        setState(() => _doubleMajorDepartmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: false),
                  ),
                  const SizedBox(height: 16),
                  _DepartmentField(
                    fieldKey: const Key('minor-department-field'),
                    label: '부전공 학과 (선택)',
                    departments: _departments,
                    value: _minorDepartmentId,
                    isEnabled: !isSubmitting,
                    onChanged: (value) =>
                        setState(() => _minorDepartmentId = value),
                    validator: (value) =>
                        _validateDepartment(value, isRequired: false),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: '전공 저장',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : widget.controller.cancelMajorEditing,
                      child: const Text('취소'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      fillViewport: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            WhitespaceWrappedText(
              '학생 정보를 불러오는 중이에요…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      fillViewport: true,
      child: Center(
        child: _SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              WhitespaceWrappedText(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.child,
    this.action,
    this.title = 'AHNI',
    this.maxWidth = 400,
    this.fillViewport = false,
    this.bottomNavigationBar,
  });

  final Widget child;
  final Widget? action;
  final String title;
  final double maxWidth;
  final bool fillViewport;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(title),
        actions: action == null
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: action,
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = fillViewport && constraints.maxHeight > 56
                ? constraints.maxHeight - 56
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DepartmentField extends StatelessWidget {
  const _DepartmentField({
    required this.fieldKey,
    required this.label,
    required this.departments,
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    required this.validator,
    this.isRequired = false,
  });

  static const _none = '';

  final Key fieldKey;
  final String label;
  final List<Department> departments;
  final String? value;
  final bool isEnabled;
  final bool isRequired;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: value ?? (isRequired ? null : _none),
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!isRequired)
          const DropdownMenuItem(value: _none, child: Text('선택 안 함')),
        for (final department in departments)
          DropdownMenuItem(
            value: department.entityId,
            child: Text(department.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: isEnabled
          ? (selected) => onChanged(selected == _none ? null : selected)
          : null,
      validator: validator,
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({
    required this.isSignUp,
    required this.isEnabled,
    required this.onChanged,
  });

  final bool isSignUp;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ValueSegmentedControl(
      key: const Key('auth-mode-switch'),
      value: isSignUp ? 'sign-up' : 'sign-in',
      isEnabled: isEnabled,
      options: const {'sign-in': '로그인', 'sign-up': '가입'},
      optionKeys: const {
        'sign-in': Key('auth-sign-in-segment'),
        'sign-up': Key('auth-sign-up-segment'),
      },
      onChanged: (value) => onChanged(value == 'sign-up'),
    );
  }
}

class _ValueSegmentedControl extends StatelessWidget {
  const _ValueSegmentedControl({
    required this.value,
    required this.isEnabled,
    required this.options,
    required this.onChanged,
    this.optionKeys = const {},
    super.key,
  });

  final String value;
  final bool isEnabled;
  final Map<String, String> options;
  final Map<String, Key> optionKeys;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options.entries)
            Expanded(
              child: Semantics(
                key: optionKeys[option.key],
                button: true,
                selected: value == option.key,
                enabled: isEnabled,
                child: Material(
                  color: value == option.key
                      ? colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: isEnabled ? () => onChanged(option.key) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Text(
                          option.value,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: value == option.key
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? colorScheme.errorContainer : const Color(0xFFEAF2FC),
          borderRadius: BorderRadius.circular(6),
        ),
        child: WhitespaceWrappedText(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isError
                ? colorScheme.onErrorContainer
                : const Color(0xFF18202A),
          ),
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.isLoading, required this.label});

  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
