// lib/services/notification_service.dart

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'package:food_recipe_app/background/notification_worker.dart';
import 'package:food_recipe_app/common/api_client.dart';
import 'package:food_recipe_app/models/recipe_model.dart';
import 'package:food_recipe_app/screens/recipe_detail_screen.dart';
import 'package:food_recipe_app/services/recipe_notification_helper.dart';
import 'package:food_recipe_app/viewmodels/recipe_viewmodel.dart';
import 'package:food_recipe_app/viewmodels/refrigerator_viewmodel.dart';

import '../services/calendar_client.dart';

class NotificationService {

  // Default daily time 18:00

  static const String _prefTime = 'notification_time';

  static const String _prefWeekdays = 'notification_weekdays'; // csv of 1..7 (Mon..Sun)
  static const String _prefLastDay = 'last_notification_day';
  static const String _prefCurrentUid = 'current_uid';

  static final FlutterLocalNotificationsPlugin _uiNotifications = FlutterLocalNotificationsPlugin();
  static bool _uiInitialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static String? _pendingPayload;
  static bool _isProcessingPayload = false;


  static Future<String> _uidPrefix() async {

    try {

      const storage = FlutterSecureStorage();

      final token = await storage.read(key: 'ACCESS_TOKEN');

      if (token != null && token.isNotEmpty) {

        final Map<String, dynamic> payload = JwtDecoder.tryDecode(token) ?? {};

        final uid = (payload['sub'] ?? payload['uid'] ?? payload['userId'] ?? '').toString();

        if (uid.isNotEmpty) return '$uid:';

      }

    } catch (_) {}

    return 'default:';

  }



  static Future<void> _storeCurrentUidPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = await _uidPrefix();
      final uid = prefix.substring(0, prefix.length - 1);
      await prefs.setString(_prefCurrentUid, uid);
    } catch (_) {}
  }

  static Future<void> configureNavigator(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    await _ensureUiNotificationsInitialized();
    final launchDetails = await _uiNotifications.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      _pendingPayload = payload;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingPayload();
    });
  }

  static Future<void> _ensureUiNotificationsInitialized() async {
    if (_uiInitialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _uiNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _uiInitialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    handleNotificationResponse(response.payload);
  }

  static void handleNotificationResponse(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _pendingPayload = payload;
    _processPendingPayload();
  }

  static void _processPendingPayload() {
    if (_isProcessingPayload) return;
    final payload = _pendingPayload;
    if (payload == null) return;
    final navigator = _navigatorKey?.currentState;
    final context = navigator?.context;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPendingPayload());
      return;
    }
    _pendingPayload = null;
    _isProcessingPayload = true;
    Future(() async {
      await _dispatchPayload(context, payload);
    }).whenComplete(() {
      _isProcessingPayload = false;
      if (_pendingPayload != null) {
        _processPendingPayload();
      }
    });
  }

  static Future<void> _dispatchPayload(BuildContext context, String payload) async {
    Map<String, dynamic> data;
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      data = decoded;
    } catch (_) {
      return;
    }
    final type = data['type'];
    if (type == 'recipe') {
      final recipeIdRaw = data['recipeId'];
      final int? recipeId = recipeIdRaw is int ? recipeIdRaw : int.tryParse('$recipeIdRaw');
      if (recipeId != null) {
        await _navigateToRecipeDetail(context, recipeId, recipeName: data['recipeName']?.toString());
      }
    }
  }

  static Future<void> _navigateToRecipeDetail(BuildContext context, int recipeId, {String? recipeName}) async {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;
    final recipeViewModel = context.read<RecipeViewModel>();
    Recipe? recipe = _findRecipeById(recipeViewModel, recipeId);
    recipe ??= await _safeFetchRecipeById(recipeViewModel, recipeId);
    if (recipe == null) {
      final name = recipeName == null || recipeName.isEmpty ? '레시피' : "'$recipeName'";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 정보를 불러오지 못했어요. 다시 시도해주세요.')),
      );
      return;
    }
    final Recipe resolvedRecipe = recipe!;
    final refrigeratorViewModel = context.read<RefrigeratorViewModel>();
    final ingredientNames = refrigeratorViewModel.userIngredients
        .map((e) => e.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: resolvedRecipe,
          userIngredients: ingredientNames,
        ),
      ),
    );
  }

  static Recipe? _findRecipeById(RecipeViewModel viewModel, int recipeId) {
    Recipe? recipe = viewModel.allRecipes.firstWhereOrNull((r) => r.id == recipeId);
    recipe ??= viewModel.recommendedRecipes.firstWhereOrNull((r) => r.id == recipeId);
    recipe ??= viewModel.filteredAiRecipes.firstWhereOrNull((r) => r.id == recipeId);
    recipe ??= viewModel.myRecipes.firstWhereOrNull((r) => r.id == recipeId);
    recipe ??= viewModel.favoriteRecipes.firstWhereOrNull((r) => r.id == recipeId);
    recipe ??= viewModel.customRecipes.firstWhereOrNull((r) => r.id == recipeId);
    return recipe;
  }

  static Future<Recipe?> _safeFetchRecipeById(RecipeViewModel viewModel, int recipeId) async {
    try {
      return await viewModel.fetchRecipeById(recipeId);
    } catch (_) {
      return null;
    }
  }


  static Future<void> ensureScheduledBackground() async {
    // Register a 15-minute periodic check; it will self-gate to fire once daily

    await _storeCurrentUidPref();

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

    final prefix = await _uidPrefix();

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    await prefs.setString('$prefix$_prefTime', '$hh:$mm');

  }

  static Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();

    final prefix = await _uidPrefix();

    final raw = prefs.getString('$prefix$_prefTime') ?? '18:00';

    final p = raw.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));

  }



  /// Weekday selection helpers

  /// Stores as comma-separated integers (1=Mon .. 7=Sun). Empty set means no days selected.

  static Future<void> setNotificationWeekdays(Set<int> weekdays) async {

    final prefs = await SharedPreferences.getInstance();

    final prefix = await _uidPrefix();

    final safe = weekdays.where((d) => d >= 1 && d <= 7).toList()..sort();

    await prefs.setString('$prefix$_prefWeekdays', safe.join(','));

  }



  static Future<Set<int>> getNotificationWeekdays() async {

    final prefs = await SharedPreferences.getInstance();

    final prefix = await _uidPrefix();

    final raw = prefs.getString('$prefix$_prefWeekdays');

    if (raw == null || raw.trim().isEmpty) return <int>{};

    return raw

        .split(',')

        .map((e) => int.tryParse(e.trim()) ?? -1)

        .where((n) => n >= 1 && n <= 7)

        .toSet();

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



    final prefix = await _uidPrefix();

    await prefs.setString('${prefix}ingredient_notification_schedule', jsonEncode(schedule));

    await prefs.setString('${prefix}ingredient_notification_schedule_counts', jsonEncode(counts));

    await prefs.setString('${prefix}ingredient_notification_schedule_names', jsonEncode(names));

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

    await _ensureUiNotificationsInitialized();
    final FlutterLocalNotificationsPlugin plugin = _uiNotifications;
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
        payload: jsonEncode({'type': 'ingredient'}),
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





    const defaultRecipeTitle = 'Recipe Suggestion (test)';

    const defaultRecipeBody = "Check today's top recipe!";
    String recipeTitle = defaultRecipeTitle;

    String recipeBody = defaultRecipeBody;

    final recipeInfo = await RecipeNotificationHelper.fetchTopRecommendation();

    if (recipeInfo != null) {

      recipeTitle = "Today's Pick (test): ${recipeInfo.displayName}";

      recipeBody = recipeInfo.buildNotificationBody();

    }



    final Map<String, dynamic> recipePayload = {
      'type': 'recipe',
      if (recipeInfo != null) 'recipeId': recipeInfo.id,
      if (recipeInfo != null) 'recipeName': recipeInfo.displayName,
    };

    await plugin.show(
      2002,
      recipeTitle,
      recipeBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelIdRecipe,
          'Recipe Recommendations',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(recipePayload),
    );
    try {
      final resp = await ApiClient().post('/api/notifications/log', body: {
        'type': 'RECIPE',

        'title': recipeTitle,

        'body': recipeBody,

      });
      if (resp.statusCode != 200 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Failed to log recipe notification (test).')),

        );
      }
    } catch (_) {}
  }

  // Schedule a one-off exact local notification for testing (fires in ~delay minutes)
  static Future<void> scheduleExactTest({int minutesFromNow = 1}) async {
    await Permission.notification.request();

    await _ensureUiNotificationsInitialized();
    final plugin = _uiNotifications;


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
        payload: jsonEncode({'type': 'recipe'}),
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
        payload: jsonEncode({'type': 'recipe'}),
      );
    }
  }

  // Run the daily notification logic immediately for quick testing.
  // Sets the notification_time to now and clears last run day so the logic passes time gates.
  // If bypassHomeOnce is true, skips the home-only gate once.
  static Future<bool> runDailyNow({bool bypassHomeOnce = false}) async {
    await Permission.notification.request();
    final prefs = await SharedPreferences.getInstance();

    final prefix = await _uidPrefix();

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    await prefs.setString('$prefix$_prefTime', '$hh:$mm');

    await prefs.remove('$prefix$_prefLastDay');

    if (bypassHomeOnce) {

      await prefs.setBool('${prefix}bypass_home_gate_once', true);

    }
    return await runDailyNotificationTask();
  }

}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleNotificationResponse(response.payload);
}

String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';

// Minimal ingredient projection for scheduling
class IngredientLite {
  final String name;
  final DateTime expiry;
  IngredientLite({required this.name, required this.expiry});
}
