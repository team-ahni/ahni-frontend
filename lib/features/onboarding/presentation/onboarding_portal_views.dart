// 로그인한 학생의 포털 탭, 내 정보, 전공 수정 화면.
part of 'onboarding_page.dart';

class _StudentPortalView extends StatefulWidget {
  const _StudentPortalView({
    required this.onboardingController,
    required this.gradeController,
    required this.gradeSimulationController,
    required this.graduationController,
    required this.scholarshipController,
    required this.courseController,
    required this.gradeRegistrationController,
    required this.gradeEditController,
    required this.inquiryController,
    required this.timetableController,
    required this.recommendationController,
    required this.profileState,
    required this.showDeveloperTools,
  });

  final OnboardingController onboardingController;
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
  final ProfileReady profileState;
  final bool showDeveloperTools;

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
        scholarshipController: widget.scholarshipController,
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
        recommendationController: widget.recommendationController,
        onAuthenticationRequired: widget.onboardingController.signOut,
        bottomNavigationBar: navigationBar,
      );
    }
    return _ProfileView(
      controller: widget.onboardingController,
      inquiryController: widget.inquiryController,
      state: widget.profileState,
      bottomNavigationBar: navigationBar,
      showDeveloperTools: widget.showDeveloperTools,
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.controller,
    required this.inquiryController,
    required this.state,
    required this.bottomNavigationBar,
    required this.showDeveloperTools,
  });

  final OnboardingController controller;
  final InquiryController inquiryController;
  final ProfileReady state;
  final Widget bottomNavigationBar;
  final bool showDeveloperTools;

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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.primaryDepartment.name} · ${profile.admissionYear}학번',
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
          const SizedBox(height: 28),
          if (state.message case final message?) ...[
            ErrorNotice(message),
            const SizedBox(height: 16),
          ],
          SectionHeader(
            title: '전공 정보',
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: state.isLoadingMajors
                  ? null
                  : controller.startMajorEditing,
              child: _ButtonLabel(
                isLoading: state.isLoadingMajors,
                label: '전공 수정',
              ),
            ),
          ),
          InfoGroup(
            key: const Key('major-information-card'),
            children: [
              InfoRow(label: '주전공', value: profile.primaryDepartment.name),
              InfoRow(
                label: '복수전공',
                value: profile.doubleMajorDepartment?.name ?? '선택 안 함',
              ),
              InfoRow(
                label: '부전공',
                value: profile.minorDepartment?.name ?? '선택 안 함',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: '학생 정보'),
          InfoGroup(
            key: const Key('student-information-card'),
            children: [
              InfoRow(label: '학교 이메일', value: profile.email),
              InfoRow(label: '입학연도', value: '${profile.admissionYear}년'),
              InfoRow(label: '학적 상태', value: enrollmentLabel),
              InfoRow(
                label: '계정 상태',
                value: profile.accountStatus == 'ACTIVE' ? '활성' : '이용 제한',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: '지원'),
          InfoGroup(
            key: const Key('support-card'),
            children: [
              NavigationRow(
                key: const Key('open-inquiries'),
                icon: Icons.support_agent_rounded,
                title: '문의사항',
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => InquiryPage(
                        controller: inquiryController,
                        onAuthenticationRequired: controller.signOut,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (showDeveloperTools) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: '개발자 도구'),
            InfoGroup(
              key: const Key('developer-tools'),
              children: [
                NavigationRow(
                  key: const Key('replay-intro'),
                  icon: Icons.slideshow_rounded,
                  title: '앱 소개 다시 보기',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (routeContext) => IntroPage(
                        onDone: () => Navigator.of(routeContext).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('major-editing-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    ErrorNotice(message),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
