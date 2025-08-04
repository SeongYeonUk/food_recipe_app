import 'package:food_recipe_app/user/user__model.dart'; // UserModel 경로 확인

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // [수정] Map의 Key를 email이 아닌 id로 사용합니다.
  final Map<String, UserModel> _users = {};

  // [수정] signUp 메소드의 파라미터를 'email' -> 'id'로 변경합니다.
  Future<bool> signUp(String id, String password, String nickname) async {
    await Future.delayed(const Duration(seconds: 1));

    // [수정] email 대신 id로 이미 존재하는 사용자인지 확인합니다.
    if (_users.containsKey(id)) {
      print('회원가입 실패: 이미 존재하는 아이디 ($id)');
      return false;
    }

    // [수정] Map의 Key와 UserModel의 id에 모두 'id' 변수를 사용합니다.
    _users[id] = UserModel(
      id: id,
      password: password,
      nickname: nickname,
    );

    print('회원가입 성공: ${id} (${nickname})');
    return true;
  }

  // [수정] login 메소드의 파라미터도 'email' -> 'id'로 변경합니다.
  Future<bool> login(String id, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // [수정] email 대신 id로 사용자를 찾고, 비밀번호를 확인합니다.
    if (_users.containsKey(id) && _users[id]!.password == password) {
      print('로그인 성공: $id');
      return true;
    }

    print('로그인 실패: 아이디 또는 비밀번호가 일치하지 않음');
    return false;
  }
}
