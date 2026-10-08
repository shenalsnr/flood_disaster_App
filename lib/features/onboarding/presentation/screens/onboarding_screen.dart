import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
import '../widgets/onboarding_visuals.dart';

/// Professional 3-step onboarding flow for WeSafe.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Get Early Warning Alerts',
      description:
          'Receive real-time notifications about floods, storms, and natural disasters in your area to stay ahead of danger.',
      buttonText: 'Next',
    ),
    _OnboardingItem(
      title: 'Report Hazards Instantly',
      description:
          'Share critical updates, take photos of rising waters, and warn your community to keep everyone safe.',
      buttonText: 'Next',
    ),
    _OnboardingItem(
      title: 'Find Safe Routes & Shelter',
      description:
          'Locate active shelters, check available resources, and find safe evacuation paths during emergencies.',
      buttonText: 'Get Started',
    ),
  ];

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const CitizenDashboardScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E18),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _currentPage == _items.length - 1 ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: _currentPage == _items.length - 1
                          ? null
                          : _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View with dynamic cards & copy
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Card Illustration Container
                        Expanded(
                          flex: 11,
                          child: _buildVisualCard(index),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          _items[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle / Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            _items[index].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls: Page Indicator & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  // Action Button ("Next" or "Get Started")
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF621F),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFFFF621F).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _items[_currentPage].buttonText,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
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

  Widget _buildVisualCard(int index) {
    switch (index) {
      case 0:
        return const EarlyWarningVisual();
      case 1:
        return const ReportHazardsVisual();
      case 2:
        return const SafeRoutesVisual();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final String buttonText;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.buttonText,
  });
}
