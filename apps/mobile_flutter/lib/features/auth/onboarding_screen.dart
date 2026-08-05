import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.monitor_heart_outlined,
      title: 'مراقبة دقيقة للحالة',
      description:
          'نظام متكامل لمراقبة المرضى المصابين بالنزيف الدماغي في الوقت الفعلي مع تنبيهات فورية.',
    ),
    _OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'تحليل متقدم للبيانات',
      description:
          'تحليل ذكي للعلامات الحيوية والبيانات السريرية لتقييم المخاطر ودعم القرارات الطبية.',
    ),
    _OnboardingPage(
      icon: Icons.group_outlined,
      title: 'فريق طبي متكامل',
      description:
          'تواصل سلس بين الأطباء والممرضين والفنيين لإدارة أفضل للحالات الحرجة.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(authStateProvider.notifier).setOnboardingComplete();
    if (mounted) context.go('/login');
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? NeuroColors.backgroundDark : NeuroColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'تخطي',
                  style: theme.labelLarge?.copyWith(color: NeuroColors.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(NeuroSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            horizontal: NeuroSpacing.xxs),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? NeuroColors.primary
                              : NeuroColors.primaryLight.withAlpha(100),
                          borderRadius: BorderRadius.circular(NeuroRadius.full),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: NeuroSpacing.xl),
                  AppButton(
                    label: _currentPage == _pages.length - 1
                        ? 'ابدأ الآن'
                        : 'التالي',
                    onPressed: _onNext,
                    icon: _currentPage == _pages.length - 1
                        ? null
                        : Icons.arrow_forward,
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

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.xxxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: NeuroColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(NeuroRadius.xxl),
            ),
            child: Icon(icon, size: 60, color: NeuroColors.primary),
          ),
          const SizedBox(height: NeuroSpacing.xxxl),
          Text(
            title,
            style: theme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeuroSpacing.lg),
          Text(
            description,
            style: theme.bodyLarge?.copyWith(color: NeuroColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
