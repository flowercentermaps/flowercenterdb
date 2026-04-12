import '../entities/notification_item.dart';

abstract interface class NotificationsRepository {
  /// Overdue follow-ups for the current user.
  Future<List<NotificationItem>> getOverdue();

  /// Follow-ups due today.
  Future<List<NotificationItem>> getDueToday();

  /// Follow-ups due tomorrow.
  Future<List<NotificationItem>> getDueTomorrow();

  /// Recent assignment activity (lead ownership changes).
  Future<List<NotificationItem>> getRecentAssignments();

  /// Dismiss a single notification (assignment row).
  Future<void> dismiss(String notificationId);

  /// Clear all notifications of a given kind for the current user.
  Future<void> clearSection(NotificationKind kind);

  /// Total undismissed badge count.
  Future<int> getBadgeCount(String userId);
}
