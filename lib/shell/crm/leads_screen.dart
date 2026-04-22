//
// import 'dart:async';
//
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../../core/constants/app_constants.dart';
// import 'customer_profile_screen.dart';
//
// Future<void> _openWhatsApp(String phone) async {
//   // Clean phone: keep digits and leading +
//   final cleaned = phone.replaceAll(RegExp(r'[\s\-().]+'), '');
//   final digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
//   if (digits.isEmpty) return;
//   final uri = Uri.parse('https://wa.me/$digits');
//   if (await canLaunchUrl(uri)) {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
// }
//
// class LeadsScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final bool initialImportantOnly;
//   final String? initialStatus;
//   final bool showOwnHeader;
//   final String? customTitle;
//   final bool allowCreate;
//
//   const LeadsScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//     this.initialImportantOnly = false,
//     this.initialStatus,
//     this.showOwnHeader = true,
//     this.customTitle,
//     this.allowCreate = true,
//   });
//
//   @override
//   State<LeadsScreen> createState() => _LeadsScreenState();
// }
//
// class _LeadsScreenState extends State<LeadsScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final TextEditingController _searchController = TextEditingController();
//
//   RealtimeChannel? _realtimeChannel;
//   Timer? _debounce;
//
//   bool _isLoading = true;
//   String? _error;
//
//   List<Map<String, dynamic>> _allLeads = [];
//   List<Map<String, dynamic>> _filteredLeads = [];
//   Map<String, Map<String, dynamic>> _profileMap = {};
//
//   String _searchQuery = '';
//   String? _selectedStatus;
//   bool _importantOnly = false;
//
//   static const List<String> _statuses = <String>[
//     'new',
//     'contacted',
//     'qualified',
//     'closed_won',
//     'closed_lost',
//   ];
//
//   String _statusLabel(String value) {
//     switch (value) {
//       case 'new':
//         return 'status_new'.tr();
//       case 'contacted':
//         return 'status_contacted'.tr();
//       case 'qualified':
//         return 'status_qualified'.tr();
//       case 'closed_won':
//         return 'status_won'.tr();
//       case 'closed_lost':
//         return 'status_lost'.tr();
//       default:
//         return value;
//     }
//   }
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   bool get _isAdmin => _role == 'admin';
//   bool get _isSales => _role == 'sales';
//   bool get _isViewer => _role == 'viewer';
//   bool get _isAccountant => _role == 'accountant';
//
//   bool get _canCreateLead => _isAdmin || _isSales;
//   bool get _canEditLead => _isAdmin || _isSales;
//   bool get _isReadOnly => _isViewer || _isAccountant;
//
//   String get _currentUserId =>
//       (widget.profile['id'] ?? '').toString().trim();
//
//   @override
//   void initState() {
//     super.initState();
//     _importantOnly = widget.initialImportantOnly;
//     _selectedStatus = widget.initialStatus;
//     _searchController.addListener(_onSearchChanged);
//     _setupRealtime();
//     _loadLeads();
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
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
//   Map<String, dynamic> _payloadMap(dynamic value) {
//     if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
//     if (value is Map) {
//       return value.map((key, val) => MapEntry(key.toString(), val));
//     }
//     return <String, dynamic>{};
//   }
//
//   Future<void> _loadSingleLeadAndUpsert(String leadId) async {
//     if (leadId.isEmpty) return;
//
//     try {
//       final response = await _supabase
//           .from('leads')
//           .select()
//           .eq('id', leadId)
//           .maybeSingle();
//
//       if (!mounted) return;
//
//       if (response == null) {
//         setState(() {
//           _removeLeadLocally(leadId);
//           _applyFilters();
//         });
//         return;
//       }
//
//       final lead = Map<String, dynamic>.from(response as Map);
//
//       final profileIds = <String>{
//         _text(lead['owner_id']),
//         _text(lead['created_by']),
//         _text(lead['assigned_by']),
//       }..removeWhere((e) => e.isEmpty);
//
//       final updatedProfileMap =
//       Map<String, Map<String, dynamic>>.from(_profileMap);
//
//       if (profileIds.isNotEmpty) {
//         final missingIds =
//         profileIds.where((id) => !updatedProfileMap.containsKey(id)).toList();
//
//         if (missingIds.isNotEmpty) {
//           final profilesResponse = await _supabase
//               .from('profiles')
//               .select('id, full_name, email, role')
//               .inFilter('id', missingIds);
//
//           for (final row in profilesResponse as List) {
//             final map = Map<String, dynamic>.from(row as Map);
//             final id = _text(map['id']);
//             if (id.isNotEmpty) {
//               updatedProfileMap[id] = map;
//             }
//           }
//         }
//       }
//
//       setState(() {
//         _profileMap = updatedProfileMap;
//         _upsertLeadLocally(lead);
//       });
//     } catch (_) {
//       // ignore
//     }
//   }
//
//   Future<void> _handleAssignmentLogRealtime(PostgresChangePayload payload) async {
//     if (!mounted || !_isSales || _currentUserId.isEmpty) return;
//
//     final row = _payloadMap(payload.newRecord);
//     if (_text(row['action_type']) != 'assign_lead') return;
//
//     final leadId = _text(row['lead_id']);
//     final meta = _payloadMap(row['meta']);
//     final oldOwnerId = _text(meta['old_owner_id']);
//     final newOwnerId = _text(meta['new_owner_id']);
//
//     final wasMine = oldOwnerId == _currentUserId;
//     final isNowMine = newOwnerId == _currentUserId;
//
//     if (wasMine && !isNowMine) {
//       if (!mounted) return;
//       setState(() {
//         _removeLeadLocally(leadId);
//         _applyFilters();
//       });
//       return;
//     }
//
//     if (isNowMine) {
//       await _loadSingleLeadAndUpsert(leadId);
//     }
//   }
//
//   void _setupRealtime() {
//     final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;
//
//     _realtimeChannel = _supabase
//         .channel('crm-leads-live-$channelKey')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'leads',
//       callback: _handleLeadRealtime,
//     )
//         .onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'activity_logs',
//       callback: _handleAssignmentLogRealtime,
//     )
//         .subscribe();
//   }
//
//   void _handleLeadRealtime(PostgresChangePayload payload) {
//     if (!mounted) return;
//
//     final eventType = payload.eventType;
//     final newRow = Map<String, dynamic>.from(payload.newRecord);
//     final oldRow = Map<String, dynamic>.from(payload.oldRecord);
//
//     setState(() {
//       switch (eventType) {
//         case PostgresChangeEvent.insert:
//         case PostgresChangeEvent.update:
//           if (newRow.isEmpty) return;
//           _upsertLeadLocally(newRow);
//           break;
//
//         case PostgresChangeEvent.delete:
//           final deletedId = _text(oldRow['id']);
//           if (deletedId.isEmpty) return;
//           _removeLeadLocally(deletedId);
//           _applyFilters();
//           break;
//
//         default:
//           break;
//       }
//     });
//   }
//
//   bool _matchesLeadVisibility(Map<String, dynamic> lead) {
//     if (_isAdmin || _isViewer || _isAccountant) return true;
//
//     if (_isSales) {
//       final ownerId = _text(lead['owner_id']);
//       return ownerId == _currentUserId;
//     }
//
//     return false;
//   }
//
//   void _removeLeadLocally(String leadId) {
//     _allLeads.removeWhere((lead) => _text(lead['id']) == leadId);
//   }
//
//   void _sortLeadsLocally() {
//     _allLeads.sort((a, b) {
//       final aUpdated = _parseDateTime(a['updated_at']);
//       final bUpdated = _parseDateTime(b['updated_at']);
//       final aCreated = _parseDateTime(a['created_at']);
//       final bCreated = _parseDateTime(b['created_at']);
//
//       if (aUpdated != null && bUpdated != null) {
//         final byUpdated = bUpdated.compareTo(aUpdated);
//         if (byUpdated != 0) return byUpdated;
//       } else if (aUpdated != null) {
//         return -1;
//       } else if (bUpdated != null) {
//         return 1;
//       }
//
//       if (aCreated != null && bCreated != null) {
//         return bCreated.compareTo(aCreated);
//       } else if (aCreated != null) {
//         return -1;
//       } else if (bCreated != null) {
//         return 1;
//       }
//
//       return 0;
//     });
//   }
//
//   void _upsertLeadLocally(Map<String, dynamic> lead) {
//     final leadId = _text(lead['id']);
//     if (leadId.isEmpty) return;
//
//     _removeLeadLocally(leadId);
//
//     if (!_matchesLeadVisibility(lead)) {
//       _applyFilters();
//       return;
//     }
//
//     _allLeads.add(lead);
//     _sortLeadsLocally();
//     _applyFilters();
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
//   Future<void> _loadLeads() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final response = await _supabase
//           .from('leads')
//           .select()
//           .order('updated_at', ascending: false)
//           .order('created_at', ascending: false)
//           .limit(20000);
//
//       final rows = (response as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       final profileIds = <String>{
//         ...rows.map((e) => _text(e['owner_id'])),
//         ...rows.map((e) => _text(e['created_by'])),
//         ...rows.map((e) => _text(e['assigned_by'])),
//       }..removeWhere((e) => e.isEmpty);
//
//       final profileMap = <String, Map<String, dynamic>>{};
//
//       if (profileIds.isNotEmpty) {
//         final profilesResponse = await _supabase
//             .from('profiles')
//             .select('id, full_name, email, role')
//             .inFilter('id', profileIds.toList());
//
//         for (final row in profilesResponse as List) {
//           final map = Map<String, dynamic>.from(row as Map);
//           final id = _text(map['id']);
//           if (id.isNotEmpty) {
//             profileMap[id] = map;
//           }
//         }
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _allLeads = rows;
//         _profileMap = profileMap;
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
//     final search = _searchQuery;
//
//     _filteredLeads = _allLeads.where((lead) {
//       final name = _text(lead['name']).toLowerCase();
//       final phone = _text(lead['phone']).toLowerCase();
//       final email = _text(lead['email']).toLowerCase();
//       final companyName = _text(lead['company_name']).toLowerCase();
//       final status = _text(lead['status']).toLowerCase();
//       final ownerLabel = _profileLabel(_text(lead['owner_id'])).toLowerCase();
//       final isImportant = lead['is_important'] == true;
//
//       final matchesSearch = search.isEmpty ||
//           name.contains(search) ||
//           phone.contains(search) ||
//           email.contains(search) ||
//           companyName.contains(search) ||
//           ownerLabel.contains(search);
//
//       final matchesStatus =
//           _selectedStatus == null || status == _selectedStatus;
//
//       final matchesImportant = !_importantOnly || isImportant;
//
//       return matchesSearch && matchesStatus && matchesImportant;
//     }).toList();
//   }
//
//   Future<void> _openCreateLeadDialog() async {
//     final result = await showDialog<_LeadFormResult>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => LeadFormDialog(
//         title: tr('lead_form_create'),
//         submitLabel: tr('btn_create'),
//         currentUserId: _currentUserId,
//       ),
//     );
//
//     if (result == null) return;
//
//     try {
//       final payload = result.toInsertPayload(
//         currentUserId: _currentUserId,
//       );
//
//       final inserted = await _supabase
//           .from('leads')
//           .insert(payload)
//           .select()
//           .single();
//
//       final leadId = (inserted['id'] ?? '').toString();
//
//       await _ensurePendingFollowUpForLead(
//         leadId: leadId,
//         requiresFollowUp: result.requiresFollowUp,
//       );
//
//       if (leadId.isNotEmpty && _currentUserId.isNotEmpty) {
//         await _logActivity(
//           leadId: leadId,
//           actionType: 'create_lead',
//           meta: {
//             'status': result.status,
//             'lead_type': result.leadType,
//             'is_important': result.isImportant,
//             'requires_follow_up': result.requiresFollowUp,
//           },
//         );
//       }
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('leads_created'))),
//       );
//
//       await _loadLeads();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('leads_create_failed', namedArgs: {'error': e.toString()}))),
//       );
//     }
//   }
//
//   Future<void> _openEditLeadDialog(Map<String, dynamic> lead) async {
//     final result = await showDialog<_LeadFormResult>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => LeadFormDialog(
//         title: tr('lead_form_edit'),
//         submitLabel: tr('btn_save'),
//         initialLead: lead,
//         currentUserId: _currentUserId,
//       ),
//     );
//
//     if (result == null) return;
//
//     final leadId = (lead['id'] ?? '').toString();
//     if (leadId.isEmpty) return;
//
//     try {
//       final oldRequiresFollowUp = lead['requires_follow_up'] == true;
//       final newRequiresFollowUp = result.requiresFollowUp;
//
//       await _supabase
//           .from('leads')
//           .update(result.toUpdatePayload())
//           .eq('id', leadId);
//
//       if (!oldRequiresFollowUp && newRequiresFollowUp) {
//         await _ensurePendingFollowUpForLead(
//           leadId: leadId,
//           requiresFollowUp: true,
//         );
//       }
//
//       await _logActivity(
//         leadId: leadId,
//         actionType: 'update_lead',
//         meta: {
//           'status': result.status,
//           'lead_type': result.leadType,
//           'is_important': result.isImportant,
//           'requires_follow_up': result.requiresFollowUp,
//         },
//       );
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('leads_updated'))),
//       );
//
//       await _loadLeads();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('leads_update_failed', namedArgs: {'error': e.toString()}))),
//       );
//     }
//   }
//
//   void _openCustomerProfile(Map<String, dynamic> lead) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => CustomerProfileScreen(
//           lead: lead,
//           profile: widget.profile,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _showLeadDetails(Map<String, dynamic> lead) async {
//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF121212),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) {
//         return LeadDetailsSheet(
//           lead: lead,
//           profileMap: _profileMap,
//           canEdit: _canEditLead,
//           onViewProfile: () {
//             Navigator.of(context).pop();
//             _openCustomerProfile(lead);
//           },
//           onEdit: _canEditLead
//               ? () async {
//             Navigator.of(context).pop();
//             await _openEditLeadDialog(lead);
//           }
//               : null,
//         );
//       },
//     );
//   }
//
//   Future<void> _logActivity({
//     required String leadId,
//     required String actionType,
//     required Map<String, dynamic> meta,
//   }) async {
//     if (_currentUserId.isEmpty) return;
//
//     try {
//       await _supabase.from('activity_logs').insert({
//         'actor_id': _currentUserId,
//         'lead_id': leadId,
//         'action_type': actionType,
//         'meta': meta,
//       });
//     } catch (_) {}
//   }
//
//   Future<void> _ensurePendingFollowUpForLead({
//     required String leadId,
//     required bool requiresFollowUp,
//   }) async {
//     if (!requiresFollowUp || leadId.isEmpty) return;
//
//     try {
//       final existing = await _supabase
//           .from('follow_ups')
//           .select('id, status')
//           .eq('lead_id', leadId)
//           .neq('status', 'done')
//           .limit(1);
//
//       final existingRows = (existing as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       if (existingRows.isNotEmpty) return;
//
//       await _supabase.from('follow_ups').insert({
//         'lead_id': leadId,
//         'assigned_to': _currentUserId.isEmpty ? null : _currentUserId,
//         'due_at': DateTime.now()
//             .add(const Duration(days: 1))
//             .toUtc()
//             .toIso8601String(),
//         'status': 'pending',
//         'notes': 'Auto-created from lead follow-up flag',
//       });
//     } catch (e) {
//       debugPrint('AUTO FOLLOW-UP CREATE FAILED: $e');
//       rethrow;
//     }
//   }
//
//   void _clearFilters() {
//     _searchController.clear();
//     setState(() {
//       _searchQuery = '';
//       _selectedStatus = null;
//       _importantOnly = false;
//       _applyFilters();
//     });
//   }
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   DateTime? _parseDateTime(dynamic value) {
//     if (value == null) return null;
//     return DateTime.tryParse(value.toString())?.toLocal();
//   }
//
//   String _displayName() {
//     final fullName = _text(widget.profile['full_name']);
//     final email = _text(widget.profile['email']);
//     return fullName.isNotEmpty ? fullName : email;
//   }
//
//   bool _missingName(Map<String, dynamic> lead) {
//     if (lead['missing_name'] is bool) return lead['missing_name'] == true;
//     return _text(lead['name']).isEmpty;
//   }
//
//   bool _missingPhone(Map<String, dynamic> lead) {
//     if (lead['missing_phone'] is bool) return lead['missing_phone'] == true;
//     return _text(lead['phone']).isEmpty;
//   }
//
//   bool _missingEmail(Map<String, dynamic> lead) {
//     if (lead['missing_email'] is bool) return lead['missing_email'] == true;
//     return _text(lead['email']).isEmpty;
//   }
//
//   List<String> _missingFields(Map<String, dynamic> lead) {
//     final list = <String>[];
//     if (_missingName(lead)) list.add('Name');
//     if (_missingPhone(lead)) list.add('Phone');
//     if (_missingEmail(lead)) list.add('Email');
//     return list;
//   }
//
//   String _profileLabel(String? userId) {
//     final id = _text(userId);
//     if (id.isEmpty) return 'Unassigned';
//
//     final profile = _profileMap[id];
//     if (profile == null) return 'Unknown user';
//
//     final fullName = _text(profile['full_name']);
//     final email = _text(profile['email']);
//
//     if (fullName.isNotEmpty) return fullName;
//     if (email.isNotEmpty) return email;
//     return 'Unknown user';
//   }
//
//   Color _statusColor(String status) {
//     switch (status) {
//       case 'new':
//         return const Color(0xFF8C6B16);
//       case 'contacted':
//         return const Color(0xFF1976D2);
//       case 'qualified':
//         return const Color(0xFF2E7D32);
//       case 'closed_won':
//         return const Color(0xFF00A86B);
//       case 'closed_lost':
//         return const Color(0xFFB00020);
//       default:
//         return const Color(0xFF555555);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isDesktop = MediaQuery.of(context).size.width >= 1000;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       floatingActionButton: (!isDesktop && _canCreateLead && widget.allowCreate)
//           ? FloatingActionButton.extended(
//         onPressed: _openCreateLeadDialog,
//         icon: const Icon(Icons.person_add_alt_1_outlined),
//         label:  Text('btn_new_lead'.tr()),
//       )
//           : null,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _LeadsHeader(
//               title: widget.customTitle ?? 'leads_title'.tr(),
//               showOwnHeader: widget.showOwnHeader,
//               searchController: _searchController,
//               selectedStatus: _selectedStatus,
//               statuses: _statuses,
//               statusLabelBuilder: _statusLabel,
//               importantOnly: _importantOnly,
//               visibleCount: _filteredLeads.length,
//               totalCount: _allLeads.length,
//               profileName: _displayName(),
//               role: _role,
//               isReadOnly: _isReadOnly,
//               canCreate: _canCreateLead && widget.allowCreate,
//               showDesktopCreateAction: isDesktop && _canCreateLead && widget.allowCreate,
//               // showDesktopCreateAction: isWide && _canCreateLead && widget.allowCreate,
//               onCreate: _openCreateLeadDialog,
//               onStatusChanged: (value) {
//                 setState(() {
//                   _selectedStatus = value;
//                   _applyFilters();
//                 });
//               },
//               onImportantOnlyChanged: (value) {
//                 setState(() {
//                   _importantOnly = value;
//                   _applyFilters();
//                 });
//               },
//               onClearFilters: _clearFilters,
//               onLogout: widget.onLogout,
//             ),
//             Expanded(
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 180),
//                 child: _buildBody(isDesktop),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody(bool isDesktop) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_error != null) {
//       return _StateCard(
//         icon: Icons.error_outline_rounded,
//         iconColor: Colors.redAccent,
//         title: 'leads_error'.tr(),
//         message: _error!,
//         actions: [
//           FilledButton.icon(
//             onPressed: _loadLeads,
//             icon: const Icon(Icons.refresh_rounded),
//             label:  Text('btn_retry'.tr()),
//           ),
//         ],
//       );
//     }
//
//     if (_filteredLeads.isEmpty) {
//       return _StateCard(
//         icon: Icons.people_outline_rounded,
//         iconColor: AppConstants.primaryColor,
//         title: _allLeads.isEmpty
//             ? 'leads_empty_title'.tr()
//             : 'leads_empty_filtered'.tr(),
//         message: _allLeads.isEmpty
//             ? (_canCreateLead
//             ? 'leads_empty_subtitle'.tr()
//             : 'leads_empty_no_access'.tr())
//             : 'leads_empty_filter_hint'.tr(),
//         actions: [
//           OutlinedButton.icon(
//             onPressed: _loadLeads,
//             icon: const Icon(Icons.refresh_rounded),
//             label:  Text('btn_refresh'.tr()),
//           ),
//           if (_canCreateLead && _allLeads.isEmpty && widget.allowCreate)
//             FilledButton.icon(
//               onPressed: _openCreateLeadDialog,
//               icon: const Icon(Icons.add_rounded),
//               label: Text(tr('btn_create_lead')),
//             ),
//         ],
//       );
//     }
//
//     if (isDesktop) {
//       return RefreshIndicator(
//         onRefresh: _loadLeads,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
//           children: [
//             const _DesktopLeadListHeader(),
//             const SizedBox(height: 8),
//             ..._filteredLeads.map((lead) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: _DesktopLeadRow(
//                   lead: lead,
//                   ownerLabel: _profileLabel(lead['owner_id']),
//                   canEdit: _canEditLead,
//                   missingFields: _missingFields(lead),
//                   statusColor: _statusColor(_text(lead['status']).toLowerCase()),
//                   onTap: () => _showLeadDetails(lead),
//                   onViewProfile: () => _openCustomerProfile(lead),
//                   onEdit: _canEditLead ? () => _openEditLeadDialog(lead) : null,
//                 ),
//               );
//             }),
//           ],
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: _loadLeads,
//       child: ListView.builder(
//         padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
//         itemCount: _filteredLeads.length,
//         itemBuilder: (context, index) {
//           final lead = _filteredLeads[index];
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: _MobileLeadCard(
//               lead: lead,
//               canEdit: _canEditLead,
//               missingFields: _missingFields(lead),
//               statusColor: _statusColor(_text(lead['status']).toLowerCase()),
//               onTap: () => _showLeadDetails(lead),
//               onViewProfile: () => _openCustomerProfile(lead),
//               onEdit: _canEditLead ? () => _openEditLeadDialog(lead) : null,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _LeadsHeader extends StatelessWidget {
//   final String title;
//   final bool showOwnHeader;
//   final TextEditingController searchController;
//   final String? selectedStatus;
//   final List<String> statuses;
//   final String Function(String) statusLabelBuilder;
//   final bool importantOnly;
//   final int visibleCount;
//   final int totalCount;
//   final String profileName;
//   final String role;
//   final bool isReadOnly;
//   final bool canCreate;
//   final bool showDesktopCreateAction;
//   final VoidCallback onCreate;
//   final ValueChanged<String?> onStatusChanged;
//   final ValueChanged<bool> onImportantOnlyChanged;
//   final VoidCallback onClearFilters;
//   final Future<void> Function() onLogout;
//
//   const _LeadsHeader({
//     required this.title,
//     required this.showOwnHeader,
//     required this.searchController,
//     required this.selectedStatus,
//     required this.statuses,
//     required this.statusLabelBuilder,
//     required this.importantOnly,
//     required this.visibleCount,
//     required this.totalCount,
//     required this.profileName,
//     required this.role,
//     required this.isReadOnly,
//     required this.canCreate,
//     required this.showDesktopCreateAction,
//     required this.onCreate,
//     required this.onStatusChanged,
//     required this.onImportantOnlyChanged,
//     required this.onClearFilters,
//     required this.onLogout,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isWide = MediaQuery.of(context).size.width >= 860;
//     final bool hasFilters =
//         searchController.text.trim().isNotEmpty ||
//             selectedStatus != null ||
//             importantOnly;
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
//       decoration: const BoxDecoration(
//         color: Color(0xFF111111),
//         border: Border(
//           bottom: BorderSide(color: Color(0xFF30260A)),
//         ),
//       ),
//       child: Column(
//         children: [
//           if (showOwnHeader)
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ),
//                 if (showDesktopCreateAction)
//                   Padding(
//                     padding: const EdgeInsetsDirectional.only(end: 12),
//                     child: FilledButton.icon(
//                       onPressed: onCreate,
//                       icon: const Icon(Icons.person_add_alt_1_outlined),
//                       label: Text('btn_new_lead'.tr()),
//                     ),
//                   ),
//                 if (!isWide)
//                   PopupMenuButton<String>(
//                     onSelected: (value) async {
//                       if (value == 'logout') {
//                         await onLogout();
//                       }
//                     },
//                     itemBuilder: (_) => [
//                       PopupMenuItem<String>(
//                         value: 'logout',
//                         child: Text('btn_logout'.tr()),
//                       ),
//                     ],
//                     icon: const Icon(Icons.account_circle_outlined),
//                   ),
//               ],
//             ),
//           if (showOwnHeader) const SizedBox(height: 12),
//
//           if (isWide)
//             Row(
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: TextField(
//                     controller: searchController,
//                     decoration: InputDecoration(
//                       hintText: 'leads_search_hint'.tr(),
//                       prefixIcon: const Icon(Icons.search_rounded),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DropdownButtonFormField<String?>(
//                     value: selectedStatus,
//                     decoration: InputDecoration(
//                       labelText: 'leads_filter_stage'.tr(),
//                     ),
//                     items: [
//                       DropdownMenuItem<String?>(
//                         value: null,
//                         child: Text('leads_filter_all'.tr()),
//                       ),
//                       ...statuses.map(
//                             (status) => DropdownMenuItem<String?>(
//                           value: status,
//                           child: Text(statusLabelBuilder(status)),
//                         ),
//                       ),
//                     ],
//                     onChanged: onStatusChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // SizedBox(
//                 //   width: 160,
//                 //   child: SwitchListTile.adaptive(
//                 //     value: importantOnly,
//                 //     onChanged: onImportantOnlyChanged,
//                 //     title: Text(
//                 //       'leads_important_only'.tr(),
//                 //       style: const TextStyle(fontSize: 13),
//                 //     ),
//                 //     contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 4),
//                 //   ),
//                 // ),
//                 _ImportantToggleButton(
//                   value: importantOnly,
//                   onChanged: onImportantOnlyChanged,
//                 ),
//                 if (hasFilters) ...[
//                   const SizedBox(width: 8),
//                   OutlinedButton.icon(
//                     onPressed: onClearFilters,
//                     icon: const Icon(Icons.clear_all_rounded),
//                     label: Text('btn_clear'.tr()),
//                   ),
//                 ],
//               ],
//             )
//           else
//             Column(
//               children: [
//                 TextField(
//                   controller: searchController,
//                   decoration: InputDecoration(
//                     hintText: 'leads_search_hint'.tr(),
//                     prefixIcon: const Icon(Icons.search_rounded),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: DropdownButtonFormField<String?>(
//                         value: selectedStatus,
//                         decoration: InputDecoration(
//                           labelText: 'leads_filter_stage'.tr(),
//                         ),
//                         items: [
//                           DropdownMenuItem<String?>(
//                             value: null,
//                             child: Text('leads_filter_all'.tr()),
//                           ),
//                           ...statuses.map(
//                                 (status) => DropdownMenuItem<String?>(
//                               value: status,
//                               child: Text(statusLabelBuilder(status)),
//                             ),
//                           ),
//                         ],
//                         onChanged: onStatusChanged,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     // Expanded(
//                     //   child: CheckboxListTile(
//                     //     value: importantOnly,
//                     //     onChanged: (value) =>
//                     //         onImportantOnlyChanged(value ?? false),
//                     //     title: Text('leads_important_only'.tr()),
//                     //     contentPadding: EdgeInsets.zero,
//                     //     controlAffinity: ListTileControlAffinity.leading,
//                     //   ),
//                     // ),
//                     Expanded(
//                       child: Align(
//                         alignment: AlignmentDirectional.centerStart,
//                         child: _ImportantToggleButton(
//                           value: importantOnly,
//                           onChanged: onImportantOnlyChanged,
//                         ),
//                       ),
//                     ),
//                     if (hasFilters)
//                       OutlinedButton.icon(
//                         onPressed: onClearFilters,
//                         icon: const Icon(Icons.clear_all_rounded),
//                         label: Text('btn_clear'.tr()),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Align(
//                   alignment: AlignmentDirectional.centerStart,
//                   child: Text(
//                     'leads_shown'.tr(
//                       namedArgs: {
//                         'shown': visibleCount.toString(),
//                         'total': totalCount.toString(),
//                       },
//                     ),
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//
//           if (isWide) ...[
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'leads_shown'.tr(
//                       namedArgs: {
//                         'shown': visibleCount.toString(),
//                         'total': totalCount.toString(),
//                       },
//                     ),
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//                 if (isReadOnly)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.06),
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.white12),
//                     ),
//                     child: Text(
//                       'leads_read_only'.tr(),
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
//
// class _ImportantToggleButton extends StatelessWidget {
//   final bool value;
//   final ValueChanged<bool> onChanged;
//
//   const _ImportantToggleButton({
//     required this.value,
//     required this.onChanged,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Color activeColor = AppConstants.primaryColor;
//     final Color borderColor =
//     value ? activeColor : Colors.white.withOpacity(0.12);
//     final Color backgroundColor =
//     value ? activeColor.withOpacity(0.14) : Colors.white.withOpacity(0.04);
//     final Color textColor = value ? activeColor : Colors.white70;
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => onChanged(!value),
//         borderRadius: BorderRadius.circular(12),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           curve: Curves.easeOut,
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: borderColor),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 value ? Icons.star_rounded : Icons.star_border_rounded,
//                 size: 18,
//                 color: textColor,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'leads_important_only'.tr(),
//                 style: TextStyle(
//                   color: textColor,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// class _ProfileMenu extends StatelessWidget {
//   final String profileName;
//   final String role;
//   final Future<void> Function() onLogout;
//
//   const _ProfileMenu({
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
//                   color: AppConstants.primaryColor,
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
//           itemBuilder: (_) => [
//             PopupMenuItem<String>(
//               value: 'logout',
//               child: Text(tr('btn_logout')),
//             ),
//           ],
//           icon: const Icon(Icons.account_circle_outlined),
//         ),
//       ],
//     );
//   }
// }
//
// class _DesktopLeadListHeader extends StatelessWidget {
//   const _DesktopLeadListHeader();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 44,
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111111),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFF30260A)),
//       ),
//       child:  Row(
//         children: [
//           Expanded(
//             flex: 24,
//             child: Text(
//               'leads_col_lead'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 18,
//             child: Text(
//               'leads_col_contact'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 14,
//             child: Text(
//               'leads_col_type'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 18,
//             child: Text(
//               'leads_col_owner'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 18,
//             child: Text(
//               'leads_col_status'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 20,
//             child: Text(
//               'leads_col_notes'.tr(),
//               style: TextStyle(
//                 fontWeight: FontWeight.w800,
//                 color: Colors.white70,
//               ),
//             ),
//           ),
//           SizedBox(width: 130),
//         ],
//       ),
//     );
//   }
// }
//
// class _DesktopLeadRow extends StatelessWidget {
//   final Map<String, dynamic> lead;
//   final String ownerLabel;
//   final bool canEdit;
//   final List<String> missingFields;
//   final Color statusColor;
//   final VoidCallback onTap;
//   final VoidCallback onViewProfile;
//   final VoidCallback? onEdit;
//
//   const _DesktopLeadRow({
//     required this.lead,
//     required this.ownerLabel,
//     required this.canEdit,
//     required this.missingFields,
//     required this.statusColor,
//     required this.onTap,
//     required this.onViewProfile,
//     required this.onEdit,
//   });
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   @override
//   Widget build(BuildContext context) {
//     final name = _text(lead['name']);
//     final phone = _text(lead['phone']);
//     final email = _text(lead['email']);
//     final leadType = _text(lead['lead_type']);
//     final companyName = _text(lead['company_name']);
//     final status = _text(lead['status']);
//     final isImportant = lead['is_important'] == true;
//     final notes = _text(lead['notes']);
//
//     final title = name.isNotEmpty
//         ? name
//         : (companyName.isNotEmpty ? companyName : 'leads_unnamed'.tr());
//
//     final subtitle = companyName.isNotEmpty && companyName != title
//         ? companyName
//         : '';
//
//     final contact = phone.isNotEmpty
//         ? phone
//         : (email.isNotEmpty ? email : 'leads_no_contactt'.tr());
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Container(
//           constraints: const BoxConstraints(minHeight: 70),
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: isImportant
//                   ? AppConstants.primaryColor
//                   : const Color(0xFF30260A),
//             ),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 flex: 24,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 15,
//                       ),
//                     ),
//                     if (subtitle.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 2),
//                         child: Text(
//                           subtitle,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(color: Colors.white70),
//                         ),
//                       ),
//                     if (missingFields.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Text(
//                           // 'Missing: ${missingFields.join(', ')}',
//                           'leads_missing'.tr(namedArgs: {
//                             "fields":missingFields.join(', ')
//                           }),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Color(0xFFFFE082),
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 flex: 18,
//                 child: GestureDetector(
//                   onTap: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
//                   child: Text(
//                     contact,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: phone.isNotEmpty
//                         ? const TextStyle(
//                             color: Color(0xFF4FC3F7),
//                             decoration: TextDecoration.underline,
//                             decorationColor: Color(0xFF4FC3F7),
//                           )
//                         : null,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 flex: 14,
//                 child: Text(
//                   leadType.isEmpty ? '—' : leadType.toUpperCase(),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Expanded(
//                 flex: 18,
//                 child: Text(
//                   ownerLabel,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Expanded(
//                 flex: 18,
//                 child: Wrap(
//                   spacing: 6,
//                   runSpacing: 6,
//                   children: [
//                     _MiniBadge(
//                       label: status.replaceAll('_', ' ').toUpperCase(),
//                       background: statusColor.withOpacity(0.18),
//                       foreground: statusColor,
//                     ),
//                     if (isImportant)
//                        _MiniBadge(
//                         label: 'leads_important'.tr(),
//                         background: Color(0xFF4A3B12),
//                         foreground: AppConstants.primaryColor,
//                       ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 flex: 20,
//                 child: Text(
//                   notes.isEmpty ? '—' : notes,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: notes.isEmpty ? Colors.white38 : Colors.white70,
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 130,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon:  Icon(Icons.person_search_outlined),
//                       tooltip: 'leads_view_profile'.tr(),
//                       color: AppConstants.primaryColor,
//                       onPressed: onViewProfile,
//                     ),
//                     if (canEdit)
//                       FilledButton(
//                         onPressed: onEdit,
//                         child:  Text('btn_edit').tr(),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _MobileLeadCard extends StatelessWidget {
//   final Map<String, dynamic> lead;
//   final bool canEdit;
//   final List<String> missingFields;
//   final Color statusColor;
//   final VoidCallback onTap;
//   final VoidCallback onViewProfile;
//   final VoidCallback? onEdit;
//
//   const _MobileLeadCard({
//     required this.lead,
//     required this.canEdit,
//     required this.missingFields,
//     required this.statusColor,
//     required this.onTap,
//     required this.onViewProfile,
//     required this.onEdit,
//   });
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   @override
//   Widget build(BuildContext context) {
//     final name = _text(lead['name']);
//     final phone = _text(lead['phone']);
//     final email = _text(lead['email']);
//     final leadType = _text(lead['lead_type']);
//     final companyName = _text(lead['company_name']);
//     final status = _text(lead['status']);
//     final isImportant = lead['is_important'] == true;
//     final notes = _text(lead['notes']);
//
//     final title = name.isNotEmpty
//         ? name
//         : (companyName.isNotEmpty ? companyName : 'followup_unnamed_lead'.tr());
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: isImportant
//                   ? AppConstants.primaryColor
//                   : const Color(0xFF30260A),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               if (companyName.isNotEmpty && companyName != title) ...[
//                 const SizedBox(height: 2),
//                 Text(
//                   companyName,
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//               ],
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: [
//                   _MiniBadge(
//                     label: status.replaceAll('_', ' ').toUpperCase(),
//                     background: statusColor.withOpacity(0.18),
//                     foreground: statusColor,
//                   ),
//                   if (isImportant)
//                      _MiniBadge(
//                       label: 'stats_important'.tr(),
//                       background: Color(0xFF4A3B12),
//                       foreground: AppConstants.primaryColor,
//                       icon: Icons.star_rounded,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               GestureDetector(
//                 onTap: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
//                 child: _InfoText(
//                   icon: Icons.phone_outlined,
//                   text: phone.isEmpty ? 'leads_no_phone'.tr() : phone,
//                   tappable: phone.isNotEmpty,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               _InfoText(
//                 icon: Icons.email_outlined,
//                 text: email.isEmpty ? 'leads_no_email'.tr() : email,
//               ),
//               const SizedBox(height: 6),
//               _InfoText(
//                 icon: Icons.business_outlined,
//                 text: leadType.isEmpty ? 'leads_unknown_type'.tr() : leadType.toUpperCase(),
//               ),
//               if (missingFields.isNotEmpty) ...[
//                 const SizedBox(height: 10),
//                 Text(
//                   // 'Missing: ${missingFields.join(', ')}',
//                   'leads_missing'.tr(
//                     namedArgs: {
//                       'fields':missingFields.join(', ')
//                     }
//                   ),
//                   style: const TextStyle(
//                     color: Color(0xFFFFE082),
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//               if (notes.isNotEmpty) ...[
//                 const SizedBox(height: 10),
//                 Text(
//                   notes,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//               ],
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   OutlinedButton.icon(
//                     onPressed: onViewProfile,
//                     icon: const Icon(Icons.person_search_outlined, size: 16),
//                     label:  Text('btn_profile'.tr()),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: AppConstants.primaryColor,
//                       side: const BorderSide(color: AppConstants.primaryColor),
//                     ),
//                   ),
//                   const Spacer(),
//                   if (canEdit)
//                     FilledButton(
//                       onPressed: onEdit,
//                       child:  Text('btn_edit'.tr()),
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
// class _InfoText extends StatelessWidget {
//   final IconData icon;
//   final String text;
//   final bool tappable;
//
//   const _InfoText({
//     required this.icon,
//     required this.text,
//     this.tappable = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: AppConstants.primaryColor),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             text,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: tappable
//                 ? const TextStyle(
//                     color: Color(0xFF4FC3F7),
//                     decoration: TextDecoration.underline,
//                     decorationColor: Color(0xFF4FC3F7),
//                   )
//                 : null,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _MiniBadge extends StatelessWidget {
//   final String label;
//   final Color background;
//   final Color foreground;
//   final IconData? icon;
//
//   const _MiniBadge({
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
// class _StateCard extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String title;
//   final String message;
//   final List<Widget> actions;
//
//   const _StateCard({
//     required this.icon,
//     required this.iconColor,
//     required this.title,
//     required this.message,
//     required this.actions,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 560),
//           padding: const EdgeInsets.all(22),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFF30260A)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 42, color: iconColor),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 alignment: WrapAlignment.center,
//                 children: actions,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class LeadDetailsSheet extends StatelessWidget {
//   final Map<String, dynamic> lead;
//   final Map<String, Map<String, dynamic>> profileMap;
//   final bool canEdit;
//   final VoidCallback? onViewProfile;
//   final VoidCallback? onEdit;
//
//   const LeadDetailsSheet({
//     super.key,
//     required this.lead,
//     required this.profileMap,
//     required this.canEdit,
//     this.onViewProfile,
//     this.onEdit,
//   });
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   String _profileLabel(String? userId) {
//     final id = _text(userId);
//     if (id.isEmpty) return 'leads_unassigned'.tr();
//
//     final profile = profileMap[id];
//     if (profile == null) return 'leads_unknown_user'.tr();
//
//     final fullName = _text(profile['full_name']);
//     final email = _text(profile['email']);
//     final role = _text(profile['role']).toUpperCase();
//
//     if (fullName.isNotEmpty) return '$fullName • $role';
//     if (email.isNotEmpty) return '$email • $role';
//     return 'leads_unknown_user'.tr();
//   }
//
//   Widget _row({
//     required String label,
//     required String value,
//     VoidCallback? onTap,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: AppConstants.primaryColor,
//               fontWeight: FontWeight.w800,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 4),
//           GestureDetector(
//             onTap: onTap,
//             child: Text(
//               value.isEmpty ? '—' : value,
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//                 color: onTap != null ? const Color(0xFF4FC3F7) : null,
//                 decoration: onTap != null ? TextDecoration.underline : null,
//                 decorationColor: onTap != null ? const Color(0xFF4FC3F7) : null,
//               ),
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
//     final title = _text(lead['name']).isNotEmpty
//         ? _text(lead['name'])
//         : (_text(lead['company_name']).isNotEmpty
//         ? _text(lead['company_name'])
//         : 'leads_details_title'.tr());
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
//                       title,
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                   ),
//                   if (onViewProfile != null)
//                     Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: OutlinedButton.icon(
//                         onPressed: onViewProfile,
//                         icon: const Icon(Icons.person_search_outlined, size: 16),
//                         label:  Text('btn_profile'.tr()),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: AppConstants.primaryColor,
//                           side: const BorderSide(color: AppConstants.primaryColor),
//                         ),
//                       ),
//                     ),
//                   if (canEdit && onEdit != null)
//                     FilledButton.icon(
//                       onPressed: onEdit,
//                       icon: const Icon(Icons.edit_outlined),
//                       label:  Text('btn_edit'.tr()),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 18),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: [
//                   if (lead['is_important'] == true)
//                      _MiniBadge(
//                       label: 'leads_important'.tr(),
//                       background: Color(0xFF4A3B12),
//                       foreground: AppConstants.primaryColor,
//                       icon: Icons.star_rounded,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               _row(
//                 label: 'lead_field_phone'.tr(),
//                 value: _text(lead['phone']),
//                 onTap: _text(lead['phone']).isNotEmpty
//                     ? () => _openWhatsApp(_text(lead['phone']))
//                     : null,
//               ),
//               _row(label: 'lead_field_email'.tr(), value: _text(lead['email'])),
//               _row(
//                 label: 'lead_field_type'.tr(),
//                 value: _text(lead['lead_type']).toUpperCase(),
//               ),
//               _row(label: 'lead_field_company'.tr(), value: _text(lead['company_name'])),
//               _row(label: 'lead_field_trn'.tr(), value: _text(lead['company_trn'])),
//               _row(
//                 label: 'lead_field_status'.tr(),
//                 value: _text(lead['status']).replaceAll('_', ' ').toUpperCase(),
//               ),
//               _row(label: 'lead_field_notes'.tr(), value: _text(lead['notes'])),
//               _row(label: 'lead_owner'.tr(), value: _profileLabel(lead['owner_id'])),
//               _row(label: 'lead_created_by'.tr(), value: _profileLabel(lead['created_by'])),
//               _row(label: 'lead_assigned_by'.tr(), value: _profileLabel(lead['assigned_by'])),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class LeadFormDialog extends StatefulWidget {
//   final String title;
//   final String submitLabel;
//   final String currentUserId;
//   final Map<String, dynamic>? initialLead;
//
//   const LeadFormDialog({
//     super.key,
//     required this.title,
//     required this.submitLabel,
//     required this.currentUserId,
//     this.initialLead,
//   });
//
//   @override
//   State<LeadFormDialog> createState() => _LeadFormDialogState();
// }
//
// class _LeadFormDialogState extends State<LeadFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//
//   late final TextEditingController _nameController;
//   late final TextEditingController _phoneController;
//   late final TextEditingController _emailController;
//   late final TextEditingController _companyNameController;
//   late final TextEditingController _companyTrnController;
//   late final TextEditingController _notesController;
//
//   late String _leadType;
//   late String _status;
//   late bool _isImportant;
//   late bool _requiresFollowUp;
//
//   bool _isSubmitting = false;
//
//   static  const List<String> _statuses = <String>[
//     'new',
//     'contacted',
//     'qualified',
//     'closed_won',
//     'closed_lost',
//   ];
//   String _statusLabel(String value) {
//     switch (value) {
//       case 'new':
//         return 'status_new'.tr();
//       case 'contacted':
//         return 'status_contacted'.tr();
//       case 'qualified':
//         return 'status_qualified'.tr();
//       case 'closed_won':
//         return 'status_won'.tr();
//       case 'closed_lost':
//         return 'status_lost'.tr();
//       default:
//         return value;
//     }
//   }
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   @override
//   void initState() {
//     super.initState();
//     final lead = widget.initialLead;
//
//     _nameController = TextEditingController(text: _text(lead?['name']));
//     _phoneController = TextEditingController(
//       text: _text(lead?['phone']).isNotEmpty ? _text(lead?['phone']) : '+971',
//     );
//     _emailController = TextEditingController(text: _text(lead?['email']));
//     _companyNameController =
//         TextEditingController(text: _text(lead?['company_name']));
//     _companyTrnController =
//         TextEditingController(text: _text(lead?['company_trn']));
//     _notesController = TextEditingController(text: _text(lead?['notes']));
//
//     _leadType = _text(lead?['lead_type']).isNotEmpty
//         ? _text(lead?['lead_type'])
//         : 'individual';
//
//     _status = _text(lead?['status']).isNotEmpty
//         ? _text(lead?['status'])
//         : 'new';
//
//     _isImportant = lead?['is_important'] == true;
//     _requiresFollowUp = lead?['requires_follow_up'] == true;
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _companyNameController.dispose();
//     _companyTrnController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }
//
//   void _submit() {
//     if (_isSubmitting) return;
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     final result = _LeadFormResult(
//       name: _nameController.text.trim(),
//       phone: _phoneController.text.trim(),
//       email: _emailController.text.trim(),
//       leadType: _leadType,
//       companyName:
//       _leadType == 'company' ? _companyNameController.text.trim() : '',
//       companyTrn:
//       _leadType == 'company' ? _companyTrnController.text.trim() : '',
//       status: _status,
//       notes: _notesController.text.trim(),
//       isImportant: _isImportant,
//       requiresFollowUp: _requiresFollowUp,
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
//                           child: TextFormField(
//                             controller: _nameController,
//                             textInputAction: TextInputAction.next,
//                             decoration:  InputDecoration(
//                               labelText: 'lead_field_name'.tr(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _phoneController,
//                             textInputAction: TextInputAction.next,
//                             decoration:  InputDecoration(
//                               labelText: 'lead_field_phone'.tr(),
//                             ),
//                             validator: (value) {
//                               if ((value ?? '').trim().isEmpty) {
//                                 return 'lead_validation_phone'.tr();
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     )
//                   else ...[
//                     TextFormField(
//                       controller: _nameController,
//                       textInputAction: TextInputAction.next,
//                       decoration:  InputDecoration(
//                         labelText: 'lead_field_name'.tr(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextFormField(
//                       controller: _phoneController,
//                       textInputAction: TextInputAction.next,
//                       decoration:  InputDecoration(
//                         labelText: 'lead_field_phone'.tr(),
//                       ),
//                       validator: (value) {
//                         if ((value ?? '').trim().isEmpty) {
//                           return 'lead_validation_phone'.tr();
//                         }
//                         return null;
//                       },
//                     ),
//                   ],
//                   const SizedBox(height: 12),
//                   if (isWide)
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _emailController,
//                             textInputAction: TextInputAction.next,
//                             decoration:  InputDecoration(
//                               labelText: 'lead_field_email'.tr(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _leadType,
//                             decoration:  InputDecoration(
//                               labelText: 'lead_field_type'.tr(),
//                             ),
//                             items:  [
//                               DropdownMenuItem(
//                                 value: 'individual',
//                                 child: Text('lead_type_individual'.tr()),
//                               ),
//                               DropdownMenuItem(
//                                 value: 'company',
//                                 child: Text('lead_type_company'.tr()),
//                               ),
//                             ],
//                             onChanged: (value) {
//                               if (value == null) return;
//                               setState(() {
//                                 _leadType = value;
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     )
//                   else ...[
//                     TextFormField(
//                       controller: _emailController,
//                       textInputAction: TextInputAction.next,
//                       decoration:  InputDecoration(
//                         labelText: 'lead_field_email'.tr(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     DropdownButtonFormField<String>(
//                       value: _leadType,
//                       decoration:  InputDecoration(
//                         labelText: 'lead_field_type'.tr(),
//                       ),
//                       items:  [
//                         DropdownMenuItem(
//                           value: 'individual',
//                           child: Text('lead_type_individual'.tr()),
//                         ),
//                         DropdownMenuItem(
//                           value: 'company',
//                           child: Text('lead_type_company'.tr()),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         if (value == null) return;
//                         setState(() {
//                           _leadType = value;
//                         });
//                       },
//                     ),
//                   ],
//                   if (_leadType == 'company') ...[
//                     const SizedBox(height: 12),
//                     if (isWide)
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: _companyNameController,
//                               textInputAction: TextInputAction.next,
//                               decoration:  InputDecoration(
//                                 labelText: 'lead_field_company'.tr(),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: TextFormField(
//                               controller: _companyTrnController,
//                               textInputAction: TextInputAction.next,
//                               decoration:  InputDecoration(
//                                 labelText: 'lead_field_trn'.tr(),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     else ...[
//                       TextFormField(
//                         controller: _companyNameController,
//                         textInputAction: TextInputAction.next,
//                         decoration:  InputDecoration(
//                           labelText: 'lead_field_company'.tr(),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _companyTrnController,
//                         textInputAction: TextInputAction.next,
//                         decoration:  InputDecoration(
//                           labelText: 'lead_field_trn'.tr(),
//                         ),
//                       ),
//                     ],
//                   ],
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<String>(
//                     value: _status,
//                     decoration:  InputDecoration(
//                       labelText: 'lead_field_status'.tr(),
//                     ),
//                     items: _statuses
//                         .map(
//                           (status) => DropdownMenuItem(
//                         value: status,
//                         child: Text(
//                           status.replaceAll('_', ' ').toUpperCase(),
//                         ),
//                       ),
//                     )
//                         .toList(),
//                     onChanged: (value) {
//                       if (value == null) return;
//                       setState(() {
//                         _status = value;
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   TextFormField(
//                     controller: _notesController,
//                     minLines: 4,
//                     maxLines: 7,
//                     decoration:  InputDecoration(
//                       labelText: 'lead_field_notes'.tr(),
//                       alignLabelWithHint: true,
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   Wrap(
//                     spacing: 10,
//                     runSpacing: 10,
//                     children: [
//                       FilterChip(
//                         selected: _isImportant,
//                         label:  Text('lead_field_important'.tr()),
//                         avatar: const Icon(Icons.star_rounded, size: 18),
//                         onSelected: (value) {
//                           setState(() {
//                             _isImportant = value;
//                           });
//                         },
//                       ),
//                       FilterChip(
//                         selected: _requiresFollowUp,
//                         label:  Text('lead_field_follow_up'.tr()),
//                         avatar: const Icon(Icons.reply_all_rounded, size: 18),
//                         onSelected: (value) {
//                           setState(() {
//                             _requiresFollowUp = value;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 18),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: _isSubmitting
//                               ? null
//                               : () => Navigator.of(context).pop(),
//                           child:  Text('btn_cancel'.tr()),
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
//                             _isSubmitting ? 'btn_saving'.tr() : widget.submitLabel,
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
// class _LeadFormResult {
//   final String name;
//   final String phone;
//   final String email;
//   final String leadType;
//   final String companyName;
//   final String companyTrn;
//   final String status;
//   final String notes;
//   final bool isImportant;
//   final bool requiresFollowUp;
//
//   const _LeadFormResult({
//     required this.name,
//     required this.phone,
//     required this.email,
//     required this.leadType,
//     required this.companyName,
//     required this.companyTrn,
//     required this.status,
//     required this.notes,
//     required this.isImportant,
//     required this.requiresFollowUp,
//   });
//
//   Map<String, dynamic> toInsertPayload({
//     required String currentUserId,
//   }) {
//     return {
//       'name': name.isEmpty ? null : name,
//       'phone': phone,
//       'email': email.isEmpty ? null : email,
//       'lead_type': leadType,
//       'company_name': companyName.isEmpty ? null : companyName,
//       'company_trn': companyTrn.isEmpty ? null : companyTrn,
//       'status': status,
//       'notes': notes.isEmpty ? null : notes,
//       'is_important': isImportant,
//       'requires_follow_up': requiresFollowUp,
//       'owner_id': currentUserId.isEmpty ? null : currentUserId,
//       'created_by': currentUserId.isEmpty ? null : currentUserId,
//       'assigned_by': null,
//     };
//   }
//
//   Map<String, dynamic> toUpdatePayload() {
//     return {
//       'name': name.isEmpty ? null : name,
//       'phone': phone,
//       'email': email.isEmpty ? null : email,
//       'lead_type': leadType,
//       'company_name': companyName.isEmpty ? null : companyName,
//       'company_trn': companyTrn.isEmpty ? null : companyTrn,
//       'status': status,
//       'notes': notes.isEmpty ? null : notes,
//       'is_important': isImportant,
//       'requires_follow_up': requiresFollowUp,
//       'updated_at': DateTime.now().toIso8601String(),
//     };
//   }
// }

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../login_screen.dart';
import '../../services/push_sender_service.dart';
import 'customer_profile_screen.dart';

Future<void> _openWhatsApp(String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-().]+'), '');
  final digits = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
  if (digits.isEmpty) return;

  final uri = Uri.parse('https://wa.me/$digits');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

enum LeadScope {
  myLeads,
  unassigned,
  allLeads,
}

enum _LeadSort {
  newestFirst,
  oldestFirst,
  nameAZ,
  nameZA,
  importantFirst,
}

class LeadsScreen extends ConsumerStatefulWidget {
  final bool initialImportantOnly;
  final String? initialStatus;
  final bool showOwnHeader;
  final String? customTitle;
  final bool allowCreate;

  const LeadsScreen({
    super.key,
    this.initialImportantOnly = false,
    this.initialStatus,
    this.showOwnHeader = true,
    this.customTitle,
    this.allowCreate = true,
  });

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final PushSenderService _pushSenderService =
  PushSenderService(_supabase);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  RealtimeChannel? _realtimeChannel;
  Timer? _debounce;
  Timer? _realtimeRefreshDebounce;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allLeads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filteredLeads = <Map<String, dynamic>>[];
  Map<String, Map<String, dynamic>> _profileMap =
  <String, Map<String, dynamic>>{};
  List<Map<String, dynamic>> _assignableUsers = <Map<String, dynamic>>[];

  String _searchQuery = '';
  String? _selectedStatus;
  bool _importantOnly = false;
  LeadScope _scope = LeadScope.myLeads;
  _LeadSort _sortBy = _LeadSort.newestFirst;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int _pageSize = 200;
  int _currentOffset = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _searchResults = [];

  static const List<String> _statuses = <String>[
    'new',
    'contacted',
    'qualified',
    'closed_won',
    'closed_lost',
  ];

  UserProfile get _profile =>
      ref.read(profileProvider).value ??
      const UserProfile(id: '', email: '', name: '', role: '', isActive: false);

  String get _role => _profile.role.trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isViewer => _role == 'viewer';
  bool get _isAccountant => _role == 'accountant';

  bool get _isReadOnly => _isViewer || _isAccountant;
  bool get _canCreateLead => (_isAdmin || _isSales) && !_isReadOnly;
  bool get _canEditLead => (_isAdmin || _isSales) && !_isReadOnly;
  bool get _canDeleteLead => _isAdmin && !_isReadOnly;
  // can_assign_leads is not in UserProfile entity — default to admin-only
  bool get _canAssignLeads => _isAdmin;

  String get _currentUserId => _profile.id;

  @override
  void initState() {
    super.initState();
    _importantOnly = widget.initialImportantOnly;
    _selectedStatus = widget.initialStatus;
    _scope = _defaultScope();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
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
    _scrollController.dispose();
    super.dispose();
  }

  LeadScope _defaultScope() {
    if (_isAdmin || _isViewer || _isAccountant) {
      return LeadScope.allLeads;
    }
    return LeadScope.myLeads;
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'new':
        return 'status_new'.tr();
      case 'contacted':
        return 'status_contacted'.tr();
      case 'qualified':
        return 'status_qualified'.tr();
      case 'closed_won':
        return 'status_won'.tr();
      case 'closed_lost':
        return 'status_lost'.tr();
      default:
        return value;
    }
  }

  void _setupRealtime() {
    final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;

    _realtimeChannel = _supabase
        .channel('crm-leads-merged-$channelKey')
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
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'activity_logs',
      callback: (_) => _scheduleRealtimeRefresh(),
    )
        .subscribe();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadData(silent: true);
    });
  }

  void _onScroll() {
    // kept for dispose — logic moved to NotificationListener
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Auto-load on scroll only on desktop — mobile uses pull-to-refresh
    if (!_isDesktop) return false;
    if (_searchQuery.isNotEmpty) return false;
    if (_isLoadingMore || !_hasMore) return false;
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent) {
        _loadMore();
      }
    }
    return false;
  }

  bool get _isDesktop {
    final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return width >= 1000;
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = _searchController.text.trim().toLowerCase();
      setState(() => _searchQuery = query);
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _applyFilters();
        });
      } else {
        _searchServerSide(query);
      }
    });
  }

  // ── Shared query builder ─────────────────────────────────────────────────
  dynamic _baseLeadsQuery() {
    var q = _supabase.from('leads').select();
    if (_isSales && _currentUserId.isNotEmpty) {
      q = q.or('owner_id.eq.$_currentUserId,created_by.eq.$_currentUserId');
    }
    return q;
  }

  // ── Fetch missing profiles and merge into _profileMap ────────────────────
  Future<void> _fetchMissingProfiles(List<Map<String, dynamic>> rows) async {
    final needed = <String>{
      ...rows.map((e) => _text(e['owner_id'])),
      ...rows.map((e) => _text(e['created_by'])),
      ...rows.map((e) => _text(e['assigned_by'])),
    }
      ..removeWhere((e) => e.isEmpty || _profileMap.containsKey(e));

    if (needed.isEmpty) return;

    final resp = await _supabase
        .from('profiles')
        .select('id, full_name, email, role, is_active')
        .inFilter('id', needed.toList());

    for (final row in resp as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = _text(map['id']);
      if (id.isNotEmpty) _profileMap[id] = map;
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // First page only — more loaded via _loadMore()
      _currentOffset = 0;

      final leadsResponse = await (_baseLeadsQuery() as dynamic)
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final rows = (leadsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _profileMap = {};
      await _fetchMissingProfiles(rows);

      final assignableResponse = await _supabase
          .from('profiles')
          .select('id, full_name, email, role, is_active')
          .inFilter('role', ['sales', 'admin'])
          .eq('is_active', true)
          .order('full_name', ascending: true);

      final assignableUsers = (assignableResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _allLeads        = rows;
        _hasMore         = rows.length == _pageSize;
        _searchResults   = [];
        _assignableUsers = assignableUsers;
        _applyFilters();
        _isLoading = false;
        _error     = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Load next page ────────────────────────────────────────────────────────
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextOffset = _currentOffset + _pageSize;
      final response = await (_baseLeadsQuery() as dynamic)
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false)
          .range(nextOffset, nextOffset + _pageSize - 1);

      final newRows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await _fetchMissingProfiles(newRows);

      if (!mounted) return;
      setState(() {
        _currentOffset = nextOffset;
        _allLeads      = [..._allLeads, ...newRows];
        _hasMore       = newRows.length == _pageSize;
        _isLoadingMore = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  // ── Server-side search (runs on all leads, no pagination limit) ───────────
  Future<void> _searchServerSide(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _applyFilters();
      });
      return;
    }

    try {
      final q = query.toLowerCase();
      final response = await (_baseLeadsQuery() as dynamic)
          .or('name.ilike.%$q%,phone.ilike.%$q%,email.ilike.%$q%,company_name.ilike.%$q%,phone2.ilike.%$q%')
          .order('updated_at', ascending: false);

      final results = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await _fetchMissingProfiles(results);

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _applyFilters();
      });
    } catch (_) {}
  }

  void _applyFilters() {
    final search = _searchQuery;
    // When searching, use server-returned results (covers all DB rows).
    // When not searching, use the paginated _allLeads.
    final base = search.isNotEmpty ? _searchResults : _allLeads;

    _filteredLeads = base.where((lead) {
      if (!_matchesScope(lead)) {
        return false;
      }

      final name = _text(lead['name']).toLowerCase();
      final phone = _text(lead['phone']).toLowerCase();
      final email = _text(lead['email']).toLowerCase();
      final companyName = _text(lead['company_name']).toLowerCase();
      final status = _text(lead['status']).toLowerCase();
      final ownerLabel = _profileLabel(_text(lead['owner_id'])).toLowerCase();
      final assignedByLabel =
      _profileLabel(_text(lead['assigned_by'])).toLowerCase();
      final isImportant = lead['is_important'] == true;

      final matchesSearch = search.isEmpty ||
          name.contains(search) ||
          phone.contains(search) ||
          email.contains(search) ||
          companyName.contains(search) ||
          ownerLabel.contains(search) ||
          assignedByLabel.contains(search);

      final matchesStatus =
          _selectedStatus == null || status == _selectedStatus;
      final matchesImportant = !_importantOnly || isImportant;

      return matchesSearch && matchesStatus && matchesImportant;
    }).toList();

    switch (_sortBy) {
      case _LeadSort.newestFirst:
        _filteredLeads.sort((a, b) {
          final aDate = a['updated_at'] ?? a['created_at'];
          final bDate = b['updated_at'] ?? b['created_at'];
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.toString().compareTo(aDate.toString());
        });
      case _LeadSort.oldestFirst:
        _filteredLeads.sort((a, b) {
          final aDate = a['updated_at'] ?? a['created_at'];
          final bDate = b['updated_at'] ?? b['created_at'];
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.toString().compareTo(bDate.toString());
        });
      case _LeadSort.nameAZ:
        _filteredLeads.sort((a, b) =>
            _text(a['name']).toLowerCase().compareTo(_text(b['name']).toLowerCase()));
      case _LeadSort.nameZA:
        _filteredLeads.sort((a, b) =>
            _text(b['name']).toLowerCase().compareTo(_text(a['name']).toLowerCase()));
      case _LeadSort.importantFirst:
        _filteredLeads.sort((a, b) {
          final aImp = a['is_important'] == true ? 0 : 1;
          final bImp = b['is_important'] == true ? 0 : 1;
          if (aImp != bImp) return aImp.compareTo(bImp);
          final aDate = a['updated_at'] ?? a['created_at'];
          final bDate = b['updated_at'] ?? b['created_at'];
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.toString().compareTo(aDate.toString());
        });
    }
  }

  bool _matchesScope(Map<String, dynamic> lead) {
    final ownerId = _text(lead['owner_id']);

    if (_isSales) {
      return ownerId == _currentUserId;
    }

    switch (_scope) {
      case LeadScope.myLeads:
        return ownerId == _currentUserId;
      case LeadScope.unassigned:
        return ownerId.isEmpty;
      case LeadScope.allLeads:
        return true;
    }
  }

  Future<void> _openCreateLeadDialog() async {
    final result = await showDialog<_LeadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadFormDialog(
        title: tr('lead_form_create'),
        submitLabel: tr('btn_create'),
        currentUserId: _currentUserId,
        availableUsers: _isAdmin ? _assignableUsers : const [],
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

      final leadId = _text(inserted['id']);

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
        SnackBar(content: Text(tr('leads_created'))),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'leads_create_failed',
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openEditLeadDialog(Map<String, dynamic> lead) async {
    final result = await showDialog<_LeadFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeadFormDialog(
        title: tr('lead_form_edit'),
        submitLabel: tr('btn_save'),
        initialLead: lead,
        currentUserId: _currentUserId,
        availableUsers: _isAdmin ? _assignableUsers : const [],
      ),
    );

    if (result == null) return;

    final leadId = _text(lead['id']);
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
        SnackBar(content: Text(tr('leads_updated'))),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'leads_update_failed',
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

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
              'source': 'leads_merged',
              'actor_name': _profile.name.isNotEmpty ? _profile.name : _profile.email,
              'old_owner_name': _userDisplayById(oldOwnerId),
              'new_owner_name': _userDisplayById(newOwnerId),
            },
          });

          await _sendAssignmentPush(
            leadId: leadId,
            leadLabel: _leadTitle(lead),
            newOwnerId: newOwnerId ?? '',
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

  Future<void> _deleteLead(Map<String, dynamic> lead) async {
    final leadId = _text(lead['id']);
    if (leadId.isEmpty) return;

    final name = _text(lead['name']);
    final company = _text(lead['company_name']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('lead_delete_confirm_title'.tr()),
        content: Text('lead_delete_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('btn_cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('btn_delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _supabase.from('leads').delete().eq('id', leadId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lead_deleted'.tr())),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lead_delete_failed'.tr(namedArgs: {'error': e.toString()})),
        ),
      );
    }
  }

  Future<void> _sendAssignmentPush({
    required String leadId,
    required String leadLabel,
    required String newOwnerId,
    required String oldOwnerId,
  }) async {
    if (newOwnerId.isEmpty) return;
    if (newOwnerId == oldOwnerId) return;

    final actorName = _profile.name.isNotEmpty ? _profile.name : _profile.email;
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

  void _openCustomerProfile(Map<String, dynamic> lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProfileScreen(
          lead: lead,
          profile: _profile.toMap(),
        ),
      ),
    );
  }

  Future<void> _showLeadDetails(Map<String, dynamic> lead) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return LeadDetailsSheet(
          lead: lead,
          profileMap: _profileMap,
          canEdit: _canEditLead,
          canAssign: _canAssignLeads,
          onViewProfile: () {
            Navigator.of(context).pop();
            _openCustomerProfile(lead);
          },
          onEdit: _canEditLead
              ? () async {
            Navigator.of(context).pop();
            await _openEditLeadDialog(lead);
          }
              : null,
          onAssign: _canAssignLeads
              ? () async {
            Navigator.of(context).pop();
            await _openAssignDialog(lead);
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
      _scope = _defaultScope();
      _applyFilters();
    });
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  // DateTime? _parseDateTime(dynamic value) {
  //   if (value == null) return null;
  //   return DateTime.tryParse(value.toString())?.toLocal();
  // }

  String _displayName() {
    return _profile.name.isNotEmpty ? _profile.name : _profile.email;
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  String _profileLabel(String? userId) {
    final id = _text(userId);
    if (id.isEmpty) return 'Unassigned';

    final profile = _profileMap[id];
    if (profile == null) return 'Unknown user';

    final fullName = _text(profile['full_name']);
    final email = _text(profile['email']);

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return 'Unknown user';
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

  String _leadTitle(Map<String, dynamic> lead) {
    final name = _text(lead['name']);
    final companyName = _text(lead['company_name']);
    final phone = _text(lead['phone']);

    if (name.isNotEmpty) return name;
    if (companyName.isNotEmpty) return companyName;
    if (phone.isNotEmpty) return phone;
    return 'Unnamed Lead';
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
    final bool isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: (!isDesktop && _canCreateLead && widget.allowCreate)
          ? FloatingActionButton.extended(
        onPressed: _openCreateLeadDialog,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text('btn_new_lead'.tr()),
      )
          : null,
      body: SafeArea(
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _LeadsHeader(
                title: widget.customTitle ?? 'leads_title'.tr(),
                showOwnHeader: widget.showOwnHeader,
                searchController: _searchController,
                selectedStatus: _selectedStatus,
                statuses: _statuses,
                statusLabelBuilder: _statusLabel,
                importantOnly: _importantOnly,
                visibleCount: _filteredLeads.length,
                totalCount: _allLeads.length,
                profileName: _displayName(),
                role: _role,
                isReadOnly: _isReadOnly,
                canCreate: _canCreateLead && widget.allowCreate,
                canAssign: _canAssignLeads,
                showDesktopCreateAction:
                isDesktop && _canCreateLead && widget.allowCreate,
                scope: _scope,
                allowScopeSelection: !_isSales,
                onScopeChanged: (value) {
                  setState(() {
                    _scope = value;
                    _applyFilters();
                  });
                },
                onCreate: _openCreateLeadDialog,
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
                onLogout: _logout,
                sortBy: _sortBy,
                onSortChanged: (value) {
                  setState(() {
                    _sortBy = value;
                    _applyFilters();
                  });
                },
              ),
            ),
          ],
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildBody(isDesktop),
          ),
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
        title: 'leads_error'.tr(),
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('btn_retry'.tr()),
          ),
        ],
      );
    }

    if (_filteredLeads.isEmpty) {
      return _StateCard(
        icon: Icons.people_outline_rounded,
        iconColor: AppConstants.primaryColor,
        title: _allLeads.isEmpty
            ? 'leads_empty_title'.tr()
            : 'leads_empty_filtered'.tr(),
        message: _allLeads.isEmpty
            ? (_canCreateLead
            ? 'leads_empty_subtitle'.tr()
            : 'leads_empty_no_access'.tr())
            : 'leads_empty_filter_hint'.tr(),
        actions: [
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('btn_refresh'.tr()),
          ),
          if (_canCreateLead && _allLeads.isEmpty && widget.allowCreate)
            FilledButton.icon(
              onPressed: _openCreateLeadDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('btn_create_lead')),
            ),
        ],
      );
    }

    if (isDesktop) {
      final showFooter = _searchQuery.isEmpty && (_hasMore || _isLoadingMore);
      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          itemCount: _filteredLeads.length + 1 + (showFooter ? 1 : 0), // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Column(
                children: [_DesktopLeadListHeader(), SizedBox(height: 8)],
              );
            }
            final itemIndex = index - 1;
            if (itemIndex == _filteredLeads.length) {
              // Footer spinner
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                ),
              );
            }
            final lead = _filteredLeads[itemIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DesktopLeadRow(
                lead: lead,
                ownerLabel: _profileLabel(lead['owner_id']),
                canEdit: _canEditLead,
                canAssign: _canAssignLeads,
                canDelete: _canDeleteLead,
                missingFields: _missingFields(lead),
                statusColor: _statusColor(_text(lead['status']).toLowerCase()),
                onTap: () => _showLeadDetails(lead),
                onViewProfile: () => _openCustomerProfile(lead),
                onEdit: _canEditLead ? () => _openEditLeadDialog(lead) : null,
                onAssign: _canAssignLeads ? () => _openAssignDialog(lead) : null,
                onDelete: _canDeleteLead ? () => _deleteLead(lead) : null,
              ),
            );
          },
        ),
      );
    }

    // Show loading indicator at bottom when fetching next page
    final showFooter = _searchQuery.isEmpty && (_hasMore || _isLoadingMore);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: isDesktop ? const ClampingScrollPhysics() : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        itemCount: _filteredLeads.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          // Footer spinner while loading next page
          if (index == _filteredLeads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final lead = _filteredLeads[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MobileLeadCard(
              lead: lead,
              ownerLabel: _profileLabel(lead['owner_id']),
              canEdit: _canEditLead,
              canAssign: _canAssignLeads,
              canDelete: _canDeleteLead,
              missingFields: _missingFields(lead),
              statusColor: _statusColor(_text(lead['status']).toLowerCase()),
              onTap: () => _showLeadDetails(lead),
              onViewProfile: () => _openCustomerProfile(lead),
              onEdit: _canEditLead ? () => _openEditLeadDialog(lead) : null,
              onAssign: _canAssignLeads ? () => _openAssignDialog(lead) : null,
              onDelete: _canDeleteLead ? () => _deleteLead(lead) : null,
            ),
          );
        },
      ),
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
  final String Function(String) statusLabelBuilder;
  final bool importantOnly;
  final int visibleCount;
  final int totalCount;
  final String profileName;
  final String role;
  final bool isReadOnly;
  final bool canCreate;
  final bool canAssign;
  final bool showDesktopCreateAction;
  final LeadScope scope;
  final bool allowScopeSelection;
  final ValueChanged<LeadScope> onScopeChanged;
  final VoidCallback onCreate;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<bool> onImportantOnlyChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onLogout;
  final _LeadSort sortBy;
  final ValueChanged<_LeadSort> onSortChanged;

  const _LeadsHeader({
    required this.title,
    required this.showOwnHeader,
    required this.searchController,
    required this.selectedStatus,
    required this.statuses,
    required this.statusLabelBuilder,
    required this.importantOnly,
    required this.visibleCount,
    required this.totalCount,
    required this.profileName,
    required this.role,
    required this.isReadOnly,
    required this.canCreate,
    required this.canAssign,
    required this.showDesktopCreateAction,
    required this.scope,
    required this.allowScopeSelection,
    required this.onScopeChanged,
    required this.onCreate,
    required this.onStatusChanged,
    required this.onImportantOnlyChanged,
    required this.onClearFilters,
    required this.onLogout,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 860;
    final bool hasFilters = searchController.text.trim().isNotEmpty ||
        selectedStatus != null ||
        importantOnly ||
        (allowScopeSelection && scope != LeadScope.allLeads);

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
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text('btn_new_lead'.tr()),
                    ),
                  ),
                if (!isWide)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await onLogout();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('btn_logout'.tr()),
                      ),
                    ],
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
              ],
            ),
          if (showOwnHeader) const SizedBox(height: 12),

          if (allowScopeSelection) ...[
            _ScopeChips(
              value: scope,
              canAssign: canAssign,
              onChanged: onScopeChanged,
            ),
            const SizedBox(height: 10),
          ],

          if (isWide)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'leads_search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'leads_filter_stage'.tr(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('leads_filter_all'.tr()),
                      ),
                      ...statuses.map(
                            (status) => DropdownMenuItem<String?>(
                          value: status,
                          child: Text(statusLabelBuilder(status)),
                        ),
                      ),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
                const SizedBox(width: 12),
                _ImportantToggleButton(
                  value: importantOnly,
                  onChanged: onImportantOnlyChanged,
                ),
                const SizedBox(width: 8),
                _SortMenuButton(sortBy: sortBy, onSortChanged: onSortChanged),
                if (hasFilters) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.clear_all_rounded),
                    label: Text('btn_clear'.tr()),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'leads_search_hint'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'leads_filter_stage'.tr(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('leads_filter_all'.tr()),
                          ),
                          ...statuses.map(
                                (status) => DropdownMenuItem<String?>(
                              value: status,
                              child: Text(statusLabelBuilder(status)),
                            ),
                          ),
                        ],
                        onChanged: onStatusChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row(
                //   children: [
                //     Expanded(
                //       child: Align(
                //         alignment: AlignmentDirectional.centerStart,
                //         child: _ImportantToggleButton(
                //           value: importantOnly,
                //           onChanged: onImportantOnlyChanged,
                //         ),
                //       ),
                //     ),
                //     if (hasFilters)
                //       OutlinedButton.icon(
                //         onPressed: onClearFilters,
                //         icon: const Icon(Icons.clear_all_rounded),
                //         label: Text('btn_clear'.tr()),
                //       ),
                //   ],
                // ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ImportantToggleButton(
                      value: importantOnly,
                      onChanged: onImportantOnlyChanged,
                    ),
                    _SortMenuButton(sortBy: sortBy, onSortChanged: onSortChanged),
                    if (hasFilters)
                      OutlinedButton.icon(
                        onPressed: onClearFilters,
                        icon: const Icon(Icons.clear_all_rounded),
                        label: Text('btn_clear'.tr()),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'leads_shown'.tr(
                      namedArgs: {
                        'shown': visibleCount.toString(),
                        'total': totalCount.toString(),
                      },
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),

          if (isWide) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'leads_shown'.tr(
                      namedArgs: {
                        'shown': visibleCount.toString(),
                        'total': totalCount.toString(),
                      },
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'leads_read_only'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScopeChips extends StatelessWidget {
  final LeadScope value;
  final bool canAssign;
  final ValueChanged<LeadScope> onChanged;

  const _ScopeChips({
    required this.value,
    required this.canAssign,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({LeadScope scope, String label, IconData icon})>[
      (scope: LeadScope.allLeads, label: tr('leads_scope_all'), icon: Icons.people_alt),
      (
      scope: LeadScope.unassigned,
      label: tr('leads_scope_unassigned'),
      icon: Icons.person_off_outlined
      ),
      (scope: LeadScope.myLeads, label: tr('leads_scope_mine'), icon: Icons.person_outline),
    ];

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final selected = value == item.scope;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 16),
                const SizedBox(width: 6),
                Text(item.label),
              ],
            ),
            onSelected: (_) => onChanged(item.scope),
          );
        }).toList(),
      ),
    );
  }
}

class _ImportantToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ImportantToggleButton({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppConstants.primaryColor;
    final Color borderColor =
    value ? activeColor : Colors.white.withOpacity(0.12);
    final Color backgroundColor =
    value ? activeColor.withOpacity(0.14) : Colors.white.withOpacity(0.04);
    final Color textColor = value ? activeColor : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.star_rounded : Icons.star_border_rounded,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'leads_important_only'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final _LeadSort sortBy;
  final ValueChanged<_LeadSort> onSortChanged;

  const _SortMenuButton({
    required this.sortBy,
    required this.onSortChanged,
  });

  String _label(_LeadSort sort) {
    switch (sort) {
      case _LeadSort.newestFirst:
        return 'sort_newest'.tr();
      case _LeadSort.oldestFirst:
        return 'sort_oldest'.tr();
      case _LeadSort.nameAZ:
        return 'sort_name_az'.tr();
      case _LeadSort.nameZA:
        return 'sort_name_za'.tr();
      case _LeadSort.importantFirst:
        return 'sort_important'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefault = sortBy == _LeadSort.newestFirst;
    final Color activeColor = AppConstants.primaryColor;
    final Color borderColor =
        isDefault ? Colors.white.withOpacity(0.12) : activeColor;
    final Color backgroundColor = isDefault
        ? Colors.white.withOpacity(0.04)
        : activeColor.withOpacity(0.14);
    final Color textColor = isDefault ? Colors.white70 : activeColor;

    return PopupMenuButton<_LeadSort>(
      onSelected: onSortChanged,
      itemBuilder: (_) => _LeadSort.values.map((sort) {
        return PopupMenuItem<_LeadSort>(
          value: sort,
          child: Row(
            children: [
              if (sort == sortBy)
                Icon(Icons.check_rounded, size: 16, color: activeColor)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(_label(sort)),
            ],
          ),
        );
      }).toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              _label(sortBy),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _DesktopLeadListHeader extends StatelessWidget {
  const _DesktopLeadListHeader();

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
            flex: 22,
            child: Text(
              'leads_col_lead'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              'leads_col_contact'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'leads_col_type'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              'Owner',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              'leads_col_status'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              'leads_col_notes'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 184),
        ],
      ),
    );
  }
}

class _DesktopLeadRow extends StatelessWidget {
  final Map<String, dynamic> lead;
  final String ownerLabel;
  final bool canEdit;
  final bool canAssign;
  final bool canDelete;
  final List<String> missingFields;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onViewProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  const _DesktopLeadRow({
    required this.lead,
    required this.ownerLabel,
    required this.canEdit,
    required this.canAssign,
    required this.canDelete,
    required this.missingFields,
    required this.statusColor,
    required this.onTap,
    required this.onViewProfile,
    required this.onEdit,
    required this.onAssign,
    required this.onDelete,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name = _text(lead['name']);
    final phone = _text(lead['phone']);
    final email = _text(lead['email']);
    final leadType = _text(lead['lead_type']);
    final companyName = _text(lead['company_name']);
    final status = _text(lead['status']);
    final isImportant = lead['is_important'] == true;
    final notes = _text(lead['notes']);

    final title = name.isNotEmpty
        ? name
        : (companyName.isNotEmpty ? companyName : 'leads_unnamed'.tr());

    final subtitle = companyName.isNotEmpty && companyName != title
        ? companyName
        : '';

    final contact = phone.isNotEmpty
        ? phone
        : (email.isNotEmpty ? email : 'leads_no_contactt'.tr());

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
            border: Border.all(
              color: isImportant
                  ? AppConstants.primaryColor
                  : const Color(0xFF30260A),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    if (missingFields.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'leads_missing'.tr(
                            namedArgs: {'fields': missingFields.join(', ')},
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 16,
                child: GestureDetector(
                  onTap: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
                  child: Text(
                    contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: phone.isNotEmpty
                        ? const TextStyle(
                      color: Color(0xFF4FC3F7),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF4FC3F7),
                    )
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  leadType.isEmpty ? '—' : leadType.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 16,
                child: Text(
                  ownerLabel,
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
                    _MiniBadge(
                      label: status.replaceAll('_', ' ').toUpperCase(),
                      background: statusColor.withOpacity(0.18),
                      foreground: statusColor,
                    ),
                    if (isImportant)
                      _MiniBadge(
                        label: 'leads_important'.tr(),
                        background: const Color(0xFF4A3B12),
                        foreground: AppConstants.primaryColor,
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 14,
                child: Text(
                  notes.isEmpty ? '—' : notes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: notes.isEmpty ? Colors.white38 : Colors.white70,
                  ),
                ),
              ),
              // SizedBox(
              //   width: 184,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       IconButton(
              //         icon: const Icon(Icons.person_search_outlined),
              //         tooltip: 'leads_view_profile'.tr(),
              //         color: AppConstants.primaryColor,
              //         onPressed: onViewProfile,
              //       ),
              //       if (canAssign)
              //         Padding(
              //           padding: const EdgeInsets.only(right: 8),
              //           child: OutlinedButton(
              //             onPressed: onAssign,
              //             child: const Text('Assign'),
              //           ),
              //         ),
              //       if (canEdit)
              //         FilledButton(
              //           onPressed: onEdit,
              //           child: Text('btn_edit'.tr()),
              //         ),
              //     ],
              //   ),
              // ),
              SizedBox(
                width: 184,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_search_outlined),
                        tooltip: 'leads_view_profile'.tr(),
                        color: AppConstants.primaryColor,
                        onPressed: onViewProfile,
                      ),
                      if (canAssign)
                        OutlinedButton(
                          onPressed: onAssign,
                          child: const Text('Assign'),
                        ),
                      if (canEdit)
                        FilledButton(
                          onPressed: onEdit,
                          child: Text('btn_edit'.tr()),
                        ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'btn_delete'.tr(),
                          color: Colors.redAccent,
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final String ownerLabel;
  final bool canEdit;
  final bool canAssign;
  final bool canDelete;
  final List<String> missingFields;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onViewProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;

  const _MobileLeadCard({
    required this.lead,
    required this.ownerLabel,
    required this.canEdit,
    required this.canAssign,
    required this.canDelete,
    required this.missingFields,
    required this.statusColor,
    required this.onTap,
    required this.onViewProfile,
    required this.onEdit,
    required this.onAssign,
    required this.onDelete,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name = _text(lead['name']);
    final phone = _text(lead['phone']);
    final email = _text(lead['email']);
    final leadType = _text(lead['lead_type']);
    final companyName = _text(lead['company_name']);
    final status = _text(lead['status']);
    final isImportant = lead['is_important'] == true;
    final notes = _text(lead['notes']);

    final title = name.isNotEmpty
        ? name
        : (companyName.isNotEmpty ? companyName : 'followup_unnamed_lead'.tr());

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
            border: Border.all(
              color: isImportant
                  ? AppConstants.primaryColor
                  : const Color(0xFF30260A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (companyName.isNotEmpty && companyName != title) ...[
                const SizedBox(height: 2),
                Text(
                  companyName,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 8),
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
                    _MiniBadge(
                      label: 'stats_important'.tr(),
                      background: const Color(0xFF4A3B12),
                      foreground: AppConstants.primaryColor,
                      icon: Icons.star_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: phone.isNotEmpty ? () => _openWhatsApp(phone) : null,
                child: _InfoText(
                  icon: Icons.phone_outlined,
                  text: phone.isEmpty ? 'leads_no_phone'.tr() : phone,
                  tappable: phone.isNotEmpty,
                ),
              ),
              const SizedBox(height: 6),
              _InfoText(
                icon: Icons.email_outlined,
                text: email.isEmpty ? 'leads_no_email'.tr() : email,
              ),
              const SizedBox(height: 6),
              _InfoText(
                icon: Icons.business_outlined,
                text: leadType.isEmpty
                    ? 'leads_unknown_type'.tr()
                    : leadType.toUpperCase(),
              ),
              const SizedBox(height: 6),
              _InfoText(
                icon: Icons.person_outline_rounded,
                text: ownerLabel,
              ),
              if (missingFields.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'leads_missing'.tr(
                    namedArgs: {'fields': missingFields.join(', ')},
                  ),
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 12),
              // Row(
              //   children: [
              //     OutlinedButton.icon(
              //       onPressed: onViewProfile,
              //       icon: const Icon(Icons.person_search_outlined, size: 16),
              //       label: Text('btn_profile'.tr()),
              //       style: OutlinedButton.styleFrom(
              //         foregroundColor: AppConstants.primaryColor,
              //         side: const BorderSide(color: AppConstants.primaryColor),
              //       ),
              //     ),
              //     const Spacer(),
              //     if (canAssign)
              //       Padding(
              //         padding: const EdgeInsets.only(right: 8),
              //         child: OutlinedButton(
              //           onPressed: onAssign,
              //           child: const Text('Assign'),
              //         ),
              //       ),
              //     if (canEdit)
              //       FilledButton(
              //         onPressed: onEdit,
              //         child: Text('btn_edit'.tr()),
              //       ),
              //   ],
              // ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person_search_outlined, size: 16),
                    label: Text('btn_profile'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                  ),
                  if (canAssign)
                    OutlinedButton(
                      onPressed: onAssign,
                      child: const Text('Assign'),
                    ),
                  if (canEdit)
                    FilledButton(
                      onPressed: onEdit,
                      child: Text('btn_edit'.tr()),
                    ),
                  if (canDelete)
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text('btn_delete'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
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
  final bool tappable;

  const _InfoText({
    required this.icon,
    required this.text,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tappable
                ? const TextStyle(
              color: Color(0xFF4FC3F7),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF4FC3F7),
            )
                : null,
          ),
        ),
      ],
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

class LeadDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> lead;
  final Map<String, Map<String, dynamic>> profileMap;
  final bool canEdit;
  final bool canAssign;
  final VoidCallback? onViewProfile;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;

  const LeadDetailsSheet({
    super.key,
    required this.lead,
    required this.profileMap,
    required this.canEdit,
    required this.canAssign,
    this.onViewProfile,
    this.onEdit,
    this.onAssign,
  });

  String _text(dynamic value) => (value ?? '').toString().trim();

  String _profileLabel(String? userId) {
    final id = _text(userId);
    if (id.isEmpty) return 'leads_unassigned'.tr();

    final profile = profileMap[id];
    if (profile == null) return 'leads_unknown_user'.tr();

    final fullName = _text(profile['full_name']);
    final email = _text(profile['email']);
    final role = _text(profile['role']).toUpperCase();

    if (fullName.isNotEmpty) return '$fullName • $role';
    if (email.isNotEmpty) return '$email • $role';
    return 'leads_unknown_user'.tr();
  }

  Widget _row({
    required String label,
    required String value,
    VoidCallback? onTap,
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
          GestureDetector(
            onTap: onTap,
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onTap != null ? const Color(0xFF4FC3F7) : null,
                decoration: onTap != null ? TextDecoration.underline : null,
                decorationColor:
                onTap != null ? const Color(0xFF4FC3F7) : null,
              ),
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
        : 'leads_details_title'.tr());

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
              // Row(
              //   children: [
              //     Expanded(
              //       child: Text(
              //         title,
              //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
              //           fontWeight: FontWeight.w900,
              //         ),
              //       ),
              //     ),
              //     if (onViewProfile != null)
              //       Padding(
              //         padding: const EdgeInsets.only(right: 8),
              //         child: OutlinedButton.icon(
              //           onPressed: onViewProfile,
              //           icon: const Icon(Icons.person_search_outlined, size: 16),
              //           label: Text('btn_profile'.tr()),
              //           style: OutlinedButton.styleFrom(
              //             foregroundColor: AppConstants.primaryColor,
              //             side: const BorderSide(color: AppConstants.primaryColor),
              //           ),
              //         ),
              //       ),
              //     if (canAssign && onAssign != null)
              //       Padding(
              //         padding: const EdgeInsets.only(right: 8),
              //         child: OutlinedButton.icon(
              //           onPressed: onAssign,
              //           icon: const Icon(Icons.swap_horiz_rounded),
              //           label: const Text('Assign'),
              //         ),
              //       ),
              //     if (canEdit && onEdit != null)
              //       FilledButton.icon(
              //         onPressed: onEdit,
              //         icon: const Icon(Icons.edit_outlined),
              //         label: Text('btn_edit'.tr()),
              //       ),
              //   ],
              // ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (onViewProfile != null)
                              OutlinedButton.icon(
                                onPressed: onViewProfile,
                                icon: const Icon(Icons.person_search_outlined, size: 16),
                                label: Text('btn_profile'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConstants.primaryColor,
                                  side: const BorderSide(color: AppConstants.primaryColor),
                                ),
                              ),
                            if (canAssign && onAssign != null)
                              OutlinedButton.icon(
                                onPressed: onAssign,
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: const Text('Assign'),
                              ),
                            if (canEdit && onEdit != null)
                              FilledButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined),
                                label: Text('btn_edit'.tr()),
                              ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (onViewProfile != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton.icon(
                            onPressed: onViewProfile,
                            icon: const Icon(Icons.person_search_outlined, size: 16),
                            label: Text('btn_profile'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.primaryColor,
                              side: const BorderSide(color: AppConstants.primaryColor),
                            ),
                          ),
                        ),
                      if (canAssign && onAssign != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton.icon(
                            onPressed: onAssign,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Assign'),
                          ),
                        ),
                      if (canEdit && onEdit != null)
                        FilledButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text('btn_edit'.tr()),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (lead['is_important'] == true)
                    _MiniBadge(
                      label: 'leads_important'.tr(),
                      background: const Color(0xFF4A3B12),
                      foreground: AppConstants.primaryColor,
                      icon: Icons.star_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _row(
                label: 'lead_field_phone'.tr(),
                value: _text(lead['phone']),
                onTap: _text(lead['phone']).isNotEmpty
                    ? () => _openWhatsApp(_text(lead['phone']))
                    : null,
              ),
              _row(label: 'lead_field_email'.tr(), value: _text(lead['email'])),
              _row(
                label: 'lead_field_type'.tr(),
                value: _text(lead['lead_type']).toUpperCase(),
              ),
              _row(label: 'lead_field_company'.tr(), value: _text(lead['company_name'])),
              _row(label: 'lead_field_trn'.tr(), value: _text(lead['company_trn'])),
              _row(
                label: 'lead_field_status'.tr(),
                value: _text(lead['status']).replaceAll('_', ' ').toUpperCase(),
              ),
              _row(label: 'lead_field_notes'.tr(), value: _text(lead['notes'])),
              _row(label: 'lead_owner'.tr(), value: _profileLabel(lead['owner_id'])),
              _row(label: 'lead_created_by'.tr(), value: _profileLabel(lead['created_by'])),
              _row(label: 'lead_assigned_by'.tr(), value: _profileLabel(lead['assigned_by'])),
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
  final List<Map<String, dynamic>> availableUsers;

  const LeadFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.currentUserId,
    this.initialLead,
    this.availableUsers = const [],
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
  late String? _ownerId;

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

    _status =
    _text(lead?['status']).isNotEmpty ? _text(lead?['status']) : 'new';

    _isImportant = lead?['is_important'] == true;
    _requiresFollowUp = lead?['requires_follow_up'] == true;

    final existingOwnerId = _text(lead?['owner_id']);
    _ownerId = existingOwnerId.isNotEmpty
        ? existingOwnerId
        : (widget.currentUserId.isNotEmpty ? widget.currentUserId : null);
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
      ownerId: _ownerId,
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
                            decoration: InputDecoration(
                              labelText: 'lead_field_name'.tr(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'lead_field_phone'.tr(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'lead_validation_phone'.tr();
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
                      decoration: InputDecoration(
                        labelText: 'lead_field_name'.tr(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'lead_field_phone'.tr(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'lead_validation_phone'.tr();
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
                            decoration: InputDecoration(
                              labelText: 'lead_field_email'.tr(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _leadType,
                            decoration: InputDecoration(
                              labelText: 'lead_field_type'.tr(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'individual',
                                child: Text('lead_type_individual'.tr()),
                              ),
                              DropdownMenuItem(
                                value: 'company',
                                child: Text('lead_type_company'.tr()),
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
                      decoration: InputDecoration(
                        labelText: 'lead_field_email'.tr(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _leadType,
                      decoration: InputDecoration(
                        labelText: 'lead_field_type'.tr(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'individual',
                          child: Text('lead_type_individual'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'company',
                          child: Text('lead_type_company'.tr()),
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
                              decoration: InputDecoration(
                                labelText: 'lead_field_company'.tr(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _companyTrnController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'lead_field_trn'.tr(),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextFormField(
                        controller: _companyNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'lead_field_company'.tr(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _companyTrnController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'lead_field_trn'.tr(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'lead_field_status'.tr(),
                    ),
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.replaceAll('_', ' ').toUpperCase()),
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
                  if (widget.availableUsers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _ownerId,
                      decoration: InputDecoration(
                        labelText: tr('lead_owner'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: widget.availableUsers.map((user) {
                        final id = _text(user['id']);
                        final fullName = _text(user['full_name']);
                        final email = _text(user['email']);
                        final role = _text(user['role']).toUpperCase();
                        final label = fullName.isNotEmpty ? '$fullName • $role' : '$email • $role';
                        return DropdownMenuItem<String?>(
                          value: id,
                          child: Text(label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _ownerId = value),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText: 'lead_field_notes'.tr(),
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
                        label: Text('lead_field_important'.tr()),
                        avatar: const Icon(Icons.star_rounded, size: 18),
                        onSelected: (value) {
                          setState(() {
                            _isImportant = value;
                          });
                        },
                      ),
                      FilterChip(
                        selected: _requiresFollowUp,
                        label: Text('lead_field_follow_up'.tr()),
                        avatar: const Icon(Icons.reply_all_rounded, size: 18),
                        onSelected: (value) {
                          setState(() {
                            _requiresFollowUp = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: Text('btn_cancel'.tr()),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSubmitting ? 'btn_saving'.tr() : widget.submitLabel,
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
  final String? ownerId;

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
    this.ownerId,
  });

  Map<String, dynamic> toInsertPayload({required String currentUserId}) {
    final effectiveOwner = (ownerId != null && ownerId!.isNotEmpty)
        ? ownerId
        : (currentUserId.isEmpty ? null : currentUserId);
    final assignedBy = (ownerId != null &&
            ownerId!.isNotEmpty &&
            ownerId != currentUserId)
        ? currentUserId
        : null;
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
      'owner_id': effectiveOwner,
      'created_by': currentUserId.isEmpty ? null : currentUserId,
      'assigned_by': assignedBy,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
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
      if (ownerId != null && ownerId!.isNotEmpty) 'owner_id': ownerId,
      'updated_at': DateTime.now().toIso8601String(),
    };
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
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF30260A)),
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
                    tr('lead_assign_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _leadLabel(),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedUserId,
                    decoration: InputDecoration(
                      labelText: tr('lead_assign_to'),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(tr('leads_unassigned')),
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
                          onPressed:
                          _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: Text(tr('btn_cancel')),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.check_rounded),
                          label: Text(_isSubmitting ? tr('btn_saving') : tr('btn_confirm')),
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

class _AssignLeadResult {
  final String? newOwnerId;

  const _AssignLeadResult({
    required this.newOwnerId,
  });
}