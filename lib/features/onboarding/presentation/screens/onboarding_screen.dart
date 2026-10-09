import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../component4_control_center/presentation/screens/responder_login_screen.dart';

/// Ultra-Premium Tactical Onboarding Screen for WeSafe Disaster Response.
/// Replaces cartoon mockups with high-resolution 3D tactical command center
/// surveillance imagery, telemetry HUD badges, and smooth aesthetic transitions.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _pulseController;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      tag: 'RADAR SURVEILLANCE',
      title: 'Early Warning & Flood Alerts',
      description:
          'Receive instant satellite alerts and predictive water level forecasts before floodwaters reach your residential sector.',
      buttonText: 'Next',
      accentColor: Color(0xFF38BDF8),
      imagePath: 'assets/images/onboard_early_warning.jpg',
      badgeTopLeft: 'RADAR LIVE • SECTOR 04',
      badgeTopRight: 'HIGH RISK ALERT',
      telemetryBottom: 'SATELLITE SURGE: 65mm/hr • RIVER MONITOR ACTIVE',
    ),
    _OnboardingItem(
      tag: 'GROUND INTELLIGENCE',
      title: 'Rapid Community Reporting',
      description:
          'Capture geotagged hazard photos and transmit instant alerts to the Disaster Operations Room—even with zero internet connection.',
      buttonText: 'Next',
      accentColor: Color(0xFFFF9100),
      imagePath: 'assets/images/onboard_hazard_report.jpg',
      badgeTopLeft: 'INCIDENT CAM • DMC VERIFIED',
      badgeTopRight: 'OFFLINE QUEUE ACTIVE',
      telemetryBottom: 'GPS: 6.9271° N, 79.8612° E • VERIFICATION LOCKED',
    ),
    _OnboardingItem(
      tag: 'LIFE-SAVING NAVIGATION',
      title: 'Safe Routes & Relief Shelters',
      description:
          'Navigate through real-time safe elevation corridors avoiding flood zones directly to active emergency camps and relief centers.',
      buttonText: 'Get Started',
      accentColor: Color(0xFF00E676),
      imagePath: 'assets/images/onboard_safe_shelter.jpg',
      badgeTopLeft: 'EVAC ROUTE ACTIVE • 3.2 KM',
      badgeTopRight: 'SHELTER ZONE A',
      telemetryBottom: 'RELIEF STATUS: FOOD, WATER & MEDICAL STOCKED',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const ResponderLoginScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = _items[_currentPage];
    final accentColor = activeItem.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar: Logo & Skip Button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand with Glowing Shield
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'We',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Safe',
                              style: TextStyle(color: accentColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _currentPage == _items.length - 1 ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: _currentPage == _items.length - 1
                          ? null
                          : _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Central Page View with 3D Visual Cards & Typography ──────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // ── 3D Visual Cinematic Card ─────────────────────────
                        Expanded(
                          flex: 12,
                          child: _buildCinematicVisualCard(item),
                        ),

                        const SizedBox(height: 22),

                        // ── Tag Badge ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.accentColor.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              color: item.accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Title ────────────────────────────────────────────
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Subtitle / Description ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
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

            // ── Bottom Controls: Dots Indicator & Action Button ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 7,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? accentColor
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Dynamic Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor:
                            accentColor == const Color(0xFF00E676) ||
                                    accentColor == const Color(0xFF38BDF8)
                                ? Colors.black
                                : Colors.white,
                        elevation: 6,
                        shadowColor: accentColor.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activeItem.buttonText.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
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

  // ── Cinematic 3D Card with Tactical Telemetry HUD ──────────────────────────
  Widget _buildCinematicVisualCard(_OnboardingItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: item.accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: item.accentColor.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. High-Resolution 3D Render Image
            Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.image_outlined,
                  color: item.accentColor,
                  size: 54,
                ),
              ),
            ),

            // 2. Tactical Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                ),
              ),
            ),

            // 3. Top-Left Badge (HUD Status)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.accentColor.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.accentColor,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.badgeTopLeft,
                      style: TextStyle(
                        color: item.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Top-Right Badge (Mode / Alert)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  item.badgeTopRight,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),

            // 5. Bottom Telemetry Bar
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF080E1A).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.accentColor.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.satellite_alt_rounded,
                      color: item.accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.telemetryBottom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String tag;
  final String title;
  final String description;
  final String buttonText;
  final Color accentColor;
  final String imagePath;
  final String badgeTopLeft;
  final String badgeTopRight;
  final String telemetryBottom;

  const _OnboardingItem({
    required this.tag,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.accentColor,
    required this.imagePath,
    required this.badgeTopLeft,
    required this.badgeTopRight,
    required this.telemetryBottom,
  });
}
