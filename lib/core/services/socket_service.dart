import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  StreamSubscription? _subscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Function(dynamic)? _onNewOrderCallback;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  void init() {
    print('✅ Initializing Firebase Admin Notification Listener');
    _initNotifications();

    // ... existing firestore listener code ...

    // Listen to the 'admin_notifications' collection
    // Removed 'where' clause to avoid "Missing Index" errors on dev environment
    _subscription = _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(10) // Listen to last 10
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data();
          // Filter in memory
          final bool isRead = data?['isRead'] ?? false;

          if (!isRead) {
            print('🔔 New Order Notification Received: ${data?['title']}');

            if (_onNewOrderCallback != null && data != null) {
              // Fetch full order details to pass to the dialog
              _fetchAndNotify(data['orderId'], data);

              // Mark as read immediately so it doesn't pop up again
              doc.doc.reference.update({'isRead': true});
            }
          }
        }
      }
    });
  }

  Future<void> _fetchAndNotify(
      String? orderId, Map<String, dynamic> notificationData) async {
    if (orderId == null) return;
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final orderData = doc.data()!;
        // Construct the data structure expected by the existing UI dialog
        final uiData = {
          'order': orderData,
          'services': orderData['services'] ?? [],
          'address': orderData['address'] ?? {},
          'orderNumber': orderData['orderNumber'],
          'amount': orderData['priceSummary']?['total'],
          'customerName': orderData['address']?['name'] ?? 'Guest',
          'createdAt': orderData['createdAt'] is Timestamp
              ? (orderData['createdAt'] as Timestamp).toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        };

        _onNewOrderCallback?.call(uiData);
        _showNotification(
            title: 'New Order',
            body: 'Order #${orderData['orderNumber']} has been received');
      }
    } catch (e) {
      print('Error fetching order for notification: $e');
    }
  }

  Future<void> startRinging() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Could not start ringing: $e');
    }
  }

  Future<void> _initNotifications() async {
    // 1. Initialize Local Notifications (keep existing config)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Explicitly request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Explicitly request permission for iOS/macOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // 2. Request FCM Permissions (Crucial for Web)
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 User granted permission: ${settings.authorizationStatus}');

      // 4. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Foreground Message Received: ${message.notification?.title}');
        _showNotification(
          title: message.notification?.title ?? 'Update',
          body: message.notification?.body ?? '',
        );
      });

      // 3. Get Token (to verify connection)
      try {
        final token = await messaging.getToken(
          vapidKey:
              'BE3HNie56n4PrfkkOjgeFbDusti6VFCsAxQOcZh56-5l7DbrTIyuyDmylbzjKBsLfAvlEMTaKCZsYKmOhpbzsMk', 
        );
        print('🔑 Admin FCM Token: $token');
      } catch (e) {
        print('❌ FCM Token not available (likely blocked): $e');
      }

    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'cloud_wash_admin_notifications',
      'Cloud Wash Admin Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  Future<void> stopRinging() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  void onNewOrder(Function(dynamic) callback) {
    _onNewOrderCallback = callback;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
