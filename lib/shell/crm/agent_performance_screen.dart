// // // import 'package:flutter/material.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // //
// // // class AgentPerformanceScreen extends StatefulWidget {
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //   final bool showOwnHeader;
// // //   final String? customTitle;
// // //
// // //   const AgentPerformanceScreen({
// // //     super.key,
// // //     required this.profile,
// // //     required this.onLogout,
// // //     this.showOwnHeader = true,
// // //     this.customTitle,
// // //   });
// // //
// // //   @override
// // //   State<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
// // // }
// // //
// // // class _AgentPerformanceScreenState extends State<AgentPerformanceScreen> {
// // //   final SupabaseClient _supabase = Supabase.instance.client;
// // //
// // //   bool _isLoading = true;
// // //   String? _error;
// // //   List<Map<String, dynamic>> _rows = [];
// // //
// // //   String get _role =>
// // //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// // //
// // //   bool get _isAdmin => _role == 'admin';
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadRows();
// // //   }
// // //
// // //   Future<void> _loadRows() async {
// // //     setState(() {
// // //       _isLoading = true;
// // //       _error = null;
// // //     });
// // //
// // //     try {
// // //       final response = await _supabase
// // //           .from('crm_agent_performance_view')
// // //           .select()
// // //           .order('full_name', ascending: true);
// // //
// // //       final rows = (response as List)
// // //           .map((e) => Map<String, dynamic>.from(e as Map))
// // //           .toList();
// // //
// // //       if (!mounted) return;
// // //
// // //       setState(() {
// // //         _rows = rows;
// // //         _isLoading = false;
// // //       });
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _error = e.toString();
// // //         _isLoading = false;
// // //       });
// // //     }
// // //   }
// // //
// // //   int _toInt(dynamic value) {
// // //     if (value == null) return 0;
// // //     if (value is int) return value;
// // //     if (value is num) return value.toInt();
// // //     return int.tryParse(value.toString().trim()) ?? 0;
// // //   }
// // //
// // //   String _text(dynamic value) => (value ?? '').toString().trim();
// // //
// // //   String _displayName() {
// // //     final fullName = _text(widget.profile['full_name']);
// // //     final email = _text(widget.profile['email']);
// // //     return fullName.isNotEmpty ? fullName : email;
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFF0A0A0A),
// // //       body: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             _AgentPerformanceHeader(
// // //               title: widget.customTitle ?? 'Agent Performance',
// // //               showOwnHeader: widget.showOwnHeader,
// // //               profileName: _displayName(),
// // //               role: _role,
// // //               onRefresh: _loadRows,
// // //               onLogout: widget.onLogout,
// // //             ),
// // //             Expanded(
// // //               child: AnimatedSwitcher(
// // //                 duration: const Duration(milliseconds: 220),
// // //                 child: _buildBody(),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildBody() {
// // //     if (!_isAdmin) {
// // //       return const _AgentAdminOnlyCard(
// // //         message: 'Only admins can view agent performance.',
// // //       );
// // //     }
// // //
// // //     if (_isLoading) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }
// // //
// // //     if (_error != null) {
// // //       return _AgentErrorCard(
// // //         title: 'Failed to load agent performance',
// // //         message: _error!,
// // //         onRetry: _loadRows,
// // //       );
// // //     }
// // //
// // //     if (_rows.isEmpty) {
// // //       return Center(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(24),
// // //           child: Container(
// // //             constraints: const BoxConstraints(maxWidth: 560),
// // //             padding: const EdgeInsets.all(24),
// // //             decoration: BoxDecoration(
// // //               color: const Color(0xFF141414),
// // //               borderRadius: BorderRadius.circular(24),
// // //               border: Border.all(color: const Color(0xFF3A2F0B)),
// // //             ),
// // //             child: const Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 Icon(
// // //                   Icons.groups_2_outlined,
// // //                   size: 44,
// // //                   color: Color(0xFFD4AF37),
// // //                 ),
// // //                 SizedBox(height: 12),
// // //                 Text(
// // //                   'No sales users found',
// // //                   textAlign: TextAlign.center,
// // //                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //
// // //     return RefreshIndicator(
// // //       onRefresh: _loadRows,
// // //       child: ListView.builder(
// // //         padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
// // //         itemCount: _rows.length,
// // //         itemBuilder: (context, index) {
// // //           final row = _rows[index];
// // //           return Padding(
// // //             padding: const EdgeInsets.only(bottom: 14),
// // //             child: _AgentPerformanceCard(
// // //               name: _text(row['full_name']).isNotEmpty
// // //                   ? _text(row['full_name'])
// // //                   : _text(row['email']),
// // //               email: _text(row['email']),
// // //               totalLeads: _toInt(row['total_leads']),
// // //               newLeads: _toInt(row['new_leads']),
// // //               contactedLeads: _toInt(row['contacted_leads']),
// // //               qualifiedLeads: _toInt(row['qualified_leads']),
// // //               wonLeads: _toInt(row['won_leads']),
// // //               lostLeads: _toInt(row['lost_leads']),
// // //               importantLeads: _toInt(row['important_leads']),
// // //               pendingFollowUps: _toInt(row['pending_followups']),
// // //               overdueFollowUps: _toInt(row['overdue_followups']),
// // //               doneFollowUps: _toInt(row['done_followups']),
// // //               missedFollowUps: _toInt(row['missed_followups']),
// // //             ),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _AgentPerformanceHeader extends StatelessWidget {
// // //   final String title;
// // //   final bool showOwnHeader;
// // //   final String profileName;
// // //   final String role;
// // //   final Future<void> Function() onRefresh;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _AgentPerformanceHeader({
// // //     required this.title,
// // //     required this.showOwnHeader,
// // //     required this.profileName,
// // //     required this.role,
// // //     required this.onRefresh,
// // //     required this.onLogout,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isWide = MediaQuery.of(context).size.width >= 860;
// // //
// // //     return Container(
// // //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF111111),
// // //         border: const Border(bottom: BorderSide(color: Color(0xFF3A2F0B))),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: const Color(0xFFD4AF37).withOpacity(0.05),
// // //             blurRadius: 16,
// // //             offset: const Offset(0, 5),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         children: [
// // //           if (showOwnHeader)
// // //             Row(
// // //               children: [
// // //                 Container(
// // //                   width: 44,
// // //                   height: 44,
// // //                   padding: const EdgeInsets.all(3),
// // //                   decoration: BoxDecoration(
// // //                     borderRadius: BorderRadius.circular(14),
// // //                     gradient: const LinearGradient(
// // //                       colors: [Color(0xFFD4AF37), Color(0xFF8C6B16)],
// // //                     ),
// // //                   ),
// // //                   child: const Icon(Icons.groups_2_outlined, color: Color(0xFF111111)),
// // //                 ),
// // //                 const SizedBox(width: 12),
// // //                 Expanded(
// // //                   child: Text(
// // //                     title,
// // //                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 if (isWide)
// // //                   _AgentHeaderProfileMenu(
// // //                     profileName: profileName,
// // //                     role: role,
// // //                     onLogout: onLogout,
// // //                   )
// // //                 else
// // //                   PopupMenuButton<String>(
// // //                     onSelected: (value) async {
// // //                       if (value == 'logout') await onLogout();
// // //                     },
// // //                     itemBuilder: (_) => const [
// // //                       PopupMenuItem<String>(
// // //                         value: 'logout',
// // //                         child: Text('Logout'),
// // //                       ),
// // //                     ],
// // //                     icon: const Icon(Icons.account_circle_outlined),
// // //                   ),
// // //               ],
// // //             ),
// // //           if (showOwnHeader) const SizedBox(height: 14),
// // //           Row(
// // //             children: [
// // //               Expanded(
// // //                 child: Text(
// // //                   'Per-sales-user lead and follow-up performance.',
// // //                   style: Theme.of(context).textTheme.bodyMedium,
// // //                 ),
// // //               ),
// // //               OutlinedButton.icon(
// // //                 onPressed: onRefresh,
// // //                 icon: const Icon(Icons.refresh_rounded),
// // //                 label: const Text('Refresh'),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _AgentHeaderProfileMenu extends StatelessWidget {
// // //   final String profileName;
// // //   final String role;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _AgentHeaderProfileMenu({
// // //     required this.profileName,
// // //     required this.role,
// // //     required this.onLogout,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         ConstrainedBox(
// // //           constraints: const BoxConstraints(maxWidth: 220),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.end,
// // //             children: [
// // //               Text(
// // //                 profileName,
// // //                 maxLines: 1,
// // //                 overflow: TextOverflow.ellipsis,
// // //                 style: const TextStyle(fontWeight: FontWeight.w700),
// // //               ),
// // //               Text(
// // //                 role.toUpperCase(),
// // //                 style: const TextStyle(
// // //                   color: Color(0xFFD4AF37),
// // //                   fontWeight: FontWeight.w800,
// // //                   fontSize: 12,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         const SizedBox(width: 8),
// // //         PopupMenuButton<String>(
// // //           onSelected: (value) async {
// // //             if (value == 'logout') await onLogout();
// // //           },
// // //           itemBuilder: (_) => const [
// // //             PopupMenuItem<String>(
// // //               value: 'logout',
// // //               child: Text('Logout'),
// // //             ),
// // //           ],
// // //           icon: const Icon(Icons.account_circle_outlined),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // }
// // //
// // // class _AgentPerformanceCard extends StatelessWidget {
// // //   final String name;
// // //   final String email;
// // //   final int totalLeads;
// // //   final int newLeads;
// // //   final int contactedLeads;
// // //   final int qualifiedLeads;
// // //   final int wonLeads;
// // //   final int lostLeads;
// // //   final int importantLeads;
// // //   final int pendingFollowUps;
// // //   final int overdueFollowUps;
// // //   final int doneFollowUps;
// // //   final int missedFollowUps;
// // //
// // //   const _AgentPerformanceCard({
// // //     required this.name,
// // //     required this.email,
// // //     required this.totalLeads,
// // //     required this.newLeads,
// // //     required this.contactedLeads,
// // //     required this.qualifiedLeads,
// // //     required this.wonLeads,
// // //     required this.lostLeads,
// // //     required this.importantLeads,
// // //     required this.pendingFollowUps,
// // //     required this.overdueFollowUps,
// // //     required this.doneFollowUps,
// // //     required this.missedFollowUps,
// // //   });
// // //
// // //   Widget _metric(String label, int value) {
// // //     return SizedBox(
// // //       width: 140,
// // //       child: Container(
// // //         padding: const EdgeInsets.all(10),
// // //         decoration: BoxDecoration(
// // //           color: const Color(0xFF101010),
// // //           borderRadius: BorderRadius.circular(14),
// // //           border: Border.all(color: const Color(0xFF2B2B2B)),
// // //         ),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Text(
// // //               value.toString(),
// // //               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
// // //             ),
// // //             const SizedBox(height: 4),
// // //             Text(
// // //               label,
// // //               style: const TextStyle(fontSize: 12),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.all(18),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF141414),
// // //         borderRadius: BorderRadius.circular(22),
// // //         border: Border.all(color: const Color(0xFF3A2F0B)),
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             name,
// // //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// // //               fontWeight: FontWeight.w900,
// // //             ),
// // //           ),
// // //           if (email.isNotEmpty) ...[
// // //             const SizedBox(height: 4),
// // //             Text(email),
// // //           ],
// // //           const SizedBox(height: 16),
// // //           const Text(
// // //             'Leads',
// // //             style: TextStyle(
// // //               color: Color(0xFFD4AF37),
// // //               fontWeight: FontWeight.w800,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 10),
// // //           Wrap(
// // //             spacing: 10,
// // //             runSpacing: 10,
// // //             children: [
// // //               _metric('Total', totalLeads),
// // //               _metric('New', newLeads),
// // //               _metric('Contacted', contactedLeads),
// // //               _metric('Qualified', qualifiedLeads),
// // //               _metric('Won', wonLeads),
// // //               _metric('Lost', lostLeads),
// // //               _metric('Important', importantLeads),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 16),
// // //           const Text(
// // //             'Follow-ups',
// // //             style: TextStyle(
// // //               color: Color(0xFFD4AF37),
// // //               fontWeight: FontWeight.w800,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 10),
// // //           Wrap(
// // //             spacing: 10,
// // //             runSpacing: 10,
// // //             children: [
// // //               _metric('Pending', pendingFollowUps),
// // //               _metric('Overdue', overdueFollowUps),
// // //               _metric('Done', doneFollowUps),
// // //               _metric('Missed', missedFollowUps),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _AgentAdminOnlyCard extends StatelessWidget {
// // //   final String message;
// // //
// // //   const _AgentAdminOnlyCard({
// // //     required this.message,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Center(
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(24),
// // //         child: Container(
// // //           constraints: const BoxConstraints(maxWidth: 560),
// // //           padding: const EdgeInsets.all(24),
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFF141414),
// // //             borderRadius: BorderRadius.circular(24),
// // //             border: Border.all(color: const Color(0xFF3A2F0B)),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               const Icon(
// // //                 Icons.lock_outline_rounded,
// // //                 size: 44,
// // //                 color: Color(0xFFD4AF37),
// // //               ),
// // //               const SizedBox(height: 12),
// // //               const Text(
// // //                 'Admin access only',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               Text(message, textAlign: TextAlign.center),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _AgentErrorCard extends StatelessWidget {
// // //   final String title;
// // //   final String message;
// // //   final Future<void> Function() onRetry;
// // //
// // //   const _AgentErrorCard({
// // //     required this.title,
// // //     required this.message,
// // //     required this.onRetry,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Center(
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(24),
// // //         child: Container(
// // //           constraints: const BoxConstraints(maxWidth: 560),
// // //           padding: const EdgeInsets.all(20),
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFF141414),
// // //             borderRadius: BorderRadius.circular(24),
// // //             border: Border.all(color: const Color(0xFF3A2F0B)),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               const Icon(
// // //                 Icons.error_outline_rounded,
// // //                 size: 42,
// // //                 color: Colors.redAccent,
// // //               ),
// // //               const SizedBox(height: 12),
// // //               Text(
// // //                 title,
// // //                 textAlign: TextAlign.center,
// // //                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               Text(message, textAlign: TextAlign.center),
// // //               const SizedBox(height: 16),
// // //               FilledButton.icon(
// // //                 onPressed: onRetry,
// // //                 icon: const Icon(Icons.refresh_rounded),
// // //                 label: const Text('Retry'),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:flutter/material.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // class AgentPerformanceScreen extends StatefulWidget {
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final bool showOwnHeader;
// //   final String? customTitle;
// //
// //   const AgentPerformanceScreen({
// //     super.key,
// //     required this.profile,
// //     required this.onLogout,
// //     this.showOwnHeader = true,
// //     this.customTitle,
// //   });
// //
// //   @override
// //   State<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
// // }
// //
// // class _AgentPerformanceScreenState extends State<AgentPerformanceScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //
// //   bool _isLoading = true;
// //   String? _error;
// //   List<Map<String, dynamic>> _rows = [];
// //
// //   String get _role =>
// //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// //
// //   bool get _isAdmin => _role == 'admin';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadRows();
// //   }
// //
// //   Future<void> _loadRows() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final response = await _supabase
// //           .from('crm_agent_performance_view')
// //           .select()
// //           .order('full_name', ascending: true);
// //
// //       final rows = (response as List)
// //           .map((e) => Map<String, dynamic>.from(e as Map))
// //           .toList();
// //
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _rows = rows;
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
// //   int _toInt(dynamic value) {
// //     if (value == null) return 0;
// //     if (value is int) return value;
// //     if (value is num) return value.toInt();
// //     return int.tryParse(value.toString().trim()) ?? 0;
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
// //   @override
// //   Widget build(BuildContext context) {
// //     final isWide = MediaQuery.of(context).size.width >= 1100;
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF0A0A0A),
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             _AgentPerformanceHeader(
// //               title: widget.customTitle ?? 'Agent Performance',
// //               showOwnHeader: widget.showOwnHeader,
// //               profileName: _displayName(),
// //               role: _role,
// //               onRefresh: _loadRows,
// //               onLogout: widget.onLogout,
// //             ),
// //             Expanded(
// //               child: AnimatedSwitcher(
// //                 duration: const Duration(milliseconds: 220),
// //                 child: _buildBody(isWide),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildBody(bool isWide) {
// //     if (!_isAdmin) {
// //       return const _AgentAdminOnlyCard(
// //         message: 'Only admins can view agent performance.',
// //       );
// //     }
// //
// //     if (_isLoading) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (_error != null) {
// //       return _AgentErrorCard(
// //         title: 'Failed to load agent performance',
// //         message: _error!,
// //         onRetry: _loadRows,
// //       );
// //     }
// //
// //     if (_rows.isEmpty) {
// //       return Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Container(
// //             constraints: const BoxConstraints(maxWidth: 560),
// //             padding: const EdgeInsets.all(24),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF141414),
// //               borderRadius: BorderRadius.circular(24),
// //               border: Border.all(color: const Color(0xFF3A2F0B)),
// //             ),
// //             child: const Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Icon(
// //                   Icons.groups_2_outlined,
// //                   size: 44,
// //                   color: Color(0xFFD4AF37),
// //                 ),
// //                 SizedBox(height: 12),
// //                 Text(
// //                   'No sales users found',
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //
// //     return RefreshIndicator(
// //       onRefresh: _loadRows,
// //       child: ListView(
// //         padding: EdgeInsets.fromLTRB(isWide ? 20 : 14, 16, isWide ? 20 : 14, 40),
// //         children: [
// //           _PerformanceOverviewRow(rows: _rows),
// //           const SizedBox(height: 18),
// //           _ChartPanel(
// //             title: 'Top Agent Comparison',
// //             child: SizedBox(
// //               height: 320,
// //               child: _AgentComparisonBarChart(rows: _rows),
// //             ),
// //           ),
// //           const SizedBox(height: 18),
// //           const _SectionTitle('Agent Breakdown'),
// //           const SizedBox(height: 14),
// //           ..._rows.map(
// //                 (row) => Padding(
// //               padding: const EdgeInsets.only(bottom: 14),
// //               child: _AgentPerformanceCard(
// //                 name: _text(row['full_name']).isNotEmpty
// //                     ? _text(row['full_name'])
// //                     : _text(row['email']),
// //                 email: _text(row['email']),
// //                 totalLeads: _toInt(row['total_leads']),
// //                 newLeads: _toInt(row['new_leads']),
// //                 contactedLeads: _toInt(row['contacted_leads']),
// //                 qualifiedLeads: _toInt(row['qualified_leads']),
// //                 wonLeads: _toInt(row['won_leads']),
// //                 lostLeads: _toInt(row['lost_leads']),
// //                 importantLeads: _toInt(row['important_leads']),
// //                 pendingFollowUps: _toInt(row['pending_followups']),
// //                 overdueFollowUps: _toInt(row['overdue_followups']),
// //                 doneFollowUps: _toInt(row['done_followups']),
// //                 missedFollowUps: _toInt(row['missed_followups']),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentPerformanceHeader extends StatelessWidget {
// //   final String title;
// //   final bool showOwnHeader;
// //   final String profileName;
// //   final String role;
// //   final Future<void> Function() onRefresh;
// //   final Future<void> Function() onLogout;
// //
// //   const _AgentPerformanceHeader({
// //     required this.title,
// //     required this.showOwnHeader,
// //     required this.profileName,
// //     required this.role,
// //     required this.onRefresh,
// //     required this.onLogout,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isWide = MediaQuery.of(context).size.width >= 860;
// //
// //     return Container(
// //       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF111111),
// //         border: const Border(bottom: BorderSide(color: Color(0xFF3A2F0B))),
// //         boxShadow: [
// //           BoxShadow(
// //             color: const Color(0xFFD4AF37).withOpacity(0.05),
// //             blurRadius: 16,
// //             offset: const Offset(0, 5),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         children: [
// //           if (showOwnHeader)
// //             Row(
// //               children: [
// //                 Container(
// //                   width: 44,
// //                   height: 44,
// //                   padding: const EdgeInsets.all(3),
// //                   decoration: BoxDecoration(
// //                     borderRadius: BorderRadius.circular(14),
// //                     gradient: const LinearGradient(
// //                       colors: [Color(0xFFD4AF37), Color(0xFF8C6B16)],
// //                     ),
// //                   ),
// //                   child: const Icon(Icons.groups_2_outlined, color: Color(0xFF111111)),
// //                 ),
// //                 const SizedBox(width: 12),
// //                 Expanded(
// //                   child: Text(
// //                     title,
// //                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                 ),
// //                 if (isWide)
// //                   _AgentHeaderProfileMenu(
// //                     profileName: profileName,
// //                     role: role,
// //                     onLogout: onLogout,
// //                   )
// //                 else
// //                   PopupMenuButton<String>(
// //                     onSelected: (value) async {
// //                       if (value == 'logout') await onLogout();
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
// //           if (showOwnHeader) const SizedBox(height: 14),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: Text(
// //                   'Compare lead ownership and follow-up workload by sales user.',
// //                   style: Theme.of(context).textTheme.bodyMedium,
// //                 ),
// //               ),
// //               OutlinedButton.icon(
// //                 onPressed: onRefresh,
// //                 icon: const Icon(Icons.refresh_rounded),
// //                 label: const Text('Refresh'),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentHeaderProfileMenu extends StatelessWidget {
// //   final String profileName;
// //   final String role;
// //   final Future<void> Function() onLogout;
// //
// //   const _AgentHeaderProfileMenu({
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
// //             if (value == 'logout') await onLogout();
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
// // class _PerformanceOverviewRow extends StatelessWidget {
// //   final List<Map<String, dynamic>> rows;
// //
// //   const _PerformanceOverviewRow({
// //     required this.rows,
// //   });
// //
// //   int _toInt(dynamic value) {
// //     if (value == null) return 0;
// //     if (value is int) return value;
// //     if (value is num) return value.toInt();
// //     return int.tryParse(value.toString().trim()) ?? 0;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final totalAgents = rows.length;
// //     final totalLeads = rows.fold<int>(0, (sum, row) => sum + _toInt(row['total_leads']));
// //     final totalWon = rows.fold<int>(0, (sum, row) => sum + _toInt(row['won_leads']));
// //     final totalPending = rows.fold<int>(0, (sum, row) => sum + _toInt(row['pending_followups']));
// //     final totalOverdue = rows.fold<int>(0, (sum, row) => sum + _toInt(row['overdue_followups']));
// //
// //     final items = [
// //       _OverviewStat('Sales Users', totalAgents, Icons.badge_outlined),
// //       _OverviewStat('Owned Leads', totalLeads, Icons.people_outline_rounded),
// //       _OverviewStat('Won Leads', totalWon, Icons.emoji_events_outlined),
// //       _OverviewStat('Pending Follow-ups', totalPending, Icons.schedule_rounded),
// //       _OverviewStat('Overdue Follow-ups', totalOverdue, Icons.warning_amber_rounded),
// //     ];
// //
// //     return Wrap(
// //       spacing: 14,
// //       runSpacing: 14,
// //       children: items.map((item) => _OverviewCard(item: item)).toList(),
// //     );
// //   }
// // }
// //
// // class _OverviewStat {
// //   final String title;
// //   final int value;
// //   final IconData icon;
// //
// //   const _OverviewStat(this.title, this.value, this.icon);
// // }
// //
// // class _OverviewCard extends StatelessWidget {
// //   final _OverviewStat item;
// //
// //   const _OverviewCard({
// //     required this.item,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox(
// //       width: 220,
// //       child: Container(
// //         padding: const EdgeInsets.all(18),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF141414),
// //           borderRadius: BorderRadius.circular(22),
// //           border: Border.all(color: const Color(0xFF3A2F0B)),
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               width: 46,
// //               height: 46,
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFF2B220B),
// //                 borderRadius: BorderRadius.circular(14),
// //               ),
// //               child: Icon(item.icon, color: const Color(0xFFD4AF37)),
// //             ),
// //             const SizedBox(width: 14),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     item.value.toString(),
// //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(item.title),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _ChartPanel extends StatelessWidget {
// //   final String title;
// //   final Widget child;
// //
// //   const _ChartPanel({
// //     required this.title,
// //     required this.child,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(18),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF141414),
// //         borderRadius: BorderRadius.circular(22),
// //         border: Border.all(color: const Color(0xFF3A2F0B)),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             title,
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w900,
// //             ),
// //           ),
// //           const SizedBox(height: 14),
// //           child,
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentComparisonBarChart extends StatelessWidget {
// //   final List<Map<String, dynamic>> rows;
// //
// //   const _AgentComparisonBarChart({
// //     required this.rows,
// //   });
// //
// //   int _toInt(dynamic value) {
// //     if (value == null) return 0;
// //     if (value is int) return value;
// //     if (value is num) return value.toInt();
// //     return int.tryParse(value.toString().trim()) ?? 0;
// //   }
// //
// //   String _name(Map<String, dynamic> row) {
// //     final name = (row['full_name'] ?? '').toString().trim();
// //     final email = (row['email'] ?? '').toString().trim();
// //     return name.isNotEmpty ? name : email;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final chartRows = rows.take(6).toList();
// //
// //     if (chartRows.isEmpty) {
// //       return const Center(child: Text('No agent data yet'));
// //     }
// //
// //     final maxValue = chartRows.fold<int>(
// //       0,
// //           (max, row) {
// //         final total = _toInt(row['total_leads']);
// //         final won = _toInt(row['won_leads']);
// //         final pending = _toInt(row['pending_followups']);
// //         final localMax = [total, won, pending].reduce((a, b) => a > b ? a : b);
// //         return localMax > max ? localMax : max;
// //       },
// //     );
// //
// //     final safeMaxY = maxValue <= 0 ? 5.0 : maxValue + 2;
// //
// //     return BarChart(
// //       BarChartData(
// //         maxY: safeMaxY.toDouble(),
// //         groupsSpace: 22,
// //         gridData: const FlGridData(show: false),
// //         borderData: FlBorderData(show: false),
// //         titlesData: FlTitlesData(
// //           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //           leftTitles: AxisTitles(
// //             sideTitles: SideTitles(
// //               showTitles: true,
// //               reservedSize: 28,
// //               getTitlesWidget: (value, meta) => Text(
// //                 value.toInt().toString(),
// //                 style: const TextStyle(fontSize: 10),
// //               ),
// //             ),
// //           ),
// //           bottomTitles: AxisTitles(
// //             sideTitles: SideTitles(
// //               showTitles: true,
// //               reservedSize: 40,
// //               getTitlesWidget: (value, meta) {
// //                 final index = value.toInt();
// //                 if (index < 0 || index >= chartRows.length) {
// //                   return const SizedBox.shrink();
// //                 }
// //                 final label = _name(chartRows[index]);
// //                 return Padding(
// //                   padding: const EdgeInsets.only(top: 8),
// //                   child: Text(
// //                     label,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: const TextStyle(fontSize: 10),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ),
// //         barGroups: List.generate(chartRows.length, (index) {
// //           final row = chartRows[index];
// //           final totalLeads = _toInt(row['total_leads']);
// //           final wonLeads = _toInt(row['won_leads']);
// //           final pendingFollowUps = _toInt(row['pending_followups']);
// //
// //           return BarChartGroupData(
// //             x: index,
// //             barsSpace: 4,
// //             barRods: [
// //               BarChartRodData(
// //                 toY: totalLeads.toDouble(),
// //                 width: 10,
// //                 borderRadius: BorderRadius.circular(4),
// //                 color: const Color(0xFFD4AF37),
// //               ),
// //               BarChartRodData(
// //                 toY: wonLeads.toDouble(),
// //                 width: 10,
// //                 borderRadius: BorderRadius.circular(4),
// //                 color: const Color(0xFF2E7D32),
// //               ),
// //               BarChartRodData(
// //                 toY: pendingFollowUps.toDouble(),
// //                 width: 10,
// //                 borderRadius: BorderRadius.circular(4),
// //                 color: const Color(0xFF1976D2),
// //               ),
// //             ],
// //           );
// //         }),
// //       ),
// //     );
// //   }
// // }
// //
// // class _SectionTitle extends StatelessWidget {
// //   final String title;
// //
// //   const _SectionTitle(this.title);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Text(
// //       title,
// //       style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //         fontWeight: FontWeight.w900,
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentPerformanceCard extends StatelessWidget {
// //   final String name;
// //   final String email;
// //   final int totalLeads;
// //   final int newLeads;
// //   final int contactedLeads;
// //   final int qualifiedLeads;
// //   final int wonLeads;
// //   final int lostLeads;
// //   final int importantLeads;
// //   final int pendingFollowUps;
// //   final int overdueFollowUps;
// //   final int doneFollowUps;
// //   final int missedFollowUps;
// //
// //   const _AgentPerformanceCard({
// //     required this.name,
// //     required this.email,
// //     required this.totalLeads,
// //     required this.newLeads,
// //     required this.contactedLeads,
// //     required this.qualifiedLeads,
// //     required this.wonLeads,
// //     required this.lostLeads,
// //     required this.importantLeads,
// //     required this.pendingFollowUps,
// //     required this.overdueFollowUps,
// //     required this.doneFollowUps,
// //     required this.missedFollowUps,
// //   });
// //
// //   Widget _metric(String label, int value) {
// //     return SizedBox(
// //       width: 128,
// //       child: Container(
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF101010),
// //           borderRadius: BorderRadius.circular(14),
// //           border: Border.all(color: const Color(0xFF2B2B2B)),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               value.toString(),
// //               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
// //             ),
// //             const SizedBox(height: 4),
// //             Text(
// //               label,
// //               style: const TextStyle(fontSize: 12),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.all(18),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF141414),
// //         borderRadius: BorderRadius.circular(22),
// //         border: Border.all(color: const Color(0xFF3A2F0B)),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             name,
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w900,
// //             ),
// //           ),
// //           if (email.isNotEmpty) ...[
// //             const SizedBox(height: 4),
// //             Text(email),
// //           ],
// //           const SizedBox(height: 16),
// //           Wrap(
// //             spacing: 10,
// //             runSpacing: 10,
// //             children: [
// //               _metric('Total Leads', totalLeads),
// //               _metric('Won Leads', wonLeads),
// //               _metric('Pending Follow-ups', pendingFollowUps),
// //               _metric('Overdue Follow-ups', overdueFollowUps),
// //             ],
// //           ),
// //           const SizedBox(height: 16),
// //           const Text(
// //             'Lead Breakdown',
// //             style: TextStyle(
// //               color: Color(0xFFD4AF37),
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           Wrap(
// //             spacing: 10,
// //             runSpacing: 10,
// //             children: [
// //               _metric('New', newLeads),
// //               _metric('Contacted', contactedLeads),
// //               _metric('Qualified', qualifiedLeads),
// //               _metric('Lost', lostLeads),
// //               _metric('Important', importantLeads),
// //             ],
// //           ),
// //           const SizedBox(height: 16),
// //           const Text(
// //             'Follow-up Breakdown',
// //             style: TextStyle(
// //               color: Color(0xFFD4AF37),
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ),
// //           const SizedBox(height: 10),
// //           Wrap(
// //             spacing: 10,
// //             runSpacing: 10,
// //             children: [
// //               _metric('Done', doneFollowUps),
// //               _metric('Missed', missedFollowUps),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentAdminOnlyCard extends StatelessWidget {
// //   final String message;
// //
// //   const _AgentAdminOnlyCard({
// //     required this.message,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(24),
// //         child: Container(
// //           constraints: const BoxConstraints(maxWidth: 560),
// //           padding: const EdgeInsets.all(24),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(24),
// //             border: Border.all(color: const Color(0xFF3A2F0B)),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               const Icon(
// //                 Icons.lock_outline_rounded,
// //                 size: 44,
// //                 color: Color(0xFFD4AF37),
// //               ),
// //               const SizedBox(height: 12),
// //               const Text(
// //                 'Admin access only',
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// //               ),
// //               const SizedBox(height: 8),
// //               Text(message, textAlign: TextAlign.center),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _AgentErrorCard extends StatelessWidget {
// //   final String title;
// //   final String message;
// //   final Future<void> Function() onRetry;
// //
// //   const _AgentErrorCard({
// //     required this.title,
// //     required this.message,
// //     required this.onRetry,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(24),
// //         child: Container(
// //           constraints: const BoxConstraints(maxWidth: 560),
// //           padding: const EdgeInsets.all(20),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(24),
// //             border: Border.all(color: const Color(0xFF3A2F0B)),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               const Icon(
// //                 Icons.error_outline_rounded,
// //                 size: 42,
// //                 color: Colors.redAccent,
// //               ),
// //               const SizedBox(height: 12),
// //               Text(
// //                 title,
// //                 textAlign: TextAlign.center,
// //                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
// //               ),
// //               const SizedBox(height: 8),
// //               Text(message, textAlign: TextAlign.center),
// //               const SizedBox(height: 16),
// //               FilledButton.icon(
// //                 onPressed: onRetry,
// //                 icon: const Icon(Icons.refresh_rounded),
// //                 label: const Text('Retry'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class AgentPerformanceScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final bool showOwnHeader;
//   final String? customTitle;
//
//   const AgentPerformanceScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//     this.showOwnHeader = true,
//     this.customTitle,
//   });
//
//   @override
//   State<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
// }
//
// class _AgentPerformanceScreenState extends State<AgentPerformanceScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _rows = [];
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   bool get _isAdmin => _role == 'admin';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRows();
//   }
//
//   Future<void> _loadRows() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final response = await _supabase
//           .from('crm_agent_performance_view')
//           .select()
//           .order('full_name', ascending: true);
//
//       final rows = (response as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       if (!mounted) return;
//
//       setState(() {
//         _rows = rows;
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
//   int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is num) return value.toInt();
//     return int.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   String _displayName() {
//     final fullName = _text(widget.profile['full_name']);
//     final email = _text(widget.profile['email']);
//     return fullName.isNotEmpty ? fullName : email;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _AgentHeader(
//               title: widget.customTitle ?? 'Agent Performance',
//               showOwnHeader: widget.showOwnHeader,
//               profileName: _displayName(),
//               role: _role,
//               onRefresh: _loadRows,
//               onLogout: widget.onLogout,
//             ),
//             Expanded(
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 220),
//                 child: _buildBody(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     if (!_isAdmin) {
//       return const _AgentAdminOnlyCard(
//         message: 'Only admins can view agent performance.',
//       );
//     }
//
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_error != null) {
//       return _AgentErrorCard(
//         title: 'Failed to load agent performance',
//         message: _error!,
//         onRetry: _loadRows,
//       );
//     }
//
//     if (_rows.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 560),
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: const Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.groups_2_outlined,
//                   size: 44,
//                   color: Color(0xFFD4AF37),
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   'No sales users found',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: _loadRows,
//       child: ListView(
//         padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
//         children: [
//           _OverviewRow(rows: _rows),
//           const SizedBox(height: 18),
//           _ChartPanel(
//             title: 'Top Agent Comparison',
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children:  [
//                 _ChartLegend(),
//                 SizedBox(height: 14),
//                 SizedBox(
//                   height: 320,
//                   child: _AgentComparisonBarChart(rows: _rows),
//                 ),
//               ],
//             ),
//           ),
//           // _ChartPanel(
//           //   title: 'Top Agent Comparison',
//           //   child: SizedBox(
//           //     height: 320,
//           //     child: _AgentComparisonBarChart(rows: _rows),
//           //   ),
//           // ),
//           const SizedBox(height: 18),
//           const _SectionTitle('Agent Breakdown'),
//           const SizedBox(height: 14),
//           ..._rows.map(
//                 (row) => Padding(
//               padding: const EdgeInsets.only(bottom: 14),
//               child: _AgentCard(
//                 name: _text(row['full_name']).isNotEmpty
//                     ? _text(row['full_name'])
//                     : _text(row['email']),
//                 email: _text(row['email']),
//                 totalLeads: _toInt(row['total_leads']),
//                 newLeads: _toInt(row['new_leads']),
//                 contactedLeads: _toInt(row['contacted_leads']),
//                 qualifiedLeads: _toInt(row['qualified_leads']),
//                 wonLeads: _toInt(row['won_leads']),
//                 lostLeads: _toInt(row['lost_leads']),
//                 importantLeads: _toInt(row['important_leads']),
//                 pendingFollowUps: _toInt(row['pending_followups']),
//                 overdueFollowUps: _toInt(row['overdue_followups']),
//                 doneFollowUps: _toInt(row['done_followups']),
//                 missedFollowUps: _toInt(row['missed_followups']),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AgentHeader extends StatelessWidget {
//   final String title;
//   final bool showOwnHeader;
//   final String profileName;
//   final String role;
//   final Future<void> Function() onRefresh;
//   final Future<void> Function() onLogout;
//
//   const _AgentHeader({
//     required this.title,
//     required this.showOwnHeader,
//     required this.profileName,
//     required this.role,
//     required this.onRefresh,
//     required this.onLogout,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final isWide = MediaQuery.of(context).size.width >= 860;
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111111),
//         border: const Border(bottom: BorderSide(color: Color(0xFF3A2F0B))),
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
//                       colors: [Color(0xFFD4AF37), Color(0xFF8C6B16)],
//                     ),
//                   ),
//                   child: const Icon(Icons.groups_2_outlined, color: Color(0xFF111111)),
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
//                   _ProfileMenu(
//                     profileName: profileName,
//                     role: role,
//                     onLogout: onLogout,
//                   )
//                 else
//                   PopupMenuButton<String>(
//                     onSelected: (value) async {
//                       if (value == 'logout') await onLogout();
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
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Compare lead ownership and follow-up workload by sales user.',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//               ),
//               OutlinedButton.icon(
//                 onPressed: onRefresh,
//                 icon: const Icon(Icons.refresh_rounded),
//                 label: const Text('Refresh'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
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
//                 style: const TextStyle(fontWeight: FontWeight.w700),
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
//             if (value == 'logout') await onLogout();
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
// class _OverviewRow extends StatelessWidget {
//   final List<Map<String, dynamic>> rows;
//
//   const _OverviewRow({
//     required this.rows,
//   });
//
//   int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is num) return value.toInt();
//     return int.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalAgents = rows.length;
//     final totalLeads = rows.fold<int>(0, (sum, row) => sum + _toInt(row['total_leads']));
//     final totalWon = rows.fold<int>(0, (sum, row) => sum + _toInt(row['won_leads']));
//     final totalPending = rows.fold<int>(0, (sum, row) => sum + _toInt(row['pending_followups']));
//     final totalOverdue = rows.fold<int>(0, (sum, row) => sum + _toInt(row['overdue_followups']));
//
//     final items = [
//       _OverviewData('Sales Users', totalAgents, Icons.badge_outlined),
//       _OverviewData('Owned Leads', totalLeads, Icons.people_outline_rounded),
//       _OverviewData('Won Leads', totalWon, Icons.emoji_events_outlined),
//       _OverviewData('Pending Follow-ups', totalPending, Icons.schedule_rounded),
//       _OverviewData('Overdue Follow-ups', totalOverdue, Icons.warning_amber_rounded),
//     ];
//
//     return Wrap(
//       spacing: 14,
//       runSpacing: 14,
//       children: items.map((item) => _OverviewCard(item: item)).toList(),
//     );
//   }
// }
//
// class _OverviewData {
//   final String title;
//   final int value;
//   final IconData icon;
//
//   const _OverviewData(this.title, this.value, this.icon);
// }
//
// class _OverviewCard extends StatelessWidget {
//   final _OverviewData item;
//
//   const _OverviewCard({
//     required this.item,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 220,
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: const Color(0xFF141414),
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(color: const Color(0xFF3A2F0B)),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 46,
//               height: 46,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF2B220B),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(item.icon, color: const Color(0xFFD4AF37)),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     item.value.toString(),
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(item.title),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ChartPanel extends StatelessWidget {
//   final String title;
//   final Widget child;
//
//   const _ChartPanel({
//     required this.title,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFF141414),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: const Color(0xFF3A2F0B)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 14),
//           child,
//         ],
//       ),
//     );
//   }
// }
// class _ChartLegend extends StatelessWidget {
//   const _ChartLegend();
//
//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 14,
//       runSpacing: 10,
//       children: const [
//         _LegendItem(
//           color: Color(0xFFD4AF37),
//           label: 'Total Leads',
//         ),
//         _LegendItem(
//           color: Color(0xFF2E7D32),
//           label: 'Won Leads',
//         ),
//         _LegendItem(
//           color: Color(0xFF1976D2),
//           label: 'Pending Follow-ups',
//         ),
//       ],
//     );
//   }
// }
//
// class _LegendItem extends StatelessWidget {
//   final Color color;
//   final String label;
//
//   const _LegendItem({
//     required this.color,
//     required this.label,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(99),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(label),
//       ],
//     );
//   }
// }
// class _AgentComparisonBarChart extends StatelessWidget {
//   final List<Map<String, dynamic>> rows;
//
//   const _AgentComparisonBarChart({
//     required this.rows,
//   });
//
//   int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     if (value is num) return value.toInt();
//     return int.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _name(Map<String, dynamic> row) {
//     final name = (row['full_name'] ?? '').toString().trim();
//     final email = (row['email'] ?? '').toString().trim();
//     return name.isNotEmpty ? name : email;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chartRows = rows.take(6).toList();
//
//     if (chartRows.isEmpty) {
//       return const Center(child: Text('No agent data yet'));
//     }
//
//     final maxValue = chartRows.fold<int>(
//       0,
//           (max, row) {
//         final total = _toInt(row['total_leads']);
//         final won = _toInt(row['won_leads']);
//         final pending = _toInt(row['pending_followups']);
//         final localMax = [total, won, pending].reduce((a, b) => a > b ? a : b);
//         return localMax > max ? localMax : max;
//       },
//     );
//
//     final safeMaxY = maxValue <= 0 ? 5.0 : maxValue + 2;
//
//     return BarChart(
//       BarChartData(
//         maxY: safeMaxY.toDouble(),
//         groupsSpace: 22,
//         gridData: const FlGridData(show: false),
//         borderData: FlBorderData(show: false),
//         titlesData: FlTitlesData(
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 28,
//               getTitlesWidget: (value, meta) => Text(
//                 value.toInt().toString(),
//                 style: const TextStyle(fontSize: 10),
//               ),
//             ),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 40,
//               getTitlesWidget: (value, meta) {
//                 final index = value.toInt();
//                 if (index < 0 || index >= chartRows.length) {
//                   return const SizedBox.shrink();
//                 }
//                 final label = _name(chartRows[index]);
//                 return Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Text(
//                     label,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(fontSize: 10),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//         barGroups: List.generate(chartRows.length, (index) {
//           final row = chartRows[index];
//           final totalLeads = _toInt(row['total_leads']);
//           final wonLeads = _toInt(row['won_leads']);
//           final pendingFollowUps = _toInt(row['pending_followups']);
//
//           return BarChartGroupData(
//             x: index,
//             barsSpace: 4,
//             barRods: [
//               BarChartRodData(
//                 toY: totalLeads.toDouble(),
//                 width: 10,
//                 borderRadius: BorderRadius.circular(4),
//                 color: const Color(0xFFD4AF37),
//               ),
//               BarChartRodData(
//                 toY: wonLeads.toDouble(),
//                 width: 10,
//                 borderRadius: BorderRadius.circular(4),
//                 color: const Color(0xFF2E7D32),
//               ),
//               BarChartRodData(
//                 toY: pendingFollowUps.toDouble(),
//                 width: 10,
//                 borderRadius: BorderRadius.circular(4),
//                 color: const Color(0xFF1976D2),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }
//
// class _SectionTitle extends StatelessWidget {
//   final String title;
//
//   const _SectionTitle(this.title);
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       title,
//       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//         fontWeight: FontWeight.w900,
//       ),
//     );
//   }
// }
//
// class _AgentCard extends StatelessWidget {
//   final String name;
//   final String email;
//   final int totalLeads;
//   final int newLeads;
//   final int contactedLeads;
//   final int qualifiedLeads;
//   final int wonLeads;
//   final int lostLeads;
//   final int importantLeads;
//   final int pendingFollowUps;
//   final int overdueFollowUps;
//   final int doneFollowUps;
//   final int missedFollowUps;
//
//   const _AgentCard({
//     required this.name,
//     required this.email,
//     required this.totalLeads,
//     required this.newLeads,
//     required this.contactedLeads,
//     required this.qualifiedLeads,
//     required this.wonLeads,
//     required this.lostLeads,
//     required this.importantLeads,
//     required this.pendingFollowUps,
//     required this.overdueFollowUps,
//     required this.doneFollowUps,
//     required this.missedFollowUps,
//   });
//
//   Widget _metric(String label, int value) {
//     return SizedBox(
//       width: 128,
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: const Color(0xFF101010),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: const Color(0xFF2B2B2B)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               value.toString(),
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: const TextStyle(fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFF141414),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: const Color(0xFF3A2F0B)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             name,
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           if (email.isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Text(email),
//           ],
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: [
//               _metric('Total Leads', totalLeads),
//               _metric('Won Leads', wonLeads),
//               _metric('Pending Follow-ups', pendingFollowUps),
//               _metric('Overdue Follow-ups', overdueFollowUps),
//             ],
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Lead Breakdown',
//             style: TextStyle(
//               color: Color(0xFFD4AF37),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: [
//               _metric('New', newLeads),
//               _metric('Contacted', contactedLeads),
//               _metric('Qualified', qualifiedLeads),
//               _metric('Lost', lostLeads),
//               _metric('Important', importantLeads),
//             ],
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Follow-up Breakdown',
//             style: TextStyle(
//               color: Color(0xFFD4AF37),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: [
//               _metric('Done', doneFollowUps),
//               _metric('Missed', missedFollowUps),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AgentAdminOnlyCard extends StatelessWidget {
//   final String message;
//
//   const _AgentAdminOnlyCard({
//     required this.message,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 560),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFF3A2F0B)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.lock_outline_rounded,
//                 size: 44,
//                 color: Color(0xFFD4AF37),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Admin access only',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
//               ),
//               const SizedBox(height: 8),
//               Text(message, textAlign: TextAlign.center),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _AgentErrorCard extends StatelessWidget {
//   final String title;
//   final String message;
//   final Future<void> Function() onRetry;
//
//   const _AgentErrorCard({
//     required this.title,
//     required this.message,
//     required this.onRetry,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 560),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFF3A2F0B)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.error_outline_rounded,
//                 size: 42,
//                 color: Colors.redAccent,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
//               ),
//               const SizedBox(height: 8),
//               Text(message, textAlign: TextAlign.center),
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: onRetry,
//                 icon: const Icon(Icons.refresh_rounded),
//                 label: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../login_screen.dart';

class AgentPerformanceScreen extends ConsumerStatefulWidget {
  final bool showOwnHeader;
  final String? customTitle;

  const AgentPerformanceScreen({
    super.key,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  ConsumerState<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
}

class _AgentPerformanceScreenState extends ConsumerState<AgentPerformanceScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  UserProfile get _profile =>
      ref.read(profileProvider).valueOrNull ??
      const UserProfile(id: '', email: '', name: '', role: '', isActive: false);

  String get _role => _profile.role.trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('crm_agent_performance_view')
          .select()
          .order('full_name', ascending: true);

      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _rows = rows;
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

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  // String _displayName() {
  //   final fullName = _text(widget.profile['full_name']);
  //   final email = _text(widget.profile['email']);
  //   return fullName.isNotEmpty ? fullName : email;
  // }

  String _displayName() {
    final name = _profile.name.trim();
    final email = _profile.email.trim();
    return name.isNotEmpty ? name : email;
  }
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _AgentHeader(
              title: widget.customTitle ?? tr('agent_title'),
              showOwnHeader: widget.showOwnHeader,
              profileName: _displayName(),
              role: _role,
              onRefresh: _loadRows,
              // onLogout: widget.
              onLogout: _handleLogout,
              // onLogout,
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
    if (!_isAdmin) {
      return _StateCard(
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFFD4AF37),
        title: tr('agent_admin_only_title'),
        message: tr('agent_admin_only_message'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
        title: tr('agent_error'),
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadRows,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('btn_retry')),
          ),
        ],
      );
    }

    if (_rows.isEmpty) {
      return _StateCard(
        icon: Icons.groups_2_outlined,
        iconColor: const Color(0xFFD4AF37),
        title: tr('agent_empty_title'),
        message: tr('agent_empty_message'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRows,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 14,
          14,
          isDesktop ? 20 : 14,
          28,
        ),
        children: [
          _OverviewGrid(rows: _rows, isDesktop: isDesktop),
          const SizedBox(height: 14),
          _Panel(
            title: tr('agent_comparison_title'),
            subtitle: tr('agent_comparison_subtitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ChartLegend(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 320,
                  child: _AgentComparisonBarChart(rows: _rows),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Panel(
            title: tr('agent_breakdown_title'),
            subtitle: tr('agent_breakdown_subtitle'),
            child: isDesktop
                ? Column(
              children: [
                const _DesktopAgentHeaderRow(),
                const SizedBox(height: 8),
                ..._rows.map(
                      (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DesktopAgentRow(
                      name: _text(row['full_name']).isNotEmpty
                          ? _text(row['full_name'])
                          : _text(row['email']),
                      email: _text(row['email']),
                      totalLeads: _toInt(row['total_leads']),
                      newLeads: _toInt(row['new_leads']),
                      contactedLeads: _toInt(row['contacted_leads']),
                      qualifiedLeads: _toInt(row['qualified_leads']),
                      wonLeads: _toInt(row['won_leads']),
                      lostLeads: _toInt(row['lost_leads']),
                      importantLeads: _toInt(row['important_leads']),
                      pendingFollowUps: _toInt(row['pending_followups']),
                      overdueFollowUps: _toInt(row['overdue_followups']),
                      doneFollowUps: _toInt(row['done_followups']),
                      missedFollowUps: _toInt(row['missed_followups']),
                    ),
                  ),
                ),
              ],
            )
                : Column(
              children: _rows
                  .map(
                    (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MobileAgentCard(
                    name: _text(row['full_name']).isNotEmpty
                        ? _text(row['full_name'])
                        : _text(row['email']),
                    email: _text(row['email']),
                    totalLeads: _toInt(row['total_leads']),
                    newLeads: _toInt(row['new_leads']),
                    contactedLeads: _toInt(row['contacted_leads']),
                    qualifiedLeads: _toInt(row['qualified_leads']),
                    wonLeads: _toInt(row['won_leads']),
                    lostLeads: _toInt(row['lost_leads']),
                    importantLeads: _toInt(row['important_leads']),
                    pendingFollowUps: _toInt(row['pending_followups']),
                    overdueFollowUps: _toInt(row['overdue_followups']),
                    doneFollowUps: _toInt(row['done_followups']),
                    missedFollowUps: _toInt(row['missed_followups']),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }
}

class _AgentHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final String profileName;
  final String role;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const _AgentHeader({
    required this.title,
    required this.showOwnHeader,
    required this.profileName,
    required this.role,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;

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
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr('btn_refresh')),
                ),
                const SizedBox(width: 12),
                if (isWide)
                  _ProfileMenu(
                    profileName: profileName,
                    role: role,
                    onLogout: onLogout,
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') await onLogout();
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
          if (showOwnHeader) const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Compare lead ownership and follow-up workload by sales user.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
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
                style: const TextStyle(fontWeight: FontWeight.w700),
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
            if (value == 'logout') await onLogout();
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

class _OverviewGrid extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool isDesktop;

  const _OverviewGrid({
    required this.rows,
    required this.isDesktop,
  });

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalAgents = rows.length;
    final totalLeads =
    rows.fold<int>(0, (sum, row) => sum + _toInt(row['total_leads']));
    final totalWon =
    rows.fold<int>(0, (sum, row) => sum + _toInt(row['won_leads']));
    final totalPending = rows.fold<int>(
      0,
          (sum, row) => sum + _toInt(row['pending_followups']),
    );
    final totalOverdue = rows.fold<int>(
      0,
          (sum, row) => sum + _toInt(row['overdue_followups']),
    );

    final items = <_OverviewData>[
      _OverviewData(tr('agent_sales_users'), totalAgents, Icons.badge_outlined),
      _OverviewData(tr('agent_owned_leads'), totalLeads, Icons.people_outline_rounded),
      _OverviewData(tr('agent_won_leads'), totalWon, Icons.emoji_events_outlined),
      _OverviewData(
        tr('agent_pending_followups'),
        totalPending,
        Icons.schedule_rounded,
      ),
      _OverviewData(
        tr('agent_overdue_followups'),
        totalOverdue,
        Icons.warning_amber_rounded,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _OverviewCard(item: items[i])),
            if (i != items.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _OverviewCard(item: items[i]),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OverviewData {
  final String title;
  final int value;
  final IconData icon;

  const _OverviewData(this.title, this.value, this.icon);
}

class _OverviewCard extends StatelessWidget {
  final _OverviewData item;

  const _OverviewCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2B220B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: const Color(0xFFD4AF37)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30260A)),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        _LegendItem(
          color: const Color(0xFFD4AF37),
          label: tr('agent_total_leads'),
        ),
        _LegendItem(
          color: const Color(0xFF2E7D32),
          label: tr('agent_won_leads'),
        ),
        _LegendItem(
          color: const Color(0xFF1976D2),
          label: tr('agent_pending_followups'),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _AgentComparisonBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _AgentComparisonBarChart({
    required this.rows,
  });

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  String _name(Map<String, dynamic> row) {
    final name = (row['full_name'] ?? '').toString().trim();
    final email = (row['email'] ?? '').toString().trim();
    return name.isNotEmpty ? name : email;
  }

  @override
  Widget build(BuildContext context) {
    final chartRows = rows.take(6).toList();

    if (chartRows.isEmpty) {
      return Center(child: Text(tr('agent_no_data')));
    }

    final maxValue = chartRows.fold<int>(
      0,
          (max, row) {
        final total = _toInt(row['total_leads']);
        final won = _toInt(row['won_leads']);
        final pending = _toInt(row['pending_followups']);
        final localMax =
        [total, won, pending].reduce((a, b) => a > b ? a : b);
        return localMax > max ? localMax : max;
      },
    );

    final safeMaxY = maxValue <= 0 ? 5.0 : maxValue + 2;

    return BarChart(
      BarChartData(
        maxY: safeMaxY.toDouble(),
        groupsSpace: 22,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartRows.length) {
                  return const SizedBox.shrink();
                }
                final label = _name(chartRows[index]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(chartRows.length, (index) {
          final row = chartRows[index];
          final totalLeads = _toInt(row['total_leads']);
          final wonLeads = _toInt(row['won_leads']);
          final pendingFollowUps = _toInt(row['pending_followups']);

          return BarChartGroupData(
            x: index,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: totalLeads.toDouble(),
                width: 10,
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFFD4AF37),
              ),
              BarChartRodData(
                toY: wonLeads.toDouble(),
                width: 10,
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF2E7D32),
              ),
              BarChartRodData(
                toY: pendingFollowUps.toDouble(),
                width: 10,
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF1976D2),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DesktopAgentHeaderRow extends StatelessWidget {
  const _DesktopAgentHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Text(
              tr('agent_col_agent'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              tr('agent_col_total'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              tr('agent_col_won'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              tr('agent_col_pending'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              tr('agent_col_overdue'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              tr('agent_col_lead_mix'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              tr('agent_col_followup_mix'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopAgentRow extends StatelessWidget {
  final String name;
  final String email;
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int wonLeads;
  final int lostLeads;
  final int importantLeads;
  final int pendingFollowUps;
  final int overdueFollowUps;
  final int doneFollowUps;
  final int missedFollowUps;

  const _DesktopAgentRow({
    required this.name,
    required this.email,
    required this.totalLeads,
    required this.newLeads,
    required this.contactedLeads,
    required this.qualifiedLeads,
    required this.wonLeads,
    required this.lostLeads,
    required this.importantLeads,
    required this.pendingFollowUps,
    required this.overdueFollowUps,
    required this.doneFollowUps,
    required this.missedFollowUps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(flex: 10, child: _CompactValue(value: totalLeads)),
          Expanded(flex: 10, child: _CompactValue(value: wonLeads)),
          Expanded(flex: 10, child: _CompactValue(value: pendingFollowUps)),
          Expanded(flex: 10, child: _CompactValue(value: overdueFollowUps)),
          Expanded(
            flex: 18,
            child: _InlineMetrics(
              items: [
                ('N', newLeads),
                ('C', contactedLeads),
                ('Q', qualifiedLeads),
                ('L', lostLeads),
                ('I', importantLeads),
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: _InlineMetrics(
              items: [
                ('D', doneFollowUps),
                ('M', missedFollowUps),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactValue extends StatelessWidget {
  final int value;

  const _CompactValue({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value.toString(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFFD4AF37),
      ),
    );
  }
}

class _InlineMetrics extends StatelessWidget {
  final List<(String, int)> items;

  const _InlineMetrics({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF2B2B2B)),
          ),
          child: Text(
            '${item.$1}:${item.$2}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

class _MobileAgentCard extends StatelessWidget {
  final String name;
  final String email;
  final int totalLeads;
  final int newLeads;
  final int contactedLeads;
  final int qualifiedLeads;
  final int wonLeads;
  final int lostLeads;
  final int importantLeads;
  final int pendingFollowUps;
  final int overdueFollowUps;
  final int doneFollowUps;
  final int missedFollowUps;

  const _MobileAgentCard({
    required this.name,
    required this.email,
    required this.totalLeads,
    required this.newLeads,
    required this.contactedLeads,
    required this.qualifiedLeads,
    required this.wonLeads,
    required this.lostLeads,
    required this.importantLeads,
    required this.pendingFollowUps,
    required this.overdueFollowUps,
    required this.doneFollowUps,
    required this.missedFollowUps,
  });

  Widget _metric(String label, int value) {
    return SizedBox(
      width: 112,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30260A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(tr('agent_col_total'), totalLeads),
              _metric(tr('agent_col_won'), wonLeads),
              _metric(tr('agent_col_pending'), pendingFollowUps),
              _metric(tr('agent_col_overdue'), overdueFollowUps),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('agent_lead_breakdown'),
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(tr('status_new'), newLeads),
              _metric(tr('status_contacted'), contactedLeads),
              _metric(tr('status_qualified'), qualifiedLeads),
              _metric(tr('status_lost'), lostLeads),
              _metric(tr('stats_important'), importantLeads),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr('agent_followup_breakdown'),
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(tr('status_done'), doneFollowUps),
              _metric(tr('status_missed'), missedFollowUps),
            ],
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
    this.actions = const [],
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
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
