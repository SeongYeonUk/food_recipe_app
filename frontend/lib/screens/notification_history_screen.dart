import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/api_client.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<dynamic> _rows = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _api.get('/api/notifications');
      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        setState(() { _rows = data as List<dynamic>; });
      } else {
        setState(() { _error = '서버 오류: ${resp.statusCode}'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 내역')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = _rows[index] as Map<String, dynamic>;
                    final type = row['type'] ?? '';
                    final title = row['title'] ?? '';
                    final body = row['body'] ?? '';
                    final sentAt = row['sentAt'] as String?;
                    return ListTile(
                      leading: Icon(type == 'INGREDIENT' ? Icons.inventory_2_outlined : Icons.restaurant_menu_outlined),
                      title: Text(title),
                      subtitle: Text(body),
                      trailing: Text(sentAt != null ? sentAt.split('.').first.replaceFirst('T', '\n') : ''),
                    );
                  },
                ),
    );
  }
}
