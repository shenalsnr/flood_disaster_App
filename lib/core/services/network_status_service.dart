import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Service that monitors real-time internet connectivity across the entire application.
class NetworkStatusService {
  static final NetworkStatusService instance = NetworkStatusService._();

  NetworkStatusService._() {
    _init();
  }

  /// Holds the current connectivity state (true = Online, false = Offline).
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  Timer? _timer;

  void _init() {
    checkConnection();
    // Periodically re-check connectivity every 3.5 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      checkConnection();
    });
  }

  /// Checks if real internet connectivity is available.
  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (isOnline.value != online) {
        isOnline.value = online;
      }
      return online;
    } catch (_) {
      if (isOnline.value != false) {
        isOnline.value = false;
      }
      return false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// A reactive badge pill that displays GREEN "ONLINE" when connected,
/// and RED "OFFLINE" with alert styling when disconnected.
class OnlineStatusBadge extends StatefulWidget {
  final double? fontSize;
  final double? dotSize;
  final EdgeInsetsGeometry? padding;

  const OnlineStatusBadge({
    super.key,
    this.fontSize,
    this.dotSize,
    this.padding,
  });

  @override
  State<OnlineStatusBadge> createState() => _OnlineStatusBadgeState();
}

class _OnlineStatusBadgeState extends State<OnlineStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.82, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatusService.instance.isOnline,
      builder: (context, isOnline, _) {
        final color = isOnline
            ? const Color(0xFF34D399) // Vivid Green
            : const Color(0xFFF87171); // Alert Red

        final text = isOnline ? 'ONLINE' : 'OFFLINE';

        return GestureDetector(
          onTap: () => NetworkStatusService.instance.checkConnection(),
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isOnline ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: isOnline ? 0.35 : 0.55),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: isOnline
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: widget.dotSize ?? 7,
                    height: widget.dotSize ?? 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isOnline ? 0.6 : 0.8),
                          blurRadius: isOnline ? 6 : 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: widget.fontSize ?? 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
