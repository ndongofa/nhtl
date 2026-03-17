class AppNotification {
  final int id;
  final String type;
  final String title;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: json['message']?.toString(),
      isRead: (json['isRead'] is bool)
          ? (json['isRead'] as bool)
          : (json['isRead']?.toString().toLowerCase() == 'true'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
