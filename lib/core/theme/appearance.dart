import 'package:flutter/material.dart';

import 'theme_controller.dart';

import '../localization/app_strings.dart';
import '../localization/language_button.dart';
/// Light mode is produced from the app's dark design by inverting lightness
/// while keeping the hues (invert + 180 degree hue rotation). It applies to
/// every screen, dialog and sheet in one place, so all components follow the
/// same Dark / Light setting.
///
/// This matrix is its own inverse, so wrapping a photo or map in
/// [Unfiltered] shows it with its natural colours in light mode.
const List<double> kLightModeMatrix = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
];

const ColorFilter kLightModeFilter = ColorFilter.matrix(kLightModeMatrix);

/// Placed once in `MaterialApp.builder`.
class AppearanceScope extends StatelessWidget {
  final Widget child;
  const AppearanceScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        if (!ThemeController.instance.isLight) return child;
        return ColorFiltered(colorFilter: kLightModeFilter, child: child);
      },
    );
  }
}

/// Keeps photos, logos and maps in their real colours in light mode.
class Unfiltered extends StatelessWidget {
  final Widget child;
  const Unfiltered({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        if (!ThemeController.instance.isLight) return child;
        return ColorFiltered(colorFilter: kLightModeFilter, child: child);
      },
    );
  }
}

/// Ready-made "Appearance" switch for any settings screen.
class ThemeToggleTile extends StatelessWidget {
  final Color activeColor;
  final EdgeInsetsGeometry? contentPadding;
  const ThemeToggleTile({
    super.key,
    this.activeColor = const Color(0xFF34D399),
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final light = ThemeController.instance.isLight;
        return Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
          contentPadding: contentPadding,
          secondary: Icon(
            light ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: activeColor,
          ),
          activeThumbColor: activeColor,
          title: Text(
            tr('Light mode'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            light ? tr('Light theme is on') : tr('Dark theme is on (saves battery)'),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          value: light,
          onChanged: (v) => ThemeController.instance.setLight(v),
          ),
        );
      },
    );
  }
}

/// Small Dark / Light button for app bars and headers of every dashboard.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final light = ThemeController.instance.isLight;
        // Language chip (English / සිං / த) + Dark / Light button, together
        // on the first page of every component.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanguageButton(),
            const SizedBox(width: 2),
            IconButton(
              tooltip: light ? tr('Switch to dark mode') : tr('Switch to light mode'),
              icon: Icon(
                light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: color ?? Colors.white,
                size: 22,
              ),
              onPressed: () => ThemeController.instance.setLight(!light),
            ),
          ],
        );
      },
    );
  }
}
