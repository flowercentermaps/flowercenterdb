import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> lead;
  final Map<String, dynamic> profile;

  const CustomerProfileScreen({
    super.key,
    required this.lead,
    required this.profile,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allLeads = [];
  List<Map<String, dynamic>> _followUps = [];
  Map<String, Map<String, dynamic>> _profileMap = {};

  String _text(dynamic value) => (value ?? '').toString().trim();

  String get _phone => _text(widget.lead['phone']);
  String get _name => _text(widget.lead['name']);
  String get _email => _text(widget.lead['email']);
  String get _companyName => _text(widget.lead['company_name']);
  String get _companyTrn => _text(widget.lead['company_trn']);
  String get _leadType => _text(widget.lead['lead_type']);

  String get _displayName {
    if (_name.isNotEmpty) return _name;
    if (_companyName.isNotEmpty) return _companyName;
    if (_phone.isNotEmpty) return _phone;
    return 'Unknown Customer';
  }

  String get _initials {
    final n = _displayName.trim();
    final parts = n.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all leads with the same phone number
      dynamic query = _supabase
          .from('leads')
          .select()
          .order('created_at', ascending: false);

      if (_phone.isNotEmpty) {
        query = _supabase
            .from('leads')
            .select()
            .eq('phone', _phone)
            .order('created_at', ascending: false);
      } else {
        query = _supabase
            .from('leads')
            .select()
            .eq('id', _text(widget.lead['id']))
            .order('created_at', ascending: false);
      }

      final leadsResponse = await query;
      final leads = (leadsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Collect all profile IDs from leads
      final profileIds = <String>{};
      for (final l in leads) {
        for (final key in ['owner_id', 'created_by', 'assigned_by']) {
          final id = _text(l[key]);
          if (id.isNotEmpty) profileIds.add(id);
        }
      }

      final profileMap = <String, Map<String, dynamic>>{};
      if (profileIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, full_name, email, role')
            .inFilter('id', profileIds.toList());
        for (final row in profilesResponse as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = _text(map['id']);
          if (id.isNotEmpty) profileMap[id] = map;
        }
      }

      // Load follow-ups for all lead IDs
      final leadIds = leads
          .map((l) => _text(l['id']))
          .where((id) => id.isNotEmpty)
          .toList();

      List<Map<String, dynamic>> followUps = [];
      if (leadIds.isNotEmpty) {
        final followUpsResponse = await _supabase
            .from('follow_ups')
            .select()
            .inFilter('lead_id', leadIds)
            .order('due_at', ascending: false);
        followUps = (followUpsResponse as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (!mounted) return;

      setState(() {
        _allLeads = leads;
        _profileMap = profileMap;
        _followUps = followUps;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xFF8C6B16);
      case 'contacted':
        return const Color(0xFF1976D2);
      case 'qualified':
        return const Color(0xFF2E7D32);
      case 'closed_won':
        return const Color(0xFF00A86B);
      case 'closed_lost':
        return const Color(0xFFB00020);
      default:
        return const Color(0xFF555555);
    }
  }

  Color _followUpStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF1976D2);
      case 'done':
        return const Color(0xFF00A86B);
      case 'missed':
        return const Color(0xFFB00020);
      case 'overdue':
        return const Color(0xFFFF6B35);
      default:
        return const Color(0xFF555555);
    }
  }

  String _profileLabel(String? userId) {
    final id = _text(userId);
    if (id.isEmpty) return 'Unassigned';
    final p = _profileMap[id];
    if (p == null) return 'Unknown';
    final fullName = _text(p['full_name']);
    final email = _text(p['email']);
    return fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : 'Unknown');
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final dt = DateTime.tryParse(value.toString())?.toLocal();
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _displayName,
          style: const TextStyle(fontWeight: FontWeight.w900),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF30260A)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildContactInfo(),
            const SizedBox(height: 24),
            _buildLeadsSection(),
            if (_followUps.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildFollowUpsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (_phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppConstants.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        _phone,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 14, color: AppConstants.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${_allLeads.length} Lead${_allLeads.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_leadType.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _leadType.toUpperCase(),
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final hasInfo = _phone.isNotEmpty ||
        _email.isNotEmpty ||
        _companyName.isNotEmpty ||
        _companyTrn.isNotEmpty;

    return _Section(
      title: 'Contact Information',
      icon: Icons.contact_page_outlined,
      child: hasInfo
          ? Column(
              children: [
                if (_phone.isNotEmpty)
                  _InfoRow(
                      label: 'Phone',
                      value: _phone,
                      icon: Icons.phone_outlined),
                if (_email.isNotEmpty)
                  _InfoRow(
                      label: 'Email',
                      value: _email,
                      icon: Icons.email_outlined),
                if (_companyName.isNotEmpty)
                  _InfoRow(
                      label: 'Company',
                      value: _companyName,
                      icon: Icons.business_outlined),
                if (_companyTrn.isNotEmpty)
                  _InfoRow(
                      label: 'TRN',
                      value: _companyTrn,
                      icon: Icons.numbers_outlined),
                if (_leadType.isNotEmpty)
                  _InfoRow(
                      label: 'Type',
                      value: _leadType.toUpperCase(),
                      icon: Icons.person_outline_rounded),
              ],
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No contact information available.',
                style: TextStyle(color: Colors.white38),
              ),
            ),
    );
  }

  Widget _buildLeadsSection() {
    return _Section(
      title: 'Lead History',
      icon: Icons.history_rounded,
      child: _allLeads.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No leads found.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          : Column(
              children: _allLeads.map((lead) {
                final status = _text(lead['status']);
                final statusColor = _statusColor(status);
                final leadName = _text(lead['name']).isNotEmpty
                    ? _text(lead['name'])
                    : (_text(lead['company_name']).isNotEmpty
                        ? _text(lead['company_name'])
                        : 'Unnamed Lead');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2000)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              leadName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.35)),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 13, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            'Owner: ${_profileLabel(lead['owner_id'])}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(lead['created_at']),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                      if (_text(lead['notes']).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _text(lead['notes']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFollowUpsSection() {
    return _Section(
      title: 'Follow-Up History',
      icon: Icons.event_note_outlined,
      child: Column(
        children: _followUps.map((fu) {
          final status = _text(fu['status']);
          final statusColor = _followUpStatusColor(status);
          final notes = _text(fu['notes']);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2000)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 10),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notes.isNotEmpty ? notes : 'Follow-up',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${_formatDate(fu['due_at'])}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 17, color: AppConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
