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
// //                 child: _buildBody(),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildBody() {
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
// //       child: ListView.builder(
// //         padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
// //         itemCount: _rows.length,
// //         itemBuilder: (context, index) {
// //           final row = _rows[index];
// //           return Padding(
// //             padding: const EdgeInsets.only(bottom: 14),
// //             child: _AgentPerformanceCard(
// //               name: _text(row['full_name']).isNotEmpty
// //                   ? _text(row['full_name'])
// //                   : _text(row['email']),
// //               email: _text(row['email']),
// //               totalLeads: _toInt(row['total_leads']),
// //               newLeads: _toInt(row['new_leads']),
// //               contactedLeads: _toInt(row['contacted_leads']),
// //               qualifiedLeads: _toInt(row['qualified_leads']),
// //               wonLeads: _toInt(row['won_leads']),
// //               lostLeads: _toInt(row['lost_leads']),
// //               importantLeads: _toInt(row['important_leads']),
// //               pendingFollowUps: _toInt(row['pending_followups']),
// //               overdueFollowUps: _toInt(row['overdue_followups']),
// //               doneFollowUps: _toInt(row['done_followups']),
// //               missedFollowUps: _toInt(row['missed_followups']),
// //             ),
// //           );
// //         },
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
// //                   'Per-sales-user lead and follow-up performance.',
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
// //       width: 140,
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
// //           const Text(
// //             'Leads',
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
// //               _metric('Total', totalLeads),
// //               _metric('New', newLeads),
// //               _metric('Contacted', contactedLeads),
// //               _metric('Qualified', qualifiedLeads),
// //               _metric('Won', wonLeads),
// //               _metric('Lost', lostLeads),
// //               _metric('Important', importantLeads),
// //             ],
// //           ),
// //           const SizedBox(height: 16),
// //           const Text(
// //             'Follow-ups',
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
// //               _metric('Pending', pendingFollowUps),
// //               _metric('Overdue', overdueFollowUps),
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
//     final isWide = MediaQuery.of(context).size.width >= 1100;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _AgentPerformanceHeader(
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
//         padding: EdgeInsets.fromLTRB(isWide ? 20 : 14, 16, isWide ? 20 : 14, 40),
//         children: [
//           _PerformanceOverviewRow(rows: _rows),
//           const SizedBox(height: 18),
//           _ChartPanel(
//             title: 'Top Agent Comparison',
//             child: SizedBox(
//               height: 320,
//               child: _AgentComparisonBarChart(rows: _rows),
//             ),
//           ),
//           const SizedBox(height: 18),
//           const _SectionTitle('Agent Breakdown'),
//           const SizedBox(height: 14),
//           ..._rows.map(
//                 (row) => Padding(
//               padding: const EdgeInsets.only(bottom: 14),
//               child: _AgentPerformanceCard(
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
// class _AgentPerformanceHeader extends StatelessWidget {
//   final String title;
//   final bool showOwnHeader;
//   final String profileName;
//   final String role;
//   final Future<void> Function() onRefresh;
//   final Future<void> Function() onLogout;
//
//   const _AgentPerformanceHeader({
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
//                   _AgentHeaderProfileMenu(
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
// class _AgentHeaderProfileMenu extends StatelessWidget {
//   final String profileName;
//   final String role;
//   final Future<void> Function() onLogout;
//
//   const _AgentHeaderProfileMenu({
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
// class _PerformanceOverviewRow extends StatelessWidget {
//   final List<Map<String, dynamic>> rows;
//
//   const _PerformanceOverviewRow({
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
//       _OverviewStat('Sales Users', totalAgents, Icons.badge_outlined),
//       _OverviewStat('Owned Leads', totalLeads, Icons.people_outline_rounded),
//       _OverviewStat('Won Leads', totalWon, Icons.emoji_events_outlined),
//       _OverviewStat('Pending Follow-ups', totalPending, Icons.schedule_rounded),
//       _OverviewStat('Overdue Follow-ups', totalOverdue, Icons.warning_amber_rounded),
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
// class _OverviewStat {
//   final String title;
//   final int value;
//   final IconData icon;
//
//   const _OverviewStat(this.title, this.value, this.icon);
// }
//
// class _OverviewCard extends StatelessWidget {
//   final _OverviewStat item;
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
//
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
// class _AgentPerformanceCard extends StatelessWidget {
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
//   const _AgentPerformanceCard({
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgentPerformanceScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool showOwnHeader;
  final String? customTitle;

  const AgentPerformanceScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  State<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
}

class _AgentPerformanceScreenState extends State<AgentPerformanceScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

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

  String _displayName() {
    final fullName = _text(widget.profile['full_name']);
    final email = _text(widget.profile['email']);
    return fullName.isNotEmpty ? fullName : email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _AgentHeader(
              title: widget.customTitle ?? 'Agent Performance',
              showOwnHeader: widget.showOwnHeader,
              profileName: _displayName(),
              role: _role,
              onRefresh: _loadRows,
              onLogout: widget.onLogout,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isAdmin) {
      return const _AgentAdminOnlyCard(
        message: 'Only admins can view agent performance.',
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _AgentErrorCard(
        title: 'Failed to load agent performance',
        message: _error!,
        onRetry: _loadRows,
      );
    }

    if (_rows.isEmpty) {
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
                  Icons.groups_2_outlined,
                  size: 44,
                  color: Color(0xFFD4AF37),
                ),
                SizedBox(height: 12),
                Text(
                  'No sales users found',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRows,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
        children: [
          _OverviewRow(rows: _rows),
          const SizedBox(height: 18),
          _ChartPanel(
            title: 'Top Agent Comparison',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                _ChartLegend(),
                SizedBox(height: 14),
                SizedBox(
                  height: 320,
                  child: _AgentComparisonBarChart(rows: _rows),
                ),
              ],
            ),
          ),
          // _ChartPanel(
          //   title: 'Top Agent Comparison',
          //   child: SizedBox(
          //     height: 320,
          //     child: _AgentComparisonBarChart(rows: _rows),
          //   ),
          // ),
          const SizedBox(height: 18),
          const _SectionTitle('Agent Breakdown'),
          const SizedBox(height: 14),
          ..._rows.map(
                (row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AgentCard(
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
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: const Border(bottom: BorderSide(color: Color(0xFF3A2F0B))),
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
                      colors: [Color(0xFFD4AF37), Color(0xFF8C6B16)],
                    ),
                  ),
                  child: const Icon(Icons.groups_2_outlined, color: Color(0xFF111111)),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Compare lead ownership and follow-up workload by sales user.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
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

class _OverviewRow extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _OverviewRow({
    required this.rows,
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
    final totalLeads = rows.fold<int>(0, (sum, row) => sum + _toInt(row['total_leads']));
    final totalWon = rows.fold<int>(0, (sum, row) => sum + _toInt(row['won_leads']));
    final totalPending = rows.fold<int>(0, (sum, row) => sum + _toInt(row['pending_followups']));
    final totalOverdue = rows.fold<int>(0, (sum, row) => sum + _toInt(row['overdue_followups']));

    final items = [
      _OverviewData('Sales Users', totalAgents, Icons.badge_outlined),
      _OverviewData('Owned Leads', totalLeads, Icons.people_outline_rounded),
      _OverviewData('Won Leads', totalWon, Icons.emoji_events_outlined),
      _OverviewData('Pending Follow-ups', totalPending, Icons.schedule_rounded),
      _OverviewData('Overdue Follow-ups', totalOverdue, Icons.warning_amber_rounded),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: items.map((item) => _OverviewCard(item: item)).toList(),
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
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF3A2F0B)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2B220B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: const Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(item.title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
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
      children: const [
        _LegendItem(
          color: Color(0xFFD4AF37),
          label: 'Total Leads',
        ),
        _LegendItem(
          color: Color(0xFF2E7D32),
          label: 'Won Leads',
        ),
        _LegendItem(
          color: Color(0xFF1976D2),
          label: 'Pending Follow-ups',
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
      return const Center(child: Text('No agent data yet'));
    }

    final maxValue = chartRows.fold<int>(
      0,
          (max, row) {
        final total = _toInt(row['total_leads']);
        final won = _toInt(row['won_leads']);
        final pending = _toInt(row['pending_followups']);
        final localMax = [total, won, pending].reduce((a, b) => a > b ? a : b);
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
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

  const _AgentCard({
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
      width: 128,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('Total Leads', totalLeads),
              _metric('Won Leads', wonLeads),
              _metric('Pending Follow-ups', pendingFollowUps),
              _metric('Overdue Follow-ups', overdueFollowUps),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Lead Breakdown',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('New', newLeads),
              _metric('Contacted', contactedLeads),
              _metric('Qualified', qualifiedLeads),
              _metric('Lost', lostLeads),
              _metric('Important', importantLeads),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Follow-up Breakdown',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric('Done', doneFollowUps),
              _metric('Missed', missedFollowUps),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentAdminOnlyCard extends StatelessWidget {
  final String message;

  const _AgentAdminOnlyCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 12),
              const Text(
                'Admin access only',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _AgentErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}