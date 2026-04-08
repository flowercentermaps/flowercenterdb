// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class FollowUpScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final bool showOwnHeader;
//   final String? customTitle;
//
//   const FollowUpScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//     this.showOwnHeader = true,
//     this.customTitle,
//   });
//
//   @override
//   State<FollowUpScreen> createState() => _FollowUpScreenState();
// }
//
// class _FollowUpScreenState extends State<FollowUpScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   RealtimeChannel? _realtimeChannel;
//   Timer? _realtimeRefreshDebounce;
//
//   final TextEditingController _searchController = TextEditingController();
//
//   Timer? _debounce;
//
//   bool _isLoading = true;
//   String? _error;
//
//   List<Map<String, dynamic>> _allFollowUps = [];
//   List<Map<String, dynamic>> _filteredFollowUps = [];
//   List<Map<String, dynamic>> _leads = [];
//
//   String _searchQuery = '';
//   String _selectedFilter = 'pending';
//
//   static const List<String> _filters = <String>[
//     'pending',
//     'done',
//     'missed',
//     'overdue',
//   ];
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   bool get _isAdmin => _role == 'admin';
//   bool get _isSales => _role == 'sales';
//   bool get _isViewer => _role == 'viewer';
//   bool get _isAccountant => _role == 'accountant';
//
//   bool get _canCreate => _isAdmin || _isSales;
//   bool get _canEdit => _isAdmin || _isSales;
//   bool get _isReadOnly => _isViewer || _isAccountant;
//
//   String get _currentUserId =>
//       (widget.profile['id'] ?? '').toString().trim();
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _searchController.addListener(_onSearchChanged);
//   //   _loadData();
//   // }
//   //
//   // @override
//   // void dispose() {
//   //   _debounce?.cancel();
//   //   _searchController.dispose();
//   //   super.dispose();
//   // }
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     _setupRealtime();
//     _loadData();
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _realtimeRefreshDebounce?.cancel();
//
//     final channel = _realtimeChannel;
//     _realtimeChannel = null;
//     if (channel != null) {
//       unawaited(_supabase.removeChannel(channel));
//     }
//
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _setupRealtime() {
//     final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;
//
//     _realtimeChannel = _supabase
//         .channel('crm-followups-$channelKey')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'follow_ups',
//       callback: (_) => _scheduleRealtimeRefresh(),
//     )
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'leads',
//       callback: (_) => _scheduleRealtimeRefresh(),
//     )
//         .subscribe();
//   }
//
//   void _scheduleRealtimeRefresh() {
//     _realtimeRefreshDebounce?.cancel();
//     _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
//       if (!mounted) return;
//       _loadData();
//     });
//   }
//
//   void _onSearchChanged() {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 250), () {
//       if (!mounted) return;
//       setState(() {
//         _searchQuery = _searchController.text.trim().toLowerCase();
//         _applyFilters();
//       });
//     });
//   }
//
//   Future<void> _loadData() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       // dynamic followUpQuery = _supabase
//       //     .from('follow_ups')
//       //     .select()
//       //     .order('due_at', ascending: true)
//       //     .order('created_at', ascending: false);
//       //
//       // if (_isSales && _currentUserId.isNotEmpty) {
//       //   followUpQuery = followUpQuery.eq('assigned_to', _currentUserId);
//       // }
//       dynamic followUpQuery = _supabase
//           .from('follow_ups')
//           .select();
//
//       if (_isSales && _currentUserId.isNotEmpty) {
//         followUpQuery = followUpQuery.eq('assigned_to', _currentUserId);
//       }
//
//       final followUpsResponse = await followUpQuery
//           .order('due_at', ascending: true)
//           .order('created_at', ascending: false);
//
//       final leadsResponse = await _supabase
//           .from('leads')
//           .select('id, name, phone, company_name')
//           .order('updated_at', ascending: false);
//
//       // final followUpsResponse = await followUpQuery;
//
//       final followUps = (followUpsResponse as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       final leads = (leadsResponse as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       if (!mounted) return;
//
//       setState(() {
//         _allFollowUps = followUps;
//         _leads = leads;
//         _applyFilters();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _applyFilters() {
//     final now = DateTime.now();
//     final search = _searchQuery;
//
//     _filteredFollowUps = _allFollowUps.where((item) {
//       final notes = _text(item['notes']).toLowerCase();
//       final leadId = _text(item['lead_id']).toLowerCase();
//       final status = _text(item['status']).toLowerCase();
//       final dueAt = _parseDateTime(item['due_at']);
//
//       final matchesSearch = search.isEmpty ||
//           notes.contains(search) ||
//           leadId.contains(search);
//
//       bool matchesFilter = true;
//       switch (_selectedFilter) {
//         case 'pending':
//           matchesFilter = status == 'pending';
//           break;
//         case 'done':
//           matchesFilter = status == 'done';
//           break;
//         case 'missed':
//           matchesFilter = status == 'missed';
//           break;
//         case 'overdue':
//           matchesFilter = status == 'pending' &&
//               dueAt != null &&
//               dueAt.isBefore(now);
//           break;
//       }
//
//       return matchesSearch && matchesFilter;
//     }).toList();
//   }
//
//   Future<void> _openCreateDialog() async {
//     final result = await showDialog<_FollowUpFormResult>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => FollowUpFormDialog(
//         title: 'Create Follow-up',
//         submitLabel: 'Create',
//         leads: _leads,
//         currentUserId: _currentUserId,
//       ),
//     );
//
//     if (result == null) return;
//
//     try {
//       await _supabase.from('follow_ups').insert(result.toInsertPayload());
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Follow-up created successfully.')),
//       );
//
//       await _loadData();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to create follow-up: $e')),
//       );
//     }
//   }
//
//   // Future<void> _openEditDialog(Map<String, dynamic> item) async {
//   //   final result = await showDialog<_FollowUpFormResult>(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (_) => FollowUpFormDialog(
//   //       title: 'Edit Follow-up',
//   //       submitLabel: 'Save',
//   //       leads: _leads,
//   //       currentUserId: _currentUserId,
//   //       initialItem: item,
//   //     ),
//   //   );
//   //
//   //   if (result == null) return;
//   //
//   //   final id = _text(item['id']);
//   //   if (id.isEmpty) return;
//   //
//   //   try {
//   //     await _supabase
//   //         .from('follow_ups')
//   //         .update(result.toUpdatePayload())
//   //         .eq('id', id);
//   //
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Follow-up updated successfully.')),
//   //     );
//   //
//   //     await _loadData();
//   //   } catch (e) {
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Failed to update follow-up: $e')),
//   //     );
//   //   }
//   // }
//   Future<void> _openEditDialog(Map<String, dynamic> item) async {
//     final result = await showDialog<_FollowUpFormResult>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => FollowUpFormDialog(
//         title: 'Edit Follow-up',
//         submitLabel: 'Save',
//         leads: _leads,
//         currentUserId: _currentUserId,
//         initialItem: item,
//       ),
//     );
//
//     if (result == null) return;
//
//     final id = _text(item['id']);
//     if (id.isEmpty) return;
//
//     try {
//       final oldStatus = _text(item['status']).toLowerCase();
//       final newStatus = result.status.toLowerCase();
//
//       await _supabase
//           .from('follow_ups')
//           .update(result.toUpdatePayload())
//           .eq('id', id);
//
//       if (oldStatus != 'done' && newStatus == 'done') {
//         final leadId = _text(item['lead_id']);
//
//         if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
//           await _supabase.from('activity_logs').insert({
//             'actor_id': _currentUserId,
//             'lead_id': leadId,
//             'action_type': 'complete_followup',
//             'meta': {
//               'follow_up_id': id,
//               'completed_at': DateTime.now().toIso8601String(),
//               'source': 'edit_followup',
//             },
//           });
//         }
//       }
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Follow-up updated successfully.')),
//       );
//
//       await _loadData();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update follow-up: $e')),
//       );
//     }
//   }
//
//   Future<void> _markAsDone(Map<String, dynamic> item) async {
//     final id = _text(item['id']);
//     final leadId = _text(item['lead_id']);
//     if (id.isEmpty) return;
//
//     try {
//       await _supabase.from('follow_ups').update({
//         'status': 'done',
//         'completed_at': DateTime.now().toIso8601String(),
//         'updated_at': DateTime.now().toIso8601String(),
//       }).eq('id', id);
//
//       if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
//         await _supabase.from('activity_logs').insert({
//           'actor_id': _currentUserId,
//           'lead_id': leadId,
//           'action_type': 'complete_followup',
//           'meta': {
//             'follow_up_id': id,
//             'completed_at': DateTime.now().toIso8601String(),
//           },
//         });
//       }
//
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Follow-up marked as done.')),
//       );
//
//       await _loadData();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to mark follow-up as done: $e')),
//       );
//     }
//   }
//
//   Future<void> _showDetails(Map<String, dynamic> item) async {
//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       builder: (_) => FollowUpDetailsSheet(
//         item: item,
//         leadLabel: _leadLabel(_text(item['lead_id'])),
//         canEdit: _canEdit,
//         canMarkDone: _canEdit && _text(item['status']).toLowerCase() != 'done',
//         onEdit: _canEdit
//             ? () async {
//           Navigator.of(context).pop();
//           await _openEditDialog(item);
//         }
//             : null,
//         onMarkDone: (_canEdit && _text(item['status']).toLowerCase() != 'done')
//             ? () async {
//           Navigator.of(context).pop();
//           await _markAsDone(item);
//         }
//             : null,
//       ),
//     );
//   }
//
//   void _clearFilters() {
//     _searchController.clear();
//     setState(() {
//       _searchQuery = '';
//       _selectedFilter = 'pending';
//       _applyFilters();
//     });
//   }
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     return DateTime.tryParse(value.toString());
//   }
//
//   String _displayName() {
//     final fullName = _text(widget.profile['full_name']);
//     final email = _text(widget.profile['email']);
//     return fullName.isNotEmpty ? fullName : email;
//   }
//
//   String _leadLabel(String leadId) {
//     if (leadId.isEmpty) return 'Unknown lead';
//
//     final match = _leads.cast<Map<String, dynamic>?>().firstWhere(
//           (lead) => _text(lead?['id']) == leadId,
//       orElse: () => null,
//     );
//
//     if (match == null) return leadId;
//
//     final name = _text(match['name']);
//     final company = _text(match['company_name']);
//     final phone = _text(match['phone']);
//
//     if (name.isNotEmpty) return name;
//     if (company.isNotEmpty) return company;
//     if (phone.isNotEmpty) return phone;
//     return leadId;
//   }
//
//   Color _statusColor(Map<String, dynamic> item) {
//     final status = _text(item['status']).toLowerCase();
//     final dueAt = _parseDateTime(item['due_at']);
//     final now = DateTime.now();
//
//     if (status == 'done') return const Color(0xFF2E7D32);
//     if (status == 'missed') return const Color(0xFFB00020);
//     if (status == 'pending' && dueAt != null && dueAt.isBefore(now)) {
//       return const Color(0xFFFF8F00);
//     }
//     return const Color(0xFF1976D2);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isWide = MediaQuery.of(context).size.width >= 900;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       floatingActionButton: _canCreate
//           ? FloatingActionButton.extended(
//         onPressed: _openCreateDialog,
//         icon: const Icon(Icons.add_task_outlined),
//         label: const Text('New Follow-up'),
//       )
//           : null,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _FollowUpHeader(
//               title: widget.customTitle ?? 'Follow Up',
//               showOwnHeader: widget.showOwnHeader,
//               searchController: _searchController,
//               selectedFilter: _selectedFilter,
//               filters: _filters,
//               visibleCount: _filteredFollowUps.length,
//               totalCount: _allFollowUps.length,
//               profileName: _displayName(),
//               role: _role,
//               isReadOnly: _isReadOnly,
//               onFilterChanged: (value) {
//                 setState(() {
//                   _selectedFilter = value;
//                   _applyFilters();
//                 });
//               },
//               onClearFilters: _clearFilters,
//               onLogout: widget.onLogout,
//             ),
//             Expanded(
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 220),
//                 child: _buildBody(isWide),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody(bool isWide) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 560),
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.error_outline_rounded,
//                   size: 42,
//                   color: Colors.redAccent,
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Failed to load follow-ups',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _error!,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 FilledButton.icon(
//                   onPressed: _loadData,
//                   icon: const Icon(Icons.refresh_rounded),
//                   label: const Text('Retry'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (_filteredFollowUps.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 520),
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.event_note_outlined,
//                   size: 46,
//                   color: Color(0xFFD4AF37),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   _allFollowUps.isEmpty
//                       ? 'No follow-ups yet'
//                       : 'No follow-ups match the current filters',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _allFollowUps.isEmpty
//                       ? (_canCreate
//                       ? 'Create your first follow-up to start tracking follow-up tasks.'
//                       : 'There are no follow-ups available for your account.')
//                       : 'Try changing the search text or filter.',
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   alignment: WrapAlignment.center,
//                   children: [
//                     OutlinedButton.icon(
//                       onPressed: _loadData,
//                       icon: const Icon(Icons.refresh_rounded),
//                       label: const Text('Refresh'),
//                     ),
//                     if (_canCreate && _allFollowUps.isEmpty)
//                       FilledButton.icon(
//                         onPressed: _openCreateDialog,
//                         icon: const Icon(Icons.add_rounded),
//                         label: const Text('Create Follow-up'),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         padding: EdgeInsets.fromLTRB(
//           isWide ? 20 : 14,
//           16,
//           isWide ? 20 : 14,
//           100,
//         ),
//         itemCount: _filteredFollowUps.length,
//         itemBuilder: (context, index) {
//           final item = _filteredFollowUps[index];
//           final status = _text(item['status']).toLowerCase();
//
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 14),
//             child: _FollowUpCard(
//               item: item,
//               leadLabel: _leadLabel(_text(item['lead_id'])),
//               canEdit: _canEdit,
//               canMarkDone: _canEdit && status != 'done',
//               statusColor: _statusColor(item),
//               onTap: () => _showDetails(item),
//               onEdit: _canEdit ? () => _openEditDialog(item) : null,
//               onMarkDone: (_canEdit && status != 'done')
//                   ? () => _markAsDone(item)
//                   : null,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _FollowUpHeader extends StatelessWidget {
//   final String title;
//   final bool showOwnHeader;
//   final TextEditingController searchController;
//   final String selectedFilter;
//   final List<String> filters;
//   final int visibleCount;
//   final int totalCount;
//   final String profileName;
//   final String role;
//   final bool isReadOnly;
//   final ValueChanged<String> onFilterChanged;
//   final VoidCallback onClearFilters;
//   final Future<void> Function() onLogout;
//
//   const _FollowUpHeader({
//     required this.title,
//     required this.showOwnHeader,
//     required this.searchController,
//     required this.selectedFilter,
//     required this.filters,
//     required this.visibleCount,
//     required this.totalCount,
//     required this.profileName,
//     required this.role,
//     required this.isReadOnly,
//     required this.onFilterChanged,
//     required this.onClearFilters,
//     required this.onLogout,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isWide = MediaQuery.of(context).size.width >= 860;
//     final hasFilters = searchController.text.trim().isNotEmpty ||
//         selectedFilter != 'pending';
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111111),
//         border: const Border(
//           bottom: BorderSide(color: Color(0xFF3A2F0B)),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFFD4AF37).withOpacity(0.05),
//             blurRadius: 16,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           if (showOwnHeader)
//             Row(
//               children: [
//                 Container(
//                   width: 44,
//                   height: 44,
//                   padding: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(14),
//                     gradient: const LinearGradient(
//                       colors: [
//                         Color(0xFFD4AF37),
//                         Color(0xFF8C6B16),
//                       ],
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.reply_all_rounded,
//                     color: Color(0xFF111111),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ),
//                 if (isWide)
//                   _FollowUpProfileMenu(
//                     profileName: profileName,
//                     role: role,
//                     onLogout: onLogout,
//                   )
//                 else
//                   PopupMenuButton<String>(
//                     onSelected: (value) async {
//                       if (value == 'logout') {
//                         await onLogout();
//                       }
//                     },
//                     itemBuilder: (_) => const [
//                       PopupMenuItem<String>(
//                         value: 'logout',
//                         child: Text('Logout'),
//                       ),
//                     ],
//                     icon: const Icon(Icons.account_circle_outlined),
//                   ),
//               ],
//             ),
//           if (showOwnHeader) const SizedBox(height: 14),
//           if (isWide)
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: TextField(
//                     controller: searchController,
//                     decoration: const InputDecoration(
//                       hintText: 'Search by notes or lead ID',
//                       prefixIcon: Icon(Icons.search_rounded),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: selectedFilter,
//                     decoration: const InputDecoration(
//                       labelText: 'Task Status',
//                       // labelText: 'Filter',
//                     ),
//                     items: filters
//                         .map(
//                           (filter) => DropdownMenuItem<String>(
//                         value: filter,
//                         child: Text(filter.toUpperCase()),
//                       ),
//                     )
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) onFilterChanged(value);
//                     },
//                   ),
//                 ),
//               ],
//             )
//           else
//             Column(
//               children: [
//                 TextField(
//                   controller: searchController,
//                   decoration: const InputDecoration(
//                     hintText: 'Search by notes or lead ID',
//                     prefixIcon: Icon(Icons.search_rounded),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField<String>(
//                   value: selectedFilter,
//                   decoration: const InputDecoration(
//                     labelText: 'Filter',
//                   ),
//                   items: filters
//                       .map(
//                         (filter) => DropdownMenuItem<String>(
//                       value: filter,
//                       child: Text(filter.toUpperCase()),
//                     ),
//                   )
//                       .toList(),
//                   onChanged: (value) {
//                     if (value != null) onFilterChanged(value);
//                   },
//                 ),
//               ],
//             ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '$visibleCount follow-up(s) shown • $totalCount total',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//               if (isReadOnly)
//                 const Padding(
//                   padding: EdgeInsets.only(right: 12),
//                   child: Text(
//                     'READ ONLY',
//                     style: TextStyle(
//                       color: Colors.orangeAccent,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               if (hasFilters)
//                 OutlinedButton.icon(
//                   onPressed: onClearFilters,
//                   icon: const Icon(Icons.filter_alt_off_rounded),
//                   label: const Text('Clear'),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _FollowUpProfileMenu extends StatelessWidget {
//   final String profileName;
//   final String role;
//   final Future<void> Function() onLogout;
//
//   const _FollowUpProfileMenu({
//     required this.profileName,
//     required this.role,
//     required this.onLogout,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 220),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 profileName,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               Text(
//                 role.toUpperCase(),
//                 style: const TextStyle(
//                   color: Color(0xFFD4AF37),
//                   fontWeight: FontWeight.w800,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         PopupMenuButton<String>(
//           onSelected: (value) async {
//             if (value == 'logout') {
//               await onLogout();
//             }
//           },
//           itemBuilder: (_) => const [
//             PopupMenuItem<String>(
//               value: 'logout',
//               child: Text('Logout'),
//             ),
//           ],
//           icon: const Icon(Icons.account_circle_outlined),
//         ),
//       ],
//     );
//   }
// }
//
// class _FollowUpCard extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final String leadLabel;
//   final bool canEdit;
//   final bool canMarkDone;
//   final Color statusColor;
//   final VoidCallback onTap;
//   final VoidCallback? onEdit;
//   final VoidCallback? onMarkDone;
//
//   const _FollowUpCard({
//     required this.item,
//     required this.leadLabel,
//     required this.canEdit,
//     required this.canMarkDone,
//     required this.statusColor,
//     required this.onTap,
//     required this.onEdit,
//     required this.onMarkDone,
//   });
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     return DateTime.tryParse(value.toString());
//   }
//
//   String _formatDateTime(DateTime? dateTime) {
//     if (dateTime == null) return 'No due date';
//     final local = dateTime.toLocal();
//     final y = local.year.toString().padLeft(4, '0');
//     final m = local.month.toString().padLeft(2, '0');
//     final d = local.day.toString().padLeft(2, '0');
//     final hh = local.hour.toString().padLeft(2, '0');
//     final mm = local.minute.toString().padLeft(2, '0');
//     return '$y-$m-$d  $hh:$mm';
//   }
//
//   bool _isOverdue(Map<String, dynamic> item) {
//     final status = _text(item['status']).toLowerCase();
//     final dueAt = _parseDateTime(item['due_at']);
//     return status == 'pending' &&
//         dueAt != null &&
//         dueAt.isBefore(DateTime.now());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final status = _text(item['status']).toLowerCase();
//     final dueAt = _parseDateTime(item['due_at']);
//     final notes = _text(item['notes']);
//     final assignedTo = _text(item['assigned_to']);
//     final leadId = _text(item['lead_id']);
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(22),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(22),
//             border: Border.all(color: const Color(0xFF3A2F0B)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.16),
//                 blurRadius: 12,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Wrap(
//                 alignment: WrapAlignment.spaceBetween,
//                 runSpacing: 8,
//                 spacing: 8,
//                 children: [
//                   ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 700),
//                     child: Text(
//                       leadLabel,
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                   ),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       _FollowUpBadge(
//                         label: status.toUpperCase(),
//                         background: statusColor.withOpacity(0.18),
//                         foreground: statusColor,
//                       ),
//                       if (_isOverdue(item))
//                         const _FollowUpBadge(
//                           label: 'OVERDUE',
//                           background: Color(0xFF4A2F09),
//                           foreground: Color(0xFFFFB74D),
//                           icon: Icons.warning_amber_rounded,
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 18,
//                 runSpacing: 10,
//                 children: [
//                   _FollowUpInfoText(
//                     icon: Icons.link_rounded,
//                     text: 'Lead ID: $leadId',
//                   ),
//                   _FollowUpInfoText(
//                     icon: Icons.event_outlined,
//                     text: _formatDateTime(dueAt),
//                   ),
//                   _FollowUpInfoText(
//                     icon: Icons.person_outline_rounded,
//                     text: assignedTo.isEmpty ? 'Unassigned' : assignedTo,
//                   ),
//                 ],
//               ),
//               if (notes.isNotEmpty) ...[
//                 const SizedBox(height: 12),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF101010),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: const Color(0xFF2B2B2B)),
//                   ),
//                   child: Text(
//                     notes,
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 14),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Tap to view details',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: const Color(0xFFBFA75A),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   if (canMarkDone)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: OutlinedButton.icon(
//                         onPressed: onMarkDone,
//                         icon: const Icon(Icons.check_circle_outline_rounded),
//                         label: const Text('Done'),
//                       ),
//                     ),
//                   if (canEdit)
//                     FilledButton.icon(
//                       onPressed: onEdit,
//                       icon: const Icon(Icons.edit_outlined),
//                       label: const Text('Edit'),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _FollowUpInfoText extends StatelessWidget {
//   final IconData icon;
//   final String text;
//
//   const _FollowUpInfoText({
//     required this.icon,
//     required this.text,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               text,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _FollowUpBadge extends StatelessWidget {
//   final String label;
//   final Color background;
//   final Color foreground;
//   final IconData? icon;
//
//   const _FollowUpBadge({
//     required this.label,
//     required this.background,
//     required this.foreground,
//     this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: foreground.withOpacity(0.35)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (icon != null) ...[
//             Icon(icon, size: 15, color: foreground),
//             const SizedBox(width: 6),
//           ],
//           Text(
//             label,
//             style: TextStyle(
//               color: foreground,
//               fontSize: 11.5,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class FollowUpDetailsSheet extends StatelessWidget {
//   final Map<String, dynamic> item;
//   final String leadLabel;
//   final bool canEdit;
//   final bool canMarkDone;
//   final VoidCallback? onEdit;
//   final VoidCallback? onMarkDone;
//
//   const FollowUpDetailsSheet({
//     super.key,
//     required this.item,
//     required this.leadLabel,
//     required this.canEdit,
//     required this.canMarkDone,
//     this.onEdit,
//     this.onMarkDone,
//   });
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     return DateTime.tryParse(value.toString());
//   }
//
//   String _formatDateTime(DateTime? dateTime) {
//     if (dateTime == null) return '—';
//     final local = dateTime.toLocal();
//     final y = local.year.toString().padLeft(4, '0');
//     final m = local.month.toString().padLeft(2, '0');
//     final d = local.day.toString().padLeft(2, '0');
//     final hh = local.hour.toString().padLeft(2, '0');
//     final mm = local.minute.toString().padLeft(2, '0');
//     return '$y-$m-$d  $hh:$mm';
//   }
//
//   Widget _row({
//     required String label,
//     required String value,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Color(0xFFD4AF37),
//               fontWeight: FontWeight.w800,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value.isEmpty ? '—' : value,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final media = MediaQuery.of(context);
//     final paddingBottom = media.viewInsets.bottom + 24;
//
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: EdgeInsets.fromLTRB(18, 18, 18, paddingBottom),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   width: 44,
//                   height: 5,
//                   decoration: BoxDecoration(
//                     color: Colors.white24,
//                     borderRadius: BorderRadius.circular(999),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       leadLabel,
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                   ),
//                   if (canMarkDone && onMarkDone != null)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: OutlinedButton.icon(
//                         onPressed: onMarkDone,
//                         icon: const Icon(Icons.check_circle_outline_rounded),
//                         label: const Text('Done'),
//                       ),
//                     ),
//                   if (canEdit && onEdit != null)
//                     FilledButton.icon(
//                       onPressed: onEdit,
//                       icon: const Icon(Icons.edit_outlined),
//                       label: const Text('Edit'),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 18),
//               _row(label: 'Lead ID', value: _text(item['lead_id'])),
//               _row(label: 'Due At', value: _formatDateTime(_parseDateTime(item['due_at']))),
//               _row(label: 'Status', value: _text(item['status']).toUpperCase()),
//               _row(label: 'Notes', value: _text(item['notes'])),
//               _row(label: 'Assigned To', value: _text(item['assigned_to'])),
//               _row(label: 'Completed At', value: _formatDateTime(_parseDateTime(item['completed_at']))),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class FollowUpFormDialog extends StatefulWidget {
//   final String title;
//   final String submitLabel;
//   final String currentUserId;
//   final List<Map<String, dynamic>> leads;
//   final Map<String, dynamic>? initialItem;
//
//   const FollowUpFormDialog({
//     super.key,
//     required this.title,
//     required this.submitLabel,
//     required this.currentUserId,
//     required this.leads,
//     this.initialItem,
//   });
//
//   @override
//   State<FollowUpFormDialog> createState() => _FollowUpFormDialogState();
// }
//
// class _FollowUpFormDialogState extends State<FollowUpFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//
//   late final TextEditingController _notesController;
//
//   String? _leadId;
//   String _status = 'pending';
//   DateTime? _dueAt;
//   bool _isSubmitting = false;
//
//   static const List<String> _statuses = <String>[
//     'pending',
//     'done',
//     'missed',
//   ];
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   @override
//   void initState() {
//     super.initState();
//     final item = widget.initialItem;
//     _notesController = TextEditingController(text: _text(item?['notes']));
//     _leadId = _text(item?['lead_id']).isNotEmpty ? _text(item?['lead_id']) : null;
//     _status = _text(item?['status']).isNotEmpty ? _text(item?['status']) : 'pending';
//     _dueAt = _parseDateTime(item?['due_at']);
//   }
//
//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }
//
//   DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     return DateTime.tryParse(value.toString())?.toLocal();
//   }
//
//   Future<void> _pickDueAt() async {
//     final now = DateTime.now();
//     final initial = _dueAt ?? now.add(const Duration(hours: 1));
//
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(now.year - 2),
//       lastDate: DateTime(now.year + 5),
//     );
//
//     if (pickedDate == null || !mounted) return;
//
//     final pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(initial),
//     );
//
//     if (pickedTime == null || !mounted) return;
//
//     setState(() {
//       _dueAt = DateTime(
//         pickedDate.year,
//         pickedDate.month,
//         pickedDate.day,
//         pickedTime.hour,
//         pickedTime.minute,
//       );
//     });
//   }
//
//   String _formatDueAt() {
//     if (_dueAt == null) return 'Select date & time';
//     final y = _dueAt!.year.toString().padLeft(4, '0');
//     final m = _dueAt!.month.toString().padLeft(2, '0');
//     final d = _dueAt!.day.toString().padLeft(2, '0');
//     final hh = _dueAt!.hour.toString().padLeft(2, '0');
//     final mm = _dueAt!.minute.toString().padLeft(2, '0');
//     return '$y-$m-$d  $hh:$mm';
//   }
//
//   String _leadLabel(Map<String, dynamic> lead) {
//     final name = _text(lead['name']);
//     final company = _text(lead['company_name']);
//     final phone = _text(lead['phone']);
//     final id = _text(lead['id']);
//
//     if (name.isNotEmpty) return '$name • $id';
//     if (company.isNotEmpty) return '$company • $id';
//     if (phone.isNotEmpty) return '$phone • $id';
//     return id;
//   }
//
//   void _submit() {
//     if (_isSubmitting) return;
//     if (!_formKey.currentState!.validate()) return;
//     if (_dueAt == null) return;
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     final result = _FollowUpFormResult(
//       leadId: _leadId!,
//       dueAt: _dueAt!,
//       status: _status,
//       notes: _notesController.text.trim(),
//       assignedTo: widget.currentUserId.isEmpty ? null : widget.currentUserId,
//     );
//
//     Navigator.of(context).pop(result);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isWide = MediaQuery.of(context).size.width >= 780;
//
//     return Dialog(
//       backgroundColor: const Color(0xFF121212),
//       insetPadding: const EdgeInsets.all(18),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(28),
//         side: const BorderSide(color: Color(0xFF3A2F0B)),
//       ),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 860),
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
//                     widget.title,
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//                   if (isWide)
//                     Row(
//                       children: [
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _leadId,
//                             decoration: const InputDecoration(
//                               labelText: 'Lead *',
//                             ),
//                             items: widget.leads
//                                 .map(
//                                   (lead) => DropdownMenuItem<String>(
//                                 value: _text(lead['id']),
//                                 child: Text(
//                                   _leadLabel(lead),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             )
//                                 .toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _leadId = value;
//                               });
//                             },
//                             validator: (value) {
//                               if ((value ?? '').trim().isEmpty) {
//                                 return 'Lead is required';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _status,
//                             decoration: const InputDecoration(
//                               labelText: 'Status',
//                             ),
//                             items: _statuses
//                                 .map(
//                                   (status) => DropdownMenuItem<String>(
//                                 value: status,
//                                 child: Text(status.toUpperCase()),
//                               ),
//                             )
//                                 .toList(),
//                             onChanged: (value) {
//                               if (value == null) return;
//                               setState(() {
//                                 _status = value;
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     )
//                   else ...[
//                     DropdownButtonFormField<String>(
//                       value: _leadId,
//                       decoration: const InputDecoration(
//                         labelText: 'Lead *',
//                       ),
//                       items: widget.leads
//                           .map(
//                             (lead) => DropdownMenuItem<String>(
//                           value: _text(lead['id']),
//                           child: Text(
//                             _leadLabel(lead),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       )
//                           .toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _leadId = value;
//                         });
//                       },
//                       validator: (value) {
//                         if ((value ?? '').trim().isEmpty) {
//                           return 'Lead is required';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     DropdownButtonFormField<String>(
//                       value: _status,
//                       decoration: const InputDecoration(
//                         labelText: 'Status',
//                       ),
//                       items: _statuses
//                           .map(
//                             (status) => DropdownMenuItem<String>(
//                           value: status,
//                           child: Text(status.toUpperCase()),
//                         ),
//                       )
//                           .toList(),
//                       onChanged: (value) {
//                         if (value == null) return;
//                         setState(() {
//                           _status = value;
//                         });
//                       },
//                     ),
//                   ],
//                   const SizedBox(height: 12),
//                   InkWell(
//                     borderRadius: BorderRadius.circular(16),
//                     onTap: _pickDueAt,
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF121212),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: const Color(0xFF3A2F0B),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.event_outlined),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               _formatDueAt(),
//                               style: TextStyle(
//                                 color: _dueAt == null
//                                     ? Colors.white60
//                                     : Colors.white,
//                               ),
//                             ),
//                           ),
//                           const Icon(Icons.edit_calendar_outlined),
//                         ],
//                       ),
//                     ),
//                   ),
//                   if (_dueAt == null)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 8, left: 4),
//                       child: Text(
//                         'Due date and time are required',
//                         style: TextStyle(
//                           color: Colors.redAccent,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 12),
//                   TextFormField(
//                     controller: _notesController,
//                     minLines: 4,
//                     maxLines: 7,
//                     decoration: const InputDecoration(
//                       labelText: 'Notes',
//                       alignLabelWithHint: true,
//                     ),
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
//                               : const Icon(Icons.save_outlined),
//                           label: Text(
//                             _isSubmitting ? 'Saving...' : widget.submitLabel,
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
//
// class _FollowUpFormResult {
//   final String leadId;
//   final DateTime dueAt;
//   final String status;
//   final String notes;
//   final String? assignedTo;
//
//   const _FollowUpFormResult({
//     required this.leadId,
//     required this.dueAt,
//     required this.status,
//     required this.notes,
//     required this.assignedTo,
//   });
//
//   Map<String, dynamic> toInsertPayload() {
//     return {
//       'lead_id': leadId,
//       'due_at': dueAt.toUtc().toIso8601String(),
//       'status': status,
//       'notes': notes.isEmpty ? null : notes,
//       'assigned_to': assignedTo,
//     };
//   }
//
//   Map<String, dynamic> toUpdatePayload() {
//     return {
//       'lead_id': leadId,
//       'due_at': dueAt.toUtc().toIso8601String(),
//       'status': status,
//       'notes': notes.isEmpty ? null : notes,
//       'assigned_to': assignedTo,
//       'updated_at': DateTime.now().toIso8601String(),
//       'completed_at': status == 'done'
//           ? DateTime.now().toIso8601String()
//           : null,
//     };
//   }
// }


import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowUpScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool showOwnHeader;
  final String? customTitle;

  const FollowUpScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeRefreshDebounce;
  Timer? _debounce;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allFollowUps = [];
  List<Map<String, dynamic>> _filteredFollowUps = [];
  List<Map<String, dynamic>> _leads = [];
  Map<String, Map<String, dynamic>> _profilesById = {};

  String _searchQuery = '';
  String _selectedFilter = 'pending';

  static const List<String> _filters = <String>[
    'pending',
    'done',
    'missed',
    'overdue',
  ];

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isViewer => _role == 'viewer';
  bool get _isAccountant => _role == 'accountant';

  bool get _canCreate => _isAdmin || _isSales;
  bool get _canEdit => _isAdmin || _isSales;
  bool get _isReadOnly => _isViewer || _isAccountant;

  String get _currentUserId =>
      (widget.profile['id'] ?? '').toString().trim();

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
        .channel('crm-followups-$channelKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'follow_ups',
      callback: (_) => _scheduleRealtimeRefresh(),
    )
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
    )
        .subscribe();
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
      dynamic followUpQuery = _supabase.from('follow_ups').select();

      if (_isSales && _currentUserId.isNotEmpty) {
        followUpQuery = followUpQuery.eq('assigned_to', _currentUserId);
      }

      final followUpsResponse = await followUpQuery
          .order('due_at', ascending: true)
          .order('created_at', ascending: false);

      final leadsResponse = await _supabase
          .from('leads')
          .select('id, name, phone, company_name')
          .order('updated_at', ascending: false);

      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email')
          .order('updated_at', ascending: false);

      final followUps = (followUpsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final leads = (leadsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final profiles = (profilesResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final profilesById = <String, Map<String, dynamic>>{};
      for (final profile in profiles) {
        final id = _text(profile['id']);
        if (id.isNotEmpty) {
          profilesById[id] = profile;
        }
      }

      if (!mounted) return;

      setState(() {
        _allFollowUps = followUps;
        _leads = leads;
        _profilesById = profilesById;
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
    final now = DateTime.now();
    final search = _searchQuery;

    _filteredFollowUps = _allFollowUps.where((item) {
      final notes = _text(item['notes']).toLowerCase();
      final status = _text(item['status']).toLowerCase();
      final dueAt = _parseDateTime(item['due_at']);

      final leadLabel = _leadLabel(_text(item['lead_id'])).toLowerCase();
      final assigneeLabel =
      _personLabel(_text(item['assigned_to']), fallback: 'unassigned')
          .toLowerCase();

      final matchesSearch = search.isEmpty ||
          notes.contains(search) ||
          leadLabel.contains(search) ||
          assigneeLabel.contains(search);

      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'pending':
          matchesFilter = status == 'pending';
          break;
        case 'done':
          matchesFilter = status == 'done';
          break;
        case 'missed':
          matchesFilter = status == 'missed';
          break;
        case 'overdue':
          matchesFilter =
              status == 'pending' && dueAt != null && dueAt.isBefore(now);
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<_FollowUpFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FollowUpFormDialog(
        title: tr('followup_form_create'),
        submitLabel: tr('btn_create'),
        leads: _leads,
        currentUserId: _currentUserId,
      ),
    );

    if (result == null) return;

    try {
      await _supabase.from('follow_ups').insert(result.toInsertPayload());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_created'))),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_create_failed', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic> item) async {
    final result = await showDialog<_FollowUpFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FollowUpFormDialog(
        title: tr('followup_form_edit'),
        submitLabel: tr('btn_save'),
        leads: _leads,
        currentUserId: _currentUserId,
        initialItem: item,
      ),
    );

    if (result == null) return;

    final id = _text(item['id']);
    if (id.isEmpty) return;

    try {
      final oldStatus = _text(item['status']).toLowerCase();
      final newStatus = result.status.toLowerCase();

      await _supabase
          .from('follow_ups')
          .update(result.toUpdatePayload())
          .eq('id', id);

      if (oldStatus != 'done' && newStatus == 'done') {
        final leadId = _text(item['lead_id']);

        if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
          await _supabase.from('activity_logs').insert({
            'actor_id': _currentUserId,
            'lead_id': leadId,
            'action_type': 'complete_followup',
            'meta': {
              'follow_up_id': id,
              'completed_at': DateTime.now().toIso8601String(),
              'source': 'edit_followup',
            },
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_updated'))),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_update_failed', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _markAsDone(Map<String, dynamic> item) async {
    final id = _text(item['id']);
    final leadId = _text(item['lead_id']);
    if (id.isEmpty) return;

    try {
      await _supabase.from('follow_ups').update({
        'status': 'done',
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
        await _supabase.from('activity_logs').insert({
          'actor_id': _currentUserId,
          'lead_id': leadId,
          'action_type': 'complete_followup',
          'meta': {
            'follow_up_id': id,
            'completed_at': DateTime.now().toIso8601String(),
          },
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_marked_done'))),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('followup_mark_done_failed', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _showDetails(Map<String, dynamic> item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FollowUpDetailsSheet(
        item: item,
        leadLabel: _leadLabel(_text(item['lead_id'])),
        assigneeLabel: _personLabel(
          _text(item['assigned_to']),
          fallback: 'Unassigned',
        ),
        canEdit: _canEdit,
        canMarkDone: _canEdit && _text(item['status']).toLowerCase() != 'done',
        onEdit: _canEdit
            ? () async {
          Navigator.of(context).pop();
          await _openEditDialog(item);
        }
            : null,
        onMarkDone:
        (_canEdit && _text(item['status']).toLowerCase() != 'done')
            ? () async {
          Navigator.of(context).pop();
          await _markAsDone(item);
        }
            : null,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedFilter = 'pending';
      _applyFilters();
    });
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _displayName() {
    final fullName = _text(widget.profile['full_name']);
    final email = _text(widget.profile['email']);
    return fullName.isNotEmpty ? fullName : email;
  }

  String _leadLabel(String leadId) {
    if (leadId.isEmpty) return 'Unknown lead';

    final match = _leads.cast<Map<String, dynamic>?>().firstWhere(
          (lead) => _text(lead?['id']) == leadId,
      orElse: () => null,
    );

    if (match == null) return 'Unknown lead';

    final name = _text(match['name']);
    final company = _text(match['company_name']);
    final phone = _text(match['phone']);

    if (name.isNotEmpty && company.isNotEmpty) {
      return '$name • $company';
    }
    if (name.isNotEmpty) return name;
    if (company.isNotEmpty) return company;
    if (phone.isNotEmpty) return phone;
    return 'Unknown lead';
  }

  String _personLabel(String profileId, {String fallback = 'Unknown user'}) {
    if (profileId.isEmpty) return fallback;

    final profile = _profilesById[profileId];
    if (profile == null) return fallback;

    final fullName = _text(profile['full_name']);
    final email = _text(profile['email']);

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return fallback;
  }

  Color _statusColor(Map<String, dynamic> item) {
    final status = _text(item['status']).toLowerCase();
    final dueAt = _parseDateTime(item['due_at']);
    final now = DateTime.now();

    if (status == 'done') return const Color(0xFF4CAF50);
    if (status == 'missed') return const Color(0xFFE53935);
    if (status == 'pending' && dueAt != null && dueAt.isBefore(now)) {
      return const Color(0xFFFFB300);
    }
    return const Color(0xFFD4AF37);
  }

  bool _isOverdue(Map<String, dynamic> item) {
    final status = _text(item['status']).toLowerCase();
    final dueAt = _parseDateTime(item['due_at']);
    return status == 'pending' &&
        dueAt != null &&
        dueAt.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: (!isDesktop && _canCreate)
          ? FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('btn_new_follow_up')),
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _FollowUpHeader(
              title: widget.customTitle ?? tr('followup_title'),
              showOwnHeader: widget.showOwnHeader,
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              filters: _filters,
              visibleCount: _filteredFollowUps.length,
              totalCount: _allFollowUps.length,
              profileName: _displayName(),
              role: _role,
              isReadOnly: _isReadOnly,
              canCreate: _canCreate,
              showDesktopCreateAction: isDesktop && _canCreate,
              onCreate: _openCreateDialog,
              onFilterChanged: (value) {
                setState(() {
                  _selectedFilter = value;
                  _applyFilters();
                });
              },
              onClearFilters: _clearFilters,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildBody(isDesktop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        title: tr('followup_error'),
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('btn_retry')),
          ),
        ],
      );
    }

    if (_filteredFollowUps.isEmpty) {
      return _StateCard(
        icon: Icons.event_note_outlined,
        iconColor: const Color(0xFFD4AF37),
        title: _allFollowUps.isEmpty
            ? tr('followup_empty_title')
            : tr('followup_empty_filtered'),
        message: _allFollowUps.isEmpty
            ? (_canCreate
            ? tr('followup_empty_subtitle')
            : tr('followup_empty_no_access'))
            : tr('followup_empty_filter_hint'),
        actions: [
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('btn_refresh')),
          ),
          if (_canCreate && _allFollowUps.isEmpty)
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('btn_create')),
            ),
        ],
      );
    }

    if (isDesktop) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            _DesktopFollowUpListHeader(),
            const SizedBox(height: 8),
            ..._filteredFollowUps.map((item) {
              final status = _text(item['status']).toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DesktopFollowUpRow(
                  item: item,
                  leadLabel: _leadLabel(_text(item['lead_id'])),
                  assigneeLabel: _personLabel(
                    _text(item['assigned_to']),
                    fallback: 'Unassigned',
                  ),
                  canEdit: _canEdit,
                  canMarkDone: _canEdit && status != 'done',
                  statusColor: _statusColor(item),
                  isOverdue: _isOverdue(item),
                  onTap: () => _showDetails(item),
                  onEdit: _canEdit ? () => _openEditDialog(item) : null,
                  onMarkDone: (_canEdit && status != 'done')
                      ? () => _markAsDone(item)
                      : null,
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        itemCount: _filteredFollowUps.length,
        itemBuilder: (context, index) {
          final item = _filteredFollowUps[index];
          final status = _text(item['status']).toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MobileFollowUpCard(
              item: item,
              leadLabel: _leadLabel(_text(item['lead_id'])),
              assigneeLabel: _personLabel(
                _text(item['assigned_to']),
                fallback: 'Unassigned',
              ),
              canEdit: _canEdit,
              canMarkDone: _canEdit && status != 'done',
              statusColor: _statusColor(item),
              isOverdue: _isOverdue(item),
              onTap: () => _showDetails(item),
              onEdit: _canEdit ? () => _openEditDialog(item) : null,
              onMarkDone: (_canEdit && status != 'done')
                  ? () => _markAsDone(item)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _FollowUpHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final TextEditingController searchController;
  final String selectedFilter;
  final List<String> filters;
  final int visibleCount;
  final int totalCount;
  final String profileName;
  final String role;
  final bool isReadOnly;
  final bool canCreate;
  final bool showDesktopCreateAction;
  final VoidCallback onCreate;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onLogout;

  const _FollowUpHeader({
    required this.title,
    required this.showOwnHeader,
    required this.searchController,
    required this.selectedFilter,
    required this.filters,
    required this.visibleCount,
    required this.totalCount,
    required this.profileName,
    required this.role,
    required this.isReadOnly,
    required this.canCreate,
    required this.showDesktopCreateAction,
    required this.onCreate,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 860;
    final hasFilters = searchController.text.trim().isNotEmpty ||
        selectedFilter != 'pending';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          bottom: BorderSide(color: Color(0xFF30260A)),
        ),
      ),
      child: Column(
        children: [
          if (showOwnHeader)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showDesktopCreateAction)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(tr('btn_new_follow_up')),
                    ),
                  ),
                if (isWide)
                  _FollowUpProfileMenu(
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
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text(tr('btn_logout')),
                      ),
                    ],
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
              ],
            ),
          if (showOwnHeader) const SizedBox(height: 12),
          if (isWide)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: tr('followup_search_hint'),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      labelText: tr('followup_filter_status'),
                    ),
                    items: filters
                        .map(
                          (filter) => DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter.toUpperCase()),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onFilterChanged(value);
                    },
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: tr('followup_search_hint'),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedFilter,
                  decoration: InputDecoration(
                    labelText: tr('followup_filter_status'),
                  ),
                  items: filters
                      .map(
                        (filter) => DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter.toUpperCase()),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onFilterChanged(value);
                  },
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$visibleCount shown • $totalCount total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              if (isReadOnly)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
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
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: Text(tr('btn_clear')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowUpProfileMenu extends StatelessWidget {
  final String profileName;
  final String role;
  final Future<void> Function() onLogout;

  const _FollowUpProfileMenu({
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
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'logout',
              child: Text(tr('btn_logout')),
            ),
          ],
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
    );
  }
}

class _DesktopFollowUpListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Text(
              tr('followup_col_lead'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              tr('followup_col_due'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              tr('followup_col_assigned_to'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              tr('followup_col_status'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 28,
            child: Text(
              tr('followup_col_notes'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 170),
        ],
      ),
    );
  }
}

class _DesktopFollowUpRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final String leadLabel;
  final String assigneeLabel;
  final bool canEdit;
  final bool canMarkDone;
  final Color statusColor;
  final bool isOverdue;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkDone;

  const _DesktopFollowUpRow({
    required this.item,
    required this.leadLabel,
    required this.assigneeLabel,
    required this.canEdit,
    required this.canMarkDone,
    required this.statusColor,
    required this.isOverdue,
    required this.onTap,
    required this.onEdit,
    required this.onMarkDone,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return tr('followup_no_due_date');
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final status = _text(item['status']).toLowerCase();
    final dueAt = _parseDateTime(item['due_at']);
    final notes = _text(item['notes']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30260A)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 28,
                child: Text(
                  leadLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 18,
                child: Text(
                  _formatDateTime(dueAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 18,
                child: Text(
                  assigneeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 16,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FollowUpBadge(
                      label: status.toUpperCase(),
                      background: statusColor.withOpacity(0.14),
                      foreground: statusColor,
                    ),
                    if (isOverdue)
                      const _FollowUpBadge(
                        label: 'OVERDUE',
                        background: Color(0xFF4A2F09),
                        foreground: Color(0xFFFFB74D),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 28,
                child: Text(
                  notes.isEmpty ? '—' : notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: notes.isEmpty ? Colors.white38 : Colors.white70,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canMarkDone)
                      OutlinedButton(
                        onPressed: onMarkDone,
                        child: Text(tr('btn_done')),
                      ),
                    if (canEdit)
                      FilledButton(
                        onPressed: onEdit,
                        child: Text(tr('btn_edit')),
                      ),
                  ],
                ),
              ),
              // SizedBox(
              //   width: 138,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       if (canMarkDone)
              //         Padding(
              //           padding: const EdgeInsets.only(right: 8),
              //           child: OutlinedButton(
              //             onPressed: onMarkDone,
              //             child: const Text('Done'),
              //           ),
              //         ),
              //       if (canEdit)
              //         FilledButton(
              //           onPressed: onEdit,
              //           child: const Text('Edit'),
              //         ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileFollowUpCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String leadLabel;
  final String assigneeLabel;
  final bool canEdit;
  final bool canMarkDone;
  final Color statusColor;
  final bool isOverdue;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkDone;

  const _MobileFollowUpCard({
    required this.item,
    required this.leadLabel,
    required this.assigneeLabel,
    required this.canEdit,
    required this.canMarkDone,
    required this.statusColor,
    required this.isOverdue,
    required this.onTap,
    required this.onEdit,
    required this.onMarkDone,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return tr('followup_no_due_date');
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final status = _text(item['status']).toLowerCase();
    final dueAt = _parseDateTime(item['due_at']);
    final notes = _text(item['notes']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF30260A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leadLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FollowUpBadge(
                    label: status.toUpperCase(),
                    background: statusColor.withOpacity(0.14),
                    foreground: statusColor,
                  ),
                  if (isOverdue)
                    const _FollowUpBadge(
                      label: 'OVERDUE',
                      background: Color(0xFF4A2F09),
                      foreground: Color(0xFFFFB74D),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.event_outlined,
                text: _formatDateTime(dueAt),
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: assigneeLabel,
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              if (canEdit || canMarkDone) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    if (canMarkDone)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: onMarkDone,
                          child: Text(tr('btn_done')),
                        ),
                      ),
                    if (canEdit)
                      FilledButton(
                        onPressed: onEdit,
                        child: Text(tr('btn_edit')),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FollowUpBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _FollowUpBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.28)),
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

class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF30260A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowUpDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final String leadLabel;
  final String assigneeLabel;
  final bool canEdit;
  final bool canMarkDone;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkDone;

  const FollowUpDetailsSheet({
    super.key,
    required this.item,
    required this.leadLabel,
    required this.assigneeLabel,
    required this.canEdit,
    required this.canMarkDone,
    this.onEdit,
    this.onMarkDone,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  Widget _row({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
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
                      leadLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (canMarkDone && onMarkDone != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: onMarkDone,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(tr('btn_done')),
                      ),
                    ),
                  if (canEdit && onEdit != null)
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(tr('btn_edit')),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _row(label: tr('followup_detail_lead'), value: leadLabel),
              _row(
                label: tr('followup_detail_due'),
                value: _formatDateTime(_parseDateTime(item['due_at'])),
              ),
              _row(label: tr('followup_col_status'), value: _text(item['status']).toUpperCase()),
              _row(label: tr('followup_detail_assigned'), value: assigneeLabel),
              _row(label: tr('followup_col_notes'), value: _text(item['notes'])),
              _row(
                label: tr('followup_detail_completed'),
                value: _formatDateTime(_parseDateTime(item['completed_at'])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FollowUpFormDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String currentUserId;
  final List<Map<String, dynamic>> leads;
  final Map<String, dynamic>? initialItem;

  const FollowUpFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.currentUserId,
    required this.leads,
    this.initialItem,
  });

  @override
  State<FollowUpFormDialog> createState() => _FollowUpFormDialogState();
}

class _FollowUpFormDialogState extends State<FollowUpFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _notesController;

  String? _leadId;
  String _status = 'pending';
  DateTime? _dueAt;
  bool _isSubmitting = false;

  static const List<String> _statuses = <String>[
    'pending',
    'done',
    'missed',
  ];

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _notesController = TextEditingController(text: _text(item?['notes']));
    _leadId = _text(item?['lead_id']).isNotEmpty ? _text(item?['lead_id']) : null;
    _status = _text(item?['status']).isNotEmpty ? _text(item?['status']) : 'pending';
    _dueAt = _parseDateTime(item?['due_at']);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDueAt() {
    if (_dueAt == null) return 'Select date & time';
    final y = _dueAt!.year.toString().padLeft(4, '0');
    final m = _dueAt!.month.toString().padLeft(2, '0');
    final d = _dueAt!.day.toString().padLeft(2, '0');
    final hh = _dueAt!.hour.toString().padLeft(2, '0');
    final mm = _dueAt!.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  String _leadLabel(Map<String, dynamic> lead) {
    final name = _text(lead['name']);
    final company = _text(lead['company_name']);
    final phone = _text(lead['phone']);

    if (name.isNotEmpty && company.isNotEmpty) return '$name • $company';
    if (name.isNotEmpty) return name;
    if (company.isNotEmpty) return company;
    if (phone.isNotEmpty) return phone;
    return 'Unnamed lead';
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_dueAt == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final result = _FollowUpFormResult(
      leadId: _leadId!,
      dueAt: _dueAt!,
      status: _status,
      notes: _notesController.text.trim(),
      assignedTo: widget.currentUserId.isEmpty ? null : widget.currentUserId,
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
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF30260A)),
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
                          child: DropdownButtonFormField<String>(
                            value: _leadId,
                            decoration: InputDecoration(
                              labelText: tr('followup_field_lead'),
                            ),
                            items: widget.leads
                                .map(
                                  (lead) => DropdownMenuItem<String>(
                                value: _text(lead['id']),
                                child: Text(
                                  _leadLabel(lead),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _leadId = value;
                              });
                            },
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return tr('followup_validation_lead');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: tr('followup_field_status'),
                            ),
                            items: _statuses
                                .map(
                                  (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.toUpperCase()),
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
                        ),
                      ],
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _leadId,
                      decoration: InputDecoration(
                        labelText: tr('followup_field_lead'),
                      ),
                      items: widget.leads
                          .map(
                            (lead) => DropdownMenuItem<String>(
                          value: _text(lead['id']),
                          child: Text(
                            _leadLabel(lead),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _leadId = value;
                        });
                      },
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return tr('followup_validation_lead');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: tr('followup_field_status'),
                      ),
                      items: _statuses
                          .map(
                            (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status.toUpperCase()),
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
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickDueAt,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF30260A),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDueAt(),
                              style: TextStyle(
                                color: _dueAt == null
                                    ? Colors.white60
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit_calendar_outlined),
                        ],
                      ),
                    ),
                  ),
                  if (_dueAt == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        tr('followup_validation_date'),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
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

class _FollowUpFormResult {
  final String leadId;
  final DateTime dueAt;
  final String status;
  final String notes;
  final String? assignedTo;

  const _FollowUpFormResult({
    required this.leadId,
    required this.dueAt,
    required this.status,
    required this.notes,
    required this.assignedTo,
  });

  Map<String, dynamic> toInsertPayload() {
    return {
      'lead_id': leadId,
      'due_at': dueAt.toUtc().toIso8601String(),
      'status': status,
      'notes': notes.isEmpty ? null : notes,
      'assigned_to': assignedTo,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'lead_id': leadId,
      'due_at': dueAt.toUtc().toIso8601String(),
      'status': status,
      'notes': notes.isEmpty ? null : notes,
      'assigned_to': assignedTo,
      'updated_at': DateTime.now().toIso8601String(),
      'completed_at': status == 'done'
          ? DateTime.now().toIso8601String()
          : null,
    };
  }
}