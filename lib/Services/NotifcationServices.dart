
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  // Firebase handles displaying notification messages in the background.
  // Do not send notifications from this handler.
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'studymate_notifications',
    'StudyMate Notifications',
    description: 'Assignment and academic updates',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification == null) return;

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? 'StudyMate Update',
        body: notification.body ?? 'You have a new academic update.',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // Save the token after login, and whenever the user changes.
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveToken(user.uid);
      }
    });

    // Update the database when Firebase refreshes the phone token.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _saveToken(user.uid, token);
      }
    });

    // Also request a token for a user who is already logged in.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _saveToken(user.uid);
    }
  }

  static Future<void> _saveToken(
      String uid, [
        String? refreshedToken,
      ]) async {
    try {
      final token =
          refreshedToken ?? await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) return;

      await FirebaseDatabase.instance
          .ref('users/$uid/fcmToken')
          .set(token);

      debugPrint('StudyMate FCM token saved for user: $uid');
    } catch (e) {
      debugPrint('Could not save StudyMate FCM token: $e');
    }
  }
}
