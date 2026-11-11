// 온보딩 화면들이 함께 쓰는 틀·카드·입력 조각.
part of 'onboarding_page.dart';

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
        child: LoadFailureView(
          title: '내 정보를 불러오지 못했어요',
          message: message,
          onRetry: onRetry,
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
    return LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        initialValue: value ?? (isRequired ? null : _none),
        isExpanded: true,
        decoration: InputDecoration(),
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
      ),
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
                      constraints: const BoxConstraints(minHeight: 48),
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
