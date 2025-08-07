// frontend/lib/user/user_model.dart

class UserModel {
  // [수정] id -> uid 로 변경하여 프로젝트 전체의 용어를 통일합니다.
  final String uid;
  final String password;
  final String nickname;

  UserModel({
    // [수정] id -> uid 로 변경
    required this.uid,
    required this.password,
    required this.nickname,
  });
}
