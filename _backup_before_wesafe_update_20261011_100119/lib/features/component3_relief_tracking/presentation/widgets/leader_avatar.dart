import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/appearance.dart';

/// Round avatar for the logged-in camp leader: shows the profile photo when
/// there is one (stored as a base64 data URL or a web link), otherwise the
/// leader's initials.
class LeaderAvatar extends StatefulWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const LeaderAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 44,
  });

  @override
  State<LeaderAvatar> createState() => _LeaderAvatarState();
}

class _LeaderAvatarState extends State<LeaderAvatar> {
  Uint8List? _bytes;
  String? _decodedFor;

  /// Decode once per photo, not on every rebuild.
  void _decode() {
    final url = widget.photoUrl;
    if (url == _decodedFor) return;
    _decodedFor = url;
    _bytes = null;
    if (url != null && url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        _bytes = base64Decode(comma == -1 ? url : url.substring(comma + 1));
      } catch (_) {
        _bytes = null;
      }
    }
  }

  String get _initials {
    final words = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !w.endsWith('.'))
        .toList();
    if (words.isEmpty) return '?';
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    return letters;
  }

  Widget _fallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      color: const Color(0xFF1F2C46),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.size * 0.36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _decode();
    final url = widget.photoUrl;
    Widget child;
    if (_bytes != null) {
      child = Unfiltered(child: Image.memory(
        _bytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ));
    } else if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
      child = Unfiltered(child: Image.network(
        url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ));
    } else {
      child = _fallback();
    }
    return ClipOval(child: child);
  }
}
