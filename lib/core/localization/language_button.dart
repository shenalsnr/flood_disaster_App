import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'language_controller.dart';
import 'language_picker_screen.dart';

/// Small globe chip ("EN" / "සිං" / "த"). Drop it into ANY screen's app bar or
/// profile page; tapping opens a sheet to switch language for the whole app.
///
///   const LanguageButton()
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  static String _short(AppLang l) {
    switch (l) {
      case AppLang.en:
        return 'EN';
      case AppLang.si:
        return 'සිං';
      case AppLang.ta:
        return 'த';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF131C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2B3A55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                size: 15, color: Color(0xFF38BDF8)),
            const SizedBox(width: 4),
            Text(
              _short(LanguageController.instance.lang),
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to change language at any time.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0B1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final controller = LanguageController.instance;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('pick_title'),
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final l in AppLang.values)
                LanguageOptionTile(
                  lang: l,
                  selected: controller.lang == l,
                  onTap: () {
                    controller.set(l);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
