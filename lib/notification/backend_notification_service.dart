import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

/// Backend-based notification service that polls the server for new notifications
/// instead of relying on Firebase Cloud Messaging.
class BackendNotificationService {
  static final BackendNotificationService _instance =
      BackendNotificationService._internal();
  factory BackendNotificationService() => _instance;
  BackendNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Timer? _pollingTimer;
  String? _lastNotificationId;
  bool _isInitialized = false;

  /// Initialize the local notification plugin
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'smart_parking_channel',
      'Smart Parking',
      description: 'Notifications de réservation Smart Parking',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  /// Start polling for new notifications
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    stopPolling();
    _pollingTimer = Timer.periodic(interval, (_) => _checkForNotifications());
    // Also check immediately
    _checkForNotifications();
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check backend for new notifications
  Future<void> _checkForNotifications() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return;

      final uri = Uri.parse('${AuthService.baseUrl}/notifications/unread');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List<dynamic>? ?? [];

        for (final notification in notifications) {
          final notifId = notification['_id']?.toString();
          if (notifId != null && notifId != _lastNotificationId) {
            _lastNotificationId = notifId;
            await _showLocalNotification(
              title: notification['title'] ?? 'Smart Parking',
              body: notification['message'] ?? '',
              payload: json.encode(notification),
            );
            // Mark as read
            await _markAsRead(notifId, token);
          }
        }
      }
    } catch (e) {
      debugPrint('Notification polling error: $e');
    }
  }

  /// Mark a notification as read on the backend
  Future<void> _markAsRead(String notificationId, String token) async {
    try {
      await http.put(
        Uri.parse(
            '${AuthService.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Show a local notification on the device
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_parking_channel',
      'Smart Parking',
      channelDescription: 'Notifications de réservation Smart Parking',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Send a booking notification (called when a reservation is created)
  static Future<bool> sendBookingNotification({
    required String bookingId,
    required String parkingName,
    required String date,
    required String time,
  }) async {
    try {
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/notifications/booking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'parkingName': parkingName,
          'date': date,
          'time': time,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending booking notification: $e');
      return false;
    }
  }

  /// Show an immediate local notification for booking confirmation
  Future<void> showBookingConfirmation({
    required String parkingName,
    required String date,
    required String time,
  }) async {
    await initialize();
    await _showLocalNotification(
      title: 'Réservation confirmée ✅',
      body: 'Votre place à $parkingName est réservée pour le $date à $time.',
    );
  }

  /// Show an immediate local notification for booking cancellation
  Future<void> showBookingCancellation({
    required String parkingName,
  }) async {
    await initialize();
    await _showLocalNotification(
      title: 'Réservation annulée',
      body: 'Votre réservation à $parkingName a été annulée.',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to booking details
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
  }
}
