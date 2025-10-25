import 'package:flutter/material.dart';
import 'package:food_recipe_app/main.dart';
import 'package:food_recipe_app/screens/google_calendar_screen.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';
import 'package:provider/provider.dart';

// ▼▼▼ [핵심 추가 1] 필요한 파일들 import ▼▼▼
import 'package:food_recipe_app/screens/map_screen.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ▲▲▲ 여기까지 ▲▲▲

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();

  // ▼▼▼ [핵심 추가 2] 위치 모니터링 상태를 관리할 변수 및 관련 함수들 ▼▼▼
  bool _isGeofenceEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadGeofenceStatus();
  }

  // 앱 시작 시 저장된 모니터링 상태를 불러옴
  Future<void> _loadGeofenceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGeofenceEnabled = prefs.getBool('geofence_enabled') ?? false;
      });
    }
  }

  // 스위치 값 변경 시 호출되는 함수
  Future<void> _onGeofenceChanged(bool value) async {
    // context가 유효한지 확인하기 위해 변수를 미리 선언
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // 스위치를 켤 때
      final hasPermission = await HomeGeofence.requestPermissions();
      if (!mounted) return;

      if (hasPermission) {
        await HomeGeofence.startMonitoring();
        await prefs.setBool('geofence_enabled', true);
        setState(() { _isGeofenceEnabled = true; });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('백그라운드 위치 추적을 시작합니다.'), backgroundColor: Colors.green),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('위치 권한이 거부되어 기능을 켤 수 없습니다.'), backgroundColor: Colors.red),
        );
      }
    } else {
      // 스위치를 끌 때
      await HomeGeofence.stopMonitoring();
      await prefs.setBool('geofence_enabled', false);
      setState(() { _isGeofenceEnabled = false; });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('백그라운드 위치 추적을 중지합니다.'), backgroundColor: Colors.orange),
      );
    }
  }
  // ▲▲▲ 여기까지 ▲▲▲

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('아니오'),
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
            '정말 탈퇴하시겠습니까?\n모든 회원 정보와 데이터가 영구적으로 삭제되며, 복구할 수 없습니다.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              child: const Text('아니오'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('예, 탈퇴합니다'),
              onPressed: () async {
                final response = await _userRepository.deleteAccount();
                if (!mounted) return;
                if (response != null && response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
                  );
                  forceLogout();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
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
            title: const Text('회원 정보 수정'),
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

          const Divider(),
          ListTile(
            leading: Icon(Icons.calendar_month_outlined, color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.grey),
            title: Text(
              calendarClient.isLoggedIn ? '구글 캘린더 연동됨' : '구글 캘린더 연동',
              style: TextStyle(color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.black, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(calendarClient.isLoggedIn ? calendarClient.userEmail ?? '클릭하여 캘린더 보기' : '유통기한 알림을 캘린더에 추가하세요'),
            onTap: () async {
              if (calendarClient.isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GoogleCalendarScreen()));
              } else {
                final success = await calendarClient.signIn();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('구글 캘린더가 성공적으로 연동되었습니다.'), backgroundColor: Colors.green),
                  );
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
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('알림창'),
            subtitle: const Text('유통기한 임박 등 주요 알림을 확인합니다.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 알림 목록을 보여주는 새로운 화면으로 이동하는 로직 구현
            },
          ),

          // ▼▼▼ [핵심 추가 3] 위치 관련 메뉴 2개 추가 ▼▼▼
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('위치 기반 서비스', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.home_work_outlined),
            title: const Text('집 위치 설정'),
            subtitle: const Text('위치 기반 알림을 위해 집 위치를 등록하세요.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('위치 기반 알림'),
            subtitle: const Text('집에 있을 때만 알림을 받습니다.'),
            trailing: Switch(
              value: _isGeofenceEnabled,
              onChanged: _onGeofenceChanged,
            ),
          ),
          // ▲▲▲ 여기까지 ▲▲▲

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
