import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central Notification Service for WeSafe.
/// Handles:
/// 1. Native Android System Notifications (Status bar & Notification Shade)
/// 2. In-App Floating Tactical Alert Banners
/// 3. Haptic feedback on auto-sync events
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Global Key to allow in-app notifications anywhere in the app
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Global Key for navigator to route from notification bar taps
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _channelsRegistered = false;

  /// Initializes the local notifications plugin for Android & iOS.
  Future<void> initialize() async {
    if (_isInitialized) {
      await registerChannels();
      return;
    }
    _isInitialized = true;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    await registerChannels();

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully with channels.');
  }

  /// Registers high-priority notification channels with Android OS.
  Future<void> registerChannels() async {
    if (_channelsRegistered) return;
    try {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();

        const disasterChannel = AndroidNotificationChannel(
          'c1_disaster_warnings',
          'Disaster Early Warnings',
          description:
              'Real-time flood, rain, and evacuation warnings for citizens.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        const broadcastChannel = AndroidNotificationChannel(
          'c4_broadcast_alerts',
          'Control Center Alerts',
          description: 'Warnings broadcast by the Disaster Control Center.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        const syncChannel = AndroidNotificationChannel(
          'hazard_auto_sync_channel',
          'Hazard Auto-Sync',
          description:
              'Alerts when offline hazard reports are auto-submitted to cloud.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        await androidPlugin.createNotificationChannel(disasterChannel);
        await androidPlugin.createNotificationChannel(broadcastChannel);
        await androidPlugin.createNotificationChannel(syncChannel);
        _channelsRegistered = true;
        debugPrint('Registered all notification channels in Android OS.');
      }
    } catch (e) {
      debugPrint('Error registering notification channels: $e');
    }
  }

  /// Displays both a native system notification and an in-app banner
  /// when an offline report is automatically submitted to Firestore.
  Future<void> showReportAutoSubmittedNotification({
    required String hazardType,
    required String location,
    int count = 1,
  }) async {
    // 1. Play tactical haptic vibration
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    final title = count > 1
        ? '🛰️ $count Offline Reports Auto-Submitted!'
        : '🛰️ Hazard Report Auto-Submitted!';
    final body = count > 1
        ? '$count queued reports have been verified and transmitted to Disaster Operations Room.'
        : 'Your offline report for "$hazardType" in $location has been successfully uploaded to Disaster Operations Room.';

    // 2. Trigger Android System Notification
    try {
      const androidDetails = AndroidNotificationDetails(
        'hazard_auto_sync_channel',
        'Hazard Auto-Sync',
        channelDescription:
            'Alerts when offline hazard reports are auto-submitted to cloud.',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF34D399),
        ledColor: Color(0xFF34D399),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableLights: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'hazard_auto_sync',
      );
    } catch (e) {
      debugPrint('Error triggering system notification: $e');
    }

    // 3. Trigger In-App Tactical Banner
    _showInAppSyncBanner(
      title: title,
      body: body,
      hazardType: hazardType,
    );
  }

  /// Sound + phone notification for a broadcast warning sent from the
  /// Control Center (Component 4) and shown to camp leaders (Component 3).
  Future<void> showBroadcastAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      const androidDetails = AndroidNotificationDetails(
        'c4_broadcast_alerts',
        'Control Center Alerts',
        channelDescription: 'Warnings broadcast by the Disaster Control Center.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Color(0xFFF87171),
      );
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: 'c4_broadcast',
      );
    } catch (e) {
      debugPrint('Broadcast notification failed: $e');
    }
  }

  /// Sound + system notification + in-app alert for live disaster warnings (Component 1).
  Future<void> showDisasterWarningNotification({
    required int id,
    required String title,
    required String body,
    required String severity,
  }) async {
    final isCritical = severity.toLowerCase() == 'critical';
    final alertColor = isCritical ? const Color(0xFFFF1744) : const Color(0xFFFF9F0A);
    final safeId = id & 0x7FFFFFFF;

    await registerChannels();

    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    try {
      final androidDetails = AndroidNotificationDetails(
        'c1_disaster_warnings',
        'Disaster Early Warnings',
        channelDescription:
            'Real-time flood, rain, and evacuation warnings for citizens.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ticker: title,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        color: alertColor,
        ledColor: alertColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: '🚨 Disaster Early Warning',
        ),
      );

      await _localNotifications.show(
        id: safeId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
        payload: 'c1_warning',
      );
      debugPrint('Posted notification to phone notification bar: $title');
    } catch (e) {
      debugPrint('Disaster warning notification failed: $e');
    }

    _showInAppDisasterBanner(
      title: title,
      body: body,
      severity: severity,
    );
  }

  /// Sends a test emergency disaster alert directly to the phone notification bar.
  Future<void> showTestWarningNotification({
    String severity = 'Critical',
    String district = 'Galle',
  }) async {
    await showDisasterWarningNotification(
      id: 99901,
      title: '🚨 $severity Alert: Rising Flood Waters in $district',
      body:
          'Dangerous water levels detected (3.8m). Evacuation routes active. Tap to view safe shelter routing.',
      severity: severity,
    );
  }

  /// Displays an in-app tactical floating warning banner.
  void _showInAppDisasterBanner({
    required String title,
    required String body,
    required String severity,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final isCritical = severity.toLowerCase() == 'critical';
    final accentColor = isCritical ? const Color(0xFFFF1744) : const Color(0xFFFF9F0A);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 14, left: 14, right: 14, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: const Color(0xFF131B2B),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor, width: 1.5),
        ),
        duration: const Duration(seconds: 6),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays an in-app banner at the top of the current screen.
  void _showInAppSyncBanner({
    required String title,
    required String body,
    required String hazardType,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 14, left: 14, right: 14, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: const Color(0xFF0A1526),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF34D399), width: 1.2),
        ),
        duration: const Duration(seconds: 5),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                color: Color(0xFF34D399),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SYNCED',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFB6C2D6),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
