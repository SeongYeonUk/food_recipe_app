import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

// 구글 API와 통신하기 위한 인증된 HTTP 클라이언트
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

// 구글 로그인 및 캘린더 데이터 처리를 담당하는 핵심 클래스
class CalendarClient extends ChangeNotifier {
  // 캘린더 읽기/쓰기 권한을 모두 요청
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[calendar.CalendarApi.calendarScope],
  );

  GoogleSignInAccount? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<Map<DateTime, List<calendar.Event>>> getEvents({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (_currentUser == null) return {};
    // ... (이 메소드는 이전과 동일합니다)
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final httpClient = GoogleAuthClient(authHeaders);
      final calendarApi = calendar.CalendarApi(httpClient);

      final events = await calendarApi.events.list(
        'primary',
        timeMin: startTime.toUtc(),
        timeMax: endTime.toUtc(),
      );

      final Map<DateTime, List<calendar.Event>> eventMap = {};
      if (events.items != null) {
        for (var event in events.items!) {
          final startTime = event.start?.dateTime ?? event.start?.date;
          if (startTime != null) {
            final date = DateTime(startTime.year, startTime.month, startTime.day);
            if (eventMap[date] == null) {
              eventMap[date] = [];
            }
            eventMap[date]!.add(event);
          }
        }
      }
      return eventMap;
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return {};
    }
  }

  // ▼▼▼ [핵심 추가] 구글 캘린더에 새로운 일정을 생성하는 메소드 ▼▼▼
  Future<bool> addExpiryDateEvent({
    required String ingredientName,
    required DateTime expiryDate,
  }) async {
    if (_currentUser == null) return false;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final httpClient = GoogleAuthClient(authHeaders);
      final calendarApi = calendar.CalendarApi(httpClient);

      final event = calendar.Event(
        summary: '$ingredientName 유통기한 임박!', // 일정 제목
        description: '냉장고에 있는 $ingredientName 의 유통기한이 곧 만료됩니다. 오늘 꼭 확인하고 요리하세요!', // 일정 설명
        start: calendar.EventDateTime(
          date: expiryDate, // 종일 일정으로 설정
        ),
        end: calendar.EventDateTime(
          date: expiryDate.add(const Duration(days: 1)), // 종일 일정은 종료일을 +1일로 설정
        ),
      );

      await calendarApi.events.insert(event, 'primary');
      return true; // 성공
    } catch (e) {
      debugPrint('Error adding event: $e');
      return false; // 실패
    }
  }
// ▲▲▲ 여기까지 ▲▲▲
}
