import 'package:flutter/material.dart';
import 'package:food_recipe_app/services/calendar_client.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class GoogleCalendarScreen extends StatefulWidget {
  const GoogleCalendarScreen({super.key});

  @override
  State<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends State<GoogleCalendarScreen> {
  late Future<Map<DateTime, List<calendar.Event>>> _eventsFuture;
  Map<DateTime, List<calendar.Event>> _events = {};
  List<calendar.Event> _selectedEvents = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // 화면이 시작될 때 현재 날짜 기준 +- 60일의 이벤트를 불러옴
    _eventsFuture = context.read<CalendarClient>().getEvents(
      startTime: DateTime.now().subtract(const Duration(days: 60)),
      endTime: DateTime.now().add(const Duration(days: 60)),
    ).then((events) {
      if (mounted) {
        setState(() {
          _events = events;
          _selectedEvents = _getEventsForDay(_selectedDay!);
        });
      }
      return events;
    });
  }

  // 특정 날짜에 해당하는 이벤트 목록을 반환하는 함수
  List<calendar.Event> _getEventsForDay(DateTime day) {
    // 시간 정보는 무시하고 날짜(YYYY-MM-DD) 기준으로 이벤트를 찾음
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구글 캘린더'),
      ),
      body: FutureBuilder<Map<DateTime, List<calendar.Event>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('일정을 불러오는 중 오류 발생: ${snapshot.error}'));
          }
          return Column(
            children: [
              // 캘린더 UI 위젯
              TableCalendar<calendar.Event>(
                locale: 'ko_KR', // 한글 로케일 설정
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // '2주' 버튼 숨기기
                  titleCentered: true,
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; // 포커스도 함께 이동
                    _selectedEvents = _getEventsForDay(selectedDay);
                  });
                },
                eventLoader: _getEventsForDay, // 각 날짜 아래에 이벤트 마커 표시
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(height: 1),
              // 선택된 날짜의 이벤트 목록
              Expanded(
                child: _selectedEvents.isEmpty
                    ? const Center(child: Text('선택된 날짜에 일정이 없습니다.'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = _selectedEvents[index];
                    final startTime = event.start?.dateTime;
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.label, color: Theme.of(context).primaryColor),
                        title: Text(event.summary ?? '제목 없음'),
                        subtitle: startTime != null
                            ? Text(DateFormat('a h:mm', 'ko_KR').format(startTime.toLocal()))
                            : const Text('종일'),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
