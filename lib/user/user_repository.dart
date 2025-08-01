import 'package:food_recipe_app/user/user__model.dart'; // 방금 만든 UserModel import

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // 이제 사용자 정보는 UserModel 객체로 관리합니다.
  final Map<String, UserModel> _users = {};

  // signUp 메서드가 nickname도 받도록 수정합니다.
  Future<bool> signUp(String email, String password, String nickname) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(email)) {
      print('회원가입 실패: 이미 존재하는 이메일 ($email)');
      return false;
    }

    // UserModel 객체를 생성하여 저장합니다.
    _users[email] = UserModel(
      email: email,
      password: password,
      nickname: nickname,
    );

    print('회원가입 성공: ${email} (${nickname})');
    return true;
  }

  // login 메서드는 UserModel의 비밀번호를 확인하도록 수정합니다.
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // 사용자가 존재하고, 저장된 비밀번호와 일치하는지 확인합니다.
    if (_users.containsKey(email) && _users[email]!.password == password) {
      return true;
    }

    return false;
  }
}
