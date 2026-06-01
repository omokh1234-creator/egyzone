import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import '../services/auth_service.dart';

class NotificationService {
  /// Fetch all notifications for the authenticated user
  static Future<List<AppNotification>> getNotifications() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Notifications'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load notifications: ${response.statusCode} - ${response.body}');
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(dynamic notificationId) async {
    final headers = await AuthService.authHeaders;
    final response = await http.put(
      Uri.parse(
          '${AuthService.baseUrl}/api/Notifications/$notificationId/read'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to mark notification as read: ${response.statusCode}');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(dynamic notificationId) async {
    final headers = await AuthService.authHeaders;
    final response = await http.delete(
      Uri.parse(
          '${AuthService.baseUrl}/api/Notifications/$notificationId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete notification: ${response.statusCode}');
    }
  }
}
