import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Offline-first support for the whole app.
///
/// * Firestore keeps an on-phone copy of everything the app has read, and
///   queues every write made without internet. When the internet comes back
///   the queue is sent to the server automatically.
/// * [QueuedWrite.queued] stops a screen from waiting forever for the server
///   when there is no internet (the write is already saved on the phone).
class OfflineSync {
  OfflineSync._();

  /// Call once, right after Firebase.initializeApp().
  static void init() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('OfflineSync init: $e');
    }
  }

  /// True when the phone really reaches the internet.
  static Future<bool> hasInternet() async {
    try {
      final r = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 3));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

extension QueuedWrite on Future<void> {
  /// Completes when the server confirms the write OR after [wait] — whichever
  /// is first. Offline, the write is already stored on the phone and is sent
  /// automatically later, so the screen can carry on instead of hanging.
  Future<void> queued({Duration wait = const Duration(seconds: 3)}) =>
      timeout(wait, onTimeout: () {});
}

/// Slim banner shown while the phone has no internet.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _timer;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _check());
  }

  Future<void> _check() async {
    final ok = await OfflineSync.hasInternet();
    if (mounted && _offline == ok) setState(() => _offline = !ok);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Material(
                color: const Color(0xFFFF6D00),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: const Text(
                      'Offline – saved on this phone, will sync automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

extension QueuedAdd<T> on Future<DocumentReference<T>> {
  /// Same as [QueuedWrite.queued] for `collection.add(...)` calls whose
  /// returned reference is not needed.
  Future<void> queued({Duration wait = const Duration(seconds: 3)}) =>
      then<void>((_) {}).timeout(wait, onTimeout: () {});
}
