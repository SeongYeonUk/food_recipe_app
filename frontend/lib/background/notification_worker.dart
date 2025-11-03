// lib/background/notification_worker.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String dailyNotificationTask = 'daily_notification_task';
const String notificationChannelIdIngredient = 'ingredient_alerts';
const String notificationChannelIdRecipe = 'recipe_recommendations_v2';

final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

Future<bool> runDailyNotificationTask() async {
    // Initialize notifications (Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    // Prepare channels
    const ingredientChannel = AndroidNotificationChannel(
      notificationChannelIdIngredient,
      'Ingredient Alerts',
      description: 'Expiry alerts at 7 and 3 days',
      importance: Importance.high,
    );
    const recipeChannel = AndroidNotificationChannel(
      notificationChannelIdRecipe,
      'Recipe Recommendations',
      description: 'Daily top recipe recommendation',
      importance: Importance.high,
    );

    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(ingredientChannel);
      await android.createNotificationChannel(recipeChannel);
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Time gating: run only around configured time once per day
      final now = DateTime.now();
      final notifTime = prefs.getString('notification_time') ?? '18:00';
      final parts = notifTime.split(':');
      final target = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

      // Allow a 15-minute window (WorkManager minimum period) and only once per day
      final lastRunDay = prefs.getString('last_notification_day');
      if (lastRunDay == '${now.year}-${now.month}-${now.day}') {
        return true;
      }
      final diffMinutes = now.difference(target).inMinutes;
      if (diffMinutes < -15 || diffMinutes > 15) {
        return true;
      }

      // Only-at-home gating (+ one-time bypass)
      final bypassHomeOnce = prefs.getBool('bypass_home_gate_once') ?? false;
      final onlyAtHome = prefs.getBool('geofence_enabled') ?? false; // reuse geofence toggle
      if (!bypassHomeOnce && onlyAtHome) {
        final isAtHome = prefs.getBool('is_at_home') ?? false;
        if (!isAtHome) {
          // Skip if not at home
          prefs.setString('last_notification_day', '${now.year}-${now.month}-${now.day}');
          return true;
        }
      }
      if (bypassHomeOnce) {
        await prefs.remove('bypass_home_gate_once');
      }

      // Determine if ingredient alert should be sent today based on precomputed schedule
      bool sendIngredientToday = true; // default true if no schedule stored
      try {
        final scheduleJson = prefs.getString('ingredient_notification_schedule');
        if (scheduleJson != null) {
          final Map<String, dynamic> schedule = jsonDecode(scheduleJson);
          final key = _ymd(now);
          if (schedule.containsKey(key)) {
            sendIngredientToday = schedule[key] == true;
          }
        }
      } catch (_) {}

      // Compute ingredient counts from cached ingredients
      if (sendIngredientToday) {
        final cached = prefs.getString('cached_ingredients');
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          int danger = 0; // 3 days
          int caution = 0; // 7 days
          for (final item in list) {
            final expiryStr = item['expiryDate'] as String?;
            if (expiryStr == null) continue;
            final expiry = DateTime.tryParse(expiryStr);
            if (expiry == null) continue;
            final daysLeft = expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
            if (daysLeft == 3) danger++;
            if (daysLeft == 7) caution++;
          }
          // Calmtech: only notify if any, and aggregate into one message
          if (danger > 0 || caution > 0) {
            final parts = <String>[];
            if (danger > 0) parts.add('위험 3일 이내: $danger개');
            if (caution > 0) parts.add('주의 7일 이내: $caution개');
            final body = parts.join(' · ');
            await _notifications.show(
              1001,
              '식재료 유통기한 알림',
              body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  notificationChannelIdIngredient,
                  'Ingredient Alerts',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              payload: 'ingredient',
            );
          }
        }
      }

      // Always propose top recipe recommendation (content fetched on open)
      await _notifications.show(
        1002,
        '오늘의 추천 레시피',
        '최고 점수 레시피를 확인해보세요!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelIdRecipe,
            'Recipe Recommendations',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: 'recipe',
      );

      await prefs.setString('last_notification_day', '${now.year}-${now.month}-${now.day}');
    } catch (_) {
      // swallow errors in background
    }
    return true;
}

String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';
