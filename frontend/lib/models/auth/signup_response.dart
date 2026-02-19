class SignupResponse {
  final String userId;
  final String email;
  final String phone;
  final String username;
  final String message;

  SignupResponse({
    required this.userId,
    required this.email,
    required this.phone,
    required this.username,
    required this.message,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
