import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Fetch all notifications from the API
  Future<void> fetchNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read (optimistic update + API call)
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere(
      (n) => n.notificationId == notificationId,
    );

    if (index >= 0 && !_notifications[index].isRead) {
      // Optimistic update
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        await NotificationService.markAsRead(notificationId);
      } catch (_) {
        // Revert on failure
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
      }
    }
  }

  /// Delete a notification (optimistic update + API call)
  Future<void> deleteNotification(int notificationId) async {
    final removed = _notifications
        .where((n) => n.notificationId == notificationId)
        .toList();

    // Optimistic update
    _notifications.removeWhere(
      (n) => n.notificationId == notificationId,
    );
    notifyListeners();

    try {
      await NotificationService.deleteNotification(notificationId);
    } catch (_) {
      // Revert on failure
      _notifications.addAll(removed);
      notifyListeners();
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markAsRead(n.notificationId);
    }
  }
}
