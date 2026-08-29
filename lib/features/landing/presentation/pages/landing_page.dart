import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _slides = const [
    _OnboardingItem(
      title: 'Mobile Point of Sale',
      description:
          'Transform your business with a Mobile Point of Sale system, enabling seamless payments, inventory management, and enhanced customer experiences.',
      primaryIcon: Icons.point_of_sale_rounded,
      secondaryIcon: Icons.contactless_rounded,
      accentColor: Color(0xFF84CC16), // Fresh lime-green accent from inspiration
      badgeText: 'FAST CHECKOUT',
    ),
    _OnboardingItem(
      title: 'Business Support Services',
      description:
          'Track sales, manage inventory, employees, and customers effortlessly on any device for streamlined business operations.',
      primaryIcon: Icons.storefront_rounded,
      secondaryIcon: Icons.people_alt_rounded,
      accentColor: Color(0xFF10B981), // Emerald
      badgeText: 'OPERATIONS & STAFF',
    ),
    _OnboardingItem(
      title: 'Real-Time Insights & Reports',
      description:
          'Monitor net profit margins, top-selling categories, payment breakdowns, and shift performance anytime, anywhere.',
      primaryIcon: Icons.analytics_rounded,
      secondaryIcon: Icons.receipt_long_rounded,
      accentColor: Color(0xFF2563EB), // Indigo Blue
      badgeText: 'SMART ANALYTICS',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Brand Logo & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/andalus11.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Andalus POS',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Middle: Interactive PageView Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stacked Hero Visual Container (Inspiration layout)
                        SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background soft tinted blob
                              Positioned(
                                top: 12,
                                child: Container(
                                  width: 240,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(44),
                                  ),
                                ),
                              ),
                              // Card 1 (Back angled layer)
                              Positioned(
                                left: 16,
                                top: 20,
                                child: Transform.rotate(
                                  angle: -0.09,
                                  child: Container(
                                    width: 150,
                                    height: 190,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0A0F172A),
                                          blurRadius: 16,
                                          offset: Offset(-2, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: item.accentColor.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            item.secondaryIcon,
                                            size: 36,
                                            color: item.accentColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 60,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: AppColors.inputBackground,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Card 2 (Front focused layer)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: Transform.rotate(
                                  angle: 0.06,
                                  child: Container(
                                    width: 165,
                                    height: 205,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: item.accentColor.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x120F172A),
                                          blurRadius: 20,
                                          offset: Offset(4, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                item.accentColor,
                                                item.accentColor.withOpacity(0.85),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: item.accentColor.withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            item.primaryIcon,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          item.badgeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: item.accentColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 38),

                        // Slide Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Slide Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13.5,
                              color: AppColors.textMedium,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation: Skip Button (Left), Pill Indicator (Center), Next Circle Arrow (Right)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Pill Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToLogin,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Pill Page Indicator
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? slide.accentColor
                              : AppColors.borderMedium,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Circular Floating Next Button with Ring Accent
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: slide.accentColor.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: slide.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: slide.accentColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentPage == _slides.length - 1
                              ? Icons.check_rounded
                              : Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 26,
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
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Color accentColor;
  final String badgeText;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.accentColor,
    required this.badgeText,
  });
}