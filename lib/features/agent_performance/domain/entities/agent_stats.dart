/// Per-agent performance row from `crm_agent_performance_view`.
class AgentStats {
  final String userId;
  final String name;
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int wonLeads;
  final int lostLeads;
  final int existingClients;
  final int pendingFollowUps;
  final int overdueFollowUps;
  final int doneFollowUps;
  final int missedFollowUps;

  const AgentStats({
    required this.userId,
    required this.name,
    this.totalLeads = 0,
    this.newLeads = 0,
    this.contactedLeads = 0,
    this.qualifiedLeads = 0,
    this.wonLeads = 0,
    this.lostLeads = 0,
    this.existingClients = 0,
    this.pendingFollowUps = 0,
    this.overdueFollowUps = 0,
    this.doneFollowUps = 0,
    this.missedFollowUps = 0,
  });

  factory AgentStats.fromMap(Map<String, dynamic> map) => AgentStats(
        userId: (map['user_id'] ?? '').toString(),
        name: (map['full_name'] ?? map['name'] ?? '').toString().trim(),
        totalLeads: _i(map['total_leads']),
        newLeads: _i(map['new_leads']),
        contactedLeads: _i(map['contacted_leads']),
        qualifiedLeads: _i(map['qualified_leads']),
        wonLeads: _i(map['won_leads']),
        lostLeads: _i(map['lost_leads']),
        existingClients: _i(map['existing_client_leads']),
        pendingFollowUps: _i(map['pending_follow_ups']),
        overdueFollowUps: _i(map['overdue_follow_ups']),
        doneFollowUps: _i(map['done_follow_ups']),
        missedFollowUps: _i(map['missed_follow_ups']),
      );

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
