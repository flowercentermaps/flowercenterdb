import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/leads_repository.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  final SupabaseClient _client;

  const LeadsRepositoryImpl(this._client);

  @override
  Future<List<Lead>> getLeads() async {
    try {
      final response = await _client
          .from('leads')
          .select('*, owner:profiles!owner_id(id, full_name, email, role)')
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Lead.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProfiles() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email, role, is_active')
          .order('full_name', ascending: true);
      return (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Lead> createLead(Lead lead) async {
    try {
      final inserted = await _client
          .from('leads')
          .insert(lead.toInsertMap())
          .select('*, owner:profiles!owner_id(id, full_name, email, role)')
          .single();
      return Lead.fromMap(Map<String, dynamic>.from(inserted));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateLead(Lead lead) async {
    try {
      await _client
          .from('leads')
          .update(lead.toInsertMap())
          .eq('id', lead.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteLead(String leadId) async {
    try {
      await _client.from('leads').delete().eq('id', leadId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> assignLead({
    required String leadId,
    required String newOwnerId,
    required String assignedById,
  }) async {
    try {
      await _client.from('leads').update({
        'owner_id': newOwnerId,
        'assigned_by': assignedById,
      }).eq('id', leadId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchLeadsForQuote(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      // Try RPC first (bypasses RLS for cross-scope search), fall back to direct query
      try {
        final result = await _client.rpc(
          'search_leads_for_quote',
          params: {'query': query.trim()},
        );
        return (result as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        // Fall back to direct query (sales users see only their leads)
        final response = await _client
            .from('leads')
            .select('id, name, phone, company, status')
            .or('name.ilike.%$query%,phone.ilike.%$query%,company.ilike.%$query%')
            .limit(20);
        return (response as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
