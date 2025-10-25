// dart
// 파일: lib/background/geofence_worker.dart
import 'dart:math';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String geofenceTask = "geofence_periodic_check";
const double homeRadiusMeters = 100.0; // 집 반경 임계값

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 초기화: 로컬 알림 채널 설정 (간단)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    try {
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('home_lat');
      final lng = prefs.getDouble('home_lng');

      if (lat == null || lng == null) {
        // 집 좌표 미설정이면 작업 종료
        return Future.value(true);
      }

      final distance = _distanceMeters(position.latitude, position.longitude, lat, lng);

      final bool wasAtHome = prefs.getBool('is_at_home') ?? false;
      final bool isAtHome = distance <= homeRadiusMeters;

      if (isAtHome != wasAtHome) {
        // 상태 변화가 있을 때만 알림 및 상태 저장
        await prefs.setBool('is_at_home', isAtHome);
        final title = isAtHome ? '집 도착' : '집 이탈';
        final body = isAtHome ? '현재 집 반경 내에 있습니다.' : '집 반경을 벗어났습니다.';
        await _showNotification(title, body);
      }
    } catch (e) {
      // 에러 로깅 필요
    }

    return Future.value(true);
  });
}

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // meters
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat/2) * sin(dLat/2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLon/2) * sin(dLon/2);
  final c = 2 * atan2(sqrt(a), sqrt(1-a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

Future _showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails('geofence_channel', 'Geofence',
      channelDescription: 'Geofence notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker');
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);
  await _flutterLocalNotificationsPlugin.show(
      0, title, body, platformChannelSpecifics,
      payload: 'geofence');
}
