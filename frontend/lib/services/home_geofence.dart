// dart
// 파일: lib/services/home_geofence.dart
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../background/geofence_worker.dart';
import 'home_location_service.dart';

class HomeGeofence {
  static Future initialize() async {
    // Workmanager 초기화 (앱 시작 시 한 번)
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<bool> requestPermissions() async {
    // Android 13+ requires notification permission
    final notif = await Permission.notification.request();
    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied || status.isPermanentlyDenied) return false;

    // Android에서 백그라운드 위치 권한 별도 요청
    final bg = await Permission.locationAlways.request();
    if (bg.isDenied || bg.isPermanentlyDenied) return false;

    return true;
  }

  static Future startMonitoring() async {
    // 15분 주기 예시(안드로이드 제한으로 최소 주기 존재)
    await Workmanager().registerPeriodicTask(
      'geofenceTaskId',
      geofenceTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  static Future stopMonitoring() async {
    await Workmanager().cancelByUniqueName('geofenceTaskId');
  }

  static Future setHome(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_lat', lat);
    await prefs.setDouble('home_lng', lng);
    try {
      await HomeLocationService().saveHome(lat, lng, radiusMeters: homeRadiusMeters.toInt());
    } catch (_) {}
  }

  static Future<bool> setHomeFromCurrent() async {
    try {
      final ok = await requestPermissions();
      if (!ok) return false;
      final pos = await getCurrentLocation();
      if (pos == null) return false;
      await setHome(pos.latitude, pos.longitude);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future syncHomeFromServer() async {
    try {
      final data = await HomeLocationService().fetchHome();
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          await prefs.setDouble('home_lat', lat);
          await prefs.setDouble('home_lng', lng);
        }
      }
    } catch (_) {}
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  // Test helper: compute and store 'is_at_home' immediately based on current device location
  static Future<bool?> updateHomeStatusOnce({double radiusMeters = 100.0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('home_lat');
      final lng = prefs.getDouble('home_lng');
      if (lat == null || lng == null) return null;

      final pos = await getCurrentLocation();
      if (pos == null) return null;

      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      final atHome = distance <= radiusMeters;
      await prefs.setBool('is_at_home', atHome);
      return atHome;
    } catch (_) {
      return null;
    }
  }
}
