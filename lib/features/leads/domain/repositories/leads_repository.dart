import '../entities/lead.dart';

abstract interface class LeadsRepository {
  /// Fetch all leads visible to the current user (respects RLS).
  Future<List<Lead>> getLeads();

  /// Fetch all user profiles usable as lead owners.
  Future<List<Map<String, dynamic>>> getProfiles();

  /// Create a new lead. Returns the inserted row.
  Future<Lead> createLead(Lead lead);

  /// Update an existing lead.
  Future<void> updateLead(Lead lead);

  /// Delete a lead by id.
  Future<void> deleteLead(String leadId);

  /// Assign lead to a different owner.
  Future<void> assignLead({
    required String leadId,
    required String newOwnerId,
    required String assignedById,
  });

  /// Search leads by phone/name/company (used for quote customer picker).
  /// Returns a lightweight list with only safe read-only fields.
  Future<List<Map<String, dynamic>>> searchLeadsForQuote(String query);
}
