import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _messaging;
  static bool _initialized = false;

  // Initialize Firebase Messaging and Local Notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // Request permission for iOS
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('User granted provisional permission');
        }
      } else {
        if (kDebugMode) {
          print('User declined or has not accepted permission');
        }
        return;
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'smart_parking_channel',
        'Smart Parking Notifications',
        description: 'Notifications for parking bookings and updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Set up foreground notification presentation options
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Received foreground message: ${message.messageId}');
        }
        _showLocalNotification(message);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Notification tapped: ${message.messageId}');
        }
        _handleNotificationTap(message.data);
      });

      // Get FCM token
      String? token = await _messaging!.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _sendTokenToServer(token);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen(_sendTokenToServer);

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  // Send FCM token to backend
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) return;

      await http.post(
        Uri.parse('${AuthService.baseUrl}/users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (kDebugMode) {
        print('FCM token sent to server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM token: $e');
      }
    }
  }

  // Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'smart_parking_channel',
      'Smart Parking Notifications',
      channelDescription: 'Notifications for parking bookings and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(message.data),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // Navigation logic based on notification type
    final type = data['type'];
    if (kDebugMode) {
      print('Notification tapped with type: $type');
    }
    // TODO: Implement navigation based on notification type
    // Example: Navigate to booking details, promotions, etc.
  }

  // Send local notification (for testing or manual triggers)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_parking_channel',
      'Smart Parking Notifications',
      channelDescription: 'Notifications for parking bookings and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data != null ? json.encode(data) : null,
    );
  }

  // Schedule booking reminder notification
  static Future<void> scheduleBookingReminder({
    required String bookingId,
    required String parkingName,
    required DateTime bookingTime,
  }) async {
    // Schedule notification 30 minutes before booking
    final reminderTime = bookingTime.subtract(const Duration(minutes: 30));
    
    if (reminderTime.isBefore(DateTime.now())) {
      return; // Don't schedule if time has passed
    }

    // For now, just show immediate notification for testing
    // In production, you would use timezone package to schedule properly
    await showLocalNotification(
      title: 'Rappel de réservation',
      body: 'Votre réservation à $parkingName commence dans 30 minutes',
      data: {
        'type': 'booking_reminder',
        'bookingId': bookingId,
      },
    );
  }

  // Cancel scheduled notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get FCM token
  static Future<String?> getToken() async {
    return await _messaging?.getToken();
  }

  // Unsubscribe from notifications (call on logout)
  static Future<void> unsubscribe() async {
    try {
      await _messaging?.deleteToken();
      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }
}
