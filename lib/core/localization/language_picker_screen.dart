import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_strings.dart';
import 'language_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Shown the very first time the app is opened (before onboarding).
/// Tapping a language switches the whole screen immediately; "Continue"
/// moves on to the onboarding pages.
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                          children: [
                            TextSpan(
                                text: 'We',
                                style: TextStyle(color: Color(0xFFF1F5F9))),
                            TextSpan(
                                text: 'Safe',
                                style: TextStyle(color: Color(0xFF38BDF8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Icon(Icons.translate_rounded,
                      color: Color(0xFF38BDF8), size: 40),
                  const SizedBox(height: 14),
                  Text(
                    tr('pick_title'),
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('pick_sub'),
                    style: const TextStyle(
                        color: Color(0xFFB6C2D6), fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final l in AppLang.values)
                            LanguageOptionTile(
                              lang: l,
                              selected: controller.lang == l,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.set(l);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Make sure a choice is saved even if the user keeps
                        // the default (English).
                        controller.set(controller.lang);
                        if (onContinue != null) {
                          onContinue!();
                        } else {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder<void>(
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              pageBuilder: (_, _, _) => const OnboardingScreen(),
                              transitionsBuilder: (_, animation, _, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF06121F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              tr('continue').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8),
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
          ),
        ),
      ),
    );
  }
}

/// One language row (used by the first-run picker and the language sheet).
class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    super.key,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF38BDF8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : const Color(0xFF131C2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : const Color(0xFF2B3A55),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.nativeName,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (lang.nativeName != lang.englishName)
                      Text(
                        lang.englishName,
                        style: const TextStyle(
                            color: Color(0xFFB6C2D6), fontSize: 13),
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent : const Color(0xFF8A98B0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
