class AuthResult {
  bool success;
  String errorMessage;

  AuthResult({required this.success, this.errorMessage = ''});
}