class UserRepository {
  static final UserRepository _instance = UserRepository._internal();

  factory UserRepository() {
    return _instance;
  }

  UserRepository._internal();

  // 사용자 정보를 저장할 Map (key: 이메일, value: 비밀번호)
  // final 키워드를 사용하여 이 Map이 다른 Map으로 교체되는 것을 방지합니다.
  final Map<String, String> _users = {};

  /// 회원가입 메서드
  /// [email]과 [password]를 받아 저장합니다.
  Future<bool> signUp(String email, String password) async {
    // 실제 서버와 통신하는 것처럼 보이게 하기 위해 1초의 딜레이를 줍니다.
    // Future.delayed를 사용하면 비동기 처리를 흉내 낼 수 있습니다.
    await Future.delayed(const Duration(seconds: 1));

    // 이미 존재하는 이메일인지 확인합니다.
    if (_users.containsKey(email)) {
      // 디버깅을 위해 콘솔에 실패 로그를 출력합니다.
      print('회원가입 실패: 이미 존재하는 이메일 ($email)');
      return false; // 이미 이메일이 존재하면 false를 반환합니다.
    }

    // 새 사용자 정보를 Map에 저장합니다.
    _users[email] = password;

    // 디버깅을 위해 콘솔에 현재 저장된 모든 사용자 목록을 출력합니다.
    print('회원가입 성공: 현재 사용자 목록 -> $_users');
    return true; // 회원가입에 성공하면 true를 반환합니다.
  }

  /// (참고) 나중에 로그인 기능 구현 시 사용할 메서드
  Future<bool> login(String email, String password) async {
    // 마찬가지로 네트워크 딜레이를 흉내 냅니다.
    await Future.delayed(const Duration(seconds: 1));

    // 이메일이 존재하지 않거나, 비밀번호가 일치하지 않으면 false를 반환합니다.
    if (!_users.containsKey(email) || _users[email] != password) {
      return false;
    }

    // 모든 조건이 맞으면 로그인 성공으로 간주하고 true를 반환합니다.
    return true;
  }
}