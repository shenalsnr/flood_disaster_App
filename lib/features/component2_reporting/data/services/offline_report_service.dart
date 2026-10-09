import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Offline Report Queue & Auto-Sync Service.
/// Manages locally stored disaster hazard reports when there is no internet.
/// Periodically monitors internet connection and automatically broadcasts
/// queued reports to Firebase Firestore as soon as device reconnects to a signal.
class OfflineReportService {
  static final OfflineReportService instance = OfflineReportService._();
  OfflineReportService._() {
    _initAutoSync();
  }

  Timer? _syncTimer;
  final List<Map<String, dynamic>> _memoryQueue = [];
  bool _isSyncing = false;

  File get _queueFile {
    final primaryDir = Directory('/data/user/0/com.example.flood_disaster/files');
    if (primaryDir.existsSync()) {
      return File('${primaryDir.path}/offline_hazard_queue.json');
    }
    final fallbackDir = Directory('/data/data/com.example.flood_disaster/files');
    if (fallbackDir.existsSync()) {
      return File('${fallbackDir.path}/offline_hazard_queue.json');
    }
    return File('${Directory.systemTemp.path}/offline_hazard_queue.json');
  }

  void _initAutoSync() {
    _loadFromDisk();
    // Run background auto-sync check every 12 seconds
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      autoSyncPendingReports();
    });
  }

  void _loadFromDisk() {
    try {
      final file = _queueFile;
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(content);
          _memoryQueue.clear();
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              _memoryQueue.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading offline queue: $e');
    }
  }

  void _saveToDisk() {
    try {
      final file = _queueFile;
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(jsonEncode(_memoryQueue));
    } catch (e) {
      debugPrint('Error saving offline queue to disk: $e');
    }
  }

  /// Verifies active internet connectivity by checking Google DNS.
  Future<bool> checkOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 2500));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('Network offline check: $e');
    }
    return false;
  }

  int get pendingCount {
    if (_memoryQueue.isEmpty) {
      _loadFromDisk();
    }
    return _memoryQueue.length;
  }

  /// Enqueues a new hazard report to offline storage.
  Future<void> queueReport(Map<String, dynamic> reportData) async {
    _memoryQueue.add(reportData);
    _saveToDisk();
    debugPrint('Report added to offline queue. Total pending: ${_memoryQueue.length}');
  }

  /// Automatically syncs all queued reports to Firestore when signal is restored.
  Future<int> autoSyncPendingReports() async {
    if (_isSyncing || _memoryQueue.isEmpty) return 0;

    final isOnline = await checkOnline();
    if (!isOnline) return 0;

    _isSyncing = true;
    int syncedCount = 0;
    debugPrint('Signal restored! Auto-submitting ${_memoryQueue.length} pending reports...');

    final List<Map<String, dynamic>> remaining = [];

    for (var report in _memoryQueue) {
      try {
        final reportPayload = Map<String, dynamic>.from(report);
        reportPayload.remove('localId');
        reportPayload['syncedAt'] = FieldValue.serverTimestamp();
        reportPayload['timestamp'] = FieldValue.serverTimestamp();
        reportPayload['status'] = 'VERIFIED';
        reportPayload['isVerified'] = true;

        await FirebaseFirestore.instance
            .collection('hazard_reports')
            .add(reportPayload)
            .timeout(const Duration(seconds: 4));

        syncedCount++;
        debugPrint('Successfully synced offline report: ${report['hazardType']}');
      } catch (e) {
        debugPrint('Failed to sync offline report, keeping in queue: $e');
        remaining.add(report);
      }
    }

    _memoryQueue.clear();
    _memoryQueue.addAll(remaining);
    _saveToDisk();

    _isSyncing = false;
    return syncedCount;
  }
}
