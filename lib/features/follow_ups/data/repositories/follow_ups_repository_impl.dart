import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/follow_up.dart';
import '../../domain/repositories/follow_ups_repository.dart';

class FollowUpsRepositoryImpl implements FollowUpsRepository {
  final SupabaseClient _client;

  const FollowUpsRepositoryImpl(this._client);

  static const _select =
      '*, lead:leads(id, name, phone), '
      'assigned_to_profile:profiles!assigned_to(id, full_name)';

  @override
  Future<List<FollowUp>> getFollowUps() async {
    try {
      final response = await _client
          .from('follow_ups')
          .select(_select)
          .order('due_at', ascending: true);
      return (response as List)
          .map((e) => FollowUp.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<FollowUp> createFollowUp(FollowUp followUp) async {
    try {
      final inserted = await _client
          .from('follow_ups')
          .insert(followUp.toInsertMap())
          .select(_select)
          .single();
      return FollowUp.fromMap(Map<String, dynamic>.from(inserted));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateFollowUp(FollowUp followUp) async {
    try {
      await _client.from('follow_ups').update({
        'status': followUp.status,
        'notes': followUp.notes,
        'due_at': followUp.dueAt?.toIso8601String(),
        'assigned_to': followUp.assignedToId,
      }).eq('id', followUp.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markDone(String followUpId) async {
    try {
      await _client.from('follow_ups').update({
        'status': 'done',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', followUpId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getPendingCount(String userId) async {
    try {
      final response = await _client
          .from('follow_ups')
          .select('id')
          .eq('assigned_to', userId)
          .eq('status', 'pending');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getOverdueCount(String userId) async {
    try {
      final response = await _client
          .from('follow_ups')
          .select('id')
          .eq('assigned_to', userId)
          .eq('status', 'overdue');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
