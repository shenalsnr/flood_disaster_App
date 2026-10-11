import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/responsive/screen_fit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../component4_control_center/data/services/session_service.dart';
import '../../../component4_control_center/presentation/screens/startup_gate.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../../core/theme/appearance.dart';

/// Animated launch screen for WeSafe.
///
/// Sequence: radar-style alert pulses ripple out → logo scales in with an
/// orange glow → brand name and tagline fade up → a progress bar fills while
/// the app prepares, then hands over to the first screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _splashDuration = Duration(milliseconds: 3400);
  static const double _logoSize = 176;

  late final AnimationController _intro;
  late final AnimationController _pulse;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _progress;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(vsync: this, duration: _splashDuration);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    Animation<double> interval(double begin, double end, Curve curve) =>
        CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: curve));

    _logoFade = interval(0.0, 0.30, Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0)
        .animate(interval(0.0, 0.45, Curves.easeOutBack));
    _titleAnim = interval(0.30, 0.58, Curves.easeOutCubic);
    _taglineAnim = interval(0.45, 0.72, Curves.easeOutCubic);
    _progress = interval(0.12, 0.96, Curves.easeInOut);
    _footerAnim = interval(0.65, 0.95, Curves.easeOut);

    _intro.forward().whenComplete(_goNext);
  }

  Future<void> _goNext() async {
    // Someone who logged in earlier (and did not log out) goes straight to
    // their dashboard; everyone else sees the onboarding / login pages.
    final signedIn = await SessionService.read();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) =>
            signedIn != null ? const StartupGate() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String _statusFor(double p) {
    if (p < 0.35) return 'Starting safety services…';
    if (p < 0.70) return 'Loading early-warning alerts…';
    if (p < 0.98) return 'Preparing offline maps…';
    return 'Ready';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.trueBlack,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.28),
            radius: 1.05,
            colors: [
              Color(0xFF14233F),
              AppColors.background,
              AppColors.trueBlack,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: ScrollFill(
            child: Column(
            children: [
              const Spacer(flex: 5),
              _buildLogo(),
              const SizedBox(height: 22),
              _buildTitle(),
              const SizedBox(height: 10),
              _buildTagline(),
              const Spacer(flex: 4),
              _buildProgress(),
              const SizedBox(height: 28),
              _buildFooter(),
              const SizedBox(height: 22),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // Shrinks on small / short phones so the splash never overflows.
    final box = ScreenFit.square(context, 300, heightFraction: 0.38);
    return SizedBox(
      width: box,
      height: box,
      child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Radar-style alert pulses.
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => CustomPaint(
              size: const Size(300, 300),
              painter: _PulsePainter(
                progress: _pulse.value,
                innerRadius: _logoSize * 0.5,
                outerRadius: 150 * 1.55,
                color: AppColors.primary,
              ),
            ),
          ),
          // Soft orange glow behind the emblem.
          AnimatedBuilder(
            animation: _logoFade,
            builder: (_, _) => Container(
              width: _logoSize * 0.9,
              height: _logoSize * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.28 * _logoFade.value,
                    ),
                    blurRadius: 80,
                    spreadRadius: 14,
                  ),
                ],
              ),
            ),
          ),
          // Logo emblem.
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Semantics(
                label: 'WeSafe logo',
                image: true,
                child: Unfiltered(child: Image.asset(
                  'assets/images/wesafe_logo.png',
                  width: _logoSize,
                  height: _logoSize,
                  filterQuality: FilterQuality.high,
                )),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(_titleAnim),
        child: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'We',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Safe',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(_taglineAnim),
        child: Column(
          children: [
            const Text(
              'Your Community, Your Safety.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            // Semantic colour cue: safe · warning · critical.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Dot(AppColors.success),
                SizedBox(width: 8),
                _Dot(AppColors.warning),
                SizedBox(width: 8),
                _Dot(AppColors.critical),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, _) {
        final p = _progress.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.border),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: p.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryDark,
                                AppColors.primaryLight,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 20,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Text(
                    _statusFor(p),
                    key: ValueKey(_statusFor(p)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      letterSpacing: 0.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _footerAnim,
      child: const Column(
        children: [
          Text(
            'FLOOD & DISASTER EARLY WARNING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Community Reporting & Relief',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
    );
  }
}

/// Three staggered expanding rings, like a radar / alert broadcast.
class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.progress,
    required this.innerRadius,
    required this.outerRadius,
    required this.color,
  });

  final double progress;
  final double innerRadius;
  final double outerRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = innerRadius + (outerRadius - innerRadius) * t;
      final fade = math.pow(1 - t, 1.6).toDouble();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 + (1 - t) * 1.4
        ..color = color.withValues(alpha: 0.42 * fade);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}
