import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/responder_models.dart';

/// Shared design system for Component 4 (colours, responsive helpers,
/// animations, photo widgets). Everything here uses only built-in Flutter
/// widgets (LayoutBuilder, MediaQuery, NavigationBar/Rail, Hero, ...).
class C4 {
  static const bg = Color(0xFF070B14);
  static const surface = Color(0xFF0F1A2E);
  static const card = Color(0xFF16213A);
  static const border = Color(0xFF24324F);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
  static const accent = Color(0xFFFF6D00);
  static const blue = Color(0xFF38BDF8);
  static const green = Color(0xFF10B981);

  static Color severity(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return const Color(0xFFEF4444);
      case IncidentSeverity.high:
        return const Color(0xFFF59E0B);
      case IncidentSeverity.medium:
        return const Color(0xFFFACC15);
      case IncidentSeverity.low:
        return const Color(0xFF10B981);
    }
  }

  static Color status(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.incoming:
        return const Color(0xFF94A3B8);
      case IncidentStatus.dispatched:
        return const Color(0xFF38BDF8);
      case IncidentStatus.onScene:
        return const Color(0xFFA78BFA);
      case IncidentStatus.resolved:
        return const Color(0xFF10B981);
    }
  }

  static IconData hazardIcon(String hazard) {
    final h = hazard.toLowerCase();
    if (h.contains('flood') || h.contains('water') || h.contains('drain')) {
      return Icons.water_rounded;
    }
    if (h.contains('land') || h.contains('mud')) return Icons.landscape_rounded;
    if (h.contains('tree') || h.contains('block')) return Icons.park_rounded;
    if (h.contains('bridge') || h.contains('struct')) {
      return Icons.foundation_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  /// Picks one of the bundled photos that fits the hazard type.
  static String fallbackPhoto(String hazard) {
    final h = hazard.toLowerCase();
    if (h.contains('flood') || h.contains('water') || h.contains('drain')) {
      return 'assets/images/onboard_early_warning.jpg';
    }
    if (h.contains('shelter') || h.contains('evac')) {
      return 'assets/images/onboard_safe_shelter.jpg';
    }
    return 'assets/images/onboard_hazard_report.jpg';
  }
}

// -----------------------------------------------------------------------------
// Responsive helpers
// -----------------------------------------------------------------------------
enum ScreenSize { compact, medium, expanded }

class Responsive {
  static ScreenSize ofWidth(double w) {
    if (w < 640) return ScreenSize.compact;
    if (w < 1024) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static ScreenSize of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  static double pad(double w) => w < 640 ? 14 : (w < 1024 ? 20 : 24);
}

/// Centers content and limits its width on tablets / desktop / web.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  /// true = only as tall as the child (use in bottom bars). false = fills the
  /// available height (use for page bodies / lists).
  final bool shrinkHeight;
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.shrinkHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      heightFactor: shrinkHeight ? 1.0 : null,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Shows a phone-designed page centred in a phone-width column on wide
/// screens (tablet / desktop / web); on phones it is shown as-is.
class ResponsiveFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveFrame({super.key, required this.child, this.maxWidth = 560});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth + 80) return child;
    return ColoredBox(
      color: C4.bg,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: ClipRect(
            child: MediaQuery(
              data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [page] with a smooth fade + slide, framed for wide screens.
Future<T?> pushPage<T>(BuildContext context, Widget page, {bool frame = true}) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => frame ? ResponsiveFrame(child: page) : page,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

// -----------------------------------------------------------------------------
// Animation helpers
// -----------------------------------------------------------------------------

/// Fade + slide-up entrance. Pass the list index for a staggered effect.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final i = math.min(index, 8);
    final total = 380 + i * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(i * 70 / total, 1.0, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

/// Number that smoothly counts to its new value.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  const AnimatedCount({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}', style: style),
    );
  }
}

/// Press-down scale feedback for cards and buttons.
class Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Tappable({super.key, required this.child, this.onTap});

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

/// Small pulsing dot used for live / critical indicators.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 9});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.2 + 0.5 * _c.value),
              blurRadius: 3 + 8 * _c.value,
              spreadRadius: 1 + 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Photos
// -----------------------------------------------------------------------------

/// Report photo (uploaded by the volunteer) or a fitting bundled photo.
class HazardPhoto extends StatelessWidget {
  final IncidentReport incident;
  final double? width;
  final double? height;
  final double radius;
  final bool overlay;
  const HazardPhoto({
    super.key,
    required this.incident,
    this.width,
    this.height,
    this.radius = 12,
    this.overlay = true,
  });

  Widget _asset() => Image.asset(
        C4.fallbackPhoto(incident.hazardType),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: C4.card,
          child: Icon(C4.hazardIcon(incident.hazardType),
              color: C4.muted, size: 32),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = incident.photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
                  opacity: frame == null && !sync ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  child: child,
                ),
                errorBuilder: (_, __, ___) => _asset(),
              )
            else
              _asset(),
            if (overlay)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
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

// -----------------------------------------------------------------------------
// Small pieces
// -----------------------------------------------------------------------------
class C4Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const C4Chip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class C4Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  const C4Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: C4.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? C4.border),
      ),
      child: child,
    );
  }
}
