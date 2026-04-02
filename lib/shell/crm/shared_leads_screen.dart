import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/push_sender_service.dart';

class SharedLeadsScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool showOwnHeader;
  final String? customTitle;

  const SharedLeadsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  State<SharedLeadsScreen> createState() => _SharedLeadsScreenState();
}

class _SharedLeadsScreenState extends State<SharedLeadsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeRefreshDebounce;

  final PushSenderService _pushSenderService =
  PushSenderService(Supabase.instance.client);

  final TextEditingController _searchController = TextEditingController();


  String _displayUserLabel(Map<String, dynamic> user) {
    final fullName = _text(user['full_name']);
    final email = _text(user['email']);
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return _text(user['id']);
  }

  String _userDisplayById(String? userId) {
    final id = _text(userId);
    if (id.isEmpty) return 'Unassigned';

    for (final user in _assignableUsers) {
      if (_text(user['id']) == id) {
        final fullName = _text(user['full_name']);
        final email = _text(user['email']);
        if (fullName.isNotEmpty) return fullName;
        if (email.isNotEmpty) return email;
        return id;
      }
    }

    return id;
  }

  Future<void> _sendAssignmentPush({
    required String leadId,
    required String leadLabel,
    required String newOwnerId,
    required String oldOwnerId,
  }) async {
    if (newOwnerId.isEmpty) return;
    if (newOwnerId == oldOwnerId) return;

    final actorName = _displayUserLabel(widget.profile);
    final oldOwnerName =
    oldOwnerId.isEmpty ? 'Unassigned' : _userDisplayById(oldOwnerId);

    await _pushSenderService.sendToUser(
      userId: newOwnerId,
      title: oldOwnerId.isEmpty ? 'New lead assigned' : 'Lead reassigned',
      body: oldOwnerId.isEmpty
          ? '$leadLabel was assigned to you by $actorName.'
          : '$leadLabel was reassigned to you by $actorName from $oldOwnerName.',
      data: {
        'type': 'lead_assignment',
        'lead_id': leadId,
        'screen': 'notifications',
      },
    );
  }

  // String _displayUserLabel(Map<String, dynamic> user) {
  //   final fullName = _text(user['full_name']);
  //   final email = _text(user['email']);
  //   if (fullName.isNotEmpty) return fullName;
  //   if (email.isNotEmpty) return email;
  //   return _text(user['id']);
  // }
  //
  // String _userDisplayById(String? userId) {
  //   final id = _text(userId);
  //   if (id.isEmpty) return 'Unassigned';
  //
  //   final user = _assignableUsers.cast<Map<String, dynamic>?>().firstWhere(
  //         (u) => _text(u?['id']) == id,
  //     orElse: () => null,
  //   );
  //
  //   if (user == null) return id;
  //
  //   final fullName = _text(user['full_name']);
  //   final email = _text(user['email']);
  //
  //   if (fullName.isNotEmpty) return fullName;
  //   if (email.isNotEmpty) return email;
  //   return id;
  // }

  Timer? _debounce;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allLeads = [];
  List<Map<String, dynamic>> _filteredLeads = [];
  List<Map<String, dynamic>> _assignableUsers = [];

  String _searchQuery = '';

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';

  bool get _canAssignLeads =>
      _isAdmin && widget.profile['can_assign_leads'] == true;

  String get _currentUserId =>
      (widget.profile['id'] ?? '').toString().trim();
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _searchController.addListener(_onSearchChanged);
  //   _loadData();
  // }
  //
  // @override
  // void dispose() {
  //   _debounce?.cancel();
  //   _searchController.dispose();
  //   super.dispose();
  // }
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _setupRealtime();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _realtimeRefreshDebounce?.cancel();

    final channel = _realtimeChannel;
    _realtimeChannel = null;
    if (channel != null) {
      unawaited(_supabase.removeChannel(channel));
    }

    _searchController.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;

    _realtimeChannel = _supabase
        .channel('crm-shared-leads-$channelKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'leads',
      callback: (_) => _scheduleRealtimeRefresh(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (_) => _scheduleRealtimeRefresh(),
    )    .subscribe((status, error) {
      debugPrint('Realtime status: $status | error: $error');
    });
        // .subscribe();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadData();
    });
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leadsResponse = await _supabase
          .from('leads')
          .select()
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false);

      final usersResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email, role, is_active')
          .inFilter('role', ['sales', 'admin'])
          .eq('is_active', true)
          .order('full_name', ascending: true);

      final leads = (leadsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final users = (usersResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _allLeads = leads;
        _assignableUsers = users;
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

      return search.isEmpty ||
          name.contains(search) ||
          phone.contains(search) ||
          email.contains(search) ||
          companyName.contains(search);
    }).toList();
  }

  // Future<void> _openAssignDialog(Map<String, dynamic> lead) async {
  //   if (!_canAssignLeads) return;
  //   final result = await showDialog<_AssignLeadResult>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => AssignLeadDialog(
  //       lead: lead,
  //       users: _assignableUsers,
  //     ),
  //   );
  //
  //   if (result == null) return;
  //
  //   final leadId = _text(lead['id']);
  //   if (leadId.isEmpty) return;
  //
  //   final oldOwnerId = _text(lead['owner_id']);
  //   final newOwnerId = result.newOwnerId;
  //   try {
  //     await _supabase.from('leads').update({
  //       'owner_id': newOwnerId,
  //       'assigned_by': _currentUserId.isEmpty ? null : _currentUserId,
  //       'updated_at': DateTime.now().toIso8601String(),
  //     }).eq('id', leadId);
  //
  //     await _supabase
  //         .from('follow_ups')
  //         .update({
  //       'assigned_to': newOwnerId,
  //       'updated_at': DateTime.now().toIso8601String(),
  //     })
  //         .eq('lead_id', leadId)
  //         .neq('status', 'done');
  //     bool logFailed = false;
  //
  //     if (_currentUserId.isNotEmpty) {
  //       try {
  //         await _supabase.from('activity_logs').insert({
  //           'actor_id': _currentUserId,
  //           'lead_id': leadId,
  //           'action_type': 'assign_lead',
  //           'meta': {
  //             'old_owner_id': oldOwnerId.isEmpty ? null : oldOwnerId,
  //             'new_owner_id': newOwnerId,
  //             'source': 'shared_leads',
  //           },
  //         });
  //       } catch (_) {
  //         logFailed = true;
  //       }
  //     }
  //
  //     if (!mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           logFailed
  //               ? 'Lead assigned, but activity log could not be recorded.'
  //               : 'Lead assigned successfully.',
  //         ),
  //       ),
  //     );
  //
  //     await _loadData();
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to assign lead: $e')),
  //     );
  //   }
  //   // try {
  //   //   await _supabase.from('leads').update({
  //   //     'owner_id': newOwnerId,
  //   //     'assigned_by': _currentUserId.isEmpty ? null : _currentUserId,
  //   //     'updated_at': DateTime.now().toIso8601String(),
  //   //   }).eq('id', leadId);
  //   //
  //   //   if (_currentUserId.isNotEmpty) {
  //   //     await _supabase.from('activity_logs').insert({
  //   //       'actor_id': _currentUserId,
  //   //       'lead_id': leadId,
  //   //       'action_type': 'assign_lead',
  //   //       'meta': {
  //   //         'old_owner_id': oldOwnerId.isEmpty ? null : oldOwnerId,
  //   //         'new_owner_id': newOwnerId,
  //   //         'source': 'shared_leads',
  //   //       },
  //   //     });
  //   //   }
  //   //
  //   //   if (!mounted) return;
  //   //   ScaffoldMessenger.of(context).showSnackBar(
  //   //     const SnackBar(content: Text('Lead assigned successfully.')),
  //   //   );
  //   //
  //   //   await _loadData();
  //   // } catch (e) {
  //   //   if (!mounted) return;
  //   //   ScaffoldMessenger.of(context).showSnackBar(
  //   //     SnackBar(content: Text('Failed to assign lead: $e')),
  //   //   );
  //   // }
  // }
  Future<void> _openAssignDialog(Map<String, dynamic> lead) async {
    if (!_canAssignLeads) return;

    final result = await showDialog<_AssignLeadResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignLeadDialog(
        lead: lead,
        users: _assignableUsers,
      ),
    );

    if (result == null) return;

    final leadId = _text(lead['id']);
    if (leadId.isEmpty) return;

    final oldOwnerId = _text(lead['owner_id']);
    final String? newOwnerId = result.newOwnerId;

    try {
      await _supabase.from('leads').update({
        'owner_id': newOwnerId,
        'assigned_by': _currentUserId.isEmpty ? null : _currentUserId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', leadId);

      await _supabase
          .from('follow_ups')
          .update({
        'assigned_to': newOwnerId,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('lead_id', leadId)
          .neq('status', 'done');

      bool logFailed = false;

      if (_currentUserId.isNotEmpty) {
        try {
          await _supabase.from('activity_logs').insert({
            'actor_id': _currentUserId,
            'lead_id': leadId,
            'action_type': 'assign_lead',
            'meta': {
              'old_owner_id': oldOwnerId.isEmpty ? null : oldOwnerId,
              'new_owner_id': newOwnerId,
              'source': 'shared_leads',

              'actor_name': _displayUserLabel(widget.profile),
              'old_owner_name': _userDisplayById(oldOwnerId),
              'new_owner_name': _userDisplayById(newOwnerId),
            },
            // 'meta': {
            //   'old_owner_id': oldOwnerId.isEmpty ? null : oldOwnerId,
            //   'new_owner_id': newOwnerId,
            //   'source': 'shared_leads',
            // },
          });

          await _sendAssignmentPush(
            leadId: leadId,
            leadLabel: _text(lead['name']).isNotEmpty
                ? _text(lead['name'])
                : _text(lead['company_name']).isNotEmpty
                ? _text(lead['company_name'])
                : _text(lead['phone']),
            newOwnerId: newOwnerId??"",
            oldOwnerId: oldOwnerId,
          );
        } catch (_) {
          logFailed = true;
        }
      }

      if (!mounted) return;

      final wasUnassigned = newOwnerId == null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            logFailed
                ? (wasUnassigned
                ? 'Lead unassigned, but activity log could not be recorded.'
                : 'Lead assigned, but activity log could not be recorded.')
                : (wasUnassigned
                ? 'Lead unassigned successfully.'
                : 'Lead assigned successfully.'),
          ),
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update lead assignment: $e')),
      );
    }
  }
  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _applyFilters();
    });
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  String _displayName() {
    final fullName = _text(widget.profile['full_name']);
    final email = _text(widget.profile['email']);
    return fullName.isNotEmpty ? fullName : email;
  }

  String _ownerLabel(String ownerId) {
    if (ownerId.isEmpty) return 'Unassigned';

    final match = _assignableUsers.cast<Map<String, dynamic>?>().firstWhere(
          (user) => _text(user?['id']) == ownerId,
      orElse: () => null,
    );

    if (match == null) return ownerId;

    final fullName = _text(match['full_name']);
    final email = _text(match['email']);
    final role = _text(match['role']).toUpperCase();

    if (fullName.isNotEmpty) return '$fullName • $role';
    if (email.isNotEmpty) return '$email • $role';
    return ownerId;
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
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _SharedLeadsHeader(
              title: widget.customTitle ?? 'Shared Leads',
              showOwnHeader: widget.showOwnHeader,
              searchController: _searchController,
              visibleCount: _filteredLeads.length,
              totalCount: _allLeads.length,
              profileName: _displayName(),
              role: _role,
              onClearFilters: _clearFilters,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBody(isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isWide) {
    if (!_canAssignLeads) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3A2F0B)),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: Color(0xFFD4AF37),
                ),
                SizedBox(height: 12),
                Text(
                  'Only authorized admins can assign or reassign leads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This module is restricted to admin users because it changes lead ownership.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                const Text(
                  'Failed to load shared leads',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadData,
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
                  Icons.share_outlined,
                  size: 46,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(height: 12),
                Text(
                  _allLeads.isEmpty
                      ? 'No leads available'
                      : 'No leads match the current search',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _allLeads.isEmpty
                      ? 'There are no leads to assign yet.'
                      : 'Try changing the search text.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          isWide ? 20 : 14,
          16,
          isWide ? 20 : 14,
          40,
        ),
        itemCount: _filteredLeads.length,
        itemBuilder: (context, index) {
          final lead = _filteredLeads[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SharedLeadCard(
              lead: lead,
              ownerLabel: _ownerLabel(_text(lead['owner_id'])),
              statusColor: _statusColor(_text(lead['status']).toLowerCase()),
              onTap: () => _openAssignDialog(lead),
              onAssign: () => _openAssignDialog(lead),
            ),
          );
        },
      ),
    );
  }
}

class _SharedLeadsHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final TextEditingController searchController;
  final int visibleCount;
  final int totalCount;
  final String profileName;
  final String role;
  final VoidCallback onClearFilters;
  final Future<void> Function() onLogout;

  const _SharedLeadsHeader({
    required this.title,
    required this.showOwnHeader,
    required this.searchController,
    required this.visibleCount,
    required this.totalCount,
    required this.profileName,
    required this.role,
    required this.onClearFilters,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 860;
    final hasFilters = searchController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF3A2F0B)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
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
                    Icons.share_outlined,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isWide)
                  _SharedLeadsProfileMenu(
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
          if (showOwnHeader) const SizedBox(height: 14),
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
                child: Text(
                  '$visibleCount lead(s) shown • $totalCount total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
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

class _SharedLeadsProfileMenu extends StatelessWidget {
  final String profileName;
  final String role;
  final Future<void> Function() onLogout;

  const _SharedLeadsProfileMenu({
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
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

class _SharedLeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final String ownerLabel;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  const _SharedLeadCard({
    required this.lead,
    required this.ownerLabel,
    required this.statusColor,
    required this.onTap,
    required this.onAssign,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name = _text(lead['name']);
    final phone = _text(lead['phone']);
    final email = _text(lead['email']);
    final companyName = _text(lead['company_name']);
    final status = _text(lead['status']);
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
            border: Border.all(color: const Color(0xFF3A2F0B)),
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (companyName.isNotEmpty && companyName != title) ...[
                          const SizedBox(height: 4),
                          Text(companyName),
                        ],
                      ],
                    ),
                  ),
                  _SharedLeadBadge(
                    label: status.replaceAll('_', ' ').toUpperCase(),
                    background: statusColor.withOpacity(0.18),
                    foreground: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _SharedLeadInfoText(
                    icon: Icons.phone_outlined,
                    text: phone.isEmpty ? 'No phone' : phone,
                  ),
                  _SharedLeadInfoText(
                    icon: Icons.email_outlined,
                    text: email.isEmpty ? 'No email' : email,
                  ),
                  _SharedLeadInfoText(
                    icon: Icons.person_outline_rounded,
                    text: ownerLabel,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to assign or reassign this lead',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFBFA75A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Assign'),
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

class _SharedLeadInfoText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SharedLeadInfoText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
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

class _SharedLeadBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _SharedLeadBadge({
    required this.label,
    required this.background,
    required this.foreground,
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
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
class AssignLeadDialog extends StatefulWidget {
  final Map<String, dynamic> lead;
  final List<Map<String, dynamic>> users;

  const AssignLeadDialog({
    super.key,
    required this.lead,
    required this.users,
  });

  @override
  State<AssignLeadDialog> createState() => _AssignLeadDialogState();
}

class _AssignLeadDialogState extends State<AssignLeadDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedUserId;
  bool _isSubmitting = false;

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    final currentOwnerId = _text(widget.lead['owner_id']);
    _selectedUserId = currentOwnerId.isNotEmpty ? currentOwnerId : null;
  }

  String _leadLabel() {
    final name = _text(widget.lead['name']);
    final company = _text(widget.lead['company_name']);
    final phone = _text(widget.lead['phone']);

    if (name.isNotEmpty) return name;
    if (company.isNotEmpty) return company;
    if (phone.isNotEmpty) return phone;
    return 'Lead';
  }

  String _userLabel(Map<String, dynamic> user) {
    final fullName = _text(user['full_name']);
    final email = _text(user['email']);
    final role = _text(user['role']).toUpperCase();

    if (fullName.isNotEmpty) return '$fullName • $role';
    if (email.isNotEmpty) return '$email • $role';
    return _text(user['id']);
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    Navigator.of(context).pop(
      _AssignLeadResult(newOwnerId: _selectedUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFF3A2F0B)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
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
                    'Assign Lead',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _leadLabel(),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String?>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...widget.users.map(
                            (user) => DropdownMenuItem<String?>(
                          value: _text(user['id']),
                          child: Text(
                            _userLabel(user),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
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
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSubmitting ? 'Saving...' : 'Confirm',
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
// class AssignLeadDialog extends StatefulWidget {
//   final Map<String, dynamic> lead;
//   final List<Map<String, dynamic>> users;
//
//   const AssignLeadDialog({
//     super.key,
//     required this.lead,
//     required this.users,
//   });
//
//   @override
//   State<AssignLeadDialog> createState() => _AssignLeadDialogState();
// }
//
// class _AssignLeadDialogState extends State<AssignLeadDialog> {
//   final _formKey = GlobalKey<FormState>();
//
//   String? _selectedUserId;
//   bool _isSubmitting = false;
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   @override
//   void initState() {
//     super.initState();
//     final currentOwnerId = _text(widget.lead['owner_id']);
//     _selectedUserId = currentOwnerId.isNotEmpty ? currentOwnerId : null;
//   }
//
//   String _leadLabel() {
//     final name = _text(widget.lead['name']);
//     final company = _text(widget.lead['company_name']);
//     final phone = _text(widget.lead['phone']);
//
//     if (name.isNotEmpty) return name;
//     if (company.isNotEmpty) return company;
//     if (phone.isNotEmpty) return phone;
//     return 'Lead';
//   }
//
//   String _userLabel(Map<String, dynamic> user) {
//     final fullName = _text(user['full_name']);
//     final email = _text(user['email']);
//     final role = _text(user['role']).toUpperCase();
//
//     if (fullName.isNotEmpty) return '$fullName • $role';
//     if (email.isNotEmpty) return '$email • $role';
//     return _text(user['id']);
//   }
//
//   void _submit() {
//     if (_isSubmitting) return;
//     if (!_formKey.currentState!.validate()) return;
//
//     final newOwnerId = (_selectedUserId ?? '').trim();
//     if (newOwnerId.isEmpty) return;
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     Navigator.of(context).pop(
//       _AssignLeadResult(newOwnerId: newOwnerId),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: const Color(0xFF121212),
//       insetPadding: const EdgeInsets.all(18),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(28),
//         side: const BorderSide(color: Color(0xFF3A2F0B)),
//       ),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 720),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Assign Lead',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     _leadLabel(),
//                     style: const TextStyle(
//                       color: Color(0xFFD4AF37),
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//                   DropdownButtonFormField<String>(
//                     value: _selectedUserId,
//                     decoration: const InputDecoration(
//                       labelText: 'Assign to',
//                     ),
//                     items: widget.users
//                         .map(
//                           (user) => DropdownMenuItem<String>(
//                         value: _text(user['id']),
//                         child: Text(
//                           _userLabel(user),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     )
//                         .toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedUserId = value;
//                       });
//                     },
//                     validator: (value) {
//                       if ((value ?? '').trim().isEmpty) {
//                         return 'Please select a user';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 18),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: _isSubmitting
//                               ? null
//                               : () => Navigator.of(context).pop(),
//                           child: const Text('Cancel'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: FilledButton.icon(
//                           onPressed: _isSubmitting ? null : _submit,
//                           icon: _isSubmitting
//                               ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                             ),
//                           )
//                               : const Icon(Icons.check_rounded),
//                           label: Text(
//                             _isSubmitting ? 'Saving...' : 'Confirm',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _AssignLeadResult {
  final String? newOwnerId;

  const _AssignLeadResult({
    required this.newOwnerId,
  });
}