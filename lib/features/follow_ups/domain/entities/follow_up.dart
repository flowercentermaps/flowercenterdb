/// Typed entity for a row in the `follow_ups` table.
class FollowUp {
  final String id;
  final String leadId;
  final String? leadName;
  final String? leadPhone;
  final String assignedToId;
  final String? assignedToName;
  final String status; // 'pending' | 'done' | 'missed' | 'overdue'
  final String? notes;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const FollowUp({
    required this.id,
    required this.leadId,
    this.leadName,
    this.leadPhone,
    required this.assignedToId,
    this.assignedToName,
    this.status = 'pending',
    this.notes,
    this.dueAt,
    this.completedAt,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isDone => status == 'done';
  bool get isMissed => status == 'missed';
  bool get isOverdue => status == 'overdue';

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    final leadMap = map['lead'] as Map<String, dynamic>?;
    final assigneeMap = map['assigned_to_profile'] as Map<String, dynamic>?
        ?? map['profiles'] as Map<String, dynamic>?;
    return FollowUp(
      id: (map['id'] ?? '').toString(),
      leadId: (map['lead_id'] ?? '').toString(),
      leadName: leadMap?['name']?.toString(),
      leadPhone: leadMap?['phone']?.toString(),
      assignedToId: (map['assigned_to'] ?? '').toString(),
      assignedToName: assigneeMap?['full_name']?.toString()
          ?? assigneeMap?['name']?.toString(),
      status: (map['status'] ?? 'pending').toString(),
      notes: map['notes']?.toString(),
      dueAt: map['due_at'] != null
          ? DateTime.tryParse(map['due_at'].toString())
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'lead_id': leadId,
        'assigned_to': assignedToId,
        'status': status,
        if (notes != null) 'notes': notes,
        if (dueAt != null) 'due_at': dueAt!.toIso8601String(),
      };
}
