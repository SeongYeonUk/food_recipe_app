class AuthStatus {

  AuthStatus.privateConstructor();


  static final AuthStatus instance = AuthStatus.privateConstructor();


  factory AuthStatus() {
    return instance;
  }

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  void logout() {
    _token = null;
  }
}