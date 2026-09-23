import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final UserRole selectedRole;
  final String userName;

  const OnboardingScreen({
    super.key,
    this.selectedRole = UserRole.student,
    this.userName = 'Student',
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    const OnboardingItem(
      title: 'Stay Organized & Achieve More',
      description:
          'Get your assignments, notes, quizzes, attendance and timetable — all in one place.',
      icon: Icons.auto_stories_rounded,
      badgeText: 'All-In-One Hub',
      badgeColor: AppColors.primary,
    ),
    const OnboardingItem(
      title: 'Interactive Courses & Materials',
      description:
          'Access course syllabus, lecture slides, video tutorials, and collaborate with professors effortlessly.',
      icon: Icons.devices_rounded,
      badgeText: 'Smart Learning',
      badgeColor: AppColors.indigo,
    ),
    const OnboardingItem(
      title: 'Track Your Academic Progress',
      description:
          'Monitor your GPA, attendance milestones, and get smart reminders for upcoming exam deadlines.',
      icon: Icons.insights_rounded,
      badgeText: 'Success Metrics',
      badgeColor: AppColors.teal,
    ),
  ];

  void _finishOnboarding() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration container
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: item.badgeColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.badgeColor.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.card,
                              ),
                              child: Icon(
                                item.icon,
                                size: 68,
                                color: item.badgeColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: item.badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.badgeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Get Started / Next Button
                  CustomButton(
                    text: isLastPage ? 'Get Started' : 'Next',
                    icon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (isLastPage) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
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

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final String badgeText;
  final Color badgeColor;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
  });
}
