// //
// //
// // import 'dart:async';
// //
// // import 'package:flutter/material.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // import '../../services/push_sender_service.dart';
// //
// // class SharedLeadsScreen extends StatefulWidget {
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final bool showOwnHeader;
// //   final String? customTitle;
// //
// //   const SharedLeadsScreen({
// //     super.key,
// //     required this.profile,
// //     required this.onLogout,
// //     this.showOwnHeader = true,
// //     this.customTitle,
// //   });
// //
// //   @override
// //   State<SharedLeadsScreen> createState() => _SharedLeadsScreenState();
// // }
// //
// // class _SharedLeadsScreenState extends State<SharedLeadsScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //   final PushSenderService _pushSenderService =
// //   PushSenderService(Supabase.instance.client);
// //
// //   RealtimeChannel? _realtimeChannel;
// //   Timer? _realtimeRefreshDebounce;
// //   Timer? _debounce;
// //
// //   final TextEditingController _searchController = TextEditingController();
// //
// //   bool _isLoading = true;
// //   String? _error;
// //
// //   List<Map<String, dynamic>> _allLeads = [];
// //   List<Map<String, dynamic>> _filteredLeads = [];
// //   List<Map<String, dynamic>> _assignableUsers = [];
// //
// //   String _searchQuery = '';
// //
// //   String get _role =>
// //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// //
// //   bool get _isAdmin => _role == 'admin';
// //
// //   bool get _canAssignLeads =>
// //       _isAdmin && widget.profile['can_assign_leads'] == true;
// //
// //   String get _currentUserId =>
// //       (widget.profile['id'] ?? '').toString().trim();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _searchController.addListener(_onSearchChanged);
// //     _setupRealtime();
// //     _loadData();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _debounce?.cancel();
// //     _realtimeRefreshDebounce?.cancel();
// //
// //     final channel = _realtimeChannel;
// //     _realtimeChannel = null;
// //     if (channel != null) {
// //       unawaited(_supabase.removeChannel(channel));
// //     }
// //
// //     _searchController.dispose();
// //     super.dispose();
// //   }
// //
// //   void _setupRealtime() {
// //     final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;
// //
// //     _realtimeChannel = _supabase
// //         .channel('crm-shared-leads-$channelKey')
// //         .onPostgresChanges(
// //       event: PostgresChangeEvent.all,
// //       schema: 'public',
// //       table: 'leads',
// //       callback: (_) => _scheduleRealtimeRefresh(),
// //     )
// //         .onPostgresChanges(
// //       event: PostgresChangeEvent.all,
// //       schema: 'public',
// //       table: 'profiles',
// //       callback: (_) => _scheduleRealtimeRefresh(),
// //     )
// //         .subscribe();
// //   }
// //
// //   void _scheduleRealtimeRefresh() {
// //     _realtimeRefreshDebounce?.cancel();
// //     _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
// //       if (!mounted) return;
// //       _loadData();
// //     });
// //   }
// //
// //   void _onSearchChanged() {
// //     _debounce?.cancel();
// //     _debounce = Timer(const Duration(milliseconds: 250), () {
// //       if (!mounted) return;
// //       setState(() {
// //         _searchQuery = _searchController.text.trim().toLowerCase();
// //         _applyFilters();
// //       });
// //     });
// //   }
// //
// //   Future<void> _loadData() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final leadsResponse = await _supabase
// //           .from('leads')
// //           .select()
// //           .order('updated_at', ascending: false)
// //           .order('created_at', ascending: false);
// //
// //       final usersResponse = await _supabase
// //           .from('profiles')
// //           .select('id, full_name, email, role, is_active')
// //           .inFilter('role', ['sales', 'admin'])
// //           .eq('is_active', true)
// //           .order('full_name', ascending: true);
// //
// //       final leads = (leadsResponse as List)
// //           .map((e) => Map<String, dynamic>.from(e as Map))
// //           .toList();
// //
// //       final users = (usersResponse as List)
// //           .map((e) => Map<String, dynamic>.from(e as Map))
// //           .toList();
// //
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _allLeads = leads;
// //         _assignableUsers = users;
// //         _applyFilters();
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() {
// //         _error = e.toString();
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   void _applyFilters() {
// //     final search = _searchQuery;
// //
// //     _filteredLeads = _allLeads.where((lead) {
// //       final name = _text(lead['name']).toLowerCase();
// //       final phone = _text(lead['phone']).toLowerCase();
// //       final email = _text(lead['email']).toLowerCase();
// //       final companyName = _text(lead['company_name']).toLowerCase();
// //       final ownerLabel = _ownerLabel(_text(lead['owner_id'])).toLowerCase();
// //
// //       return search.isEmpty ||
// //           name.contains(search) ||
// //           phone.contains(search) ||
// //           email.contains(search) ||
// //           companyName.contains(search) ||
// //           ownerLabel.contains(search);
// //     }).toList();
// //   }
// //
// //   Future<void> _openAssignDialog(Map<String, dynamic> lead) async {
// //     if (!_canAssignLeads) return;
// //
// //     final result = await showDialog<_AssignLeadResult>(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (_) => AssignLeadDialog(
// //         lead: lead,
// //         users: _assignableUsers,
// //       ),
// //     );
// //
// //     if (result == null) return;
// //
// //     final leadId = _text(lead['id']);
// //     if (leadId.isEmpty) return;
// //
// //     final oldOwnerId = _text(lead['owner_id']);
// //     final String? newOwnerId = result.newOwnerId;
// //
// //     try {
// //       await _supabase.from('leads').update({
// //         'owner_id': newOwnerId,
// //         'assigned_by': _currentUserId.isEmpty ? null : _currentUserId,
// //         'updated_at': DateTime.now().toIso8601String(),
// //       }).eq('id', leadId);
// //
// //       await _supabase
// //           .from('follow_ups')
// //           .update({
// //         'assigned_to': newOwnerId,
// //         'updated_at': DateTime.now().toIso8601String(),
// //       })
// //           .eq('lead_id', leadId)
// //           .neq('status', 'done');
// //
// //       bool logFailed = false;
// //
// //       if (_currentUserId.isNotEmpty) {
// //         try {
// //           await _supabase.from('activity_logs').insert({
// //             'actor_id': _currentUserId,
// //             'lead_id': leadId,
// //             'action_type': 'assign_lead',
// //             'meta': {
// //               'old_owner_id': oldOwnerId.isEmpty ? null : oldOwnerId,
// //               'new_owner_id': newOwnerId,
// //               'source': 'shared_leads',
// //               'actor_name': _displayUserLabel(widget.profile),
// //               'old_owner_name': _userDisplayById(oldOwnerId),
// //               'new_owner_name': _userDisplayById(newOwnerId),
// //             },
// //           });
// //
// //           await _sendAssignmentPush(
// //             leadId: leadId,
// //             leadLabel: _leadTitle(lead),
// //             newOwnerId: newOwnerId ?? '',
// //             oldOwnerId: oldOwnerId,
// //           );
// //         } catch (_) {
// //           logFailed = true;
// //         }
// //       }
// //
// //       if (!mounted) return;
// //
// //       final wasUnassigned = newOwnerId == null;
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             logFailed
// //                 ? (wasUnassigned
// //                 ? 'Lead unassigned, but activity log could not be recorded.'
// //                 : 'Lead assigned, but activity log could not be recorded.')
// //                 : (wasUnassigned
// //                 ? 'Lead unassigned successfully.'
// //                 : 'Lead assigned successfully.'),
// //           ),
// //         ),
// //       );
// //
// //       await _loadData();
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to update lead assignment: $e')),
// //       );
// //     }
// //   }
// //
// //   Future<void> _sendAssignmentPush({
// //     required String leadId,
// //     required String leadLabel,
// //     required String newOwnerId,
// //     required String oldOwnerId,
// //   }) async {
// //     if (newOwnerId.isEmpty) return;
// //     if (newOwnerId == oldOwnerId) return;
// //
// //     final actorName = _displayUserLabel(widget.profile);
// //     final oldOwnerName =
// //     oldOwnerId.isEmpty ? 'Unassigned' : _userDisplayById(oldOwnerId);
// //
// //     await _pushSenderService.sendToUser(
// //       userId: newOwnerId,
// //       title: oldOwnerId.isEmpty ? 'New lead assigned' : 'Lead reassigned',
// //       body: oldOwnerId.isEmpty
// //           ? '$leadLabel was assigned to you by $actorName.'
// //           : '$leadLabel was reassigned to you by $actorName from $oldOwnerName.',
// //       data: {
// //         'type': 'lead_assignment',
// //         'lead_id': leadId,
// //         'screen': 'notifications',
// //       },
// //     );
// //   }
// //
// //   void _clearFilters() {
// //     _searchController.clear();
// //     setState(() {
// //       _searchQuery = '';
// //       _applyFilters();
// //     });
// //   }
// //
// //   String _text(dynamic value) => (value ?? '').toString().trim();
// //
// //   String _displayName() {
// //     final fullName = _text(widget.profile['full_name']);
// //     final email = _text(widget.profile['email']);
// //     return fullName.isNotEmpty ? fullName : email;
// //   }
// //
// //   String _displayUserLabel(Map<String, dynamic> user) {
// //     final fullName = _text(user['full_name']);
// //     final email = _text(user['email']);
// //     if (fullName.isNotEmpty) return fullName;
// //     if (email.isNotEmpty) return email;
// //     return _text(user['id']);
// //   }
// //
// //   String _userDisplayById(String? userId) {
// //     final id = _text(userId);
// //     if (id.isEmpty) return 'Unassigned';
// //
// //     for (final user in _assignableUsers) {
// //       if (_text(user['id']) == id) {
// //         final fullName = _text(user['full_name']);
// //         final email = _text(user['email']);
// //         if (fullName.isNotEmpty) return fullName;
// //         if (email.isNotEmpty) return email;
// //         return id;
// //       }
// //     }
// //
// //     return id;
// //   }
// //
// //   String _leadTitle(Map<String, dynamic> lead) {
// //     final name = _text(lead['name']);
// //     final companyName = _text(lead['company_name']);
// //     final phone = _text(lead['phone']);
// //
// //     if (name.isNotEmpty) return name;
// //     if (companyName.isNotEmpty) return companyName;
// //     if (phone.isNotEmpty) return phone;
// //     return 'Unnamed Lead';
// //   }
// //
// //   String _ownerLabel(String ownerId) {
// //     if (ownerId.isEmpty) return 'Unassigned';
// //
// //     final match = _assignableUsers.cast<Map<String, dynamic>?>().firstWhere(
// //           (user) => _text(user?['id']) == ownerId,
// //       orElse: () => null,
// //     );
// //
// //     if (match == null) return 'Unknown user';
// //
// //     final fullName = _text(match['full_name']);
// //     final email = _text(match['email']);
// //
// //     if (fullName.isNotEmpty) return fullName;
// //     if (email.isNotEmpty) return email;
// //     return 'Unknown user';
// //   }
// //
// //   Color _statusColor(String status) {
// //     switch (status) {
// //       case 'new':
// //         return const Color(0xFF8C6B16);
// //       case 'contacted':
// //         return const Color(0xFF1976D2);
// //       case 'qualified':
// //         return const Color(0xFF2E7D32);
// //       case 'closed_won':
// //         return const Color(0xFF00A86B);
// //       case 'closed_lost':
// //         return const Color(0xFFB00020);
// //       default:
// //         return const Color(0xFF555555);
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bool isDesktop = MediaQuery.of(context).size.width >= 1000;
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF0A0A0A),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             _SharedLeadsHeader(
// //               title: widget.customTitle ?? 'Shared Leads',
// //               showOwnHeader: widget.showOwnHeader,
// //               searchController: _searchController,
// //               visibleCount: _filteredLeads.length,
// //               totalCount: _allLeads.length,
// //               profileName: _displayName(),
// //               role: _role,
// //               onClearFilters: _clearFilters,
// //               onLogout: widget.onLogout,
// //             ),
// //             Expanded(
// //               child: AnimatedSwitcher(
// //                 duration: const Duration(milliseconds: 180),
// //                 child: _buildBody(isDesktop),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildBody(bool isDesktop) {
// //     if (!_canAssignLeads) {
// //       return const _SharedLeadsStateCard(
// //         icon: Icons.lock_outline_rounded,
// //         iconColor: Color(0xFFD4AF37),
// //         title: 'Restricted module',
// //         message:
// //         'Only authorized admins can assign or reassign leads because this changes lead ownership.',
// //       );
// //     }
// //
// //     if (_isLoading) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (_error != null) {
// //       return _SharedLeadsStateCard(
// //         icon: Icons.error_outline_rounded,
// //         iconColor: Colors.redAccent,
// //         title: 'Failed to load shared leads',
// //         message: _error!,
// //         actions: [
// //           FilledButton.icon(
// //             onPressed: _loadData,
// //             icon: const Icon(Icons.refresh_rounded),
// //             label: const Text('Retry'),
// //           ),
// //         ],
// //       );
// //     }
// //
// //     if (_filteredLeads.isEmpty) {
// //       return _SharedLeadsStateCard(
// //         icon: Icons.share_outlined,
// //         iconColor: const Color(0xFFD4AF37),
// //         title: _allLeads.isEmpty
// //             ? 'No leads available'
// //             : 'No leads match the current search',
// //         message: _allLeads.isEmpty
// //             ? 'There are no leads to assign yet.'
// //             : 'Try changing the search text.',
// //         actions: [
// //           OutlinedButton.icon(
// //             onPressed: _loadData,
// //             icon: const Icon(Icons.refresh_rounded),
// //             label: const Text('Refresh'),
// //           ),
// //         ],
// //       );
// //     }
// //
// //     if (isDesktop) {
// //       return RefreshIndicator(
// //         onRefresh: _loadData,
// //         child: ListView(
// //           padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
// //           children: [
// //             const _DesktopSharedLeadsHeaderRow(),
// //             const SizedBox(height: 8),
// //             ..._filteredLeads.map(
// //                   (lead) => Padding(
// //                 padding: const EdgeInsets.only(bottom: 8),
// //                 child: _DesktopSharedLeadRow(
// //                   lead: lead,
// //                   ownerLabel: _ownerLabel(_text(lead['owner_id'])),
// //                   statusColor: _statusColor(_text(lead['status']).toLowerCase()),
// //                   onTap: () => _openAssignDialog(lead),
// //                   onAssign: () => _openAssignDialog(lead),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     return RefreshIndicator(
// //       onRefresh: _loadData,
// //       child: ListView.builder(
// //         padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
// //         itemCount: _filteredLeads.length,
// //         itemBuilder: (context, index) {
// //           final lead = _filteredLeads[index];
// //           return Padding(
// //             padding: const EdgeInsets.only(bottom: 10),
// //             child: _MobileSharedLeadCard(
// //               lead: lead,
// //               ownerLabel: _ownerLabel(_text(lead['owner_id'])),
// //               statusColor: _statusColor(_text(lead['status']).toLowerCase()),
// //               onTap: () => _openAssignDialog(lead),
// //               onAssign: () => _openAssignDialog(lead),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// // class _SharedLeadsHeader extends StatelessWidget {
// //   final String title;
// //   final bool showOwnHeader;
// //   final TextEditingController searchController;
// //   final int visibleCount;
// //   final int totalCount;
// //   final String profileName;
// //   final String role;
// //   final VoidCallback onClearFilters;
// //   final Future<void> Function() onLogout;
// //
// //   const _SharedLeadsHeader({
// //     required this.title,
// //     required this.showOwnHeader,
// //     required this.searchController,
// //     required this.visibleCount,
// //     required this.totalCount,
// //     required this.profileName,
// //     required this.role,
// //     required this.onClearFilters,
// //     required this.onLogout,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final bool isWide = MediaQuery.of(context).size.width >= 860;
// //     final hasFilters = searchController.text.trim().isNotEmpty;
// //
// //     return Container(
// //       padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
// //       decoration: const BoxDecoration(
// //         color: Color(0xFF111111),
// //         border: Border(
// //           bottom: BorderSide(color: Color(0xFF30260A)),
// //         ),
// //       ),
// //       child: Column(
// //         children: [
// //           if (showOwnHeader)
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: Text(
// //                     title,
// //                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                 ),
// //                 if (isWide)
// //                   _SharedLeadsProfileMenu(
// //                     profileName: profileName,
// //                     role: role,
// //                     onLogout: onLogout,
// //                   )
// //                 else
// //                   PopupMenuButton<String>(
// //                     onSelected: (value) async {
// //                       if (value == 'logout') {
// //                         await onLogout();
// //                       }
// //                     },
// //                     itemBuilder: (_) => const [
// //                       PopupMenuItem<String>(
// //                         value: 'logout',
// //                         child: Text('Logout'),
// //                       ),
// //                     ],
// //                     icon: const Icon(Icons.account_circle_outlined),
// //                   ),
// //               ],
// //             ),
// //           if (showOwnHeader) const SizedBox(height: 12),
// //           TextField(
// //             controller: searchController,
// //             decoration: const InputDecoration(
// //               hintText: 'Search by name, phone, email, company, or owner',
// //               prefixIcon: Icon(Icons.search_rounded),
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: Text(
// //                   '$visibleCount shown • $totalCount total',
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.w700,
// //                     color: Colors.white70,
// //                   ),
// //                 ),
// //               ),
// //               if (hasFilters)
// //                 TextButton.icon(
// //                   onPressed: onClearFilters,
// //                   icon: const Icon(Icons.filter_alt_off_rounded),
// //                   label: const Text('Clear'),
// //                 ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _SharedLeadsProfileMenu extends StatelessWidget {
// //   final String profileName;
// //   final String role;
// //   final Future<void> Function() onLogout;
// //
// //   const _SharedLeadsProfileMenu({
// //     required this.profileName,
// //     required this.role,
// //     required this.onLogout,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         ConstrainedBox(
// //           constraints: const BoxConstraints(maxWidth: 220),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: [
// //               Text(
// //                 profileName,
// //                 maxLines: 1,
// //                 overflow: TextOverflow.ellipsis,
// //                 style: const TextStyle(fontWeight: FontWeight.w700),
// //               ),
// //               Text(
// //                 role.toUpperCase(),
// //                 style: const TextStyle(
// //                   color: Color(0xFFD4AF37),
// //                   fontWeight: FontWeight.w800,
// //                   fontSize: 12,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //         const SizedBox(width: 8),
// //         PopupMenuButton<String>(
// //           onSelected: (value) async {
// //             if (value == 'logout') {
// //               await onLogout();
// //             }
// //           },
// //           itemBuilder: (_) => const [
// //             PopupMenuItem<String>(
// //               value: 'logout',
// //               child: Text('Logout'),
// //             ),
// //           ],
// //           icon: const Icon(Icons.account_circle_outlined),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // class _DesktopSharedLeadsHeaderRow extends StatelessWidget {
// //   const _DesktopSharedLeadsHeaderRow();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: 44,
// //       padding: const EdgeInsets.symmetric(horizontal: 14),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF111111),
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(color: const Color(0xFF30260A)),
// //       ),
// //       child: const Row(
// //         children: [
// //           Expanded(
// //             flex: 26,
// //             child: Text(
// //               'Lead',
// //               style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 18,
// //             child: Text(
// //               'Contact',
// //               style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 20,
// //             child: Text(
// //               'Owner',
// //               style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 16,
// //             child: Text(
// //               'Status',
// //               style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 20,
// //             child: Text(
// //               'Company',
// //               style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
// //             ),
// //           ),
// //           SizedBox(width: 108),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _DesktopSharedLeadRow extends StatelessWidget {
// //   final Map<String, dynamic> lead;
// //   final String ownerLabel;
// //   final Color statusColor;
// //   final VoidCallback onTap;
// //   final VoidCallback onAssign;
// //
// //   const _DesktopSharedLeadRow({
// //     required this.lead,
// //     required this.ownerLabel,
// //     required this.statusColor,
// //     required this.onTap,
// //     required this.onAssign,
// //   });
// //
// //   String _text(dynamic value) => (value ?? '').toString().trim();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final name = _text(lead['name']);
// //     final phone = _text(lead['phone']);
// //     final email = _text(lead['email']);
// //     final companyName = _text(lead['company_name']);
// //     final status = _text(lead['status']);
// //
// //     final title = name.isNotEmpty
// //         ? name
// //         : (companyName.isNotEmpty ? companyName : 'Unnamed Lead');
// //
// //     final contact = phone.isNotEmpty
// //         ? phone
// //         : (email.isNotEmpty ? email : 'No contact');
// //
// //     return Material(
// //       color: Colors.transparent,
// //       child: InkWell(
// //         borderRadius: BorderRadius.circular(16),
// //         onTap: onTap,
// //         child: Container(
// //           constraints: const BoxConstraints(minHeight: 70),
// //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(16),
// //             border: Border.all(color: const Color(0xFF30260A)),
// //           ),
// //           child: Row(
// //             children: [
// //               Expanded(
// //                 flex: 26,
// //                 child: Text(
// //                   title,
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.w800,
// //                     fontSize: 15,
// //                   ),
// //                 ),
// //               ),
// //               Expanded(
// //                 flex: 18,
// //                 child: Text(
// //                   contact,
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //               Expanded(
// //                 flex: 20,
// //                 child: Text(
// //                   ownerLabel,
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ),
// //               Expanded(
// //                 flex: 16,
// //                 child: _SharedLeadBadge(
// //                   label: status.replaceAll('_', ' ').toUpperCase(),
// //                   background: statusColor.withOpacity(0.18),
// //                   foreground: statusColor,
// //                 ),
// //               ),
// //               Expanded(
// //                 flex: 20,
// //                 child: Text(
// //                   companyName.isEmpty ? '—' : companyName,
// //                   maxLines: 1,
// //                   overflow: TextOverflow.ellipsis,
// //                   style: TextStyle(
// //                     color: companyName.isEmpty ? Colors.white38 : Colors.white70,
// //                   ),
// //                 ),
// //               ),
// //               SizedBox(
// //                 width: 108,
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.end,
// //                   children: [
// //                     FilledButton(
// //                       onPressed: onAssign,
// //                       child: const Text('Assign'),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _MobileSharedLeadCard extends StatelessWidget {
// //   final Map<String, dynamic> lead;
// //   final String ownerLabel;
// //   final Color statusColor;
// //   final VoidCallback onTap;
// //   final VoidCallback onAssign;
// //
// //   const _MobileSharedLeadCard({
// //     required this.lead,
// //     required this.ownerLabel,
// //     required this.statusColor,
// //     required this.onTap,
// //     required this.onAssign,
// //   });
// //
// //   String _text(dynamic value) => (value ?? '').toString().trim();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final name = _text(lead['name']);
// //     final phone = _text(lead['phone']);
// //     final email = _text(lead['email']);
// //     final companyName = _text(lead['company_name']);
// //     final status = _text(lead['status']);
// //
// //     final title = name.isNotEmpty
// //         ? name
// //         : (companyName.isNotEmpty ? companyName : 'Unnamed Lead');
// //
// //     return Material(
// //       color: Colors.transparent,
// //       child: InkWell(
// //         borderRadius: BorderRadius.circular(18),
// //         onTap: onTap,
// //         child: Container(
// //           padding: const EdgeInsets.all(14),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(18),
// //             border: Border.all(color: const Color(0xFF30260A)),
// //           ),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 title,
// //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
// //                   fontWeight: FontWeight.w900,
// //                 ),
// //               ),
// //               if (companyName.isNotEmpty && companyName != title) ...[
// //                 const SizedBox(height: 2),
// //                 Text(
// //                   companyName,
// //                   style: const TextStyle(color: Colors.white70),
// //                 ),
// //               ],
// //               const SizedBox(height: 8),
// //               _SharedLeadBadge(
// //                 label: status.replaceAll('_', ' ').toUpperCase(),
// //                 background: statusColor.withOpacity(0.18),
// //                 foreground: statusColor,
// //               ),
// //               const SizedBox(height: 10),
// //               _SharedLeadInfoText(
// //                 icon: Icons.phone_outlined,
// //                 text: phone.isEmpty ? 'No phone' : phone,
// //               ),
// //               const SizedBox(height: 6),
// //               _SharedLeadInfoText(
// //                 icon: Icons.email_outlined,
// //                 text: email.isEmpty ? 'No email' : email,
// //               ),
// //               const SizedBox(height: 6),
// //               _SharedLeadInfoText(
// //                 icon: Icons.person_outline_rounded,
// //                 text: ownerLabel,
// //               ),
// //               const SizedBox(height: 12),
// //               Row(
// //                 children: [
// //                   const Spacer(),
// //                   FilledButton(
// //                     onPressed: onAssign,
// //                     child: const Text('Assign'),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _SharedLeadInfoText extends StatelessWidget {
// //   final IconData icon;
// //   final String text;
// //
// //   const _SharedLeadInfoText({
// //     required this.icon,
// //     required this.text,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
// //         const SizedBox(width: 6),
// //         Expanded(
// //           child: Text(
// //             text,
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // class _SharedLeadBadge extends StatelessWidget {
// //   final String label;
// //   final Color background;
// //   final Color foreground;
// //
// //   const _SharedLeadBadge({
// //     required this.label,
// //     required this.background,
// //     required this.foreground,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
// //       decoration: BoxDecoration(
// //         color: background,
// //         borderRadius: BorderRadius.circular(999),
// //         border: Border.all(color: foreground.withOpacity(0.35)),
// //       ),
// //       child: Text(
// //         label,
// //         style: TextStyle(
// //           color: foreground,
// //           fontSize: 11.5,
// //           fontWeight: FontWeight.w800,
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _SharedLeadsStateCard extends StatelessWidget {
// //   final IconData icon;
// //   final Color iconColor;
// //   final String title;
// //   final String message;
// //   final List<Widget> actions;
// //
// //   const _SharedLeadsStateCard({
// //     required this.icon,
// //     required this.iconColor,
// //     required this.title,
// //     required this.message,
// //     this.actions = const [],
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(24),
// //         child: Container(
// //           constraints: const BoxConstraints(maxWidth: 560),
// //           padding: const EdgeInsets.all(22),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(24),
// //             border: Border.all(color: const Color(0xFF30260A)),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(icon, size: 42, color: iconColor),
// //               const SizedBox(height: 12),
// //               Text(
// //                 title,
// //                 textAlign: TextAlign.center,
// //                 style: const TextStyle(
// //                   fontSize: 20,
// //                   fontWeight: FontWeight.w900,
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               Text(
// //                 message,
// //                 textAlign: TextAlign.center,
// //               ),
// //               if (actions.isNotEmpty) ...[
// //                 const SizedBox(height: 16),
// //                 Wrap(
// //                   spacing: 10,
// //                   runSpacing: 10,
// //                   alignment: WrapAlignment.center,
// //                   children: actions,
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class AssignLeadDialog extends StatefulWidget {
// //   final Map<String, dynamic> lead;
// //   final List<Map<String, dynamic>> users;
// //
// //   const AssignLeadDialog({
// //     super.key,
// //     required this.lead,
// //     required this.users,
// //   });
// //
// //   @override
// //   State<AssignLeadDialog> createState() => _AssignLeadDialogState();
// // }
// //
// // class _AssignLeadDialogState extends State<AssignLeadDialog> {
// //   final _formKey = GlobalKey<FormState>();
// //
// //   String? _selectedUserId;
// //   bool _isSubmitting = false;
// //
// //   String _text(dynamic value) => (value ?? '').toString().trim();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     final currentOwnerId = _text(widget.lead['owner_id']);
// //     _selectedUserId = currentOwnerId.isNotEmpty ? currentOwnerId : null;
// //   }
// //
// //   String _leadLabel() {
// //     final name = _text(widget.lead['name']);
// //     final company = _text(widget.lead['company_name']);
// //     final phone = _text(widget.lead['phone']);
// //
// //     if (name.isNotEmpty) return name;
// //     if (company.isNotEmpty) return company;
// //     if (phone.isNotEmpty) return phone;
// //     return 'Lead';
// //   }
// //
// //   String _userLabel(Map<String, dynamic> user) {
// //     final fullName = _text(user['full_name']);
// //     final email = _text(user['email']);
// //     final role = _text(user['role']).toUpperCase();
// //
// //     if (fullName.isNotEmpty) return '$fullName • $role';
// //     if (email.isNotEmpty) return '$email • $role';
// //     return _text(user['id']);
// //   }
// //
// //   void _submit() {
// //     if (_isSubmitting) return;
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     setState(() {
// //       _isSubmitting = true;
// //     });
// //
// //     Navigator.of(context).pop(
// //       _AssignLeadResult(newOwnerId: _selectedUserId),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       backgroundColor: const Color(0xFF121212),
// //       insetPadding: const EdgeInsets.all(18),
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(24),
// //         side: const BorderSide(color: Color(0xFF30260A)),
// //       ),
// //       child: ConstrainedBox(
// //         constraints: const BoxConstraints(maxWidth: 720),
// //         child: Padding(
// //           padding: const EdgeInsets.all(20),
// //           child: SingleChildScrollView(
// //             child: Form(
// //               key: _formKey,
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     'Assign Lead',
// //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 10),
// //                   Text(
// //                     _leadLabel(),
// //                     style: const TextStyle(
// //                       color: Color(0xFFD4AF37),
// //                       fontWeight: FontWeight.w800,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   DropdownButtonFormField<String?>(
// //                     value: _selectedUserId,
// //                     decoration: const InputDecoration(
// //                       labelText: 'Assign to',
// //                     ),
// //                     items: [
// //                       const DropdownMenuItem<String?>(
// //                         value: null,
// //                         child: Text('Unassigned'),
// //                       ),
// //                       ...widget.users.map(
// //                             (user) => DropdownMenuItem<String?>(
// //                           value: _text(user['id']),
// //                           child: Text(
// //                             _userLabel(user),
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                     onChanged: (value) {
// //                       setState(() {
// //                         _selectedUserId = value;
// //                       });
// //                     },
// //                   ),
// //                   const SizedBox(height: 18),
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: OutlinedButton(
// //                           onPressed: _isSubmitting
// //                               ? null
// //                               : () => Navigator.of(context).pop(),
// //                           child: const Text('Cancel'),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 12),
// //                       Expanded(
// //                         child: FilledButton.icon(
// //                           onPressed: _isSubmitting ? null : _submit,
// //                           icon: _isSubmitting
// //                               ? const SizedBox(
// //                             width: 18,
// //                             height: 18,
// //                             child: CircularProgressIndicator(
// //                               strokeWidth: 2,
// //                             ),
// //                           )
// //                               : const Icon(Icons.check_rounded),
// //                           label: Text(
// //                             _isSubmitting ? 'Saving...' : 'Confirm',
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _AssignLeadResult {
// //   final String? newOwnerId;
// //
// //   const _AssignLeadResult({
// //     required this.newOwnerId,
// //   });
// // }
//
// import 'package:flutter/material.dart';
//
// import 'leads_screen.dart';
//
// class SharedLeadsScreen extends StatelessWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final bool showOwnHeader;
//   final String? customTitle;
//
//   const SharedLeadsScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//     this.showOwnHeader = true,
//     this.customTitle,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return LeadsScreen(
//       profile: profile,
//       onLogout: onLogout,
//       showOwnHeader: showOwnHeader,
//       customTitle: customTitle ?? 'Leads',
//       allowCreate: true,
//     );
//   }
// }