import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_recipe_app/main.dart';
import 'package:food_recipe_app/screens/allergy_ingredient_screen.dart';
import 'package:food_recipe_app/screens/google_calendar_screen.dart';
import 'package:food_recipe_app/screens/map_screen.dart';
import 'package:food_recipe_app/screens/notification_history_screen.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:food_recipe_app/services/home_geofence.dart';
import 'package:food_recipe_app/services/notification_service.dart';
import 'package:food_recipe_app/user/user_model.dart';
import 'package:food_recipe_app/user/user_repository.dart';
import 'package:food_recipe_app/viewmodels/allergy_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 첫 진입은 모두 닫힘, 이후에는 마지막 상태를 복원
  static bool? _cachedGeneralExpanded;
  static bool? _cachedBasicNotificationExpanded;
  static bool? _cachedScheduleNotificationExpanded;
  static bool? _cachedLocationNotificationExpanded;

  final UserRepository _userRepository = UserRepository();
  bool _isGeofenceEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoadingNotifTime = true;
  Set<int> _selectedWeekdays = <int>{};
  bool _generalExpanded = false;
  bool _basicNotificationExpanded = false;
  bool _scheduleNotificationExpanded = false;
  bool _locationNotificationExpanded = false;

  @override
  void initState() {
    super.initState();
    _generalExpanded = _cachedGeneralExpanded ?? false;
    _basicNotificationExpanded = _cachedBasicNotificationExpanded ?? false;
    _scheduleNotificationExpanded = _cachedScheduleNotificationExpanded ?? false;
    _locationNotificationExpanded = _cachedLocationNotificationExpanded ?? false;
    _loadGeofenceStatus();
    _loadNotificationTime();
    _loadWeekdays();
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

  Future<void> _loadWeekdays() async {
    final set = await NotificationService.getNotificationWeekdays();
    if (!mounted) return;
    setState(() {
      _selectedWeekdays = set;
    });
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
          const SnackBar(content: Text('백그라운드 위치 추적이 켜졌어요.'), backgroundColor: Colors.green),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('위치 권한을 거부하여 기능을 사용할 수 없어요.'), backgroundColor: Colors.red),
        );
      }
    } else {
      await HomeGeofence.stopMonitoring();
      await prefs.setBool('geofence_enabled', false);
      setState(() => _isGeofenceEnabled = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('백그라운드 위치 추적이 중지되었어요.'), backgroundColor: Colors.orange),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('네, 탈퇴할래요'),
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
                    const SnackBar(content: Text('오류가 발생했어요. 다시 시도해주세요.')),
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

  List<Widget> _buildGeneralTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('회원정보 수정'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('로그아웃'),
        onTap: _logout,
      ),
      ListTile(
        leading: Icon(Icons.person_remove_outlined, color: Colors.red[700]),
        title: Text('회원탈퇴', style: TextStyle(color: Colors.red[700])),
        onTap: _showDeleteAccountDialog,
      ),
      ListTile(
        leading: const Icon(Icons.sick_outlined),
        title: const Text('알레르기 재료'),
        subtitle: const Text('등록한 알레르기 재료는 추천에서 제외돼요.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => AllergyViewModel(),
                child: const AllergyIngredientScreen(),
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildBasicNotificationTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: const Text('알림 확인'),
        subtitle: const Text('최근 도착한 알림 내용을 확인해요.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: const Text('알림 시간'),
        subtitle: Text(
          _isLoadingNotifTime
              ? '불러오는 중...'
              : '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
        ),
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
      ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('알림 요일'),
        subtitle: Text(_formatWeekdays(_selectedWeekdays)),
        onTap: () async {
          final picked = await showModalBottomSheet<Set<int>>(
            context: context,
            builder: (_) => _WeekdayPicker(initial: _selectedWeekdays),
          );
          if (picked != null) {
            setState(() {
              _selectedWeekdays = picked;
            });
            await NotificationService.setNotificationWeekdays(picked);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 요일이 저장되었어요.')),
            );
          }
        },
      ),
    ];
  }

  List<Widget> _buildScheduleTiles(CalendarClient calendarClient) {
    return [
      ListTile(
        leading: Icon(
          Icons.calendar_month_outlined,
          color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          '구글 캘린더 연동',
          style: TextStyle(
            color: calendarClient.isLoggedIn ? Theme.of(context).primaryColor : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          calendarClient.isLoggedIn
              ? (calendarClient.userEmail ?? '연결된 계정을 확인하세요.')
              : '구글 계정과 연동하면 일정 기반 알림을 받아요.',
        ),
        onTap: () async {
          if (calendarClient.isLoggedIn) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GoogleCalendarScreen()));
          } else {
            final success = await calendarClient.signIn();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('구글 캘린더가 연동되었어요.'), backgroundColor: Colors.green),
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
      ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: const Text('매일 알림 로직 즉시 실행'),
        subtitle: const Text('현재 시각 기준으로 알림 예약을 확인해요.'),
        onTap: () async {
          final ok = await NotificationService.runDailyNow();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? '매일 알림 로직이 실행되었어요.' : '실행 조건을 확인해주세요.')),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: const Text('테스트 알림 보내기'),
        subtitle: const Text('즉시 2개의 테스트 알림을 보내요.'),
        onTap: () async {
          await NotificationService.debugSendNow(context);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('테스트 알림을 발송했어요.')),
          );
        },
      ),
    ];
  }

  List<Widget> _buildLocationTiles() {
    return [
      ListTile(
        leading: const Icon(Icons.home_filled),
        title: const Text('집상태 갱신'),
        subtitle: const Text('현재 위치가 집인지 즉시 확인'),
        onTap: () async {
          final atHome = await HomeGeofence.updateHomeStatusOnce();
          if (!mounted) return;
          if (atHome == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('위치 권한 또는 GPS 상태를 확인해주세요.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(atHome ? '현재 집에 있는 것으로 확인했어요.' : '지금은 집 밖에 있어요.')),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.home_work_outlined),
        title: const Text('집위치 설정'),
        subtitle: const Text('지도의 집 아이콘을 눌러 위치를 지정하세요.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
        },
      ),
      ListTile(
        leading: const Icon(Icons.my_location_outlined),
        title: const Text('현재 위치를 집으로 설정'),
        subtitle: const Text('GPS를 감지해 현재 위치를 곧바로 집으로 지정해요.'),
        onTap: () async {
          final ok = await HomeGeofence.setHomeFromCurrent();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? '현재 위치가 집으로 저장되었어요.' : '현재 위치 정보를 가져오지 못했어요. 권한을 확인해주세요.')),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: const Text('집에 있을 때만 보기'),
        subtitle: const Text('집에 있을 때만 위치 기반 알림을 켜요.'),
        trailing: Switch(
          value: _isGeofenceEnabled,
          onChanged: _onGeofenceChanged,
        ),
      ),
    ];
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
          _buildToggleSection(
            title: '일반 설정',
            expanded: _generalExpanded,
            onToggle: () => setState(() {
              _generalExpanded = !_generalExpanded;
              _cachedGeneralExpanded = _generalExpanded;
            }),
            children: _buildGeneralTiles(),
          ),
          _buildToggleSection(
            title: '알림 기본',
            expanded: _basicNotificationExpanded,
            onToggle: () => setState(() {
              _basicNotificationExpanded = !_basicNotificationExpanded;
              _cachedBasicNotificationExpanded = _basicNotificationExpanded;
            }),
            children: _buildBasicNotificationTiles(),
          ),
          _buildToggleSection(
            title: '일정 기반 알림',
            expanded: _scheduleNotificationExpanded,
            onToggle: () => setState(() {
              _scheduleNotificationExpanded = !_scheduleNotificationExpanded;
              _cachedScheduleNotificationExpanded = _scheduleNotificationExpanded;
            }),
            children: _buildScheduleTiles(calendarClient),
          ),
          _buildToggleSection(
            title: '위치 기반 알림',
            expanded: _locationNotificationExpanded,
            onToggle: () => setState(() {
              _locationNotificationExpanded = !_locationNotificationExpanded;
              _cachedLocationNotificationExpanded = _locationNotificationExpanded;
            }),
            children: _buildLocationTiles(),
          ),
          const Divider(),
          const ListTile(
            title: Text('앱 버전'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final sectionChildren = _separateChildren(children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: onToggle,
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: sectionChildren),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _separateChildren(List<Widget> tiles) {
    final List<Widget> separated = [];
    for (var i = 0; i < tiles.length; i++) {
      separated.add(tiles[i]);
      if (i != tiles.length - 1) {
        separated.add(const Divider(height: 1));
      }
    }
    return separated;
  }
}

class _IngredientLiteInput {
  final String name;
  final DateTime expiry;
  _IngredientLiteInput({required this.name, required this.expiry});
}

String _formatWeekdays(Set<int> set) {
  if (set.isEmpty) return '요일을 선택해주세요';
  const labels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
  final list = set.toList()..sort();
  return list.map((d) => labels[d] ?? d.toString()).join(', ');
}

class _WeekdayPicker extends StatefulWidget {
  final Set<int> initial;
  const _WeekdayPicker({required this.initial});
  @override
  State<_WeekdayPicker> createState() => _WeekdayPickerState();
}

class _WeekdayPickerState extends State<_WeekdayPicker> {
  late Set<int> selected;
  @override
  void initState() {
    super.initState();
    selected = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    const labels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림 요일 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [1, 2, 3, 4, 5, 6, 7])
                  ChoiceChip(
                    label: Text(labels[d]!),
                    selected: selected.contains(d),
                    onSelected: (_) {
                      setState(() => selected.contains(d) ? selected.remove(d) : selected.add(d));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => selected.clear());
                  },
                  child: const Text('전체 해제'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(selected);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
