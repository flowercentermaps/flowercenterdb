/// Entity for in-app notification items (follow-up urgency + assignment changes).
class NotificationItem {
  final String id;
  final NotificationKind kind;
  final String leadId;
  final String leadName;
  final String? assignedToId;
  final String? assignedToName;
  final String? changedById;
  final String? changedByName;
  final String? fromUserId;
  final String? fromUserName;
  final DateTime? dueAt;
  final DateTime? changedAt;
  final bool isDismissed;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.leadId,
    required this.leadName,
    this.assignedToId,
    this.assignedToName,
    this.changedById,
    this.changedByName,
    this.fromUserId,
    this.fromUserName,
    this.dueAt,
    this.changedAt,
    this.isDismissed = false,
  });

  factory NotificationItem.fromFollowUpMap(Map<String, dynamic> map) {
    final leadMap = map['lead'] as Map<String, dynamic>? ?? {};
    final due = map['due_at'] != null
        ? DateTime.tryParse(map['due_at'].toString())
        : null;
    final now = DateTime.now();
    NotificationKind kind;
    if (due != null && due.isBefore(now)) {
      kind = NotificationKind.overdue;
    } else if (due != null && due.day == now.day && due.month == now.month && due.year == now.year) {
      kind = NotificationKind.dueToday;
    } else {
      kind = NotificationKind.dueTomorrow;
    }
    return NotificationItem(
      id: (map['id'] ?? '').toString(),
      kind: kind,
      leadId: (map['lead_id'] ?? '').toString(),
      leadName: (leadMap['name'] ?? 'Unnamed Lead').toString(),
      assignedToId: map['assigned_to']?.toString(),
      dueAt: due,
    );
  }

  factory NotificationItem.fromAssignmentMap(Map<String, dynamic> map) {
    final leadMap = map['lead'] as Map<String, dynamic>? ?? {};
    return NotificationItem(
      id: (map['id'] ?? '').toString(),
      kind: NotificationKind.assignment,
      leadId: (map['lead_id'] ?? '').toString(),
      leadName: (leadMap['name'] ?? 'Unnamed Lead').toString(),
      fromUserId: map['from_user_id']?.toString(),
      fromUserName: map['from_user_name']?.toString(),
      assignedToId: map['to_user_id']?.toString(),
      assignedToName: map['to_user_name']?.toString(),
      changedById: map['changed_by_id']?.toString(),
      changedByName: map['changed_by_name']?.toString(),
      changedAt: map['changed_at'] != null
          ? DateTime.tryParse(map['changed_at'].toString())
          : null,
      isDismissed: map['is_dismissed'] == true,
    );
  }
}

enum NotificationKind { overdue, dueToday, dueTomorrow, assignment }
