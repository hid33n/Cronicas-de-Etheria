// lib/services/notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

/// Modelo de notificación pendiente para persistencia
class _PendingNotification {
  final int id;
  final String title;
  final String body;
  final String assetPath;
  final DateTime fireDate;

  _PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.assetPath,
    required this.fireDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'assetPath': assetPath,
        'fireDate': fireDate.toIso8601String(),
      };

  factory _PendingNotification.fromJson(Map<String, dynamic> j) {
    return _PendingNotification(
      id: j['id'],
      title: j['title'],
      body: j['body'],
      assetPath: j['assetPath'],
      fireDate: DateTime.parse(j['fireDate']),
    );
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flnp =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal para notificaciones importantes',
    importance: Importance.high,
  );

  /// Inicializa zona horaria, canal, plugin y re-agenda pendientes
  Future<void> init() async {
    // 1️⃣ Timezones
    tzData.initializeTimeZones();
    final String tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    // 2️⃣ Crear canal en Android 8+
    await _flnp
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
      ?..createNotificationChannel(_androidChannel);

    // 3️⃣ Inicializar el plugin
    await _flnp.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('Notification tapped: ${resp.payload}');
      },
    );

    // 4️⃣ Re-agendar notificaciones pendientes tras reboot o reinicio de app
    await _reschedulePending();
  }

  /// Carga bytes desde un asset
  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final bd = await rootBundle.load(assetPath);
    return bd.buffer.asUint8List();
  }

  /// Copia asset a temp y devuelve el path
  Future<String> _copyAssetToFile(
      String assetPath, String filename) async {
    final bytes = await _loadAssetBytes(assetPath);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Programa una notificación local con zonedSchedule y persiste
  Future<void> scheduleTrainingDone({
    required int id,
    required String title,
    required String body,
    required DateTime finishTime,
    required String assetPath,
  }) async {
    // Prepara estilo BigPicture si el asset existe
    BigPictureStyleInformation? style;
    String? picPathIos;
    try {
      final picPath = await _copyAssetToFile(assetPath, 'item_$id.png');
      picPathIos = await _copyAssetToFile(assetPath, 'item_ios_$id.png');
      style = BigPictureStyleInformation(
        FilePathAndroidBitmap(picPath),
        largeIcon: FilePathAndroidBitmap(picPath),
        contentTitle: title,
        summaryText: body,
      );
    } catch (_) {
      style = null;
    }

    final scheduledDate = tz.TZDateTime.from(finishTime, tz.local);
    debugPrint('🗓️ Scheduling notification id=$id at $scheduledDate');

    await _flnp.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: style,
        ),
        iOS: DarwinNotificationDetails(
          attachments: style != null && picPathIos != null
              ? [DarwinNotificationAttachment(picPathIos)]
              : [],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: null,
      matchDateTimeComponents: null,
    );

    debugPrint('✅ Notification scheduled id=$id');

    // Persiste en SharedPreferences
    final pending = _PendingNotification(
      id: id,
      title: title,
      body: body,
      assetPath: assetPath,
      fireDate: finishTime,
    );
    await _savePending(pending);
  }

  /// Alias para mejoras de edificio, usando otro rango de IDs
  Future<void> scheduleBuildingDone({
    required int id,
    required String buildingName,
    required DateTime finishTime,
    required String assetPath,
  }) =>
      scheduleTrainingDone(
        id: id + 100000,
        title: 'Mejora completada',
        body: 'Tu $buildingName ya está lista.',
        finishTime: finishTime,
        assetPath: assetPath,
      );

  /// Guarda notificación pendiente en SharedPreferences
  Future<void> _savePending(_PendingNotification p) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pendingNotis') ?? [];
    list.add(jsonEncode(p.toJson()));
    await prefs.setStringList('pendingNotis', list);
  }

  /// Re-agenda todas las notificaciones pendientes
  Future<void> _reschedulePending() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('pendingNotis') ?? [];
    final now = DateTime.now();
    final remaining = <String>[];

    for (var item in list) {
      final p = _PendingNotification.fromJson(jsonDecode(item));
      if (p.fireDate.isAfter(now)) {
        await scheduleTrainingDone(
          id: p.id,
          title: p.title,
          body: p.body,
          finishTime: p.fireDate,
          assetPath: p.assetPath,
        );
        remaining.add(item);
      }
    }
    await prefs.setStringList('pendingNotis', remaining);
  }

  /// Muestra una notificación inmediata
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String? assetPath,
  }) async {
    debugPrint('🚀 Showing immediate notification id=$id');
    BigPictureStyleInformation? style;
    if (assetPath != null) {
      try {
        final pic = await _copyAssetToFile(assetPath, 'imm_$id.png');
        style = BigPictureStyleInformation(
          FilePathAndroidBitmap(pic),
          largeIcon: FilePathAndroidBitmap(pic),
        );
      } catch (_) {
        style = null;
      }
    }
    await _flnp.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: style,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
