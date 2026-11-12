// 처음 가입한 학생의 학생 정보 등록 화면.
part of 'onboarding_page.dart';

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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('registration-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    ErrorNotice(message),
                    const SizedBox(height: 16),
                  ],
                  _RelinkPanel(
                    stage: widget.state.relinkStage,
                    onRequest: widget.controller.requestRelink,
                    onCheck: widget.controller.retry,
                  ),
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
                  LabeledField(
                    label: '입학연도',
                    child: TextFormField(
                      key: const Key('admission-year'),
                      controller: _admissionYearController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateAdmissionYear,
                      decoration: const InputDecoration(hintText: '2024'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: '닉네임 (선택)',
                    child: TextFormField(
                      key: const Key('nickname'),
                      controller: _nicknameController,
                      enabled: !isSubmitting,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                      decoration: const InputDecoration(),
                    ),
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
                      child: BusyButtonLabel(
                        isBusy: isSubmitting,
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
