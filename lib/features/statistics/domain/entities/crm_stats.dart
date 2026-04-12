/// Aggregated CRM statistics from `crm_statistics_view`.
class CrmStats {
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int wonLeads;
  final int lostLeads;
  final int existingClients;
  final int importantLeads;
  final int pendingFollowUps;
  final int overdueFollowUps;
  final int doneFollowUps;
  final int missedFollowUps;

  const CrmStats({
    this.totalLeads = 0,
    this.newLeads = 0,
    this.contactedLeads = 0,
    this.qualifiedLeads = 0,
    this.wonLeads = 0,
    this.lostLeads = 0,
    this.existingClients = 0,
    this.importantLeads = 0,
    this.pendingFollowUps = 0,
    this.overdueFollowUps = 0,
    this.doneFollowUps = 0,
    this.missedFollowUps = 0,
  });

  factory CrmStats.fromMaps(
    Map<String, dynamic> leadMap,
    Map<String, dynamic> followUpMap,
  ) =>
      CrmStats(
        totalLeads: _i(leadMap['total_leads']),
        newLeads: _i(leadMap['new_leads']),
        contactedLeads: _i(leadMap['contacted_leads']),
        qualifiedLeads: _i(leadMap['qualified_leads']),
        wonLeads: _i(leadMap['won_leads']),
        lostLeads: _i(leadMap['lost_leads']),
        existingClients: _i(leadMap['existing_client_leads']),
        importantLeads: _i(leadMap['important_leads']),
        pendingFollowUps: _i(followUpMap['pending_follow_ups']),
        overdueFollowUps: _i(followUpMap['overdue_follow_ups']),
        doneFollowUps: _i(followUpMap['done_follow_ups']),
        missedFollowUps: _i(followUpMap['missed_follow_ups']),
      );

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
