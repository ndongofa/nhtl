class LoginResponse {
  final String userId;
  final String email;
  final String phone;
  final String fullName;
  final String role;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  LoginResponse({
    required this.userId,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'user',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 86400,
    );
  }
}
