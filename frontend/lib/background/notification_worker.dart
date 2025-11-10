// lib/background/notification_worker.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Workmanager?먯꽌 吏곸젒 import?섏? ?딆븘???섎룄濡? ???뚯씪?
// ?쒖닔 ?⑥닔(runDailyNotificationTask)留??몄텧?⑸땲??

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
    final currentUid = prefs.getString('current_uid') ?? 'default';
    final prefix = currentUid + ':';

    // Weekday gating: if user selected specific weekdays, notify only on those
    final weekdayCsv = prefs.getString(prefix + 'notification_weekdays');
    if (weekdayCsv != null) {
      final sel = weekdayCsv
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? -1)
          .where((n) => n >= 1 && n <= 7)
          .toSet();
      if (sel.isEmpty) {
        // No days selected -> no notifications today
        return true;
      }
      final todayW = DateTime.now().weekday; // 1=Mon .. 7=Sun
      if (!sel.contains(todayW)) {
        return true;
      }
    }

    // Time gating: run only around configured time once per day
    final now = DateTime.now();
    final notifTime = prefs.getString(prefix + 'notification_time') ?? '18:00';
    final parts = notifTime.split(':');
    final target = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

    // Allow a 15-minute window and only once per day
    final lastRunDay = prefs.getString(prefix + 'last_notification_day');
    if (lastRunDay == _ymd(now)) {
      return true;
    }
    final diffMinutes = now.difference(target).inMinutes;
    if (diffMinutes < -15 || diffMinutes > 15) {
      return true;
    }

    // Home gate (+ one-time bypass)
    final bypassHomeOnce = prefs.getBool(prefix + 'bypass_home_gate_once') ?? false;
    final onlyAtHome = prefs.getBool('geofence_enabled') ?? false;
    if (!bypassHomeOnce && onlyAtHome) {
      final isAtHome = prefs.getBool('is_at_home') ?? false;
      if (!isAtHome) {
        await prefs.setString(prefix + 'last_notification_day', _ymd(now));
        return true;
      }
    }
    if (bypassHomeOnce) {
      await prefs.remove(prefix + 'bypass_home_gate_once');
    }

    // Read precomputed schedule (calendar shift) for today
    bool sendIngredientToday = true; // default true if no schedule stored
    int scheduledD3 = 0;
    int scheduledD7 = 0;
    List<String> scheduledD3Names = [];
    List<String> scheduledD7Names = [];
    try {
      final key = _ymd(now);
      final scheduleJson = prefs.getString(prefix + 'ingredient_notification_schedule');
      if (scheduleJson != null) {
        final Map<String, dynamic> schedule = jsonDecode(scheduleJson);
        if (schedule.containsKey(key)) {
          sendIngredientToday = schedule[key] == true;
        }
      }
      final countsJson = prefs.getString(prefix + 'ingredient_notification_schedule_counts');
      if (countsJson != null) {
        final Map<String, dynamic> map = jsonDecode(countsJson);
        if (map.containsKey(key)) {
          final obj = map[key] as Map<String, dynamic>;
          scheduledD3 = (obj['d3'] as int?) ?? 0;
          scheduledD7 = (obj['d7'] as int?) ?? 0;
        }
      }
      final namesJson = prefs.getString(prefix + 'ingredient_notification_schedule_names');
      if (namesJson != null) {
        final Map<String, dynamic> nmap = jsonDecode(namesJson);
        if (nmap.containsKey(key)) {
          final obj = nmap[key] as Map<String, dynamic>;
          final d3l = obj['d3'] as List<dynamic>?;
          final d7l = obj['d7'] as List<dynamic>?;
          if (d3l != null) scheduledD3Names = d3l.map((e) => e.toString()).toList();
          if (d7l != null) scheduledD7Names = d7l.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    // Compute base counts from cache
    if (sendIngredientToday) {
      final cached = prefs.getString('cached_ingredients');
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        int danger = 0; // 3 days
        int caution = 0; // 7 days
        final List<String> d3Names = [];
        final List<String> d7Names = [];
        for (final item in list) {
          final expiryStr = item['expiryDate'] as String?;
          if (expiryStr == null) continue;
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry == null) continue;
          final daysLeft = expiry.difference(DateTime(now.year, now.month, now.day)).inDays;
          if (daysLeft == 3) { danger++; d3Names.add((item['name'] ?? '').toString()); }
          if (daysLeft == 7) { caution++; d7Names.add((item['name'] ?? '').toString()); }
        }

        // Prefer scheduled (shifted) counts/names when present
        if ((scheduledD3 + scheduledD7) > 0) {
          danger = scheduledD3;
          caution = scheduledD7;
        }
        final useD3Names = scheduledD3Names.isNotEmpty ? scheduledD3Names : d3Names;
        final useD7Names = scheduledD7Names.isNotEmpty ? scheduledD7Names : d7Names;

        if (danger > 0 || caution > 0) {
          final parts = <String>[];
          if (danger > 0) {
            final n3 = useD3Names.take(3).join(', ');
            parts.add(n3.isEmpty ? 'D-3 alerts: ' + danger.toString() : 'D-3 alerts: ' + danger.toString() + ' (' + n3 + ')');
          }
          if (caution > 0) {
            final n7 = useD7Names.take(3).join(', ');
            parts.add(n7.isEmpty ? 'D-7 alerts: ' + caution.toString() : 'D-7 alerts: ' + caution.toString() + ' (' + n7 + ')');
          }
          final body = parts.join(' 쨌 ');
          await _notifications.show(1001, 'Ingredient Expiry Alerts',
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

    // Recipe suggestion
    await _notifications.show(1002, 'Recipe Suggestion', 'Check today\'s top recipe!',
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

    await prefs.setString(prefix + 'last_notification_day', _ymd(now));
  } catch (_) {}

  return true;
}

String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';



