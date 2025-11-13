import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class CalendarClient extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();

      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signInSilently();
        if (_currentUser == null) {
          _currentUser = await _googleSignIn.signIn();
        }
      }

      if (_currentUser != null &&
          !await _googleSignIn.requestScopes([
            calendar.CalendarApi.calendarScope,
          ])) {
        await _googleSignIn.signOut();
        _currentUser = null;
        return false;
      }

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

  Future<http.Client?> _getHttpClient() async {
    if (_currentUser == null) {
      _currentUser = await _googleSignIn.signInSilently();
    }
    if (_currentUser == null) {
      debugPrint('User not signed in.');
      return null;
    }

    // ⭐️ 1. 수정된 부분: 'final' 키워드를 제거했습니다.
    Map<String, String> authHeaders;
    try {
      authHeaders = await _currentUser!.authHeaders;
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      // authHeaders에 문제가 생기면(토큰 만료 등) 재로그인 시도
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return null;
      // ⭐️ 2. 이제 여기서 재할당이 가능합니다.
      authHeaders = await _currentUser!.authHeaders;
    }

    return _AuthenticatedClient(authHeaders, http.Client());
  }

  Future<Map<DateTime, List<calendar.Event>>> getEvents({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final httpClient = await _getHttpClient();
      if (httpClient == null) return {};

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
            final date = DateTime(
              startTime.year,
              startTime.month,
              startTime.day,
            );
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

  Future<bool> addExpiryDateEvent({
    required String ingredientName,
    required DateTime expiryDate,
  }) async {
    try {
      final httpClient = await _getHttpClient();
      if (httpClient == null) return false;

      final calendarApi = calendar.CalendarApi(httpClient);

      final event = calendar.Event(
        summary: '$ingredientName 유통기한 임박!',
        description:
            '냉장고에 있는 $ingredientName 의 유통기한이 곧 만료됩니다. 오늘 꼭 확인하고 요리하세요!',
        start: calendar.EventDateTime(date: expiryDate),
        end: calendar.EventDateTime(
          date: expiryDate.add(const Duration(days: 1)),
        ),
      );

      await calendarApi.events.insert(event, 'primary');
      return true;
    } catch (e) {
      debugPrint('Error adding event: $e');
      return false;
    }
  }
}

/// 6.x 버전을 위한 헬퍼 클래스
/// 모든 http 요청에 인증 헤더를 자동으로 추가합니다.
class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._headers, this._inner);

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
