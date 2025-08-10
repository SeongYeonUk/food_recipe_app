// frontend/lib/user/user_model.dart
// 이 파일의 내용을 아래 코드로 완전히 교체해주세요.

class UserModel {
  UserModel.privateConstructor();

  static final UserModel _instance = UserModel.privateConstructor();
  factory UserModel() {
    return _instance;
  }

  String? uid;
  String? nickname;

  void loadFromMap(Map<String, dynamic> data) {
    uid = data['uid'];
    nickname = data['nickname'];
  }

  void clear() {
    uid = null;
    nickname = null;
  }
}

