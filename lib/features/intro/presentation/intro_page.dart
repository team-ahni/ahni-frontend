import 'package:ahni_mobile/core/presentation/ahni_mascot.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:flutter/material.dart';

typedef _IntroSlide = ({AhniMood mood, String title, String body});

// 앱이 실제로 하는 일만 소개한다. 장마다 '아띠'의 표정이 바뀐다.
const _slides = <_IntroSlide>[
  (
    mood: AhniMood.hello,
    title: '안녕하세요, 아띠예요',
    body: 'AHNI는 INHA를 뒤집은 이름이에요. 학생 쪽에서 학사 생활을 함께 챙겨요.',
  ),
  (
    mood: AhniMood.curious,
    title: '성적과 졸업 요건을 한눈에',
    body: '성적을 등록하면 평점과 남은 졸업 학점, 필수과목을 바로 보여 줘요.',
  ),
  (
    mood: AhniMood.hello,
    title: '시간표는 캡처 한 장으로',
    body: '수강신청 확인 화면을 캡처하면 시간표를 한 번에 채워요. 캡처는 기기 안에서만 읽어요.',
  ),
  (
    mood: AhniMood.cheer,
    title: '들으면 좋은 과목도 골라 드려요',
    body: '이번 학기에 들으면 좋은 과목과 분반을 추천하고, 바로 시간표에 넣을 수 있어요.',
  ),
];

/// 처음 실행할 때 보여 주는 앱 소개. 끝까지 넘기거나 건너뛰면 [onDone]을 부른다.
class IntroPage extends StatefulWidget {
  const IntroPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const Key('intro-page'),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                // 마지막 장에서는 '시작하기'와 같은 일이라 숨긴다.
                child: Visibility(
                  visible: !_isLast,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    key: const Key('intro-skip'),
                    onPressed: widget.onDone,
                    child: const Text('건너뛰기'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) =>
                    _IntroSlideView(slide: _slides[index]),
              ),
            ),
            Semantics(
              label: '${_slides.length}장 중 ${_index + 1}장',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? colorScheme.primary
                              : colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('intro-next'),
                  onPressed: _next,
                  child: Text(_isLast ? '시작하기' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // 내용을 세로 가운데에 두되, 큰 글자로 넘치면 스크롤한다.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AhniMascot(mood: slide.mood, size: 180),
              const SizedBox(height: 32),
              WhitespaceWrappedText(
                slide.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              WhitespaceWrappedText(
                slide.body,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
