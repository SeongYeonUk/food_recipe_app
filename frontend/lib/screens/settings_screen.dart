import 'package:flutter/material.dart';
import 'package:food_recipe_app/main.dart';
import 'package:food_recipe_app/screens/google_calendar_screen.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();

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
    // watch를 사용하여 CalendarClient의 로그인 상태가 변경될 때마다 UI를 다시 그리도록 함
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
