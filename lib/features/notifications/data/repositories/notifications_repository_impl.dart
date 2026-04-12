import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final SupabaseClient _client;

  const NotificationsRepositoryImpl(this._client);

  @override
  Future<List<NotificationItem>> getOverdue() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('follow_ups')
          .select('*, lead:leads(id, name)')
          .eq('status', 'pending')
          .lt('due_at', now)
          .order('due_at', ascending: true);
      return (response as List)
          .map((e) => NotificationItem.fromFollowUpMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NotificationItem>> getDueToday() async {
    try {
      final now = DateTime.now();
      final start =
          DateTime(now.year, now.month, now.day).toIso8601String();
      final end =
          DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      final response = await _client
          .from('follow_ups')
          .select('*, lead:leads(id, name)')
          .eq('status', 'pending')
          .gte('due_at', start)
          .lte('due_at', end)
          .order('due_at', ascending: true);
      return (response as List)
          .map((e) => NotificationItem.fromFollowUpMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NotificationItem>> getDueTomorrow() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final start =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day).toIso8601String();
      final end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59)
          .toIso8601String();
      final response = await _client
          .from('follow_ups')
          .select('*, lead:leads(id, name)')
          .eq('status', 'pending')
          .gte('due_at', start)
          .lte('due_at', end)
          .order('due_at', ascending: true);
      return (response as List)
          .map((e) => NotificationItem.fromFollowUpMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NotificationItem>> getRecentAssignments() async {
    try {
      final response = await _client
          .from('activity_logs')
          .select('*, lead:leads(id, name)')
          .eq('action', 'assign')
          .eq('is_dismissed', false)
          .order('changed_at', ascending: false)
          .limit(50);
      return (response as List)
          .map((e) => NotificationItem.fromAssignmentMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> dismiss(String notificationId) async {
    try {
      await _client
          .from('activity_logs')
          .update({'is_dismissed': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> clearSection(NotificationKind kind) async {
    // Only assignment notifications are stored in DB; follow-up sections
    // don't have persistent dismiss — clearing them is a local-only op.
    if (kind != NotificationKind.assignment) return;
    try {
      await _client
          .from('activity_logs')
          .update({'is_dismissed': true})
          .eq('action', 'assign')
          .eq('is_dismissed', false);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getBadgeCount(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final overdue = await _client
          .from('follow_ups')
          .select('id')
          .eq('assigned_to', userId)
          .eq('status', 'pending')
          .lt('due_at', now);
      final assignments = await _client
          .from('activity_logs')
          .select('id')
          .eq('is_dismissed', false);
      return (overdue as List).length + (assignments as List).length;
    } catch (e) {
      return 0;
    }
  }
}
