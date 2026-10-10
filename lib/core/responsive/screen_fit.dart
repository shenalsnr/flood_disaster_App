import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App-wide helpers that make every screen adapt to the phone it runs on
/// (small / large phones, short screens, landscape, big system font size).
class ScreenFit {
  ScreenFit._();

  /// Used in `MaterialApp.builder`. Keeps the system font-size setting working
  /// but limits it so layouts do not overflow on very large text settings,
  /// and makes sure content never goes under the notch / gesture bar when a
  /// screen forgot its own SafeArea.
  static Widget appBuilder(BuildContext context, Widget? child) {
    final mq = MediaQuery.of(context);
    final scaler = mq.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
    );
    return MediaQuery(
      data: mq.copyWith(textScaler: scaler),
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Scales a design value (made for a ~390dp wide phone) to the real width,
  /// never smaller than 0.8x or larger than 1.25x.
  static double scale(BuildContext context, double designValue) {
    final w = MediaQuery.sizeOf(context).width;
    return designValue * (w / 390).clamp(0.8, 1.25);
  }

  /// A square size that fits the screen: [designSize] on normal phones,
  /// smaller on small / short screens.
  static double square(BuildContext context, double designSize,
      {double heightFraction = 0.4}) {
    final s = MediaQuery.sizeOf(context);
    return math.min(designSize, math.min(s.width * 0.8, s.height * heightFraction));
  }
}

/// Column-style page body that fills the screen on tall phones (so `Spacer`
/// and `Expanded` work) and scrolls instead of overflowing on short screens
/// or in landscape.
class ScrollFill extends StatelessWidget {
  final Widget child;
  const ScrollFill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
