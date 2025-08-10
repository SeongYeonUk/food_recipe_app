import 'package:flutter/material.dart';
import 'package:food_recipe_app/main.dart';
import 'package:food_recipe_app/user/auth_status.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserRepository _userRepository = UserRepository();
  bool _isNotificationsEnabled = true;

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
                const CircleAvatar(
                  radius: 32,
                  child: Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userModel.nickname ?? '사용자',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userModel.uid ?? 'user_id',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
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
          ListTile(
            leading: const Icon(Icons.notifications_none_outlined),
            title: const Text('알림 설정'),
            trailing: Switch(
              value: _isNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isNotificationsEnabled = value;
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: _logout,
          ),
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: Colors.red[700]),
            title: Text(
              '회원 탈퇴',
              style: TextStyle(color: Colors.red[700]),
            ),
            onTap: _showDeleteAccountDialog,
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



