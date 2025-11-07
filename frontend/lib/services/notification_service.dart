// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:food_recipe_app/common/api_client.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:food_recipe_app/background/notification_worker.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../background/notification_worker.dart';
import '../services/calendar_client.dart';

class NotificationService {
  // Default daily time 18:00
  static const String _prefTime = 'notification_time';

  static Future<void> ensureScheduledBackground() async {
    // Register a 15-minute periodic check; it will self-gate to fire once daily
    await Workmanager().registerPeriodicTask(
      'daily_notification_periodic',
      dailyNotificationTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    await prefs.setString(_prefTime, '$hh:$mm');
  }

  static Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefTime) ?? '18:00';
    final p = raw.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  // Build an 8-day ingredient notification schedule considering calendar events.
  // Writes a date->bool map to SharedPreferences ('ingredient_notification_schedule').
  static Future<void> buildIngredientSchedule(BuildContext context, List<IngredientLite> ingredients) async {
    final prefs = await SharedPreferences.getInstance();

    // Compute candidate dates for alerts (7 and 3 days before expiry)
    final Map<String, bool> schedule = {};
    final Map<String, Map<String, int>> counts = {}; // { 'YYYY-M-D': { 'd3': n, 'd7': n } }
    final Map<String, Map<String, List<String>>> names = {}; // { 'YYYY-M-D': { 'd3': [...], 'd7': [...] } }
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 8));

    // Calendar events lookup via provider
    final cal = context.read<CalendarClient>();
    Map<DateTime, List<calendar.Event>> events = {};
    if (cal.isLoggedIn) {
      try {
        events = await cal.getEvents(startTime: start, endTime: end);
      } catch (_) {}
    }

    for (final ing in ingredients) {
      final d7 = DateTime(ing.expiry.year, ing.expiry.month, ing.expiry.day).subtract(const Duration(days: 7));
      final d3 = DateTime(ing.expiry.year, ing.expiry.month, ing.expiry.day).subtract(const Duration(days: 3));
      for (final target in [d7, d3]) {
        if (target.isBefore(start) || target.isAfter(end)) continue;
        DateTime notifyDay = target;
        // If calendar has events on target, shift one day earlier
        final key = DateTime(target.year, target.month, target.day);
        if (events[key]?.isNotEmpty == true) {
          notifyDay = target.subtract(const Duration(days: 1));
        }
        final ymd = _ymd(notifyDay);
        schedule[ymd] = true; // any ingredient makes that day "true"
        // track counts by type
        counts.putIfAbsent(ymd, () => { 'd3': 0, 'd7': 0 });
        if (target == d3) {
          counts[ymd]!['d3'] = (counts[ymd]!['d3'] ?? 0) + 1;
          names.putIfAbsent(ymd, () => { 'd3': <String>[], 'd7': <String>[] });
          names[ymd]!['d3']!.add(ing.name);
        } else {
          counts[ymd]!['d7'] = (counts[ymd]!['d7'] ?? 0) + 1;
          names.putIfAbsent(ymd, () => { 'd3': <String>[], 'd7': <String>[] });
          names[ymd]!['d7']!.add(ing.name);
        }
      }
    }

    await prefs.setString('ingredient_notification_schedule', jsonEncode(schedule));
    await prefs.setString('ingredient_notification_schedule_counts', jsonEncode(counts));
    await prefs.setString('ingredient_notification_schedule_names', jsonEncode(names));
  }

  // Debug helper: trigger notifications immediately in foreground to validate setup
  static Future<void> debugSendNow(BuildContext context) async {
    // Ensure permission on Android 13+
    await Permission.notification.request();

    // Reuse the background logic indirectly by showing notifications based on cache
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Honor "집에서만 보기" gating to match real behavior
    final onlyAtHome = prefs.getBool('geofence_enabled') ?? false;
    if (onlyAtHome) {
      final isAtHome = prefs.getBool('is_at_home') ?? false;
      if (!isAtHome) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('집에서만 보기 설정으로 인해 알림이 차단되었어요.')), 
          );
        }
        return;
      }
    }

    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);

    // Create channels if missing
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
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(ingredientChannel);
      await android.createNotificationChannel(recipeChannel);
    }

    // Ingredient aggregation
    final cached = prefs.getString('cached_ingredients');
    int danger = 0;
    int caution = 0;
    if (cached != null) {
      final List<dynamic> list = jsonDecode(cached);
      for (final item in list) {
        final expiryStr = item['expiryDate'] as String?;
        if (expiryStr == null) continue;
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry == null) continue;
        final daysLeft = expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
        if (daysLeft == 3) danger++;
        if (daysLeft == 7) caution++;
      }
    }
    if (danger > 0 || caution > 0) {
      final parts = <String>[];
      if (danger > 0) parts.add('위험 3일 이내: $danger개');
      if (caution > 0) parts.add('주의 7일 이내: $caution개');
      final body = parts.join(' · ');
      await plugin.show(
        2001,
        '식재료 유통기한 알림 (테스트)',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelIdIngredient,
            'Ingredient Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      // Log to server history (optional)
      try {
        final resp = await ApiClient().post('/api/notifications/log', body: {
          'type': 'INGREDIENT',
          'title': '식재료 유통기한 알림 (테스트)',
          'body': body,
        });
        if (resp.statusCode != 200 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('서버에 알림 이력을 기록하지 못했어요 (식재료).')),
          );
        }
      } catch (_) {}
    }

    await plugin.show(
      2002,
      '오늘의 추천 레시피 (테스트)',
      '설정이 정상인지 점검해 보세요',
      const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelIdRecipe,
            'Recipe Recommendations',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    try {
      final resp = await ApiClient().post('/api/notifications/log', body: {
        'type': 'RECIPE',
        'title': '오늘의 추천 레시피 (테스트)',
        'body': '설정이 정상인지 점검해 보세요',
      });
      if (resp.statusCode != 200 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버에 알림 이력을 기록하지 못했어요 (레시피).')),
        );
      }
    } catch (_) {}
  }

  // Schedule a one-off exact local notification for testing (fires in ~delay minutes)
  static Future<void> scheduleExactTest({int minutesFromNow = 1}) async {
    await Permission.notification.request();

    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);

    // Ensure channels exist with high importance
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
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(ingredientChannel);
      await android.createNotificationChannel(recipeChannel);
    }

    // Initialize timezone database (safe to call multiple times)
    try { tz.initializeTimeZones(); } catch (_) {}
    try { tz.setLocalLocation(tz.getLocation('Asia/Seoul')); } catch (_) {}
    final scheduled = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutesFromNow));

    try {
      await plugin.zonedSchedule(
        3001,
        '정확 알림 테스트',
        '${minutesFromNow}분 후에 도착하는 알림입니다.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelIdRecipe,
            'Recipe Recommendations',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      // Fallback: show immediately with error context so you know it reached the plugin
      await plugin.show(
        3001,
        '정확 알림 예약 실패(즉시 표시)',
        e.toString(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelIdRecipe,
            'Recipe Recommendations',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  // Run the daily notification logic immediately for quick testing.
  // Sets the notification_time to now and clears last run day so the logic passes time gates.
  // If bypassHomeOnce is true, skips the home-only gate once.
  static Future<bool> runDailyNow({bool bypassHomeOnce = false}) async {
    await Permission.notification.request();
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    await prefs.setString('notification_time', '$hh:$mm');
    await prefs.remove('last_notification_day');
    if (bypassHomeOnce) {
      await prefs.setBool('bypass_home_gate_once', true);
    }
    return await runDailyNotificationTask();
  }
}

String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';

// Minimal ingredient projection for scheduling
class IngredientLite {
  final String name;
  final DateTime expiry;
  IngredientLite({required this.name, required this.expiry});
}
