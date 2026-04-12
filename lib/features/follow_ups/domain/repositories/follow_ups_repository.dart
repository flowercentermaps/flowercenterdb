import '../entities/follow_up.dart';

abstract interface class FollowUpsRepository {
  /// Fetch all follow-ups visible to the current user.
  Future<List<FollowUp>> getFollowUps();

  /// Create a new follow-up.
  Future<FollowUp> createFollowUp(FollowUp followUp);

  /// Update an existing follow-up.
  Future<void> updateFollowUp(FollowUp followUp);

  /// Mark a follow-up as done.
  Future<void> markDone(String followUpId);

  /// Count of pending follow-ups for badge display.
  Future<int> getPendingCount(String userId);

  /// Count of overdue follow-ups for badge display.
  Future<int> getOverdueCount(String userId);
}
