import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/grad_button.dart';

class _OnboardingSlide {
  final String imagePath;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

const _slides = [
  _OnboardingSlide(
    imagePath: 'assets/images/debate.png',
    title: 'Debat',
    description: 'Defann pozisyon ou sou sijè ki konte pou kominote ayisyen an',
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/vote.png',
    title: 'Vote',
    description: 'Di sa w panse sou matchup yo epi fè vwa w konte',
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/comment.png',
    title: 'Agimante',
    description: 'Ekri agiman ou epi kore pozisyon w ak bon rezonnman',
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/predict.png',
    title: 'Prediksyon',
    description: 'Predi sa ki pral rive epi ranpòte pwen enfliyans',
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/influencer.png',
    title: 'Enfliyans',
    description:
        'Bati repitasyon ou kòm yon vwa moun ka fè konfyans nan kominote a',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loading = false;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({bool showLoading = false}) async {
    if (showLoading) setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/create-account');
  }

  Future<void> _complete() => _finish(showLoading: true);

  void _next() {
    if (_isLastPage) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.bg0,
        child: SafeArea(
          child: Column(
            children: [
              // Skip button row
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: _isLastPage
                      ? const SizedBox(height: 36)
                      : TextButton(
                          onPressed: _skip,
                          child: const Text(
                            'Sote',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return _SlidePage(slide: _slides[index]);
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: Column(
                  children: [
                    // Page indicator
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _slides.length,
                      effect: const ExpandingDotsEffect(
                        activeDotColor: AppColors.gradPurple,
                        dotColor: AppColors.border,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Primary button
                    GradButton(
                      label: _isLastPage ? 'Kòmanse' : 'Kontinye',
                      onTap: _loading ? null : _next,
                      loading: _loading,
                    ),
                    if (!_isLastPage) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Sote',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in glowing container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                slide.imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 44),
          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              slide.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
