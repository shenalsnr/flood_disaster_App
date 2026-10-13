import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'language_controller.dart';
import 'translation_service.dart';

/// Drop-in replacement for Text() for anything OTHER PEOPLE wrote
/// (warning message, chat, hazard report description ...).
///
///   TranslatedText(report.description, style: ...)
///
/// It shows the text in the viewer's language. If it had to be translated a
/// small "Translated automatically - Show original" link appears.
/// Rebuilds automatically when the language is switched.
class TranslatedText extends StatefulWidget {
  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.showBadge = true,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool showBadge;

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translated; // null = original is shown / not translated
  bool _showOriginal = false;
  AppLang? _forLang;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _load();
  }

  Future<void> _load() async {
    final lang = LanguageController.instance.lang;
    _forLang = lang;
    final my = ++_token;
    final svc = TranslationService.instance;
    final hit = svc.cached(widget.text, to: lang);
    if (hit != null) {
      if (mounted) setState(() => _apply(hit));
      return;
    }
    final r = await svc.translate(widget.text, to: lang);
    if (!mounted || my != _token) return;
    setState(() => _apply(r));
  }

  void _apply(String r) {
    _translated = (r == widget.text) ? null : r;
  }

  @override
  Widget build(BuildContext context) {
    // Language was switched while this widget was alive -> translate again.
    if (_forLang != LanguageController.instance.lang) {
      _showOriginal = false;
      _translated = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final shown =
        (_translated != null && !_showOriginal) ? _translated! : widget.text;
    final text = Text(
      shown,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
    if (_translated == null || !widget.showBadge) return text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => setState(() => _showOriginal = !_showOriginal),
          child: Text(
            _showOriginal
                ? tr('show_translation')
                : '${tr('translated_auto')} · ${tr('show_original')}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
