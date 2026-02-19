class SignupRequest {
  final String? email;
  final String? phone;
  final String username;
  final String fullName;
  final String password;
  final String confirmPassword;

  SignupRequest({
    this.email,
    this.phone,
    required this.username,
    required this.fullName,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone': phone,
        'username': username,
        'fullName': fullName,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}
