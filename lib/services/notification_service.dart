import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> init() async {
    if (kIsWeb)
      return; // flutter_local_notifications is not fully supported on web yet

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    // Configuration iOS complète avec toutes les permissions nécessaires
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // Gestion pour iOS < 10 (déprécié mais nécessaire pour compatibilité)
        if (payload != null) {
          try {
            final payloadData = jsonDecode(payload);
            final type = payloadData['type'];
            final id = payloadData['id'];
            _handleNavigation(type, id);
          } catch (e) {
            print("Failed to parse notification payload: $e");
            navigatorKey.currentState?.pushReplacementNamed('/notifications');
          }
        }
      },
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
          if (notificationResponse.payload != null) {
            try {
              final payloadData = jsonDecode(notificationResponse.payload!);
              final type = payloadData['type'];
              final id = payloadData['id'];
              _handleNavigation(type, id);
            } catch (e) {
              print("Failed to parse notification payload: $e");
              navigatorKey.currentState?.pushReplacementNamed('/notifications');
            }
          } else {
            navigatorKey.currentState?.pushReplacementNamed('/notifications');
          }
        },
      );

      // IMPORTANT: Demander les permissions iOS explicitement
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _requestIOSPermissions();
      }
    } catch (e) {
      print("Erreur d'initialisation des notifications: $e");
    }
  }

  static Future<void> _requestIOSPermissions() async {
    final iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
  }

  static void _handleNavigation(String? type, dynamic id) {
    if (type == 'annonce' && id != null) {
      navigatorKey.currentState?.pushNamed('/annonces');
    } else if (type == 'cours' && id != null) {
      navigatorKey.currentState?.pushNamed('/emploi');
    } else if (type == 'examen' || type == 'examens') {
      navigatorKey.currentState?.pushNamed('/examens');
    } else if (type == 'calendrier') {
      navigatorKey.currentState?.pushNamed('/calendrier');
    } else if (type == 'resultat' || type == 'resultats') {
      navigatorKey.currentState?.pushNamed('/resultats');
    } else {
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  static Future<void> showNativeNotification({
    required int id,
    required String title,
    required String body,
    String? type,
    int? relatedId,
  }) async {
    final payload = jsonEncode({
      'type': type ?? 'general',
      'id': relatedId,
    });

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'estim_campus_channel',
      'ESTIM Campus Notifications',
      channelDescription: 'Notifications pour l\'application ESTIM Campus',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: false,
      enableVibration: false,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics,
        payload: payload);
  }

  // Méthode pour annuler une notification spécifique
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Méthode pour annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
