import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative banner shown above "Shelter Capacity Overview".
/// Drawn in code (no image asset needed), so it scales to any screen width.
class CampHeroBanner extends StatelessWidget {
  const CampHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1C2740)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CustomPaint(painter: _CampScenePainter()),
        ),
      ),
    );
  }
}

class _CampScenePainter extends CustomPainter {
  const _CampScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Night sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1730), Color(0xFF16305A), Color(0xFF1F4B73)],
        ).createShader(rect),
    );

    // Stars
    final rnd = math.Random(7);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 26; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.55),
        rnd.nextDouble() * 1.1 + 0.3,
        star,
      );
    }

    // Moon with glow
    final moon = Offset(w * 0.82, h * 0.24);
    canvas.drawCircle(
      moon,
      h * 0.2,
      Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(moon, h * 0.085, Paint()..color = const Color(0xFFFEF3C7));

    // Far hills
    final far = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.48, w * 0.45, h * 0.68)
      ..quadraticBezierTo(w * 0.7, h * 0.86, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF123047));

    // Near ground
    final near = Path()
      ..moveTo(0, h * 0.84)
      ..quadraticBezierTo(w * 0.35, h * 0.7, w * 0.65, h * 0.84)
      ..quadraticBezierTo(w * 0.85, h * 0.92, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = const Color(0xFF0D2236));

    // Tents
    _tent(canvas, Offset(w * 0.26, h * 0.86), h * 0.36,
        const Color(0xFFF87171));
    _tent(canvas, Offset(w * 0.5, h * 0.9), h * 0.46,
        const Color(0xFF34D399));
    _tent(canvas, Offset(w * 0.72, h * 0.87), h * 0.32,
        const Color(0xFF60A5FA));

    // Safe-shelter shield
    final c = Offset(w * 0.1, h * 0.3);
    final s = h * 0.17;
    final shield = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.85, c.dy - s * 0.55)
      ..lineTo(c.dx + s * 0.85, c.dy + s * 0.15)
      ..quadraticBezierTo(c.dx + s * 0.8, c.dy + s * 0.8, c.dx, c.dy + s)
      ..quadraticBezierTo(
          c.dx - s * 0.8, c.dy + s * 0.8, c.dx - s * 0.85, c.dy + s * 0.15)
      ..lineTo(c.dx - s * 0.85, c.dy - s * 0.55)
      ..close();
    canvas.drawPath(
        shield, Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.18));
    canvas.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF34D399));
    final tick = Path()
      ..moveTo(c.dx - s * 0.4, c.dy)
      ..lineTo(c.dx - s * 0.08, c.dy + s * 0.32)
      ..lineTo(c.dx + s * 0.45, c.dy - s * 0.3);
    canvas.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF34D399));
  }

  void _tent(Canvas canvas, Offset base, double height, Color color) {
    final half = height * 0.85;
    final body = Path()
      ..moveTo(base.dx - half, base.dy)
      ..lineTo(base.dx, base.dy - height)
      ..lineTo(base.dx + half, base.dy)
      ..close();
    canvas.drawPath(body, Paint()..color = color.withValues(alpha: 0.9));
    // Shaded side
    final shade = Path()
      ..moveTo(base.dx, base.dy - height)
      ..lineTo(base.dx + half, base.dy)
      ..lineTo(base.dx + half * 0.15, base.dy)
      ..close();
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.2));
    // Lit doorway
    final door = Path()
      ..moveTo(base.dx - half * 0.25, base.dy)
      ..lineTo(base.dx, base.dy - height * 0.5)
      ..lineTo(base.dx + half * 0.25, base.dy)
      ..close();
    canvas.drawPath(
      door,
      Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
