import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';
import '../models/offline_hazard_report.dart';
import 'offline_hazard_database.dart';

/// Offline Report Queue & Auto-Sync Service backed by SQLite persistent storage.
/// Manages locally stored disaster hazard reports when there is no internet.
/// Periodically monitors internet connection and automatically broadcasts
/// queued reports to Firebase Firestore as soon as device reconnects to a signal.
class OfflineReportService {
  static final OfflineReportService instance = OfflineReportService._();
  OfflineReportService._() {
    _initAutoSync();
  }

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _cachedPendingCount = 0;

  void _initAutoSync() {
    _refreshCachedCount();
    // Run background auto-sync check every 12 seconds
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      autoSyncPendingReports();
    });
  }

  Future<void> _refreshCachedCount() async {
    try {
      _cachedPendingCount =
          await OfflineHazardDatabase.instance.getPendingCount();
    } catch (_) {}
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

  int get pendingCount => _cachedPendingCount;

  /// Returns actual live pending count from SQLite.
  Future<int> getLivePendingCount() async {
    try {
      _cachedPendingCount =
          await OfflineHazardDatabase.instance.getPendingCount();
    } catch (_) {}
    return _cachedPendingCount;
  }

  /// Enqueues a new hazard report to SQLite offline storage as PENDING_SYNC.
  Future<void> queueReport(Map<String, dynamic> reportData) async {
    final now = DateTime.now();
    final localId = reportData['localId'] as String? ??
        '#OFF-${now.millisecondsSinceEpoch ~/ 1000}';

    final report = OfflineHazardReport(
      id: localId,
      hazardType: reportData['hazardType'] as String? ?? 'Hazard',
      severity: reportData['severity'] as String? ?? 'MEDIUM',
      description: reportData['description'] as String? ?? '',
      location: reportData['location'] as String? ?? 'Field Location',
      latitude: (reportData['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (reportData['longitude'] as num?)?.toDouble() ?? 79.8612,
      reporterName: reportData['reporterName'] as String? ?? 'Volunteer',
      reporterEmail: reportData['reporterEmail'] as String? ?? '',
      photoPath: reportData['photoPath'] as String?,
      hasPhoto: reportData['hasPhoto'] as bool? ?? false,
      status: 'PENDING_SYNC',
      createdAt: now,
      updatedAt: now,
    );

    await OfflineHazardDatabase.instance.insertReport(report);
    await _refreshCachedCount();
    debugPrint('Report added to SQLite offline storage. ID: $localId, Total pending: $_cachedPendingCount');
  }

  /// Saves a draft report directly into SQLite.
  Future<void> saveDraft(OfflineHazardReport draft) async {
    await OfflineHazardDatabase.instance.insertReport(draft);
    await _refreshCachedCount();
  }

  /// Automatically syncs all queued reports to Firestore when signal is restored.
  Future<int> autoSyncPendingReports() async {
    if (_isSyncing) return 0;

    final isOnline = await checkOnline();
    if (!isOnline) return 0;

    final pendingReports =
        await OfflineHazardDatabase.instance.getPendingReports();
    if (pendingReports.isEmpty) {
      _cachedPendingCount = 0;
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;
    String lastHazard = 'Hazard';
    String lastLocation = 'Field Sector';
    debugPrint('Signal restored! Auto-submitting ${pendingReports.length} SQLite pending reports...');

    for (var report in pendingReports) {
      try {
        final payload = report.toFirestoreMap();
        payload['syncedAt'] = FieldValue.serverTimestamp();
        payload['timestamp'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('hazard_reports')
            .add(payload)
            .timeout(const Duration(seconds: 4));

        // Mark as SYNCED in SQLite
        await OfflineHazardDatabase.instance.markAsSynced(report.id);
        syncedCount++;
        lastHazard = report.hazardType;
        lastLocation = report.location;
        debugPrint('Successfully synced offline report: ${report.id} - ${report.hazardType}');
      } catch (e) {
        debugPrint('Failed to sync offline report ${report.id}, keeping in queue: $e');
      }
    }

    await _refreshCachedCount();

    // Trigger Notification for auto-submitted reports!
    if (syncedCount > 0) {
      NotificationService.instance.showReportAutoSubmittedNotification(
        hazardType: lastHazard,
        location: lastLocation,
        count: syncedCount,
      );
    }

    _isSyncing = false;
    return syncedCount;
  }

  /// Manually syncs a single offline report to Firestore.
  Future<bool> syncSingleReport(OfflineHazardReport report) async {
    final isOnline = await checkOnline();
    if (!isOnline) return false;

    try {
      final payload = report.toFirestoreMap();
      payload['syncedAt'] = FieldValue.serverTimestamp();
      payload['timestamp'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('hazard_reports')
          .add(payload)
          .timeout(const Duration(seconds: 4));

      await OfflineHazardDatabase.instance.markAsSynced(report.id);
      await _refreshCachedCount();

      NotificationService.instance.showReportAutoSubmittedNotification(
        hazardType: report.hazardType,
        location: report.location,
        count: 1,
      );
      return true;
    } catch (e) {
      debugPrint('Manual sync single report failed: $e');
      return false;
    }
  }
}
