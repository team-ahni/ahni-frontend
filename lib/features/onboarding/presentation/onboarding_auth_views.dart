// 로그인·가입, 비밀번호 찾기, 이메일 인증 대기, 계정 재연결 화면.
part of 'onboarding_page.dart';

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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                WhitespaceWrappedText(
                  '인증 메일이 오지 않으면 입력한 주소와 스팸함을 확인해 주세요. '
                  '이미 가입한 계정이 있다면 로그인해 주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.message case final message?) ...[
                  const SizedBox(height: 16),
                  state.isError
                      ? ErrorNotice(message)
                      : NoticeCallout(message: message),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    widget.state.isError
                        ? ErrorNotice(message)
                        : NoticeCallout(message: message),
                    const SizedBox(height: 16),
                  ],
                  LabeledField(
                    label: '새 비밀번호',
                    child: TextFormField(
                      key: const Key('new-password'),
                      controller: _passwordController,
                      enabled: !isSubmitting,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                      errorBuilder: fieldErrorBuilder,
                      validator: _validatePassword,
                      decoration: InputDecoration(
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
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('update-password'),
                      onPressed: isSubmitting ? null : _submit,
                      child: BusyButtonLabel(
                        isBusy: isSubmitting,
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
            const AhniMascot(size: 88),
            const SizedBox(height: 16),
            WhitespaceWrappedText(
              '학사 준비, 함께 이어가요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                    widget.state.isError
                        ? ErrorNotice(message)
                        : NoticeCallout(message: message),
                    const SizedBox(height: 16),
                  ],
                  LabeledField(
                    label: '학교 이메일',
                    child: TextFormField(
                      key: const Key('auth-email'),
                      controller: _emailController,
                      enabled: !isSubmitting,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      errorBuilder: fieldErrorBuilder,
                      forceErrorText: _passwordResetEmailError,
                      onChanged: (_) {
                        if (_passwordResetEmailError != null) {
                          setState(() => _passwordResetEmailError = null);
                        }
                      },
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        hintText: 'student@inha.edu',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: '비밀번호',
                    child: TextFormField(
                      key: const Key('auth-password'),
                      controller: _passwordController,
                      enabled: !isSubmitting,
                      obscureText: _obscurePassword,
                      autofillHints: _isSignUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                      errorBuilder: fieldErrorBuilder,
                      validator: _validatePassword,
                      decoration: InputDecoration(
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
                      child: BusyButtonLabel(
                        isBusy: isSubmitting,
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

class _RelinkPanel extends StatelessWidget {
  const _RelinkPanel({
    required this.stage,
    required this.onRequest,
    required this.onCheck,
  });

  final RelinkStage stage;
  final VoidCallback onRequest;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return switch (stage) {
      RelinkStage.unavailable => const SizedBox.shrink(),
      RelinkStage.available || RelinkStage.submitting => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('request-relink'),
            onPressed: stage == RelinkStage.submitting ? null : onRequest,
            child: BusyButtonLabel(
              isBusy: stage == RelinkStage.submitting,
              label: '기존 정보 연결 요청',
            ),
          ),
        ),
      ),
      RelinkStage.requested => Padding(
        key: const Key('relink-requested'),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NoticeCallout(
              message: '기존 정보 연결을 요청했어요. 관리자가 본인 확인을 마치면 이 계정에서 기존 성적과 시간표를 볼 수 있어요.',
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onCheck, child: const Text('연결 확인')),
          ],
        ),
      ),
    };
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
