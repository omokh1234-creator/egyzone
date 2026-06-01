class AppNotification {
  final dynamic notificationId;
  final String message;
  final bool isRead;
  final String? createdAt;
  final dynamic userId;

  AppNotification({
    this.notificationId,
    required this.message,
    this.isRead = false,
    this.createdAt,
    this.userId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? json['id'],
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      userId: json['userId'],
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      notificationId: notificationId,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      userId: userId,
    );
  }
}
