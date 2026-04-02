import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class LeadsScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool initialImportantOnly;
  final String? initialStatus;
  final bool showOwnHeader;
  final String? customTitle;
  final bool allowCreate;
  const LeadsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.initialImportantOnly = false,
    this.initialStatus,
    this.showOwnHeader = true,
    this.customTitle,
    this.allowCreate = true,
  });
  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;

  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allLeads = [];
  List<Map<String, dynamic>> _filteredLeads = [];

  String _searchQuery = '';
  String? _selectedStatus;
  bool _importantOnly = false;

  static const List<String> _statuses = <String>[
    'new',
    'contacted',
    'qualified',
    'closed_won',
    'closed_lost',
  ];

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isViewer => _role == 'viewer';
  bool get _isAccountant => _role == 'accountant';

  bool get _canCreateLead => _isAdmin || _isSales;
  bool get _canEditLead => _isAdmin || _isSales;
  bool get _isReadOnly => _isViewer || _isAccountant;

  String get _currentUserId =>
      (widget.profile['id'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _importantOnly = widget.initialImportantOnly;
    _selectedStatus = widget.initialStatus;
    _searchController.addListener(_onSearchChanged);
    _setupRealtime();
    _loadLeads();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    final channel = _realtimeChannel;
    _realtimeChannel = null;
    if (channel != null) {
      unawaited(_supabase.removeChannel(channel));
    }

    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payloadMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  Future<void> _loadSingleLeadAndUpsert(String leadId) async {
    if (leadId.isEmpty) return;

    try {
      final response = await _supabase
          .from('leads')
          .select()
          .eq('id', leadId)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _removeLeadLocally(leadId);
          _applyFilters();
        });
        return;
      }

      final lead = Map<String, dynamic>.from(response as Map);

      setState(() {
        _upsertLeadLocally(lead);
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _handleAssignmentLogRealtime(PostgresChangePayload payload) async {
    if (!mounted || !_isSales || _currentUserId.isEmpty) return;

    final row = _payloadMap(payload.newRecord);
    if (_text(row['action_type']) != 'assign_lead') return;

    final leadId = _text(row['lead_id']);
    final meta = _payloadMap(row['meta']);
    final oldOwnerId = _text(meta['old_owner_id']);
    final newOwnerId = _text(meta['new_owner_id']);

    final wasMine = oldOwnerId == _currentUserId;
    final isNowMine = newOwnerId == _currentUserId;

    if (wasMine && !isNowMine) {
      if (!mounted) return;
      setState(() {
        _removeLeadLocally(leadId);
        _applyFilters();
      });
      return;
    }

    if (isNowMine) {
      await _loadSingleLeadAndUpsert(leadId);
    }
  }
  void _setupRealtime() {
    final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;

    _realtimeChannel = _supabase
        .channel('crm-leads-live-$channelKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'leads',
      callback: _handleLeadRealtime,
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'activity_logs',
      callback: _handleAssignmentLogRealtime,
    )
        .subscribe();
  }

  void _handleLeadRealtime(PostgresChangePayload payload) {
    if (!mounted) return;

    final eventType = payload.eventType;
    final newRow = Map<String, dynamic>.from(payload.newRecord);
    final oldRow = Map<String, dynamic>.from(payload.oldRecord);

    setState(() {
      switch (eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          if (newRow.isEmpty) return;
          _upsertLeadLocally(newRow);
          break;

        case PostgresChangeEvent.delete:
          final deletedId = _text(oldRow['id']);
          if (deletedId.isEmpty) return;
          _removeLeadLocally(deletedId);
          _applyFilters();
          break;

        default:
          break;
      }
    });
  }

  bool _matchesLeadVisibility(Map<String, dynamic> lead) {
    if (_isAdmin || _isViewer || _isAccountant) return true;

    if (_isSales) {
      final ownerId = _text(lead['owner_id']);
      return ownerId == _currentUserId;
    }

    return false;
  }

  void _removeLeadLocally(String leadId) {
    _allLeads.removeWhere((lead) => _text(lead['id']) == leadId);
  }

  void _sortLeadsLocally() {
    _allLeads.sort((a, b) {
      final aUpdated = _parseDateTime(a['updated_at']);
      final bUpdated = _parseDateTime(b['updated_at']);
      final aCreated = _parseDateTime(a['created_at']);
      final bCreated = _parseDateTime(b['created_at']);

      if (aUpdated != null && bUpdated != null) {
        final byUpdated = bUpdated.compareTo(aUpdated);
        if (byUpdated != 0) return byUpdated;
      } else if (aUpdated != null) {
        return -1;
      } else if (bUpdated != null) {
        return 1;
      }

      if (aCreated != null && bCreated != null) {
        return bCreated.compareTo(aCreated);
      } else if (aCreated != null) {
        return -1;
      } else if (bCreated != null) {
        return 1;
      }

      return 0;
    });
  }

  void _upsertLeadLocally(Map<String, dynamic> lead) {
    final leadId = _text(lead['id']);
    if (leadId.isEmpty) return;

    _removeLeadLocally(leadId);

    if (!_matchesLeadVisibility(lead)) {
      _applyFilters();
      return;
    }

    _allLeads.add(lead);
    _sortLeadsLocally();
    _applyFilters();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _applyFilters();
      });
    });
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('leads')
          .select()
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false);

      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _allLeads = rows;
        _applyFilters();
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

  void _applyFilters() {
    final search = _searchQuery;

    _filteredLeads = _allLeads.where((lead) {
      final name = _text(lead['name']).toLowerCase();
      final phone = _text(lead['phone']).toLowerCase();
      final email = _text(lead['email']).toLowerCase();
      final companyName = _text(lead['company_name']).toLowerCase();
      final status = _text(lead['status']).toLowerCase();
      final isImportant = lead['is_important'] == true;

      final matchesSearch = search.isEmpty ||
          name.contains(search) ||
          phone.contains(search) ||
          email.contains(search) ||
          companyName.contains(search);

      final matchesStatus =
          _selectedStatus == null || status == _selectedStatus;

      final matchesImportant = !_importantOnly || isImportant;

      return matchesSearch && matchesStatus && matchesImportant;
    }).toList();
  }

  Future<void> _openCreateLeadDialog() async {
    final result = await showDialog<_LeadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadFormDialog(
        title: 'Create Lead',
        submitLabel: 'Create',
        currentUserId: _currentUserId,
      ),
    );

    if (result == null) return;

    try {
      final payload = result.toInsertPayload(
        currentUserId: _currentUserId,
      );

      final inserted = await _supabase
          .from('leads')
          .insert(payload)
          .select()
          .single();

      final leadId = (inserted['id'] ?? '').toString();

      await _ensurePendingFollowUpForLead(
        leadId: leadId,
        requiresFollowUp: result.requiresFollowUp,
      );

      if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
        await _logActivity(
          leadId: leadId,
          actionType: 'create_lead',
          meta: {
            'status': result.status,
            'lead_type': result.leadType,
            'is_important': result.isImportant,
            'requires_follow_up': result.requiresFollowUp,
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead created successfully.')),
      );

      await _loadLeads();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lead: $e')),
      );
    }
  }

  Future<void> _openEditLeadDialog(Map<String, dynamic> lead) async {
    final result = await showDialog<_LeadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadFormDialog(
        title: 'Edit Lead',
        submitLabel: 'Save',
        initialLead: lead,
        currentUserId: _currentUserId,
      ),
    );

    if (result == null) return;

    final leadId = (lead['id'] ?? '').toString();
    if (leadId.isEmpty) return;

    try {
      final oldRequiresFollowUp = lead['requires_follow_up'] == true;
      final newRequiresFollowUp = result.requiresFollowUp;

      await _supabase
          .from('leads')
          .update(result.toUpdatePayload())
          .eq('id', leadId);

      if (!oldRequiresFollowUp && newRequiresFollowUp) {
        await _ensurePendingFollowUpForLead(
          leadId: leadId,
          requiresFollowUp: true,
        );
      }

      await _logActivity(
        leadId: leadId,
        actionType: 'update_lead',
        meta: {
          'status': result.status,
          'lead_type': result.leadType,
          'is_important': result.isImportant,
          'requires_follow_up': result.requiresFollowUp,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead updated successfully.')),
      );

      await _loadLeads();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update lead: $e')),
      );
    }
  }

  Future<void> _showLeadDetails(Map<String, dynamic> lead) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return LeadDetailsSheet(
          lead: lead,
          canEdit: _canEditLead,
          onEdit: _canEditLead
              ? () async {
            Navigator.of(context).pop();
            await _openEditLeadDialog(lead);
          }
              : null,
        );
      },
    );
  }

  Future<void> _logActivity({
    required String leadId,
    required String actionType,
    required Map<String, dynamic> meta,
  }) async {
    if (_currentUserId.isEmpty) return;

    try {
      await _supabase.from('activity_logs').insert({
        'actor_id': _currentUserId,
        'lead_id': leadId,
        'action_type': actionType,
        'meta': meta,
      });
    } catch (_) {}
  }

  Future<void> _ensurePendingFollowUpForLead({
    required String leadId,
    required bool requiresFollowUp,
  }) async {
    if (!requiresFollowUp || leadId.isEmpty) return;

    try {
      final existing = await _supabase
          .from('follow_ups')
          .select('id, status')
          .eq('lead_id', leadId)
          .neq('status', 'done')
          .limit(1);

      final existingRows = (existing as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (existingRows.isNotEmpty) return;

      await _supabase.from('follow_ups').insert({
        'lead_id': leadId,
        'assigned_to': _currentUserId.isEmpty ? null : _currentUserId,
        'due_at': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'status': 'pending',
        'notes': 'Auto-created from lead follow-up flag',
      });
    } catch (e) {
      debugPrint('AUTO FOLLOW-UP CREATE FAILED: $e');
      rethrow;
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _importantOnly = false;
      _applyFilters();
    });
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _displayName() {
    final fullName = _text(widget.profile['full_name']);
    final email = _text(widget.profile['email']);
    return fullName.isNotEmpty ? fullName : email;
  }

  bool _missingName(Map<String, dynamic> lead) {
    if (lead['missing_name'] is bool) return lead['missing_name'] == true;
    return _text(lead['name']).isEmpty;
  }

  bool _missingPhone(Map<String, dynamic> lead) {
    if (lead['missing_phone'] is bool) return lead['missing_phone'] == true;
    return _text(lead['phone']).isEmpty;
  }

  bool _missingEmail(Map<String, dynamic> lead) {
    if (lead['missing_email'] is bool) return lead['missing_email'] == true;
    return _text(lead['email']).isEmpty;
  }

  List<String> _missingFields(Map<String, dynamic> lead) {
    final list = <String>[];
    if (_missingName(lead)) list.add('Name');
    if (_missingPhone(lead)) list.add('Phone');
    if (_missingEmail(lead)) list.add('Email');
    return list;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: (_canCreateLead && widget.allowCreate)
          ? FloatingActionButton.extended(
        onPressed: _openCreateLeadDialog,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('New Lead'),
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _LeadsHeader(
              title: widget.customTitle ?? 'Leads',
              showOwnHeader: widget.showOwnHeader,
              searchController: _searchController,
              selectedStatus: _selectedStatus,
              statuses: _statuses,
              importantOnly: _importantOnly,
              visibleCount: _filteredLeads.length,
              totalCount: _allLeads.length,
              profileName: _displayName(),
              role: _role,
              isReadOnly: _isReadOnly,
              onStatusChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _applyFilters();
                });
              },
              onImportantOnlyChanged: (value) {
                setState(() {
                  _importantOnly = value;
                  _applyFilters();
                });
              },
              onClearFilters: _clearFilters,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBody(theme, isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isWide) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3A2F0B)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load leads',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadLeads,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredLeads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3A2F0B)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 46,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  _allLeads.isEmpty
                      ? 'No leads yet'
                      : 'No leads match the current filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _allLeads.isEmpty
                      ? (_canCreateLead
                      ? 'Create your first lead to start using the CRM module.'
                      : 'There are no leads available for your account.')
                      : 'Try adjusting the search or filter values.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadLeads,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                    if (_canCreateLead && _allLeads.isEmpty)
                      FilledButton.icon(
                        onPressed: _openCreateLeadDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Lead'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeads,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          isWide ? 20 : 14,
          16,
          isWide ? 20 : 14,
          100,
        ),
        itemCount: _filteredLeads.length,
        itemBuilder: (context, index) {
          final lead = _filteredLeads[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _LeadCard(
              lead: lead,
              canEdit: _canEditLead,
              missingFields: _missingFields(lead),
              statusColor: _statusColor(_text(lead['status']).toLowerCase()),
              onTap: () => _showLeadDetails(lead),
              onEdit: _canEditLead ? () => _openEditLeadDialog(lead) : null,
            ),
          );
        },
      ),
    );
  }
}
class _LeadsHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final TextEditingController searchController;
  final String? selectedStatus;
  final List<String> statuses;
  final bool importantOnly;
  final int visibleCount;
  final int totalCount;
  final String profileName;
  final String role;
  final bool isReadOnly;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<bool> onImportantOnlyChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onLogout;

  const _LeadsHeader({
    required this.title,
    required this.showOwnHeader,
    required this.searchController,
    required this.selectedStatus,
    required this.statuses,
    required this.importantOnly,
    required this.visibleCount,
    required this.totalCount,
    required this.profileName,
    required this.role,
    required this.isReadOnly,
    required this.onStatusChanged,
    required this.onImportantOnlyChanged,
    required this.onClearFilters,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWide = MediaQuery.of(context).size.width >= 860;
    final bool hasFilters =
        searchController.text.trim().isNotEmpty ||
            selectedStatus != null ||
            importantOnly;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF3A2F0B)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row(
          //   children: [
          //     Container(
          //       width: 44,
          //       height: 44,
          //       padding: const EdgeInsets.all(3),
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(14),
          //         gradient: const LinearGradient(
          //           colors: [
          //             AppConstants.primaryColor,
          //             Color(0xFF8C6B16),
          //           ],
          //         ),
          //       ),
          //       child: const Icon(
          //         Icons.people_alt_outlined,
          //         color: Color(0xFF111111),
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: Text(
          //         'Leads',
          //         style: theme.textTheme.headlineSmall?.copyWith(
          //           fontWeight: FontWeight.w900,
          //         ),
          //       ),
          //     ),
          //     if (isWide)
          //       _ProfileMenu(
          //         profileName: profileName,
          //         role: role,
          //         onLogout: onLogout,
          //       )
          //     else
          //       PopupMenuButton<String>(
          //         onSelected: (value) async {
          //           if (value == 'logout') {
          //             await onLogout();
          //           }
          //         },
          //         itemBuilder: (_) => const [
          //           PopupMenuItem<String>(
          //             value: 'logout',
          //             child: Text('Logout'),
          //           ),
          //         ],
          //         icon: const Icon(Icons.account_circle_outlined),
          //       ),
          //   ],
          // ),
          if (showOwnHeader)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD4AF37),
                        Color(0xFF8C6B16),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showOwnHeader) const SizedBox(height: 14),
                if (isWide)
                  _ProfileMenu(
                    profileName: profileName,
                    role: role,
                    onLogout: onLogout,
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await onLogout();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone, email, company',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Stage',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...statuses.map(
                            (status) => DropdownMenuItem<String?>(
                          value: status,
                          child: Text(status.replaceAll('_', ' ').toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  selected: importantOnly,
                  label: const Text('Important only'),
                  avatar: const Icon(Icons.star_rounded, size: 18),
                  onSelected: onImportantOnlyChanged,
                ),
              ],
            )
          else
            Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone, email, company',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...statuses.map(
                                (status) => DropdownMenuItem<String?>(
                              value: status,
                              child: Text(
                                status.replaceAll('_', ' ').toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: onStatusChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      selected: importantOnly,
                      label: const Text('Important'),
                      onSelected: onImportantOnlyChanged,
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$visibleCount lead(s) shown • $totalCount total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isReadOnly)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text(
                    'READ ONLY',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (hasFilters)
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String profileName;
  final String role;
  final Future<void> Function() onLogout;

  const _ProfileMenu({
    required this.profileName,
    required this.role,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                profileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                role.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'logout') {
              await onLogout();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final bool canEdit;
  final List<String> missingFields;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _LeadCard({
    required this.lead,
    required this.canEdit,
    required this.missingFields,
    required this.statusColor,
    required this.onTap,
    required this.onEdit,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _text(lead['name']);
    final phone = _text(lead['phone']);
    final email = _text(lead['email']);
    final leadType = _text(lead['lead_type']);
    final companyName = _text(lead['company_name']);
    final status = _text(lead['status']);
    final isImportant = lead['is_important'] == true;
    final requiresFollowUp = lead['requires_follow_up'] == true;
    final isCompleted = lead['is_completed'] == true;

    final title = name.isNotEmpty
        ? name
        : (companyName.isNotEmpty ? companyName : 'Unnamed Lead');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isImportant
                  ? AppConstants.primaryColor
                  : const Color(0xFF3A2F0B),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap(
              //   alignment: WrapAlignment.spaceBetween,
              //   runSpacing: 8,
              //   spacing: 8,
              //   children: [
              //     ConstrainedBox(
              //       constraints: const BoxConstraints(maxWidth: 700),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             title,
              //             style: theme.textTheme.titleLarge?.copyWith(
              //               fontWeight: FontWeight.w900,
              //             ),
              //           ),
              //           if (companyName.isNotEmpty && companyName != title) ...[
              //             const SizedBox(height: 4),
              //             Text(
              //               companyName,
              //               style: theme.textTheme.bodyMedium,
              //             ),
              //           ],
              //         ],
              //       ),
              //     ),
              //     Wrap(
              //       spacing: 8,
              //       runSpacing: 8,
              //       children: [
              //         _MiniBadge(
              //           label: status.replaceAll('_', ' ').toUpperCase(),
              //           background: statusColor.withOpacity(0.18),
              //           foreground: statusColor,
              //         ),
              //         if (isImportant)
              //           const _MiniBadge(
              //             label: 'IMPORTANT',
              //             background: Color(0xFF4A3B12),
              //             foreground: AppConstants.primaryColor,
              //             icon: Icons.star_rounded,
              //           ),
              //         if (requiresFollowUp)
              //           const _MiniBadge(
              //             label: 'FOLLOW UP',
              //             background: Color(0xFF1E3553),
              //             foreground: Color(0xFF90CAF9),
              //             icon: Icons.reply_all_rounded,
              //           ),
              //         if (isCompleted)
              //           const _MiniBadge(
              //             label: 'COMPLETED',
              //             background: Color(0xFF1D3B24),
              //             foreground: Color(0xFF81C784),
              //             icon: Icons.check_circle_rounded,
              //           ),
              //       ],
              //     ),
              //   ],
              // ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    label: status.replaceAll('_', ' ').toUpperCase(),
                    background: statusColor.withOpacity(0.18),
                    foreground: statusColor,
                  ),
                  if (isImportant)
                    const _MiniBadge(
                      label: 'IMPORTANT',
                      background: Color(0xFF4A3B12),
                      foreground: AppConstants.primaryColor,
                      icon: Icons.star_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _InfoText(icon: Icons.phone_outlined, text: phone.isEmpty ? 'No phone' : phone),
                  _InfoText(icon: Icons.email_outlined, text: email.isEmpty ? 'No email' : email),
                  _InfoText(
                    icon: Icons.business_outlined,
                    text: leadType.isEmpty ? 'Unknown type' : leadType.toUpperCase(),
                  ),
                ],
              ),
              if (missingFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2A05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7B6220)),
                  ),
                  child: Text(
                    'Missing data: ${missingFields.join(', ')}',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to view details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFBFA75A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canEdit)
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppConstants.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LeadDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> lead;
  final bool canEdit;
  final VoidCallback? onEdit;

  const LeadDetailsSheet({
    super.key,
    required this.lead,
    required this.canEdit,
    this.onEdit,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  Widget _row({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final paddingBottom = media.viewInsets.bottom + 24;
    final title = _text(lead['name']).isNotEmpty
        ? _text(lead['name'])
        : (_text(lead['company_name']).isNotEmpty
        ? _text(lead['company_name'])
        : 'Lead Details');

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, paddingBottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (canEdit && onEdit != null)
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              // Wrap(
              //   spacing: 10,
              //   runSpacing: 10,
              //   children: [
              //     if (lead['is_important'] == true)
              //       const _MiniBadge(
              //         label: 'IMPORTANT',
              //         background: Color(0xFF4A3B12),
              //         foreground: AppConstants.primaryColor,
              //         icon: Icons.star_rounded,
              //       ),
              //     // if (lead['requires_follow_up'] == true)
              //     //   const _MiniBadge(
              //     //     label: 'FOLLOW UP',
              //     //     background: Color(0xFF1E3553),
              //     //     foreground: Color(0xFF90CAF9),
              //     //     icon: Icons.reply_all_rounded,
              //     //   ),
              //     // if (lead['is_completed'] == true)
              //     //   const _MiniBadge(
              //     //     label: 'COMPLETED',
              //     //     background: Color(0xFF1D3B24),
              //     //     foreground: Color(0xFF81C784),
              //     //     icon: Icons.check_circle_rounded,
              //     //   ),
              //   ],
              // ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (lead['is_important'] == true)
                    const _MiniBadge(
                      label: 'IMPORTANT',
                      background: Color(0xFF4A3B12),
                      foreground: AppConstants.primaryColor,
                      icon: Icons.star_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _row(label: 'Phone', value: _text(lead['phone'])),
              _row(label: 'Email', value: _text(lead['email'])),
              _row(label: 'Lead Type', value: _text(lead['lead_type']).toUpperCase()),
              _row(label: 'Company Name', value: _text(lead['company_name'])),
              _row(label: 'Company TRN', value: _text(lead['company_trn'])),
              _row(label: 'Status', value: _text(lead['status']).replaceAll('_', ' ').toUpperCase()),
              _row(label: 'Notes', value: _text(lead['notes'])),
              _row(label: 'Owner ID', value: _text(lead['owner_id'])),
              _row(label: 'Created By', value: _text(lead['created_by'])),
            ],
          ),
        ),
      ),
    );
  }
}

class LeadFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String currentUserId;
  final Map<String, dynamic>? initialLead;

  const LeadFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.currentUserId,
    this.initialLead,
  });

  @override
  State<LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<LeadFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyTrnController;
  late final TextEditingController _notesController;

  late String _leadType;
  late String _status;
  late bool _isImportant;
  late bool _requiresFollowUp;
  // late bool _isCompleted;

  bool _isSubmitting = false;

  static const List<String> _statuses = <String>[
    'new',
    'contacted',
    'qualified',
    'closed_won',
    'closed_lost',
  ];

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    final lead = widget.initialLead;

    _nameController = TextEditingController(text: _text(lead?['name']));
    _phoneController = TextEditingController(
      text: _text(lead?['phone']).isNotEmpty ? _text(lead?['phone']) : '+971',
    );
    _emailController = TextEditingController(text: _text(lead?['email']));
    _companyNameController =
        TextEditingController(text: _text(lead?['company_name']));
    _companyTrnController =
        TextEditingController(text: _text(lead?['company_trn']));
    _notesController = TextEditingController(text: _text(lead?['notes']));

    _leadType = _text(lead?['lead_type']).isNotEmpty
        ? _text(lead?['lead_type'])
        : 'individual';

    _status = _text(lead?['status']).isNotEmpty
        ? _text(lead?['status'])
        : 'new';

    _isImportant = lead?['is_important'] == true;
    _requiresFollowUp = lead?['requires_follow_up'] == true;
    // _isCompleted = lead?['is_completed'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _companyTrnController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final result = _LeadFormResult(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      leadType: _leadType,
      companyName:
      _leadType == 'company' ? _companyNameController.text.trim() : '',
      companyTrn:
      _leadType == 'company' ? _companyTrnController.text.trim() : '',
      status: _status,
      notes: _notesController.text.trim(),
      isImportant: _isImportant,
      requiresFollowUp: _requiresFollowUp,
      // isCompleted: _isCompleted,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 780;

    return Dialog(
      backgroundColor: const Color(0xFF121212),
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFF3A2F0B)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone *',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Phone is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Phone is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _leadType,
                            decoration: const InputDecoration(
                              labelText: 'Lead Type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'individual',
                                child: Text('INDIVIDUAL'),
                              ),
                              DropdownMenuItem(
                                value: 'company',
                                child: Text('COMPANY'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _leadType = value;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _leadType,
                      decoration: const InputDecoration(
                        labelText: 'Lead Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'individual',
                          child: Text('INDIVIDUAL'),
                        ),
                        DropdownMenuItem(
                          value: 'company',
                          child: Text('COMPANY'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _leadType = value;
                        });
                      },
                    ),
                  ],
                  if (_leadType == 'company') ...[
                    const SizedBox(height: 12),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _companyNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _companyTrnController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Company TRN',
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextFormField(
                        controller: _companyNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _companyTrnController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Company TRN',
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _status = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilterChip(
                        selected: _isImportant,
                        label: const Text('Important'),
                        avatar: const Icon(Icons.star_rounded, size: 18),
                        onSelected: (value) {
                          setState(() {
                            _isImportant = value;
                          });
                        },
                      ),
                      FilterChip(
                        selected: _requiresFollowUp,
                        label: const Text('Create Follow-up Task'),
                        avatar: const Icon(Icons.reply_all_rounded, size: 18),
                        onSelected: (value) {
                          setState(() {
                            _requiresFollowUp = value;
                          });
                        },
                      ),
                      // FilterChip(
                      //   selected: _isCompleted,
                      //   label: const Text('Completed'),
                      //   avatar: const Icon(Icons.check_circle_rounded, size: 18),
                      //   onSelected: (value) {
                      //     setState(() {
                      //       _isCompleted = value;
                      //     });
                      //   },
                      // ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSubmitting ? 'Saving...' : widget.submitLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadFormResult {
  final String name;
  final String phone;
  final String email;
  final String leadType;
  final String companyName;
  final String companyTrn;
  final String status;
  final String notes;
  final bool isImportant;
  final bool requiresFollowUp;
  // final bool isCompleted;

  const _LeadFormResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.leadType,
    required this.companyName,
    required this.companyTrn,
    required this.status,
    required this.notes,
    required this.isImportant,
    required this.requiresFollowUp,
    // required this.isCompleted,
  });

  Map<String, dynamic> toInsertPayload({
    required String currentUserId,
  }) {
    return {
      'name': name.isEmpty ? null : name,
      'phone': phone,
      'email': email.isEmpty ? null : email,
      'lead_type': leadType,
      'company_name': companyName.isEmpty ? null : companyName,
      'company_trn': companyTrn.isEmpty ? null : companyTrn,
      'status': status,
      'notes': notes.isEmpty ? null : notes,
      'is_important': isImportant,
      'requires_follow_up': requiresFollowUp,
      // 'is_completed': isCompleted,
      'owner_id': currentUserId.isEmpty ? null : currentUserId,
      'created_by': currentUserId.isEmpty ? null : currentUserId,
      'assigned_by': null,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'name': name.isEmpty ? null : name,
      'phone': phone,
      'email': email.isEmpty ? null : email,
      'lead_type': leadType,
      'company_name': companyName.isEmpty ? null : companyName,
      'company_trn': companyTrn.isEmpty ? null : companyTrn,
      'status': status,
      'notes': notes.isEmpty ? null : notes,
      'is_important': isImportant,
      'requires_follow_up': requiresFollowUp,
      // 'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}