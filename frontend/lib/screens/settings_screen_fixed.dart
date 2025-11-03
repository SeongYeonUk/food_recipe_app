import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_recipe_app/main.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:food_recipe_app/services/notification_service.dart';
import 'package:food_recipe_app/screens/google_calendar_screen.dart';
import 'package:food_recipe_app/screens/map_screen_fixed.dart';
import 'package:food_recipe_app/screens/notification_history_screen.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();
  bool _isGeofenceEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoadingNotifTime = true;

  @override
  void initState() {
    super.initState();
    _loadGeofenceStatus();
    _loadNotificationTime();
  }

  Future<void> _loadGeofenceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGeofenceEnabled = prefs.getBool('geofence_enabled') ?? false;
    });
  }

  Future<void> _loadNotificationTime() async {
    final t = await NotificationService.getNotificationTime();
    if (!mounted) return;
    setState(() {
      _notificationTime = t;
      _isLoadingNotifTime = false;
    });
    await _rebuildIngredientSchedule();
  }

  Future<void> _rebuildIngredientSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_ingredients');
      final List<_IngredientLiteInput> ingredients = [];
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        for (final item in list) {
          final expiryStr = item['expiryDate'] as String?;
          if (expiryStr == null) continue;
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry == null) continue;
          ingredients.add(_IngredientLiteInput(name: item['name'] ?? '', expiry: expiry));
        }
      }
      await NotificationService.buildIngredientSchedule(
        context,
        ingredients.map((e) => IngredientLite(name: e.name, expiry: e.expiry)).toList(),
      );
    } catch (_) {}
  }

  Future<void> _onGeofenceChanged(bool value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final hasPermission = await HomeGeofence.requestPermissions();
      if (!mounted) return;
      if (hasPermission) {
        await HomeGeofence.startMonitoring();
        await prefs.setBool('geofence_enabled', true);
        setState(() => _isGeofenceEnabled = true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('백그라운드 위치 추적을 시작했어요.'), backgroundColor: Colors.green),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되어 기능을 사용할 수 없어요.'), backgroundColor: Colors.red),
        );
      }
    } else {
      await HomeGeofence.stopMonitoring();
      await prefs.setBool('geofence_enabled', false);
      setState(() => _isGeofenceEnabled = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('백그라운드 위치 추적을 중지했어요.'), backgroundColor: Colors.orange),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃 하시겠어요?'),
          actions: [
            TextButton(
              child: const Text('아니요'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () {
                forceLogout();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text(
            '정말 탈퇴하시겠어요?\n모든 회원 정보가 삭제되며, 복구할 수 없어요.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              child: const Text('아니요'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('예, 탈퇴할게요'),
              onPressed: () async {
                final response = await _userRepository.deleteAccount();
                if (!mounted) return;
                if (response != null && response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원 탈퇴가 완료되었어요.')),
                  );
                  forceLogout();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('오류가 발생했어요. 다시 시도해 주세요.')),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = UserModel();
    final calendarClient = context.watch<CalendarClient>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Row(
              children: [
                const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel.nickname ?? '사용자',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userModel.uid ?? 'user_id',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('회원 정보 설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: _logout,
          ),
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: Colors.red[700]),
            title: Text('회원 탈퇴', style: TextStyle(color: Colors.red[700])),
            onTap: _showDeleteAccountDialog,
          ),

          // 알림 시간 설정
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('알림 시간'),
            subtitle: Text(_isLoadingNotifTime
                ? '로딩 중...'
                : '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}'),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _notificationTime,
              );
              if (picked != null) {
                await NotificationService.setNotificationTime(picked);
                await NotificationService.ensureScheduledBackground();
                setState(() => _notificationTime = picked);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('알림 시간이 저장되었어요.')),
                  );
                }
                await _rebuildIngredientSchedule();
              }
            },
          ),

          const Divider(),
          ListTile(
            leading: Icon(
              Icons.calendar_month_outlined,
              color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.grey,
            ),
            title: Text(
              calendarClient.isLoggedIn ? '구글 캘린더 연동됨' : '구글 캘린더 연동',
              style: TextStyle(
                color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              calendarClient.isLoggedIn
                  ? (calendarClient.userEmail ?? '캘린더 보기')
                  : '유통기한 알림을 캘린더에 추가해요',
            ),
            onTap: () async {
              if (calendarClient.isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GoogleCalendarScreen()));
              } else {
                final success = await calendarClient.signIn();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('구글 캘린더에 연동되었어요.'), backgroundColor: Colors.green),
                  );
                  await _rebuildIngredientSchedule();
                }
              }
            },
            trailing: calendarClient.isLoggedIn
                ? TextButton(
                    onPressed: () => calendarClient.signOut(),
                    child: const Text('연동 해제'),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          // 알림 내역 화면
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('알림 확인'),
            subtitle: const Text('서버에 저장된 알림 내역 보기'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()));
            },
          ),

          // 집 상태 즉시 갱신(테스트)
          ListTile(
            leading: const Icon(Icons.home_filled),
            title: const Text('집 상태 갱신(테스트)'),
            subtitle: const Text('현재 위치와 집 위치를 비교하여 즉시 판정'),
            onTap: () async {
              final atHome = await HomeGeofence.updateHomeStatusOnce();
              if (!mounted) return;
              if (atHome == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('집 위치 또는 현재 위치를 확인할 수 없어요.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(atHome ? '지금 집에 있는 것으로 판정했어요.' : '지금 집에 없는 것으로 판정했어요.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule_send_outlined),
            title: const Text('정확 알림 테스트(1분 후)'),
            subtitle: const Text('Allow while idle로 정확 시각에 도착'),
            onTap: () async {
              await NotificationService.scheduleExactTest(minutesFromNow: 1);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('1분 후 정확 알림을 예약했어요.')), 
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('일일 알림 로직 즉시 실행'),
            subtitle: const Text('현재 시간 기준, 게이트 그대로 적용'),
            onTap: () async {
              final ok = await NotificationService.runDailyNow();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? '일일 알림 로직을 실행했어요.' : '실행 실패 또는 조건 미충족.')), 
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_filled),
            title: const Text('일일 알림 즉시 실행(집 게이트 무시 1회)'),
            subtitle: const Text('테스트 편의를 위해 1회만 집 조건 무시'),
            onTap: () async {
              final ok = await NotificationService.runDailyNow(bypassHomeOnce: true);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? '집 게이트를 무시하고 실행했어요.' : '실행 실패.')), 
              );
            },
          ),

          // 테스트 알림 보내기
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('테스트 알림 보내기'),
            subtitle: const Text('지금 즉시 로컬 알림 2개 발송'),
            onTap: () async {
              await NotificationService.debugSendNow(context);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('테스트 알림을 보냈어요.')),
              );
            },
          ),

          // 위치 기반
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('위치 기반 서비스', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.home_work_outlined),
            title: const Text('집 위치 설정'),
            subtitle: const Text('위치 기반 알림을 위해 집 위치를 등록해요'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.my_location_outlined),
            title: const Text('현재 위치를 집으로 설정'),
            subtitle: const Text('GPS로 현재 위치를 읽어 즉시 저장'),
            onTap: () async {
              final ok = await HomeGeofence.setHomeFromCurrent();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? '현재 위치를 집으로 저장했어요.' : '현재 위치를 읽지 못했어요. 위치 권한/서비스를 확인해 주세요.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('집에서만 보기'),
            subtitle: const Text('집에 있을 때만 알림을 받아요'),
            trailing: Switch(
              value: _isGeofenceEnabled,
              onChanged: _onGeofenceChanged,
            ),
          ),

          const Divider(),
          ListTile(
            title: const Text('앱 버전'),
            trailing: const Text('1.0.0'),
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _IngredientLiteInput {
  final String name;
  final DateTime expiry;
  _IngredientLiteInput({required this.name, required this.expiry});
}
