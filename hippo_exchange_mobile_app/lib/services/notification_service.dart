// File: lib/services/notification_service.dart
// A small, dependency-light notification system built around flutter_local_notifications
// plus SharedPreferences for a simple in-app "inbox".
//
// Add to pubspec.yaml:
//   dependencies:
//     shared_preferences: ^2.2.3
//   dev_dependencies: 
//   (none)
//  
//   (Optional – for system tray/banners):
//   dependencies:
//     flutter_local_notifications: ^17.2.1
//
// Android: add POST_NOTIFICATIONS permission for API 33+ in AndroidManifest.xml:
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
//
// iOS: request permission via initialize() (already handled).
//
// Usage:
//   await NotificationService.instance.initialize();
//   await NotificationService.instance.notifyLocal(
//     title: "Item added",
//     body: '“$name” was added successfully.',
//     payload: {"type": "item_added", "itemId": id},
//   );
//
//   // To read items (for the inbox):
//   final all = await NotificationService.instance.getAll();
//

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// If you want system notifications (banner/tray), enable this import and pubspec dep.
// Then set `enableSystemNotifications: true` when calling initialize().
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.payload,
    required this.read,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        payload: payload,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
        'read': read,
      };

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        payload: (j['payload'] as Map).map((k, v) => MapEntry(k.toString(), v)),
        read: j['read'] as bool? ?? false,
      );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _prefsKey = 'app_notifications_v1';
  static const _channelId = 'local_notifications_default';
  static const _channelName = 'Local Notifications';
  static const _channelDesc = 'General app notifications';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({bool enableSystemNotifications = true}) async {
    if (_initialized) return;

    // Local notifications initialization
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      // Tap handling - could route to a screen using payload
      debugPrint('Notification tapped: ${resp.payload}');
    });

    if (enableSystemNotifications) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.defaultImportance,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    return raw
        .map((s) => AppNotification.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<int> getUnreadCount() async {
    final all = await getAll();
    return all.where((n) => !n.read).length;
  }

  Future<void> markAllRead() async {
    final all = await getAll();
    final updated = all.map((n) => n.copyWith(read: true)).toList();
    await _saveAll(updated);
  }

  Future<void> deleteById(String id) async {
    final all = await getAll();
    final updated = all.where((n) => n.id != id).toList();
    await _saveAll(updated);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> notifyLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    bool showSystemBanner = true,
  }) async {
    final n = AppNotification(
      id: UniqueKey().toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      payload: payload ?? const {},
      read: false,
    );

    // Save to inbox
    final all = await getAll();
    all.add(n);
    await _saveAll(all);

    // Optionally show system banner
    if (showSystemBanner) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(
        n.id.hashCode, // unique int
        title,
        body,
        platformDetails,
        payload: jsonEncode(n.payload),
      );
    }
  }

  Future<void> _saveAll(List<AppNotification> all) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = all.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, raw);
  }
}
