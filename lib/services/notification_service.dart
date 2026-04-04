import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:setting_group_debits/services/log_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request permissions (iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log.info('Firebase: User granted notification permission');
    }

    // 2. Setup Local Notifications (for foreground messages)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(settings: initSettings);

    // 3. Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log.info('Firebase: Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 5. Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log.info('Firebase: App opened via notification: ${message.data}');
    });
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      log.warning('Firebase: getToken error (expected on simulator): $e');
      return null;
    }
  }

  Future<void> subscribeToGroup(String syncId) async {
    try {
      await _fcm.subscribeToTopic('group_$syncId');
      log.info('Firebase: Subscribed to group_$syncId');
    } catch (e) {
      log.warning('Firebase: subscribeToTopic error (expected on simulator): $e');
    }
  }

  Future<void> unsubscribeFromGroup(String syncId) async {
    try {
      await _fcm.unsubscribeFromTopic('group_$syncId');
    } catch (e, s) {
      log.error('Firebase: unsubscribeFromTopic error', e, s);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    if (message.notification == null) return;
    
    final notification = message.notification!;
    const androidDetails = AndroidNotificationDetails(
      'billshare_channel',
      'BillShare Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
    );
  }
}

// Global background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log.info('Firebase: Handling background message ${message.messageId}');
}
