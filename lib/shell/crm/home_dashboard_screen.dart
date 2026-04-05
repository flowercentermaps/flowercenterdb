// // // import 'package:flutter/material.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // //
// // // class HomeDashboardScreen extends StatefulWidget {
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //   final bool showOwnHeader;
// // //   final String? customTitle;
// // //
// // //   const HomeDashboardScreen({
// // //     super.key,
// // //     required this.profile,
// // //     required this.onLogout,
// // //     this.showOwnHeader = true,
// // //     this.customTitle,
// // //   });
// // //
// // //   @override
// // //   State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
// // // }
// // //
// // // class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
// // //   final SupabaseClient _supabase = Supabase.instance.client;
// // //
// // //   bool _isLoading = true;
// // //   String? _error;
// // //   Map<String, dynamic>? _leadStats;
// // //   Map<String, dynamic>? _followUpStats;
// // //
// // //   String get _role =>
// // //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// // //
// // //   bool get _isAdmin => _role == 'admin';
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadDashboard();
// // //   }
// // //
// // //   Future<void> _loadDashboard() async {
// // //     setState(() {
// // //       _isLoading = true;
// // //       _error = null;
// // //     });
// // //
// // //     try {
// // //       final leadResponse = await _supabase
// // //           .from('crm_statistics_view')
// // //           .select()
// // //           .limit(1)
// // //           .maybeSingle();
// // //
// // //       final followUpResponse = await _supabase
// // //           .from('crm_followup_statistics_view')
// // //           .select()
// // //           .limit(1)
// // //           .maybeSingle();
// // //
// // //       if (!mounted) return;
// // //
// // //       setState(() {
// // //         _leadStats = leadResponse == null
// // //             ? <String, dynamic>{}
// // //             : Map<String, dynamic>.from(leadResponse);
// // //         _followUpStats = followUpResponse == null
// // //             ? <String, dynamic>{}
// // //             : Map<String, dynamic>.from(followUpResponse);
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
// // //   String _displayName() {
// // //     final fullName = (widget.profile['full_name'] ?? '').toString().trim();
// // //     final email = (widget.profile['email'] ?? '').toString().trim();
// // //     return fullName.isNotEmpty ? fullName : email;
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isWide = MediaQuery.of(context).size.width >= 980;
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFF0A0A0A),
// // //       body: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             _HomeDashboardHeader(
// // //               title: widget.customTitle ?? 'Home',
// // //               showOwnHeader: widget.showOwnHeader,
// // //               profileName: _displayName(),
// // //               role: _role,
// // //               onRefresh: _loadDashboard,
// // //               onLogout: widget.onLogout,
// // //             ),
// // //             Expanded(
// // //               child: AnimatedSwitcher(
// // //                 duration: const Duration(milliseconds: 220),
// // //                 child: _buildBody(isWide),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildBody(bool isWide) {
// // //     if (_isLoading) {
// // //       return const Center(child: CircularProgressIndicator());
// // //     }
// // //
// // //     if (_error != null) {
// // //       return _HomeErrorCard(
// // //         title: 'Failed to load dashboard',
// // //         message: _error!,
// // //         onRetry: _loadDashboard,
// // //       );
// // //     }
// // //
// // //     final leadStats = _leadStats ?? {};
// // //     final followUpStats = _followUpStats ?? {};
// // //
// // //     final totalLeads = _toInt(leadStats['total_leads']);
// // //     final importantLeads = _toInt(leadStats['important_leads']);
// // //     final pendingFollowUps = _toInt(followUpStats['pending_followups']);
// // //     final overdueFollowUps = _toInt(followUpStats['overdue_followups']);
// // //
// // //     final leadCards = [
// // //       _DashboardStatData('Total Leads', totalLeads, Icons.people_outline_rounded),
// // //       _DashboardStatData('Important Leads', importantLeads, Icons.star_outline_rounded),
// // //       _DashboardStatData('Pending Follow-ups', pendingFollowUps, Icons.schedule_rounded),
// // //       _DashboardStatData('Overdue Follow-ups', overdueFollowUps, Icons.warning_amber_rounded),
// // //     ];
// // //
// // //     return RefreshIndicator(
// // //       onRefresh: _loadDashboard,
// // //       child: ListView(
// // //         padding: EdgeInsets.fromLTRB(isWide ? 20 : 14, 16, isWide ? 20 : 14, 40),
// // //         children: [
// // //           Wrap(
// // //             spacing: 14,
// // //             runSpacing: 14,
// // //             children: leadCards
// // //                 .map((item) => _DashboardStatCard(
// // //               data: item,
// // //               width: isWide ? 250 : double.infinity,
// // //             ))
// // //                 .toList(),
// // //           ),
// // //           const SizedBox(height: 18),
// // //           isWide
// // //               ? Row(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Expanded(
// // //                 child: _SummaryPanel(
// // //                   title: 'Pipeline Snapshot',
// // //                   items: [
// // //                     _SummaryLine('New', _toInt(leadStats['new_leads'])),
// // //                     _SummaryLine('Contacted', _toInt(leadStats['contacted_leads'])),
// // //                     _SummaryLine('Qualified', _toInt(leadStats['qualified_leads'])),
// // //                     _SummaryLine('Won', _toInt(leadStats['won_leads'])),
// // //                     _SummaryLine('Lost', _toInt(leadStats['lost_leads'])),
// // //                   ],
// // //                 ),
// // //               ),
// // //               const SizedBox(width: 14),
// // //               Expanded(
// // //                 child: _SummaryPanel(
// // //                   title: 'Follow-up Snapshot',
// // //                   items: [
// // //                     _SummaryLine('Pending', _toInt(followUpStats['pending_followups'])),
// // //                     _SummaryLine('Overdue', _toInt(followUpStats['overdue_followups'])),
// // //                     _SummaryLine('Done', _toInt(followUpStats['done_followups'])),
// // //                     _SummaryLine('Missed', _toInt(followUpStats['missed_followups'])),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           )
// // //               : Column(
// // //             children: [
// // //               _SummaryPanel(
// // //                 title: 'Pipeline Snapshot',
// // //                 items: [
// // //                   _SummaryLine('New', _toInt(leadStats['new_leads'])),
// // //                   _SummaryLine('Contacted', _toInt(leadStats['contacted_leads'])),
// // //                   _SummaryLine('Qualified', _toInt(leadStats['qualified_leads'])),
// // //                   _SummaryLine('Won', _toInt(leadStats['won_leads'])),
// // //                   _SummaryLine('Lost', _toInt(leadStats['lost_leads'])),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 14),
// // //               _SummaryPanel(
// // //                 title: 'Follow-up Snapshot',
// // //                 items: [
// // //                   _SummaryLine('Pending', _toInt(followUpStats['pending_followups'])),
// // //                   _SummaryLine('Overdue', _toInt(followUpStats['overdue_followups'])),
// // //                   _SummaryLine('Done', _toInt(followUpStats['done_followups'])),
// // //                   _SummaryLine('Missed', _toInt(followUpStats['missed_followups'])),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 18),
// // //           const _DashboardInfoCard(),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _HomeDashboardHeader extends StatelessWidget {
// // //   final String title;
// // //   final bool showOwnHeader;
// // //   final String profileName;
// // //   final String role;
// // //   final Future<void> Function() onRefresh;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _HomeDashboardHeader({
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
// // //                   child: const Icon(Icons.dashboard_outlined, color: Color(0xFF111111)),
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
// // //                   _HomeProfileMenu(
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
// // //                   'Quick overview of leads and follow-up workload.',
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
// // // class _HomeProfileMenu extends StatelessWidget {
// // //   final String profileName;
// // //   final String role;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _HomeProfileMenu({
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
// // // class _DashboardStatData {
// // //   final String title;
// // //   final int value;
// // //   final IconData icon;
// // //
// // //   const _DashboardStatData(this.title, this.value, this.icon);
// // // }
// // //
// // // class _DashboardStatCard extends StatelessWidget {
// // //   final _DashboardStatData data;
// // //   final double width;
// // //
// // //   const _DashboardStatCard({
// // //     required this.data,
// // //     required this.width,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return SizedBox(
// // //       width: width == double.infinity ? null : width,
// // //       child: Container(
// // //         constraints: const BoxConstraints(minHeight: 110, minWidth: 220),
// // //         padding: const EdgeInsets.all(18),
// // //         decoration: BoxDecoration(
// // //           color: const Color(0xFF141414),
// // //           borderRadius: BorderRadius.circular(22),
// // //           border: Border.all(color: const Color(0xFF3A2F0B)),
// // //         ),
// // //         child: Row(
// // //           children: [
// // //             Container(
// // //               width: 46,
// // //               height: 46,
// // //               decoration: BoxDecoration(
// // //                 color: const Color(0xFF2B220B),
// // //                 borderRadius: BorderRadius.circular(14),
// // //               ),
// // //               child: Icon(data.icon, color: const Color(0xFFD4AF37)),
// // //             ),
// // //             const SizedBox(width: 14),
// // //             Expanded(
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     data.value.toString(),
// // //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 4),
// // //                   Text(data.title),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _SummaryLine {
// // //   final String label;
// // //   final int value;
// // //
// // //   const _SummaryLine(this.label, this.value);
// // // }
// // //
// // // class _SummaryPanel extends StatelessWidget {
// // //   final String title;
// // //   final List<_SummaryLine> items;
// // //
// // //   const _SummaryPanel({
// // //     required this.title,
// // //     required this.items,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: double.infinity,
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
// // //             title,
// // //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// // //               fontWeight: FontWeight.w900,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 14),
// // //           ...items.map(
// // //                 (item) => Padding(
// // //               padding: const EdgeInsets.only(bottom: 10),
// // //               child: Row(
// // //                 children: [
// // //                   Expanded(child: Text(item.label)),
// // //                   Text(
// // //                     item.value.toString(),
// // //                     style: const TextStyle(
// // //                       fontWeight: FontWeight.w900,
// // //                       color: Color(0xFFD4AF37),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _DashboardInfoCard extends StatelessWidget {
// // //   const _DashboardInfoCard();
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: double.infinity,
// // //       padding: const EdgeInsets.all(18),
// // //       decoration: BoxDecoration(
// // //         color: const Color(0xFF141414),
// // //         borderRadius: BorderRadius.circular(22),
// // //         border: Border.all(color: const Color(0xFF3A2F0B)),
// // //       ),
// // //       child: const Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Text(
// // //             'How to use this dashboard',
// // //             style: TextStyle(
// // //               fontSize: 18,
// // //               fontWeight: FontWeight.w900,
// // //             ),
// // //           ),
// // //           SizedBox(height: 10),
// // //           Text('Leads tracks the sales pipeline.'),
// // //           SizedBox(height: 6),
// // //           Text('Follow Up tracks action tasks and deadlines.'),
// // //           SizedBox(height: 6),
// // //           Text('Statistics and Agent Performance give the full admin breakdown.'),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _HomeErrorCard extends StatelessWidget {
// // //   final String title;
// // //   final String message;
// // //   final Future<void> Function() onRetry;
// // //
// // //   const _HomeErrorCard({
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
// // class HomeDashboardScreen extends StatefulWidget {
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final bool showOwnHeader;
// //   final String? customTitle;
// //
// //   const HomeDashboardScreen({
// //     super.key,
// //     required this.profile,
// //     required this.onLogout,
// //     this.showOwnHeader = true,
// //     this.customTitle,
// //   });
// //
// //   @override
// //   State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
// // }
// //
// // class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //
// //   bool _isLoading = true;
// //   String? _error;
// //   Map<String, dynamic>? _leadStats;
// //   Map<String, dynamic>? _followUpStats;
// //
// //   String get _role =>
// //       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadDashboard();
// //   }
// //
// //   Future<void> _loadDashboard() async {
// //     setState(() {
// //       _isLoading = true;
// //       _error = null;
// //     });
// //
// //     try {
// //       final leadResponse = await _supabase
// //           .from('crm_statistics_view')
// //           .select()
// //           .limit(1)
// //           .maybeSingle();
// //
// //       final followUpResponse = await _supabase
// //           .from('crm_followup_statistics_view')
// //           .select()
// //           .limit(1)
// //           .maybeSingle();
// //
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _leadStats = leadResponse == null
// //             ? <String, dynamic>{}
// //             : Map<String, dynamic>.from(leadResponse);
// //         _followUpStats = followUpResponse == null
// //             ? <String, dynamic>{}
// //             : Map<String, dynamic>.from(followUpResponse);
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
// //   String _displayName() {
// //     final fullName = (widget.profile['full_name'] ?? '').toString().trim();
// //     final email = (widget.profile['email'] ?? '').toString().trim();
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
// //             _HomeDashboardHeader(
// //               title: widget.customTitle ?? 'Home',
// //               showOwnHeader: widget.showOwnHeader,
// //               profileName: _displayName(),
// //               role: _role,
// //               onRefresh: _loadDashboard,
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
// //     if (_isLoading) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (_error != null) {
// //       return _HomeErrorCard(
// //         title: 'Failed to load dashboard',
// //         message: _error!,
// //         onRetry: _loadDashboard,
// //       );
// //     }
// //
// //     final leadStats = _leadStats ?? {};
// //     final followUpStats = _followUpStats ?? {};
// //
// //     final totalLeads = _toInt(leadStats['total_leads']);
// //     final importantLeads = _toInt(leadStats['important_leads']);
// //     final pendingFollowUps = _toInt(followUpStats['pending_followups']);
// //     final overdueFollowUps = _toInt(followUpStats['overdue_followups']);
// //
// //     final newLeads = _toInt(leadStats['new_leads']);
// //     final contactedLeads = _toInt(leadStats['contacted_leads']);
// //     final qualifiedLeads = _toInt(leadStats['qualified_leads']);
// //     final wonLeads = _toInt(leadStats['won_leads']);
// //     final lostLeads = _toInt(leadStats['lost_leads']);
// //
// //     final doneFollowUps = _toInt(followUpStats['done_followups']);
// //     final missedFollowUps = _toInt(followUpStats['missed_followups']);
// //
// //     final kpis = [
// //       _DashboardStatData('Total Leads', totalLeads, Icons.people_outline_rounded),
// //       _DashboardStatData('Important Leads', importantLeads, Icons.star_outline_rounded),
// //       _DashboardStatData('Pending Follow-ups', pendingFollowUps, Icons.schedule_rounded),
// //       _DashboardStatData('Overdue Follow-ups', overdueFollowUps, Icons.warning_amber_rounded),
// //     ];
// //
// //     return RefreshIndicator(
// //       onRefresh: _loadDashboard,
// //       child: ListView(
// //         padding: EdgeInsets.fromLTRB(isWide ? 20 : 14, 16, isWide ? 20 : 14, 40),
// //         children: [
// //           Wrap(
// //             spacing: 14,
// //             runSpacing: 14,
// //             children: kpis
// //                 .map((item) => _DashboardStatCard(
// //               data: item,
// //               width: isWide ? 250 : double.infinity,
// //             ))
// //                 .toList(),
// //           ),
// //           const SizedBox(height: 18),
// //           isWide
// //               ? Row(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Expanded(
// //                 child: _ChartPanel(
// //                   title: 'Lead Stage Distribution',
// //                   child: SizedBox(
// //                     height: 280,
// //                     child: _LeadStageDonutChart(
// //                       newLeads: newLeads,
// //                       contactedLeads: contactedLeads,
// //                       qualifiedLeads: qualifiedLeads,
// //                       wonLeads: wonLeads,
// //                       lostLeads: lostLeads,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(width: 14),
// //               Expanded(
// //                 child: _ChartPanel(
// //                   title: 'Follow-up Workload',
// //                   child: SizedBox(
// //                     height: 280,
// //                     child: _FollowUpBarChart(
// //                       pending: pendingFollowUps,
// //                       overdue: overdueFollowUps,
// //                       done: doneFollowUps,
// //                       missed: missedFollowUps,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           )
// //               : Column(
// //             children: [
// //               _ChartPanel(
// //                 title: 'Lead Stage Distribution',
// //                 child: SizedBox(
// //                   height: 280,
// //                   child: _LeadStageDonutChart(
// //                     newLeads: newLeads,
// //                     contactedLeads: contactedLeads,
// //                     qualifiedLeads: qualifiedLeads,
// //                     wonLeads: wonLeads,
// //                     lostLeads: lostLeads,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 14),
// //               _ChartPanel(
// //                 title: 'Follow-up Workload',
// //                 child: SizedBox(
// //                   height: 280,
// //                   child: _FollowUpBarChart(
// //                     pending: pendingFollowUps,
// //                     overdue: overdueFollowUps,
// //                     done: doneFollowUps,
// //                     missed: missedFollowUps,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 18),
// //           isWide
// //               ? Row(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               const Expanded(child: _QuickActionsPanel()),
// //               const SizedBox(width: 14),
// //               const Expanded(child: _DashboardInfoCard()),
// //             ],
// //           )
// //               : const Column(
// //             children: [
// //               _QuickActionsPanel(),
// //               SizedBox(height: 14),
// //               _DashboardInfoCard(),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _HomeDashboardHeader extends StatelessWidget {
// //   final String title;
// //   final bool showOwnHeader;
// //   final String profileName;
// //   final String role;
// //   final Future<void> Function() onRefresh;
// //   final Future<void> Function() onLogout;
// //
// //   const _HomeDashboardHeader({
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
// //                   child: const Icon(Icons.dashboard_outlined, color: Color(0xFF111111)),
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
// //                   _HomeProfileMenu(
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
// //                   'Quick overview of leads and follow-up workload.',
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
// // class _HomeProfileMenu extends StatelessWidget {
// //   final String profileName;
// //   final String role;
// //   final Future<void> Function() onLogout;
// //
// //   const _HomeProfileMenu({
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
// // class _DashboardStatData {
// //   final String title;
// //   final int value;
// //   final IconData icon;
// //
// //   const _DashboardStatData(this.title, this.value, this.icon);
// // }
// //
// // class _DashboardStatCard extends StatelessWidget {
// //   final _DashboardStatData data;
// //   final double width;
// //
// //   const _DashboardStatCard({
// //     required this.data,
// //     required this.width,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox(
// //       width: width == double.infinity ? null : width,
// //       child: Container(
// //         constraints: const BoxConstraints(minHeight: 110, minWidth: 220),
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
// //               child: Icon(data.icon, color: const Color(0xFFD4AF37)),
// //             ),
// //             const SizedBox(width: 14),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     data.value.toString(),
// //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(data.title),
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
// // class _LeadStageDonutChart extends StatelessWidget {
// //   final int newLeads;
// //   final int contactedLeads;
// //   final int qualifiedLeads;
// //   final int wonLeads;
// //   final int lostLeads;
// //
// //   const _LeadStageDonutChart({
// //     required this.newLeads,
// //     required this.contactedLeads,
// //     required this.qualifiedLeads,
// //     required this.wonLeads,
// //     required this.lostLeads,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final sections = [
// //       _ChartLegendItem('New', newLeads, const Color(0xFFD4AF37)),
// //       _ChartLegendItem('Contacted', contactedLeads, const Color(0xFF1976D2)),
// //       _ChartLegendItem('Qualified', qualifiedLeads, const Color(0xFF2E7D32)),
// //       _ChartLegendItem('Won', wonLeads, const Color(0xFF00A86B)),
// //       _ChartLegendItem('Lost', lostLeads, const Color(0xFFB00020)),
// //     ];
// //
// //     final total = sections.fold<int>(0, (sum, item) => sum + item.value);
// //
// //     if (total == 0) {
// //       return const Center(child: Text('No lead data yet'));
// //     }
// //
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: PieChart(
// //             PieChartData(
// //               centerSpaceRadius: 48,
// //               sectionsSpace: 3,
// //               sections: sections
// //                   .where((item) => item.value > 0)
// //                   .map(
// //                     (item) => PieChartSectionData(
// //                   value: item.value.toDouble(),
// //                   title: '',
// //                   radius: 52,
// //                   color: item.color,
// //                 ),
// //               )
// //                   .toList(),
// //             ),
// //           ),
// //         ),
// //         const SizedBox(width: 16),
// //         Expanded(
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: sections
// //                 .map((item) => _LegendRow(item: item))
// //                 .toList(),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // class _FollowUpBarChart extends StatelessWidget {
// //   final int pending;
// //   final int overdue;
// //   final int done;
// //   final int missed;
// //
// //   const _FollowUpBarChart({
// //     required this.pending,
// //     required this.overdue,
// //     required this.done,
// //     required this.missed,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final values = [pending, overdue, done, missed];
// //     final maxY = (values.reduce((a, b) => a > b ? a : b)).toDouble();
// //     final safeMaxY = maxY <= 0 ? 5.0 : maxY + 2;
// //
// //     return BarChart(
// //       BarChartData(
// //         maxY: safeMaxY,
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
// //               getTitlesWidget: (value, meta) {
// //                 const labels = ['Pending', 'Overdue', 'Done', 'Missed'];
// //                 return Padding(
// //                   padding: const EdgeInsets.only(top: 8),
// //                   child: Text(
// //                     labels[value.toInt()],
// //                     style: const TextStyle(fontSize: 11),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ),
// //         barGroups: [
// //           _bar(0, pending, const Color(0xFF1976D2)),
// //           _bar(1, overdue, const Color(0xFFFF8F00)),
// //           _bar(2, done, const Color(0xFF2E7D32)),
// //           _bar(3, missed, const Color(0xFFB00020)),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   BarChartGroupData _bar(int x, int value, Color color) {
// //     return BarChartGroupData(
// //       x: x,
// //       barRods: [
// //         BarChartRodData(
// //           toY: value.toDouble(),
// //           width: 22,
// //           borderRadius: BorderRadius.circular(6),
// //           color: color,
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // class _ChartLegendItem {
// //   final String label;
// //   final int value;
// //   final Color color;
// //
// //   const _ChartLegendItem(this.label, this.value, this.color);
// // }
// //
// // class _LegendRow extends StatelessWidget {
// //   final _ChartLegendItem item;
// //
// //   const _LegendRow({
// //     required this.item,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 10),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 12,
// //             height: 12,
// //             decoration: BoxDecoration(
// //               color: item.color,
// //               borderRadius: BorderRadius.circular(99),
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(child: Text(item.label)),
// //           Text(
// //             item.value.toString(),
// //             style: const TextStyle(
// //               fontWeight: FontWeight.w900,
// //               color: Color(0xFFD4AF37),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _QuickActionsPanel extends StatelessWidget {
// //   const _QuickActionsPanel();
// //
// //   Widget _actionButton({
// //     required IconData icon,
// //     required String label,
// //   }) {
// //     return SizedBox(
// //       width: 160,
// //       child: OutlinedButton.icon(
// //         onPressed: null,
// //         icon: Icon(icon),
// //         label: Text(label),
// //       ),
// //     );
// //   }
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
// //             'Quick Actions',
// //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //               fontWeight: FontWeight.w900,
// //             ),
// //           ),
// //           const SizedBox(height: 14),
// //           Wrap(
// //             spacing: 10,
// //             runSpacing: 10,
// //             children: [
// //               _actionButton(icon: Icons.people_alt_outlined, label: 'Open Leads'),
// //               _actionButton(icon: Icons.reply_all_rounded, label: 'Open Follow Up'),
// //               _actionButton(icon: Icons.share_outlined, label: 'Open Assignments'),
// //               _actionButton(icon: Icons.inventory_2_outlined, label: 'Open Products'),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _DashboardInfoCard extends StatelessWidget {
// //   const _DashboardInfoCard();
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
// //       child: const Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             'How to use this dashboard',
// //             style: TextStyle(
// //               fontSize: 18,
// //               fontWeight: FontWeight.w900,
// //             ),
// //           ),
// //           SizedBox(height: 10),
// //           Text('Leads tracks the pipeline stage of each lead.'),
// //           SizedBox(height: 6),
// //           Text('Follow Up tracks action tasks and deadlines.'),
// //           SizedBox(height: 6),
// //           Text('Use Statistics and Agent Performance for deeper admin analysis.'),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _HomeErrorCard extends StatelessWidget {
// //   final String title;
// //   final String message;
// //   final Future<void> Function() onRetry;
// //
// //   const _HomeErrorCard({
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
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class HomeDashboardScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final bool showOwnHeader;
//   final String? customTitle;
//
//   const HomeDashboardScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//     this.showOwnHeader = true,
//     this.customTitle,
//   });
//
//   @override
//   State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
// }
//
// class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   bool _isLoading = true;
//   String? _error;
//   Map<String, dynamic>? _leadStats;
//   Map<String, dynamic>? _followUpStats;
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDashboard();
//   }
//
//   Future<void> _loadDashboard() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final leadResponse = await _supabase
//           .from('crm_statistics_view')
//           .select()
//           .limit(1)
//           .maybeSingle();
//
//       final followUpResponse = await _supabase
//           .from('crm_followup_statistics_view')
//           .select()
//           .limit(1)
//           .maybeSingle();
//
//       if (!mounted) return;
//
//       setState(() {
//         _leadStats = leadResponse == null
//             ? <String, dynamic>{}
//             : Map<String, dynamic>.from(leadResponse);
//         _followUpStats = followUpResponse == null
//             ? <String, dynamic>{}
//             : Map<String, dynamic>.from(followUpResponse);
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
//   String _displayName() {
//     final fullName = (widget.profile['full_name'] ?? '').toString().trim();
//     final email = (widget.profile['email'] ?? '').toString().trim();
//     return fullName.isNotEmpty ? fullName : email;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWide = MediaQuery.of(context).size.width >= 980;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _HomeHeader(
//               title: widget.customTitle ?? 'Home',
//               showOwnHeader: widget.showOwnHeader,
//               profileName: _displayName(),
//               role: _role,
//               onRefresh: _loadDashboard,
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
//       return _ErrorCard(
//         title: 'Failed to load dashboard',
//         message: _error!,
//         onRetry: _loadDashboard,
//       );
//     }
//
//     final leadStats = _leadStats ?? {};
//     final followUpStats = _followUpStats ?? {};
//
//     final cards = [
//       _KpiData('Total Leads', _toInt(leadStats['total_leads']), Icons.people_outline_rounded),
//       _KpiData('Won Leads', _toInt(leadStats['won_leads']), Icons.emoji_events_outlined),
//       _KpiData('Pending Follow-ups', _toInt(followUpStats['pending_followups']), Icons.schedule_rounded),
//       _KpiData('Overdue Follow-ups', _toInt(followUpStats['overdue_followups']), Icons.warning_amber_rounded),
//     ];
//
//     return RefreshIndicator(
//       onRefresh: _loadDashboard,
//       child: ListView(
//         padding: EdgeInsets.fromLTRB(isWide ? 20 : 14, 16, isWide ? 20 : 14, 40),
//         children: [
//           Wrap(
//             alignment: .center,
//             spacing: 14,
//             runSpacing: 14,
//             children: cards
//                 .map((item) => _KpiCard(
//               data: item,
//               width: isWide ? 250 : double.infinity,
//             ))
//                 .toList(),
//           ),
//           const SizedBox(height: 18),
//           isWide
//               // ? Column(
//               //   children: [
//               //     const Row(
//               //                 crossAxisAlignment: CrossAxisAlignment.start,
//               //                 children: [
//               //     Expanded(child: _QuickActionsPanel()),
//               //     SizedBox(width: 14),
//               //                 ],
//               //               ),
//               //     Expanded(child: _AttentionPanel()),
//               //   ],
//               // )
//               ? const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(child: _QuickActionsPanel()),
//                 ],
//               ),
//               SizedBox(height: 14),
//               _AttentionPanel(),
//             ],
//           )
//               : const Column(
//             children: [
//               _QuickActionsPanel(),
//               SizedBox(height: 14),
//               _AttentionPanel(),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _HomeHeader extends StatelessWidget {
//   final String title;
//   final bool showOwnHeader;
//   final String profileName;
//   final String role;
//   final Future<void> Function() onRefresh;
//   final Future<void> Function() onLogout;
//
//   const _HomeHeader({
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
//                   child: const Icon(Icons.dashboard_outlined, color: Color(0xFF111111)),
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
//                   'Operational dashboard for what needs attention now.',
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
// class _KpiData {
//   final String title;
//   final int value;
//   final IconData icon;
//
//   const _KpiData(this.title, this.value, this.icon);
// }
//
// class _KpiCard extends StatelessWidget {
//   final _KpiData data;
//   final double width;
//
//   const _KpiCard({
//     required this.data,
//     required this.width,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width == double.infinity ? null : width,
//       child: Container(
//         constraints: const BoxConstraints(minHeight: 110, minWidth: 220),
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
//               child: Icon(data.icon, color: const Color(0xFFD4AF37)),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     data.value.toString(),
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(data.title),
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
// class _QuickActionsPanel extends StatelessWidget {
//   const _QuickActionsPanel();
//
//   Widget _action({
//     required IconData icon,
//     required String label,
//   }) {
//     return SizedBox(
//       // width: 160,
//       child: OutlinedButton.icon(
//         onPressed: null,
//         icon: Icon(icon),
//         label: Text(label),
//       ),
//     );
//   }
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
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             'Quick Actions',
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           const SizedBox(height: 14),
//           Wrap(
//             alignment: .center,
//             spacing: 10,
//             runSpacing: 10,
//             children: [
//               _action(icon: Icons.person_add_alt_1_outlined, label: 'New Lead'),
//               _action(icon: Icons.people_alt_outlined, label: 'Open Leads'),
//               _action(icon: Icons.reply_all_rounded, label: 'Open Follow Up'),
//               _action(icon: Icons.share_outlined, label: 'Assignments'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _AttentionPanel extends StatelessWidget {
//   const _AttentionPanel();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       margin: EdgeInsets.only(top: 100),
//       // decoration: BoxDecoration(
//       //   color: const Color(0xFF141414),
//       //   borderRadius: BorderRadius.circular(22),
//       //   border: Border.all(color: const Color(0xFF3A2F0B)),
//       // ),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             'Attention',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           SizedBox(height: 12),
//           Text('Use this page as a launchpad, not a full analytics report.',),
//           SizedBox(height: 6),
//           Text('Deep charts and system-wide breakdowns belong in Statistics.'),
//           SizedBox(height: 6),
//           Text('Team comparison belongs in Agent Performance.'),
//         ],
//       ),
//     );
//   }
// }
//
// class _ErrorCard extends StatelessWidget {
//   final String title;
//   final String message;
//   final Future<void> Function() onRetry;
//
//   const _ErrorCard({
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool showOwnHeader;
  final String? customTitle;

  const HomeDashboardScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _leadStats;
  Map<String, dynamic>? _followUpStats;

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leadResponse = await _supabase
          .from('crm_statistics_view')
          .select()
          .limit(1)
          .maybeSingle();

      final followUpResponse = await _supabase
          .from('crm_followup_statistics_view')
          .select()
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _leadStats = leadResponse == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(leadResponse);
        _followUpStats = followUpResponse == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(followUpResponse);
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

  String _displayName() {
    final fullName = (widget.profile['full_name'] ?? '').toString().trim();
    final email = (widget.profile['email'] ?? '').toString().trim();
    return fullName.isNotEmpty ? fullName : email;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              title: widget.customTitle ?? 'Home',
              showOwnHeader: widget.showOwnHeader,
              profileName: _displayName(),
              role: _role,
              onRefresh: _loadDashboard,
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
        title: 'Failed to load dashboard',
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final leadStats = _leadStats ?? {};
    final followUpStats = _followUpStats ?? {};

    final totalLeads = _toInt(leadStats['total_leads']);
    final importantLeads = _toInt(leadStats['important_leads']);
    final wonLeads = _toInt(leadStats['won_leads']);
    final newLeads = _toInt(leadStats['new_leads']);
    final contactedLeads = _toInt(leadStats['contacted_leads']);
    final qualifiedLeads = _toInt(leadStats['qualified_leads']);
    final lostLeads = _toInt(leadStats['lost_leads']);

    final pendingFollowUps = _toInt(followUpStats['pending_followups']);
    final overdueFollowUps = _toInt(followUpStats['overdue_followups']);
    final doneFollowUps = _toInt(followUpStats['done_followups']);
    final missedFollowUps = _toInt(followUpStats['missed_followups']);

    final cards = <_KpiData>[
      _KpiData('Total Leads', totalLeads, Icons.people_outline_rounded),
      _KpiData('Won Leads', wonLeads, Icons.emoji_events_outlined),
      _KpiData(
        'Pending Follow-ups',
        pendingFollowUps,
        Icons.schedule_rounded,
      ),
      _KpiData(
        'Overdue Follow-ups',
        overdueFollowUps,
        Icons.warning_amber_rounded,
      ),
    ];

    final pipelineSnapshot = <_SummaryLine>[
      _SummaryLine('New', newLeads),
      _SummaryLine('Contacted', contactedLeads),
      _SummaryLine('Qualified', qualifiedLeads),
      _SummaryLine('Won', wonLeads),
      _SummaryLine('Lost', lostLeads),
      _SummaryLine('Important', importantLeads),
    ];

    final followUpSnapshot = <_SummaryLine>[
      _SummaryLine('Pending', pendingFollowUps),
      _SummaryLine('Overdue', overdueFollowUps),
      _SummaryLine('Done', doneFollowUps),
      _SummaryLine('Missed', missedFollowUps),
    ];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 14,
          14,
          isDesktop ? 20 : 14,
          28,
        ),
        children: [
          _KpiGrid(
            items: cards,
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 14),
          isDesktop
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  title: 'Quick Actions',
                  subtitle: 'Fast entry points to the main CRM work',
                  child: const _QuickActionsPanel(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Panel(
                  title: 'Attention',
                  subtitle: 'What this page is for',
                  child: const _AttentionPanel(),
                ),
              ),
            ],
          )
              : Column(
            children: [
              _Panel(
                title: 'Quick Actions',
                subtitle: 'Fast entry points to the main CRM work',
                child: const _QuickActionsPanel(),
              ),
              const SizedBox(height: 14),
              _Panel(
                title: 'Attention',
                subtitle: 'What this page is for',
                child: const _AttentionPanel(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          isDesktop
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryPanel(
                  title: 'Pipeline Snapshot',
                  items: pipelineSnapshot,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryPanel(
                  title: 'Follow-up Snapshot',
                  items: followUpSnapshot,
                ),
              ),
            ],
          )
              : Column(
            children: [
              _SummaryPanel(
                title: 'Pipeline Snapshot',
                items: pipelineSnapshot,
              ),
              const SizedBox(height: 14),
              _SummaryPanel(
                title: 'Follow-up Snapshot',
                items: followUpSnapshot,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final String profileName;
  final String role;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const _HomeHeader({
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
                  label: const Text('Refresh'),
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
          if (showOwnHeader) const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Operational dashboard for what needs attention now.',
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

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> items;
  final bool isDesktop;

  const _KpiGrid({
    required this.items,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _KpiCard(data: items[i])),
            if (i != items.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _KpiCard(data: items[i]),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _KpiData {
  final String title;
  final int value;
  final IconData icon;

  const _KpiData(this.title, this.value, this.icon);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({
    required this.data,
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
            child: Icon(data.icon, color: const Color(0xFFD4AF37)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
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

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  Widget _action({
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _action(
          icon: Icons.person_add_alt_1_outlined,
          label: 'New Lead',
        ),
        _action(
          icon: Icons.people_alt_outlined,
          label: 'Open Leads',
        ),
        _action(
          icon: Icons.reply_all_rounded,
          label: 'Open Follow Up',
        ),
        _action(
          icon: Icons.share_outlined,
          label: 'Assignments',
        ),
      ],
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine('Use this page as a launchpad, not a full analytics report.'),
        SizedBox(height: 8),
        _InfoLine('Deep charts and system-wide breakdowns belong in Statistics.'),
        SizedBox(height: 8),
        _InfoLine('Team comparison belongs in Agent Performance.'),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 7,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine {
  final String label;
  final int value;

  const _SummaryLine(this.label, this.value);
}

class _SummaryPanel extends StatelessWidget {
  final String title;
  final List<_SummaryLine> items;

  const _SummaryPanel({
    required this.title,
    required this.items,
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
          const SizedBox(height: 12),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    item.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
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