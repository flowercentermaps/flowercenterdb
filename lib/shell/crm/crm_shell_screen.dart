// // // import 'package:flowercenterdb/shell/crm/shared_leads_screen.dart';
// // // import 'package:flowercenterdb/shell/crm/statistics_screen.dart';
// // // import 'package:flutter/material.dart';
// // //
// // // import '../../core/constants/app_constants.dart';
// // // import '../../price_list_screen.dart';
// // // import '../../user_role_management_screen.dart';
// // // import 'agent_performance_screen.dart';
// // // import 'follow_up_screen.dart';
// // // import 'home_dashboard_screen.dart';
// // // import 'important_leads_screen.dart';
// // // import 'leads_screen.dart';
// // // import 'notifications_screen.dart';
// // //
// // //
// // // class CrmShellScreen extends StatefulWidget {
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const CrmShellScreen({
// // //     super.key,
// // //     required this.profile,
// // //     required this.onLogout,
// // //   });
// // //
// // //   @override
// // //   State<CrmShellScreen> createState() => _CrmShellScreenState();
// // // }
// // //
// // // class _CrmShellScreenState extends State<CrmShellScreen> {
// // //   int _selectedIndex = 0;
// // //
// // //   String get _role => (widget.profile['role'] ?? '')
// // //       .toString()
// // //       .trim()
// // //       .toLowerCase();
// // //
// // //   bool get _isAdmin => _role == 'admin';
// // //   bool get _isSales => _role == 'sales';
// // //   bool get _isViewer => _role == 'viewer';
// // //   bool get _isAccountant => _role == 'accountant';
// // //
// // //   bool get _canAssignLeads =>
// // //       _isAdmin && widget.profile['can_assign_leads'] == true;
// // //
// // //   List<_CrmNavItem> get _items {
// // //     final items = <_CrmNavItem>[
// // //       // _CrmNavItem(
// // //       //   keyName: 'home',
// // //       //   label: 'Home',
// // //       //   icon: Icons.dashboard_outlined,
// // //       //   builder: () => HomeDashboardScreen(
// // //       //     profile: widget.profile,
// // //       //     onLogout: widget.onLogout,
// // //       //     showOwnHeader: false,
// // //       //   ),
// // //       // ),
// // //       _CrmNavItem(
// // //         keyName: 'home',
// // //         label: 'Home',
// // //         icon: Icons.dashboard_outlined,
// // //         builder: () => HomeDashboardScreen(
// // //           profile: widget.profile,
// // //           onLogout: widget.onLogout,
// // //           showOwnHeader: false,
// // //         ),
// // //       ),
// // //       _CrmNavItem(
// // //         keyName: 'notifications',
// // //         label: 'Notifications',
// // //         icon: Icons.notifications_active_outlined,
// // //         builder: () => NotificationsScreen(
// // //           profile: widget.profile,
// // //           onLogout: widget.onLogout,
// // //           showOwnHeader: false,
// // //         ),
// // //       ),
// // //       _CrmNavItem(
// // //         keyName: 'leads',
// // //         label: 'Leads',
// // //         icon: Icons.people_alt_outlined,
// // //         builder: () => LeadsScreen(
// // //           profile: widget.profile,
// // //           onLogout: widget.onLogout,
// // //         ),
// // //       ),
// // //       _CrmNavItem(
// // //         keyName: 'follow_up',
// // //         label: 'Follow Up',
// // //         icon: Icons.reply_all_rounded,
// // //         builder: () => FollowUpScreen(
// // //           profile: widget.profile,
// // //           onLogout: widget.onLogout,
// // //           showOwnHeader: false,
// // //         ),
// // //       ),
// // //       _CrmNavItem(
// // //         keyName: 'products',
// // //         label: 'Products',
// // //         icon: Icons.inventory_2_outlined,
// // //         builder: () => PriceListScreen(
// // //           profile: widget.profile,
// // //           onLogout: widget.onLogout,
// // //         ),
// // //       ),
// // //     ];
// // //
// // //     if (_isAdmin) {
// // //       items.add(
// // //         _CrmNavItem(
// // //           keyName: 'statistics',
// // //           label: 'Statistics',
// // //           icon: Icons.bar_chart_rounded,
// // //           builder: () => StatisticsScreen(
// // //             profile: widget.profile,
// // //             onLogout: widget.onLogout,
// // //             showOwnHeader: false,
// // //           ),
// // //         ),
// // //         // _CrmNavItem(
// // //         //   keyName: 'statistics',
// // //         //   label: 'Statistics',
// // //         //   icon: Icons.bar_chart_rounded,
// // //         //   builder: () => const _PlaceholderModule(
// // //         //     title: 'Statistics',
// // //         //     subtitle: 'Next step: build global CRM analytics and ratios.',
// // //         //     icon: Icons.bar_chart_rounded,
// // //         //   ),
// // //         // ),
// // //       );
// // //
// // //       if (_canAssignLeads) {
// // //         items.add(
// // //           _CrmNavItem(
// // //             keyName: 'shared_leads',
// // //             label: 'Shared Leads',
// // //             icon: Icons.share_outlined,
// // //             builder: () => SharedLeadsScreen(
// // //               profile: widget.profile,
// // //               onLogout: widget.onLogout,
// // //               showOwnHeader: false,
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //
// // //       items.addAll([
// // //         _CrmNavItem(
// // //           keyName: 'agent_performance',
// // //           label: 'Agent Performance',
// // //           icon: Icons.groups_2_outlined,
// // //           builder: () => AgentPerformanceScreen(
// // //             profile: widget.profile,
// // //             onLogout: widget.onLogout,
// // //             showOwnHeader: false,
// // //           ),
// // //         ),
// // //         _CrmNavItem(
// // //           keyName: 'user_roles',
// // //           label: 'User Roles',
// // //           icon: Icons.admin_panel_settings_outlined,
// // //           builder: () => UserRoleManagementScreen(
// // //             currentUserId: (widget.profile['id'] ?? '').toString(),
// // //           ),
// // //         ),
// // //       ]);
// // //     }
// // //
// // //     if (_isAccountant) {
// // //       items.add(
// // //         _CrmNavItem(
// // //           keyName: 'accounting_tools',
// // //           label: 'Accounting',
// // //           icon: Icons.receipt_long_outlined,
// // //           builder: () => const _PlaceholderModule(
// // //             title: 'Accounting',
// // //             subtitle:
// // //             'Accountant role is active. Add quotation/accounting tools here next.',
// // //             icon: Icons.receipt_long_outlined,
// // //           ),
// // //         ),
// // //       );
// // //     }
// // //
// // //     if (_isViewer) {
// // //       return items
// // //           .where((item) =>
// // //       item.keyName == 'home' ||
// // //           item.keyName == 'leads' ||
// // //           item.keyName == 'follow_up')
// // //           .toList();
// // //     }
// // //
// // //     return items;
// // //   }
// // //   // List<_CrmNavItem> get _items {
// // //   //   final items = <_CrmNavItem>[
// // //   //     _CrmNavItem(
// // //   //       keyName: 'home',
// // //   //       label: 'Home',
// // //   //       icon: Icons.dashboard_outlined,
// // //   //       builder: () => _DashboardPlaceholder(
// // //   //         profile: widget.profile,
// // //   //       ),
// // //   //     ),
// // //   //     _CrmNavItem(
// // //   //       keyName: 'leads',
// // //   //       label: 'Leads',
// // //   //       icon: Icons.people_alt_outlined,
// // //   //       builder: () => LeadsScreen(
// // //   //         profile: widget.profile,
// // //   //         onLogout: widget.onLogout,
// // //   //       ),
// // //   //     ),
// // //   //     _CrmNavItem(
// // //   //       keyName: 'important',
// // //   //       label: 'Important Leads',
// // //   //       icon: Icons.star_border_rounded,
// // //   //       builder: () => ImportantLeadsScreen(
// // //   //         profile: widget.profile,
// // //   //         onLogout: widget.onLogout,
// // //   //       ),
// // //   //     ),
// // //   //     _CrmNavItem(
// // //   //       keyName: 'follow_up',
// // //   //       label: 'Follow Up',
// // //   //       icon: Icons.reply_all_rounded,
// // //   //       builder: () => FollowUpScreen(
// // //   //         profile: widget.profile,
// // //   //         onLogout: widget.onLogout,
// // //   //         showOwnHeader: false,
// // //   //       ),
// // //   //     ),
// // //   //     _CrmNavItem(
// // //   //       keyName: 'products',
// // //   //       label: 'Products',
// // //   //       icon: Icons.inventory_2_outlined,
// // //   //       builder: () => PriceListScreen(
// // //   //         profile: widget.profile,
// // //   //         onLogout: widget.onLogout,
// // //   //       ),
// // //   //     ),
// // //   //   ];
// // //   //
// // //   //   if (_isAdmin) {
// // //   //     items.addAll([
// // //   //       _CrmNavItem(
// // //   //         keyName: 'statistics',
// // //   //         label: 'Statistics',
// // //   //         icon: Icons.bar_chart_rounded,
// // //   //         builder: () => const _PlaceholderModule(
// // //   //           title: 'Statistics',
// // //   //           subtitle: 'Next step: build global CRM analytics and ratios.',
// // //   //           icon: Icons.bar_chart_rounded,
// // //   //         ),
// // //   //       ),
// // //   //       _CrmNavItem(
// // //   //         keyName: 'shared_leads',
// // //   //         label: 'Shared Leads',
// // //   //         icon: Icons.share_outlined,
// // //   //         builder: () => SharedLeadsScreen(
// // //   //           profile: widget.profile,
// // //   //           onLogout: widget.onLogout,
// // //   //           showOwnHeader: false,
// // //   //         ),
// // //   //       ),
// // //   //       _CrmNavItem(
// // //   //         keyName: 'agent_performance',
// // //   //         label: 'Agent Performance',
// // //   //         icon: Icons.groups_2_outlined,
// // //   //         builder: () => const _PlaceholderModule(
// // //   //           title: 'Agent Performance',
// // //   //           subtitle: 'Next step: build per-agent metrics and activity insights.',
// // //   //           icon: Icons.groups_2_outlined,
// // //   //         ),
// // //   //       ),
// // //   //       _CrmNavItem(
// // //   //         keyName: 'user_roles',
// // //   //         label: 'User Roles',
// // //   //         icon: Icons.admin_panel_settings_outlined,
// // //   //         builder: () => UserRoleManagementScreen(
// // //   //           currentUserId: (widget.profile['id'] ?? '').toString(),
// // //   //         ),
// // //   //       ),
// // //   //     ]);
// // //   //   }
// // //   //
// // //   //   if (_isAccountant) {
// // //   //     items.add(
// // //   //       _CrmNavItem(
// // //   //         keyName: 'accounting_tools',
// // //   //         label: 'Accounting',
// // //   //         icon: Icons.receipt_long_outlined,
// // //   //         builder: () => const _PlaceholderModule(
// // //   //           title: 'Accounting',
// // //   //           subtitle:
// // //   //           'Accountant role is active. Add quotation/accounting tools here next.',
// // //   //           icon: Icons.receipt_long_outlined,
// // //   //         ),
// // //   //       ),
// // //   //     );
// // //   //   }
// // //   //
// // //   //   if (_isViewer) {
// // //   //     return items
// // //   //         .where((item) => item.keyName == 'home' || item.keyName == 'leads')
// // //   //         .toList();
// // //   //   }
// // //   //
// // //   //   return items;
// // //   // }
// // //
// // //   void _selectIndex(int index) {
// // //     if (index < 0 || index >= _items.length) return;
// // //     setState(() {
// // //       _selectedIndex = index;
// // //     });
// // //     Navigator.of(context).maybePop();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //
// // //
// // //     final isWide = MediaQuery.of(context).size.width >= 1024;
// // //     final items = _items;
// // //
// // //     final mobileNavItems = items.take(5).toList();
// // //     final mobileSelectedIndex =
// // //     _selectedIndex < mobileNavItems.length ? _selectedIndex : 0;
// // //
// // //     if (_selectedIndex >= items.length) {
// // //       _selectedIndex = 0;
// // //     }
// // //
// // //     final currentItem = items[_selectedIndex];
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFF0A0A0A),
// // //       drawer: isWide ? null : _CrmDrawer(
// // //         items: items,
// // //         selectedIndex: _selectedIndex,
// // //         onSelect: _selectIndex,
// // //         profile: widget.profile,
// // //         onLogout: widget.onLogout,
// // //       ),
// // //       body: SafeArea(
// // //         child: isWide
// // //             ? Row(
// // //           children: [
// // //             _CrmSidebar(
// // //               items: items,
// // //               selectedIndex: _selectedIndex,
// // //               onSelect: _selectIndex,
// // //               profile: widget.profile,
// // //               onLogout: widget.onLogout,
// // //             ),
// // //             const VerticalDivider(
// // //               width: 1,
// // //               thickness: 1,
// // //               color: Color(0xFF3A2F0B),
// // //             ),
// // //             Expanded(
// // //               child: Column(
// // //                 children: [
// // //                   _CrmTopBar(
// // //                     title: currentItem.label,
// // //                     profile: widget.profile,
// // //                   ),
// // //                   const Divider(
// // //                     height: 1,
// // //                     thickness: 1,
// // //                     color: Color(0xFF3A2F0B),
// // //                   ),
// // //                   Expanded(
// // //                     child: KeyedSubtree(
// // //                       key: ValueKey(currentItem.keyName),
// // //                       child: currentItem.builder(),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         )
// // //             : Column(
// // //           children: [
// // //             _CrmMobileTopBar(
// // //               title: currentItem.label,
// // //               profile: widget.profile,
// // //             ),
// // //             const Divider(
// // //               height: 1,
// // //               thickness: 1,
// // //               color: Color(0xFF3A2F0B),
// // //             ),
// // //             Expanded(
// // //               child: KeyedSubtree(
// // //                 key: ValueKey(currentItem.keyName),
// // //                 child: currentItem.builder(),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //       bottomNavigationBar: isWide
// // //           ? null
// // //           : NavigationBar(
// // //         selectedIndex: mobileSelectedIndex,
// // //         onDestinationSelected: _selectIndex,
// // //         destinations: mobileNavItems.map((item) {
// // //           return NavigationDestination(
// // //             icon: Icon(item.icon),
// // //             label: item.label,
// // //           );
// // //         }).toList(),
// // //       ),
// // //       // bottomNavigationBar: isWide
// // //       //     ? null
// // //       //     : NavigationBar(
// // //       //   selectedIndex: _selectedIndex.clamp(0, items.length - 1),
// // //       //   onDestinationSelected: _selectIndex,
// // //       //   destinations: items.take(5).map((item) {
// // //       //     return NavigationDestination(
// // //       //       icon: Icon(item.icon),
// // //       //       label: item.label,
// // //       //     );
// // //       //   }).toList(),
// // //       // ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CrmNavItem {
// // //   final String keyName;
// // //   final String label;
// // //   final IconData icon;
// // //   final Widget Function() builder;
// // //
// // //   const _CrmNavItem({
// // //     required this.keyName,
// // //     required this.label,
// // //     required this.icon,
// // //     required this.builder,
// // //   });
// // // }
// // //
// // // class _CrmSidebar extends StatelessWidget {
// // //   final List<_CrmNavItem> items;
// // //   final int selectedIndex;
// // //   final ValueChanged<int> onSelect;
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _CrmSidebar({
// // //     required this.items,
// // //     required this.selectedIndex,
// // //     required this.onSelect,
// // //     required this.profile,
// // //     required this.onLogout,
// // //   });
// // //
// // //   String _displayName() {
// // //     final fullName = (profile['full_name'] ?? '').toString().trim();
// // //     final email = (profile['email'] ?? '').toString().trim();
// // //     return fullName.isNotEmpty ? fullName : email;
// // //   }
// // //
// // //   String _role() {
// // //     return (profile['role'] ?? '').toString().trim().toUpperCase();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       width: 280,
// // //       color: const Color(0xFF111111),
// // //       child: Column(
// // //         children: [
// // //           Container(
// // //             alignment: Alignment.centerLeft,
// // //             child: Padding(
// // //               padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   SizedBox(
// // //                     width: 200,
// // //                     child: Row(
// // //                       mainAxisAlignment: .spaceBetween,
// // //                       children: [
// // //                         Image.asset('assets/icons/logo.png',height: 40,),
// // //                         const Text(
// // //                           'Flower Center CRM',
// // //                           style: TextStyle(
// // //                             fontSize: 15,
// // //                             fontWeight: FontWeight.w900,
// // //                             color: AppConstants.primaryColor,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 10),
// // //                   Text(
// // //                     _displayName(),
// // //                     maxLines: 1,
// // //                     overflow: TextOverflow.ellipsis,
// // //                     style: const TextStyle(
// // //                       fontWeight: FontWeight.w700,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 4),
// // //                   Text(
// // //                     _role(),
// // //                     style: const TextStyle(
// // //                       color: AppConstants.primaryColor,
// // //                       fontWeight: FontWeight.w800,
// // //                       fontSize: 12,
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
// // //           Expanded(
// // //             child: ListView.builder(
// // //               padding: const EdgeInsets.all(12),
// // //               itemCount: items.length,
// // //               itemBuilder: (context, index) {
// // //                 final item = items[index];
// // //                 final selected = index == selectedIndex;
// // //
// // //                 return Padding(
// // //                   padding: const EdgeInsets.only(bottom: 8),
// // //                   child: Material(
// // //                     color: Colors.transparent,
// // //                     child: InkWell(
// // //                       borderRadius: BorderRadius.circular(16),
// // //                       onTap: () => onSelect(index),
// // //                       child: Container(
// // //                         padding: const EdgeInsets.symmetric(
// // //                           horizontal: 14,
// // //                           vertical: 14,
// // //                         ),
// // //                         decoration: BoxDecoration(
// // //                           color: selected
// // //                               ? const Color(0xFF2B220B)
// // //                               : const Color(0xFF141414),
// // //                           borderRadius: BorderRadius.circular(16),
// // //                           border: Border.all(
// // //                             color: selected
// // //                                 ? AppConstants.primaryColor
// // //                                 : const Color(0xFF3A2F0B),
// // //                           ),
// // //                         ),
// // //                         child: Row(
// // //                           children: [
// // //                             Icon(
// // //                               item.icon,
// // //                               color: selected
// // //                                   ? AppConstants.primaryColor
// // //                                   : null,
// // //                             ),
// // //                             const SizedBox(width: 12),
// // //                             Expanded(
// // //                               child: Text(
// // //                                 item.label,
// // //                                 style: TextStyle(
// // //                                   fontWeight: FontWeight.w700,
// // //                                   color: selected
// // //                                       ? AppConstants.primaryColor
// // //                                       : null,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
// // //           Padding(
// // //             padding: const EdgeInsets.all(12),
// // //             child: SizedBox(
// // //               width: double.infinity,
// // //               child: OutlinedButton.icon(
// // //                 onPressed: onLogout,
// // //                 icon: const Icon(Icons.logout_rounded),
// // //                 label: const Text('Logout'),
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CrmDrawer extends StatelessWidget {
// // //   final List<_CrmNavItem> items;
// // //   final int selectedIndex;
// // //   final ValueChanged<int> onSelect;
// // //   final Map<String, dynamic> profile;
// // //   final Future<void> Function() onLogout;
// // //
// // //   const _CrmDrawer({
// // //     required this.items,
// // //     required this.selectedIndex,
// // //     required this.onSelect,
// // //     required this.profile,
// // //     required this.onLogout,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final fullName = (profile['full_name'] ?? '').toString().trim();
// // //     final email = (profile['email'] ?? '').toString().trim();
// // //     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
// // //
// // //     return Drawer(
// // //       backgroundColor: const Color(0xFF111111),
// // //       child: SafeArea(
// // //         child: Column(
// // //           children: [
// // //             ListTile(
// // //               title: const Text(
// // //                 'Flower Center CRM',
// // //                 style: TextStyle(
// // //                   color: AppConstants.primaryColor,
// // //                   fontWeight: FontWeight.w900,
// // //                 ),
// // //               ),
// // //               subtitle: Text(
// // //                 fullName.isNotEmpty ? '$fullName • $role' : '$email • $role',
// // //               ),
// // //             ),
// // //             const Divider(color: Color(0xFF3A2F0B)),
// // //             Expanded(
// // //               child: ListView.builder(
// // //                 itemCount: items.length,
// // //                 itemBuilder: (context, index) {
// // //                   final item = items[index];
// // //                   return ListTile(
// // //                     selected: index == selectedIndex,
// // //                     leading: Icon(item.icon),
// // //                     title: Text(item.label),
// // //                     onTap: () => onSelect(index),
// // //                   );
// // //                 },
// // //               ),
// // //             ),
// // //             const Divider(color: Color(0xFF3A2F0B)),
// // //             ListTile(
// // //               leading: const Icon(Icons.logout_rounded),
// // //               title: const Text('Logout'),
// // //               onTap: () async {
// // //                 Navigator.of(context).pop();
// // //                 await onLogout();
// // //               },
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CrmTopBar extends StatelessWidget {
// // //   final String title;
// // //   final Map<String, dynamic> profile;
// // //
// // //   const _CrmTopBar({
// // //     required this.title,
// // //     required this.profile,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final fullName = (profile['full_name'] ?? '').toString().trim();
// // //     final email = (profile['email'] ?? '').toString().trim();
// // //
// // //     return Container(
// // //       height: 72,
// // //       color: const Color(0xFF111111),
// // //       padding: const EdgeInsets.symmetric(horizontal: 20),
// // //       child: Row(
// // //         children: [
// // //           Expanded(
// // //             child: Text(
// // //               title,
// // //               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                 fontWeight: FontWeight.w900,
// // //               ),
// // //             ),
// // //           ),
// // //           ConstrainedBox(
// // //             constraints: const BoxConstraints(maxWidth: 260),
// // //             child: Text(
// // //               fullName.isNotEmpty ? fullName : email,
// // //               overflow: TextOverflow.ellipsis,
// // //               style: const TextStyle(fontWeight: FontWeight.w700),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _CrmMobileTopBar extends StatelessWidget {
// // //   final String title;
// // //   final Map<String, dynamic> profile;
// // //
// // //   const _CrmMobileTopBar({
// // //     required this.title,
// // //     required this.profile,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       color: const Color(0xFF111111),
// // //       height: 64,
// // //       padding: const EdgeInsets.symmetric(horizontal: 8),
// // //       child: Row(
// // //         children: [
// // //           Builder(
// // //             builder: (context) {
// // //               return IconButton(
// // //                 onPressed: () => Scaffold.of(context).openDrawer(),
// // //                 icon: const Icon(Icons.menu_rounded),
// // //               );
// // //             },
// // //           ),
// // //           Expanded(
// // //             child: Text(
// // //               title,
// // //               style: Theme.of(context).textTheme.titleLarge?.copyWith(
// // //                 fontWeight: FontWeight.w900,
// // //               ),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _DashboardPlaceholder extends StatelessWidget {
// // //   final Map<String, dynamic> profile;
// // //
// // //   const _DashboardPlaceholder({
// // //     required this.profile,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
// // //
// // //     return SingleChildScrollView(
// // //       padding: const EdgeInsets.all(20),
// // //       child: Column(
// // //         children: [
// // //           Wrap(
// // //             spacing: 14,
// // //             runSpacing: 14,
// // //             children: const [
// // //               _StatCard(
// // //                 title: 'Total Leads',
// // //                 value: '—',
// // //                 icon: Icons.people_outline_rounded,
// // //               ),
// // //               _StatCard(
// // //                 title: 'Important Leads',
// // //                 value: '—',
// // //                 icon: Icons.star_outline_rounded,
// // //               ),
// // //               _StatCard(
// // //                 title: 'Follow-ups',
// // //                 value: '—',
// // //                 icon: Icons.reply_all_rounded,
// // //               ),
// // //             ],
// // //           ),
// // //           const SizedBox(height: 18),
// // //           Container(
// // //             width: double.infinity,
// // //             padding: const EdgeInsets.all(20),
// // //             decoration: BoxDecoration(
// // //               color: const Color(0xFF141414),
// // //               borderRadius: BorderRadius.circular(24),
// // //               border: Border.all(color: const Color(0xFF3A2F0B)),
// // //             ),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 const Text(
// // //                   'Dashboard placeholder',
// // //                   style: TextStyle(
// // //                     fontSize: 18,
// // //                     fontWeight: FontWeight.w900,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 10),
// // //                 Text(
// // //                   'Logged in as $role. The CRM shell is now ready. Next modules to build are Important Leads, Follow Up, Shared Leads, and Statistics.',
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // // class _StatCard extends StatelessWidget {
// // //   final String title;
// // //   final String value;
// // //   final IconData icon;
// // //
// // //   const _StatCard({
// // //     required this.title,
// // //     required this.value,
// // //     required this.icon,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return SizedBox(
// // //       width: 240,
// // //       child: Container(
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
// // //               child: Icon(icon, color: AppConstants.primaryColor),
// // //             ),
// // //             const SizedBox(width: 14),
// // //             Expanded(
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Text(
// // //                     value,
// // //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// // //                       fontWeight: FontWeight.w900,
// // //                     ),
// // //                   ),
// // //                   const SizedBox(height: 4),
// // //                   Text(title),
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
// // // class _PlaceholderModule extends StatelessWidget {
// // //   final String title;
// // //   final String subtitle;
// // //   final IconData icon;
// // //
// // //   const _PlaceholderModule({
// // //     required this.title,
// // //     required this.subtitle,
// // //     required this.icon,
// // //   });
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Center(
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(24),
// // //         child: Container(
// // //           constraints: const BoxConstraints(maxWidth: 620),
// // //           padding: const EdgeInsets.all(24),
// // //           decoration: BoxDecoration(
// // //             color: const Color(0xFF141414),
// // //             borderRadius: BorderRadius.circular(24),
// // //             border: Border.all(color: const Color(0xFF3A2F0B)),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Icon(icon, size: 44, color: AppConstants.primaryColor),
// // //               const SizedBox(height: 14),
// // //               Text(
// // //                 title,
// // //                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// // //                   fontWeight: FontWeight.w900,
// // //                 ),
// // //                 textAlign: TextAlign.center,
// // //               ),
// // //               const SizedBox(height: 10),
// // //               Text(
// // //                 subtitle,
// // //                 textAlign: TextAlign.center,
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// // import 'dart:async';
// //
// // import 'package:FlowerCenterCrm/shell/crm/shared_leads_screen.dart';
// // import 'package:FlowerCenterCrm/shell/crm/statistics_screen.dart';
// //
// // import 'package:flutter/material.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // import '../../core/constants/app_constants.dart';
// // import '../../price_list_screen.dart';
// // import '../../user_role_management_screen.dart';
// // import 'agent_performance_screen.dart';
// // import 'follow_up_screen.dart';
// // import 'home_dashboard_screen.dart';
// // import 'leads_screen.dart';
// // import 'notifications_screen.dart';
// //
// // class CrmShellScreen extends StatefulWidget {
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //
// //   const CrmShellScreen({
// //     super.key,
// //     required this.profile,
// //     required this.onLogout,
// //   });
// //
// //   @override
// //   State<CrmShellScreen> createState() => _CrmShellScreenState();
// // }
// //
// // class _CrmShellScreenState extends State<CrmShellScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //
// //   int _selectedIndex = 0;
// //
// //   RealtimeChannel? _badgeChannel;
// //   Timer? _badgeRefreshDebounce;
// //
// //   int _notificationsBadgeCount = 0;
// //   int _followUpBadgeCount = 0;
// //
// //   String get _role => (widget.profile['role'] ?? '')
// //       .toString()
// //       .trim()
// //       .toLowerCase();
// //
// //   bool get _isAdmin => _role == 'admin';
// //   bool get _isSales => _role == 'sales';
// //   bool get _isViewer => _role == 'viewer';
// //   bool get _isAccountant => _role == 'accountant';
// //
// //   String get _currentUserId =>
// //       (widget.profile['id'] ?? '').toString().trim();
// //
// //   bool get _canAssignLeads =>
// //       _isAdmin && widget.profile['can_assign_leads'] == true;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _setupBadgeRealtime();
// //     _refreshBadgeCounts();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _badgeRefreshDebounce?.cancel();
// //
// //     final channel = _badgeChannel;
// //     _badgeChannel = null;
// //     if (channel != null) {
// //       unawaited(_supabase.removeChannel(channel));
// //     }
// //
// //     super.dispose();
// //   }
// //
// //
// //   void _setupBadgeRealtime() {
// //     final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;
// //
// //     _badgeChannel = _supabase
// //         .channel('crm-shell-badges-$channelKey')
// //         .onPostgresChanges(
// //       event: PostgresChangeEvent.all,
// //       schema: 'public',
// //       table: 'follow_ups',
// //       callback: (_) => _scheduleBadgeRefresh(),
// //     )
// //         .onPostgresChanges(
// //       event: PostgresChangeEvent.all,
// //       schema: 'public',
// //       table: 'activity_logs',
// //       callback: (_) => _scheduleBadgeRefresh(),
// //     )
// //         .onPostgresChanges(
// //       event: PostgresChangeEvent.all,
// //       schema: 'public',
// //       table: 'notification_dismissals',
// //       callback: (_) => _scheduleBadgeRefresh(),
// //     )
// //         .subscribe();
// //   }
// //
// //   void _scheduleBadgeRefresh() {
// //     _badgeRefreshDebounce?.cancel();
// //     _badgeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
// //       if (!mounted) return;
// //       _refreshBadgeCounts();
// //     });
// //   }
// //
// //   Future<void> _refreshBadgeCounts() async {
// //     try {
// //       final results = await Future.wait<int>([
// //         _loadNotificationsBadgeCount(),
// //         _loadFollowUpBadgeCount(),
// //       ]);
// //
// //       if (!mounted) return;
// //
// //       setState(() {
// //         _notificationsBadgeCount = results[0];
// //         _followUpBadgeCount = results[1];
// //       });
// //     } catch (_) {
// //       if (!mounted) return;
// //       setState(() {
// //         _notificationsBadgeCount = 0;
// //         _followUpBadgeCount = 0;
// //       });
// //     }
// //   }
// //
// //   Future<int> _loadNotificationsBadgeCount() async {
// //     if (!_isAdmin && !_isSales) {
// //       return 0;
// //     }
// //
// //     final dismissals = await _loadDismissalKeys();
// //
// //     final now = DateTime.now();
// //     final startToday = DateTime(now.year, now.month, now.day);
// //     final startTomorrow = startToday.add(const Duration(days: 1));
// //     final startDayAfterTomorrow = startToday.add(const Duration(days: 2));
// //
// //     dynamic overdueQuery = _supabase
// //         .from('follow_ups')
// //         .select('id, assigned_to, due_at, status')
// //         .eq('status', 'pending')
// //         .lt('due_at', startToday.toUtc().toIso8601String());
// //
// //     dynamic todayQuery = _supabase
// //         .from('follow_ups')
// //         .select('id, assigned_to, due_at, status')
// //         .eq('status', 'pending')
// //         .gte('due_at', startToday.toUtc().toIso8601String())
// //         .lt('due_at', startTomorrow.toUtc().toIso8601String());
// //
// //     dynamic tomorrowQuery = _supabase
// //         .from('follow_ups')
// //         .select('id, assigned_to, due_at, status')
// //         .eq('status', 'pending')
// //         .gte('due_at', startTomorrow.toUtc().toIso8601String())
// //         .lt('due_at', startDayAfterTomorrow.toUtc().toIso8601String());
// //
// //     if (_isSales && _currentUserId.isNotEmpty) {
// //       overdueQuery = overdueQuery.eq('assigned_to', _currentUserId);
// //       todayQuery = todayQuery.eq('assigned_to', _currentUserId);
// //       tomorrowQuery = tomorrowQuery.eq('assigned_to', _currentUserId);
// //     }
// //
// //     final overdueResponse = await overdueQuery;
// //     final todayResponse = await todayQuery;
// //     final tomorrowResponse = await tomorrowQuery;
// //
// //     final assignmentLogsResponse = await _supabase
// //         .from('activity_logs')
// //         .select('id, actor_id, action_type, meta')
// //         .eq('action_type', 'assign_lead')
// //         .order('created_at', ascending: false)
// //         .limit(30);
// //
// //     final overdue = (overdueResponse as List)
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .where((item) => !_isDismissedKey(
// //       dismissals,
// //       category: 'overdue_followups',
// //       entityType: 'follow_up',
// //       entityId: _text(item['id']),
// //     ))
// //         .length;
// //
// //     final dueToday = (todayResponse as List)
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .where((item) => !_isDismissedKey(
// //       dismissals,
// //       category: 'due_today_followups',
// //       entityType: 'follow_up',
// //       entityId: _text(item['id']),
// //     ))
// //         .length;
// //
// //     final dueTomorrow = (tomorrowResponse as List)
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .where((item) => !_isDismissedKey(
// //       dismissals,
// //       category: 'due_tomorrow_followups',
// //       entityType: 'follow_up',
// //       entityId: _text(item['id']),
// //     ))
// //         .length;
// //
// //     final assignmentLogs = (assignmentLogsResponse as List)
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .where((item) {
// //       if (_isAdmin) {
// //         return !_isDismissedKey(
// //           dismissals,
// //           category: 'assignment_logs',
// //           entityType: 'activity_log',
// //           entityId: _text(item['id']),
// //         );
// //       }
// //
// //       if (!_isSales || _currentUserId.isEmpty) return false;
// //
// //       final meta = _payloadMap(item['meta']);
// //       final actorId = _text(item['actor_id']);
// //       final oldOwnerId = _text(meta['old_owner_id']);
// //       final newOwnerId = _text(meta['new_owner_id']);
// //
// //       final matchesSalesRelevance = actorId == _currentUserId ||
// //           oldOwnerId == _currentUserId ||
// //           newOwnerId == _currentUserId;
// //
// //       return matchesSalesRelevance &&
// //           !_isDismissedKey(
// //             dismissals,
// //             category: 'assignment_logs',
// //             entityType: 'activity_log',
// //             entityId: _text(item['id']),
// //           );
// //     }).length;
// //
// //     return overdue + dueToday + dueTomorrow + assignmentLogs;
// //   }
// //
// //   Future<int> _loadFollowUpBadgeCount() async {
// //     final now = DateTime.now();
// //     final startToday = DateTime(now.year, now.month, now.day);
// //     final startTomorrow = startToday.add(const Duration(days: 1));
// //
// //     dynamic query = _supabase
// //         .from('follow_ups')
// //         .select('id')
// //         .eq('status', 'pending')
// //         .lt('due_at', startTomorrow.toUtc().toIso8601String());
// //
// //     if (_isSales && _currentUserId.isNotEmpty) {
// //       query = query.eq('assigned_to', _currentUserId);
// //     }
// //
// //     final response = await query;
// //     return (response as List).length;
// //   }
// //
// //   Future<Set<String>> _loadDismissalKeys() async {
// //     if (_currentUserId.isEmpty) return <String>{};
// //
// //     final response = await _supabase
// //         .from('notification_dismissals')
// //         .select('category, entity_type, entity_id')
// //         .eq('user_id', _currentUserId);
// //
// //     return (response as List)
// //         .map((row) => Map<String, dynamic>.from(row as Map))
// //         .map((row) => _dismissalKey(
// //       category: _text(row['category']),
// //       entityType: _text(row['entity_type']),
// //       entityId: _text(row['entity_id']),
// //     ))
// //         .toSet();
// //   }
// //
// //   String _dismissalKey({
// //     required String category,
// //     required String entityType,
// //     required String entityId,
// //   }) {
// //     return '$category|$entityType|$entityId';
// //   }
// //
// //   bool _isDismissedKey(
// //       Set<String> dismissals, {
// //         required String category,
// //         required String entityType,
// //         required String entityId,
// //       }) {
// //     return dismissals.contains(
// //       _dismissalKey(
// //         category: category,
// //         entityType: entityType,
// //         entityId: entityId,
// //       ),
// //     );
// //   }
// //
// //   Map<String, dynamic> _payloadMap(dynamic value) {
// //     if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
// //     if (value is Map) {
// //       return value.map((key, val) => MapEntry(key.toString(), val));
// //     }
// //     return <String, dynamic>{};
// //   }
// //
// //   String _text(dynamic value) => (value ?? '').toString().trim();
// //
// //   int _badgeCountFor(String keyName) {
// //     switch (keyName) {
// //       case 'notifications':
// //         return _notificationsBadgeCount;
// //       case 'follow_up':
// //         return _followUpBadgeCount;
// //       default:
// //         return 0;
// //     }
// //   }
// //
// //   List<_CrmNavItem> get _items {
// //     final items = <_CrmNavItem>[
// //       _CrmNavItem(
// //         keyName: 'home',
// //         label: 'Home',
// //         icon: Icons.dashboard_outlined,
// //         badgeCount: _badgeCountFor('home'),
// //         builder: () => HomeDashboardScreen(
// //           profile: widget.profile,
// //           onLogout: widget.onLogout,
// //           showOwnHeader: false,
// //         ),
// //       ),
// //       _CrmNavItem(
// //         keyName: 'notifications',
// //         label: 'Notifications',
// //         icon: Icons.notifications_active_outlined,
// //         badgeCount: _badgeCountFor('notifications'),
// //         builder: () => NotificationsScreen(
// //           profile: widget.profile,
// //           onLogout: widget.onLogout,
// //           showOwnHeader: false,
// //         ),
// //       ),
// //       _CrmNavItem(
// //         keyName: 'leads',
// //         label: 'Leads',
// //         icon: Icons.people_alt_outlined,
// //         badgeCount: _badgeCountFor('leads'),
// //         builder: () => LeadsScreen(
// //           profile: widget.profile,
// //           onLogout: widget.onLogout,
// //         ),
// //       ),
// //       _CrmNavItem(
// //         keyName: 'follow_up',
// //         label: 'Follow Up',
// //         icon: Icons.reply_all_rounded,
// //         badgeCount: _badgeCountFor('follow_up'),
// //         builder: () => FollowUpScreen(
// //           profile: widget.profile,
// //           onLogout: widget.onLogout,
// //           showOwnHeader: false,
// //         ),
// //       ),
// //       _CrmNavItem(
// //         keyName: 'products',
// //         label: 'Products',
// //         icon: Icons.inventory_2_outlined,
// //         badgeCount: _badgeCountFor('products'),
// //         builder: () =>
// //             PriceListScreen(
// //           profile: widget.profile,
// //           onLogout: widget.onLogout,
// //         ),
// //       ),
// //     ];
// //
// //     if (_isAdmin) {
// //       items.add(
// //         _CrmNavItem(
// //           keyName: 'statistics',
// //           label: 'Statistics',
// //           icon: Icons.bar_chart_rounded,
// //           badgeCount: _badgeCountFor('statistics'),
// //           builder: () => StatisticsScreen(
// //             profile: widget.profile,
// //             onLogout: widget.onLogout,
// //             showOwnHeader: false,
// //           ),
// //         ),
// //       );
// //
// //       if (_canAssignLeads) {
// //         items.add(
// //           _CrmNavItem(
// //             keyName: 'shared_leads',
// //             label: 'Shared Leads',
// //             icon: Icons.share_outlined,
// //             badgeCount: _badgeCountFor('shared_leads'),
// //             builder: () => SharedLeadsScreen(
// //               profile: widget.profile,
// //               onLogout: widget.onLogout,
// //               showOwnHeader: false,
// //             ),
// //           ),
// //         );
// //       }
// //
// //       items.addAll([
// //         _CrmNavItem(
// //           keyName: 'agent_performance',
// //           label: 'Agent Performance',
// //           icon: Icons.groups_2_outlined,
// //           badgeCount: _badgeCountFor('agent_performance'),
// //           builder: () => AgentPerformanceScreen(
// //             profile: widget.profile,
// //             onLogout: widget.onLogout,
// //             showOwnHeader: false,
// //           ),
// //         ),
// //         _CrmNavItem(
// //           keyName: 'user_roles',
// //           label: 'User Roles',
// //           icon: Icons.admin_panel_settings_outlined,
// //           badgeCount: _badgeCountFor('user_roles'),
// //           builder: () => UserRoleManagementScreen(
// //             currentUserId: (widget.profile['id'] ?? '').toString(),
// //           ),
// //         ),
// //       ]);
// //     }
// //
// //     if (_isAccountant) {
// //       items.add(
// //         _CrmNavItem(
// //           keyName: 'accounting_tools',
// //           label: 'Accounting',
// //           icon: Icons.receipt_long_outlined,
// //           badgeCount: _badgeCountFor('accounting_tools'),
// //           builder: () => const _PlaceholderModule(
// //             title: 'Accounting',
// //             subtitle:
// //             'Accountant role is active. Add quotation/accounting tools here next.',
// //             icon: Icons.receipt_long_outlined,
// //           ),
// //         ),
// //       );
// //     }
// //
// //     if (_isViewer) {
// //       return items
// //           .where((item) =>
// //       item.keyName == 'home' ||
// //           item.keyName == 'leads' ||
// //           item.keyName == 'follow_up')
// //           .toList();
// //     }
// //
// //     return items;
// //   }
// //
// //   void _selectIndex(int index) {
// //     if (index < 0 || index >= _items.length) return;
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //     Navigator.of(context).maybePop();
// //   }
// //   Future<void> _deleteMyAccount() async {
// //     final confirmed = await _showDeleteAccountDialog();
// //     if (confirmed != true) return;
// //
// //     try {
// //       await _supabase.functions.invoke('delete-account');
// //
// //       await _supabase.auth.signOut();
// //
// //       if (!mounted) return;
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Your account has been deleted.')),
// //       );
// //
// //       await widget.onLogout();
// //     } catch (e) {
// //       if (!mounted) return;
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to delete account: $e')),
// //       );
// //     }
// //   }
// //
// //   Future<bool?> _showDeleteAccountDialog() {
// //     return showDialog<bool>(
// //       context: context,
// //       barrierDismissible: false,
// //       useRootNavigator: true,
// //       builder: (dialogContext) {
// //         return AlertDialog(
// //           title: const Text('Delete My Account'),
// //           content: const Text(
// //             'This will permanently delete your login account. '
// //                 'You will lose access immediately. This action cannot be undone.',
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(false),
// //               child: const Text('Cancel'),
// //             ),
// //             FilledButton(
// //               onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(true),
// //               child: const Text('Delete'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //   @override
// //   Widget build(BuildContext context) {
// //     final isWide = MediaQuery.of(context).size.width >= 1024;
// //     final items = _items;
// //
// //     final mobileNavItems = items.take(5).toList();
// //     final mobileSelectedIndex =
// //     _selectedIndex < mobileNavItems.length ? _selectedIndex : 0;
// //
// //     if (_selectedIndex >= items.length) {
// //       _selectedIndex = 0;
// //     }
// //
// //     final currentItem = items[_selectedIndex];
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFF0A0A0A),
// //       drawer: isWide
// //           ? null
// //           :
// //       _CrmSidebar(
// //         items: items,
// //         selectedIndex: _selectedIndex,
// //         onSelect: _selectIndex,
// //         profile: widget.profile,
// //         onLogout: widget.onLogout,
// //         onDeleteAccount: _deleteMyAccount,
// //       ),
// //       // _CrmDrawer(
// //       //   items: items,
// //       //   selectedIndex: _selectedIndex,
// //       //   onSelect: _selectIndex,
// //       //   profile: widget.profile,
// //       //   onLogout: widget.onLogout,
// //       // ),
// //       body: SafeArea(
// //         child: isWide
// //             ? Row(
// //           children: [
// //             _CrmDrawer(
// //               items: items,
// //               selectedIndex: _selectedIndex,
// //               onSelect: _selectIndex,
// //               profile: widget.profile,
// //               onLogout: widget.onLogout,
// //               onDeleteAccount: _deleteMyAccount,
// //             ),
// //             // _CrmSidebar(
// //             //   items: items,
// //             //   selectedIndex: _selectedIndex,
// //             //   onSelect: _selectIndex,
// //             //   profile: widget.profile,
// //             //   onLogout: widget.onLogout,
// //             // ),
// //             const VerticalDivider(
// //               width: 1,
// //               thickness: 1,
// //               color: Color(0xFF3A2F0B),
// //             ),
// //             Expanded(
// //               child: Column(
// //                 children: [
// //                   _CrmTopBar(
// //                     title: currentItem.label,
// //                     profile: widget.profile,
// //                   ),
// //                   const Divider(
// //                     height: 1,
// //                     thickness: 1,
// //                     color: Color(0xFF3A2F0B),
// //                   ),
// //                   Expanded(
// //                     child: KeyedSubtree(
// //                       key: ValueKey(currentItem.keyName),
// //                       child: currentItem.builder(),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         )
// //             : Column(
// //           children: [
// //             _CrmMobileTopBar(
// //               title: currentItem.label,
// //               profile: widget.profile,
// //             ),
// //             const Divider(
// //               height: 1,
// //               thickness: 1,
// //               color: Color(0xFF3A2F0B),
// //             ),
// //             Expanded(
// //               child: KeyedSubtree(
// //                 key: ValueKey(currentItem.keyName),
// //                 child: currentItem.builder(),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       bottomNavigationBar: isWide
// //           ? null
// //           : NavigationBar(
// //         selectedIndex: mobileSelectedIndex,
// //         onDestinationSelected: _selectIndex,
// //         destinations: mobileNavItems.map((item) {
// //           return NavigationDestination(
// //             icon: _NavIconWithBadge(
// //               icon: item.icon,
// //               badgeCount: item.badgeCount,
// //               selected: false,
// //             ),
// //             selectedIcon: _NavIconWithBadge(
// //               icon: item.icon,
// //               badgeCount: item.badgeCount,
// //               selected: true,
// //             ),
// //             label: item.label,
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }
// // }
// //
// // class _CrmNavItem {
// //   final String keyName;
// //   final String label;
// //   final IconData icon;
// //   final int badgeCount;
// //   final Widget Function() builder;
// //
// //   const _CrmNavItem({
// //     required this.keyName,
// //     required this.label,
// //     required this.icon,
// //     required this.badgeCount,
// //     required this.builder,
// //   });
// // }
// //
// // class _NavIconWithBadge extends StatelessWidget {
// //   final IconData icon;
// //   final int badgeCount;
// //   final bool selected;
// //
// //   const _NavIconWithBadge({
// //     required this.icon,
// //     required this.badgeCount,
// //     required this.selected,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final text = badgeCount > 99 ? '99+' : badgeCount.toString();
// //
// //     return Stack(
// //       clipBehavior: Clip.none,
// //       children: [
// //         Icon(
// //           icon,
// //           color: selected ? AppConstants.primaryColor : null,
// //         ),
// //         if (badgeCount > 0)
// //           Positioned(
// //             right: -10,
// //             top: -8,
// //             child: Container(
// //               constraints: const BoxConstraints(
// //                 minWidth: 18,
// //                 minHeight: 18,
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFFB00020),
// //                 borderRadius: BorderRadius.circular(999),
// //                 border: Border.all(
// //                   color: const Color(0xFF111111),
// //                   width: 1.2,
// //                 ),
// //               ),
// //               alignment: Alignment.center,
// //               child: Text(
// //                 text,
// //                 style: const TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 10,
// //                   fontWeight: FontWeight.w900,
// //                   height: 1,
// //                 ),
// //               ),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// // }
// //
// // class _CrmSidebar extends StatelessWidget {
// //   final List<_CrmNavItem> items;
// //   final int selectedIndex;
// //   final ValueChanged<int> onSelect;
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final Future<void> Function() onDeleteAccount;
// //
// //   const _CrmSidebar({
// //     required this.items,
// //     required this.selectedIndex,
// //     required this.onSelect,
// //     required this.profile,
// //     required this.onLogout,
// //     required this.onDeleteAccount,
// //   });
// //
// //   String _displayName() {
// //     final fullName = (profile['full_name'] ?? '').toString().trim();
// //     final email = (profile['email'] ?? '').toString().trim();
// //     return fullName.isNotEmpty ? fullName : email;
// //   }
// //
// //   String _role() {
// //     return (profile['role'] ?? '').toString().trim().toUpperCase();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       width: 280,
// //       color: const Color(0xFF111111),
// //       child: Column(
// //         children: [
// //           Container(
// //             alignment: Alignment.centerLeft,
// //             child: Padding(
// //               padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   SizedBox(
// //                     width: 200,
// //                     child: Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Image.asset(
// //                           'assets/icons/logo.png',
// //                           height: 40,
// //                         ),
// //                         const Text(
// //                           'Flower Center CRM',
// //                           style: TextStyle(
// //                             fontSize: 15,
// //                             fontWeight: FontWeight.w900,
// //                             color: AppConstants.primaryColor,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 10),
// //                   Text(
// //                     _displayName(),
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: const TextStyle(
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(
// //                     _role(),
// //                     style: const TextStyle(
// //                       color: AppConstants.primaryColor,
// //                       fontWeight: FontWeight.w800,
// //                       fontSize: 12,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
// //           Expanded(
// //             child: ListView.builder(
// //               padding: const EdgeInsets.all(12),
// //               itemCount: items.length,
// //               itemBuilder: (context, index) {
// //                 final item = items[index];
// //                 final selected = index == selectedIndex;
// //
// //                 return Padding(
// //                   padding: const EdgeInsets.only(bottom: 8),
// //                   child: Material(
// //                     color: Colors.transparent,
// //                     child: InkWell(
// //                       borderRadius: BorderRadius.circular(16),
// //                       onTap: () => onSelect(index),
// //                       child: Container(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 14,
// //                           vertical: 14,
// //                         ),
// //                         decoration: BoxDecoration(
// //                           color: selected
// //                               ? const Color(0xFF2B220B)
// //                               : const Color(0xFF141414),
// //                           borderRadius: BorderRadius.circular(16),
// //                           border: Border.all(
// //                             color: selected
// //                                 ? AppConstants.primaryColor
// //                                 : const Color(0xFF3A2F0B),
// //                           ),
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             _NavIconWithBadge(
// //                               icon: item.icon,
// //                               badgeCount: item.badgeCount,
// //                               selected: selected,
// //                             ),
// //                             const SizedBox(width: 12),
// //                             Expanded(
// //                               child: Text(
// //                                 item.label,
// //                                 style: TextStyle(
// //                                   fontWeight: FontWeight.w700,
// //                                   color: selected
// //                                       ? AppConstants.primaryColor
// //                                       : null,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
// //           Padding(
// //             padding: const EdgeInsets.all(12),
// //             child: Column(
// //               children: [
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: onDeleteAccount,
// //                     icon: const Icon(Icons.delete_forever_rounded),
// //                     label: const Text('Delete My Account'),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: onLogout,
// //                     icon: const Icon(Icons.logout_rounded),
// //                     label: const Text('Logout'),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           // Padding(
// //           //   padding: const EdgeInsets.all(12),
// //           //   child: SizedBox(
// //           //     width: double.infinity,
// //           //     child: OutlinedButton.icon(
// //           //       onPressed: onLogout,
// //           //       icon: const Icon(Icons.logout_rounded),
// //           //       label: const Text('Logout'),
// //           //     ),
// //           //   ),
// //           // ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _CrmDrawer extends StatelessWidget {
// //   final List<_CrmNavItem> items;
// //   final int selectedIndex;
// //   final ValueChanged<int> onSelect;
// //   final Map<String, dynamic> profile;
// //   final Future<void> Function() onLogout;
// //   final Future<void> Function() onDeleteAccount;
// //
// //   const _CrmDrawer({
// //     required this.items,
// //     required this.selectedIndex,
// //     required this.onSelect,
// //     required this.profile,
// //     required this.onLogout,
// //     required this.onDeleteAccount,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final fullName = (profile['full_name'] ?? '').toString().trim();
// //     final email = (profile['email'] ?? '').toString().trim();
// //     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
// //
// //     return Drawer(
// //       backgroundColor: const Color(0xFF111111),
// //       child: SafeArea(
// //         child: Column(
// //           children: [
// //             ListTile(
// //               title: const Text(
// //                 'Flower Center CRM',
// //                 style: TextStyle(
// //                   color: AppConstants.primaryColor,
// //                   fontWeight: FontWeight.w900,
// //                 ),
// //               ),
// //               subtitle: Text(
// //                 fullName.isNotEmpty ? '$fullName • $role' : '$email • $role',
// //               ),
// //             ),
// //             const Divider(color: Color(0xFF3A2F0B)),
// //             Expanded(
// //               child: ListView.builder(
// //                 itemCount: items.length,
// //                 itemBuilder: (context, index) {
// //                   final item = items[index];
// //                   return ListTile(
// //                     selected: index == selectedIndex,
// //                     leading: _NavIconWithBadge(
// //                       icon: item.icon,
// //                       badgeCount: item.badgeCount,
// //                       selected: index == selectedIndex,
// //                     ),
// //                     title: Text(item.label),
// //                     onTap: () => onSelect(index),
// //                   );
// //                 },
// //               ),
// //             ),
// //             const Divider(color: Color(0xFF3A2F0B)),
// //             ListTile(
// //               leading: const Icon(Icons.delete_forever_rounded),
// //               title: const Text('Delete My Account'),
// //               onTap: () {
// //                 Navigator.of(context).pop();
// //                 Future.microtask(onDeleteAccount);
// //               },
// //             ),
// //             ListTile(
// //               leading: const Icon(Icons.logout_rounded),
// //               title: const Text('Logout'),
// //               onTap: () async {
// //                 Navigator.of(context).pop();
// //                 await onLogout();
// //               },
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class _CrmTopBar extends StatelessWidget {
// //   final String title;
// //   final Map<String, dynamic> profile;
// //
// //   const _CrmTopBar({
// //     required this.title,
// //     required this.profile,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final fullName = (profile['full_name'] ?? '').toString().trim();
// //     final email = (profile['email'] ?? '').toString().trim();
// //
// //     return Container(
// //       height: 72,
// //       color: const Color(0xFF111111),
// //       padding: const EdgeInsets.symmetric(horizontal: 20),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Text(
// //               title,
// //               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                 fontWeight: FontWeight.w900,
// //               ),
// //             ),
// //           ),
// //           ConstrainedBox(
// //             constraints: const BoxConstraints(maxWidth: 260),
// //             child: Text(
// //               fullName.isNotEmpty ? fullName : email,
// //               overflow: TextOverflow.ellipsis,
// //               style: const TextStyle(fontWeight: FontWeight.w700),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _CrmMobileTopBar extends StatelessWidget {
// //   final String title;
// //   final Map<String, dynamic> profile;
// //
// //   const _CrmMobileTopBar({
// //     required this.title,
// //     required this.profile,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: const Color(0xFF111111),
// //       height: 64,
// //       padding: const EdgeInsets.symmetric(horizontal: 8),
// //       child: Row(
// //         children: [
// //           Builder(
// //             builder: (context) {
// //               return IconButton(
// //                 onPressed: () => Scaffold.of(context).openDrawer(),
// //                 icon: const Icon(Icons.menu_rounded),
// //               );
// //             },
// //           ),
// //           Expanded(
// //             child: Text(
// //               title,
// //               style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //                 fontWeight: FontWeight.w900,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _DashboardPlaceholder extends StatelessWidget {
// //   final Map<String, dynamic> profile;
// //
// //   const _DashboardPlaceholder({
// //     required this.profile,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
// //
// //     return SingleChildScrollView(
// //       padding: const EdgeInsets.all(20),
// //       child: Column(
// //         children: [
// //           Wrap(
// //             spacing: 14,
// //             runSpacing: 14,
// //             children: const [
// //               _StatCard(
// //                 title: 'Total Leads',
// //                 value: '—',
// //                 icon: Icons.people_outline_rounded,
// //               ),
// //               _StatCard(
// //                 title: 'Important Leads',
// //                 value: '—',
// //                 icon: Icons.star_outline_rounded,
// //               ),
// //               _StatCard(
// //                 title: 'Follow-ups',
// //                 value: '—',
// //                 icon: Icons.reply_all_rounded,
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 18),
// //           Container(
// //             width: double.infinity,
// //             padding: const EdgeInsets.all(20),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF141414),
// //               borderRadius: BorderRadius.circular(24),
// //               border: Border.all(color: const Color(0xFF3A2F0B)),
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text(
// //                   'Dashboard placeholder',
// //                   style: TextStyle(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.w900,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 10),
// //                 Text(
// //                   'Logged in as $role. The CRM shell is now ready. Next modules to build are Important Leads, Follow Up, Shared Leads, and Statistics.',
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _StatCard extends StatelessWidget {
// //   final String title;
// //   final String value;
// //   final IconData icon;
// //
// //   const _StatCard({
// //     required this.title,
// //     required this.value,
// //     required this.icon,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox(
// //       width: 240,
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
// //               child: Icon(icon, color: AppConstants.primaryColor),
// //             ),
// //             const SizedBox(width: 14),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     value,
// //                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
// //                       fontWeight: FontWeight.w900,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 4),
// //                   Text(title),
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
// // class _PlaceholderModule extends StatelessWidget {
// //   final String title;
// //   final String subtitle;
// //   final IconData icon;
// //
// //   const _PlaceholderModule({
// //     required this.title,
// //     required this.subtitle,
// //     required this.icon,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(24),
// //         child: Container(
// //           constraints: const BoxConstraints(maxWidth: 620),
// //           padding: const EdgeInsets.all(24),
// //           decoration: BoxDecoration(
// //             color: const Color(0xFF141414),
// //             borderRadius: BorderRadius.circular(24),
// //             border: Border.all(color: const Color(0xFF3A2F0B)),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               Icon(icon, size: 44, color: AppConstants.primaryColor),
// //               const SizedBox(height: 14),
// //               Text(
// //                 title,
// //                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                   fontWeight: FontWeight.w900,
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 10),
// //               Text(
// //                 subtitle,
// //                 textAlign: TextAlign.center,
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'dart:async';
//
// import 'package:FlowerCenterCrm/shell/crm/shared_leads_screen.dart';
// import 'package:FlowerCenterCrm/shell/crm/statistics_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../../core/constants/app_constants.dart';
// import '../../price_list_screen.dart';
// import '../../user_role_management_screen.dart';
// import 'agent_performance_screen.dart';
// import 'follow_up_screen.dart';
// import 'home_dashboard_screen.dart';
// import 'leads_screen.dart';
// import 'notifications_screen.dart';
//
// class CrmShellScreen extends StatefulWidget {
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//
//   const CrmShellScreen({
//     super.key,
//     required this.profile,
//     required this.onLogout,
//   });
//
//   @override
//   State<CrmShellScreen> createState() => _CrmShellScreenState();
// }
//
// class _CrmShellScreenState extends State<CrmShellScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   int _selectedIndex = 0;
//
//   RealtimeChannel? _badgeChannel;
//   Timer? _badgeRefreshDebounce;
//
//   int _notificationsBadgeCount = 0;
//   int _followUpBadgeCount = 0;
//
//   String get _role =>
//       (widget.profile['role'] ?? '').toString().trim().toLowerCase();
//
//   bool get _isAdmin => _role == 'admin';
//   bool get _isSales => _role == 'sales';
//   bool get _isViewer => _role == 'viewer';
//   bool get _isAccountant => _role == 'accountant';
//
//   String get _currentUserId =>
//       (widget.profile['id'] ?? '').toString().trim();
//
//   bool get _canAssignLeads =>
//       _isAdmin && widget.profile['can_assign_leads'] == true;
//
//   @override
//   void initState() {
//     super.initState();
//     _setupBadgeRealtime();
//     _refreshBadgeCounts();
//   }
//
//   @override
//   void dispose() {
//     _badgeRefreshDebounce?.cancel();
//
//     final channel = _badgeChannel;
//     _badgeChannel = null;
//     if (channel != null) {
//       unawaited(_supabase.removeChannel(channel));
//     }
//
//     super.dispose();
//   }
//
//   void _setupBadgeRealtime() {
//     final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;
//
//     _badgeChannel = _supabase
//         .channel('crm-shell-badges-$channelKey')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'follow_ups',
//       callback: (_) => _scheduleBadgeRefresh(),
//     )
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'activity_logs',
//       callback: (_) => _scheduleBadgeRefresh(),
//     )
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all,
//       schema: 'public',
//       table: 'notification_dismissals',
//       callback: (_) => _scheduleBadgeRefresh(),
//     )
//         .subscribe();
//   }
//
//   void _scheduleBadgeRefresh() {
//     _badgeRefreshDebounce?.cancel();
//     _badgeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
//       if (!mounted) return;
//       _refreshBadgeCounts();
//     });
//   }
//
//   Future<void> _refreshBadgeCounts() async {
//     try {
//       final results = await Future.wait<int>([
//         _loadNotificationsBadgeCount(),
//         _loadFollowUpBadgeCount(),
//       ]);
//
//       if (!mounted) return;
//
//       setState(() {
//         _notificationsBadgeCount = results[0];
//         _followUpBadgeCount = results[1];
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         _notificationsBadgeCount = 0;
//         _followUpBadgeCount = 0;
//       });
//     }
//   }
//
//   Future<int> _loadNotificationsBadgeCount() async {
//     if (!_isAdmin && !_isSales) {
//       return 0;
//     }
//
//     final dismissals = await _loadDismissalKeys();
//
//     final now = DateTime.now();
//     final startToday = DateTime(now.year, now.month, now.day);
//     final startTomorrow = startToday.add(const Duration(days: 1));
//     final startDayAfterTomorrow = startToday.add(const Duration(days: 2));
//
//     dynamic overdueQuery = _supabase
//         .from('follow_ups')
//         .select('id, assigned_to, due_at, status')
//         .eq('status', 'pending')
//         .lt('due_at', startToday.toUtc().toIso8601String());
//
//     dynamic todayQuery = _supabase
//         .from('follow_ups')
//         .select('id, assigned_to, due_at, status')
//         .eq('status', 'pending')
//         .gte('due_at', startToday.toUtc().toIso8601String())
//         .lt('due_at', startTomorrow.toUtc().toIso8601String());
//
//     dynamic tomorrowQuery = _supabase
//         .from('follow_ups')
//         .select('id, assigned_to, due_at, status')
//         .eq('status', 'pending')
//         .gte('due_at', startTomorrow.toUtc().toIso8601String())
//         .lt('due_at', startDayAfterTomorrow.toUtc().toIso8601String());
//
//     if (_isSales && _currentUserId.isNotEmpty) {
//       overdueQuery = overdueQuery.eq('assigned_to', _currentUserId);
//       todayQuery = todayQuery.eq('assigned_to', _currentUserId);
//       tomorrowQuery = tomorrowQuery.eq('assigned_to', _currentUserId);
//     }
//
//     final overdueResponse = await overdueQuery;
//     final todayResponse = await todayQuery;
//     final tomorrowResponse = await tomorrowQuery;
//
//     final assignmentLogsResponse = await _supabase
//         .from('activity_logs')
//         .select('id, actor_id, action_type, meta')
//         .eq('action_type', 'assign_lead')
//         .order('created_at', ascending: false)
//         .limit(30);
//
//     final overdue = (overdueResponse as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .where(
//           (item) => !_isDismissedKey(
//         dismissals,
//         category: 'overdue_followups',
//         entityType: 'follow_up',
//         entityId: _text(item['id']),
//       ),
//     )
//         .length;
//
//     final dueToday = (todayResponse as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .where(
//           (item) => !_isDismissedKey(
//         dismissals,
//         category: 'due_today_followups',
//         entityType: 'follow_up',
//         entityId: _text(item['id']),
//       ),
//     )
//         .length;
//
//     final dueTomorrow = (tomorrowResponse as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .where(
//           (item) => !_isDismissedKey(
//         dismissals,
//         category: 'due_tomorrow_followups',
//         entityType: 'follow_up',
//         entityId: _text(item['id']),
//       ),
//     )
//         .length;
//
//     final assignmentLogs = (assignmentLogsResponse as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .where((item) {
//       if (_isAdmin) {
//         final actorId = _text(item['actor_id']);
//         return actorId != _currentUserId &&
//             !_isDismissedKey(
//               dismissals,
//               category: 'assignment_logs',
//               entityType: 'activity_log',
//               entityId: _text(item['id']),
//             );
//       }
//
//       if (!_isSales || _currentUserId.isEmpty) return false;
//
//       final meta = _payloadMap(item['meta']);
//       final oldOwnerId = _text(meta['old_owner_id']);
//       final newOwnerId = _text(meta['new_owner_id']);
//
//       final matchesSalesRelevance =
//           oldOwnerId == _currentUserId || newOwnerId == _currentUserId;
//
//       return matchesSalesRelevance &&
//           !_isDismissedKey(
//             dismissals,
//             category: 'assignment_logs',
//             entityType: 'activity_log',
//             entityId: _text(item['id']),
//           );
//     }).length;
//
//     return overdue + dueToday + dueTomorrow + assignmentLogs;
//   }
//
//   Future<int> _loadFollowUpBadgeCount() async {
//     final now = DateTime.now();
//     final startToday = DateTime(now.year, now.month, now.day);
//     final startTomorrow = startToday.add(const Duration(days: 1));
//
//     dynamic query = _supabase
//         .from('follow_ups')
//         .select('id')
//         .eq('status', 'pending')
//         .lt('due_at', startTomorrow.toUtc().toIso8601String());
//
//     if (_isSales && _currentUserId.isNotEmpty) {
//       query = query.eq('assigned_to', _currentUserId);
//     }
//
//     final response = await query;
//     return (response as List).length;
//   }
//
//   Future<Set<String>> _loadDismissalKeys() async {
//     if (_currentUserId.isEmpty) return <String>{};
//
//     final response = await _supabase
//         .from('notification_dismissals')
//         .select('category, entity_type, entity_id')
//         .eq('user_id', _currentUserId);
//
//     return (response as List)
//         .map((row) => Map<String, dynamic>.from(row as Map))
//         .map(
//           (row) => _dismissalKey(
//         category: _text(row['category']),
//         entityType: _text(row['entity_type']),
//         entityId: _text(row['entity_id']),
//       ),
//     )
//         .toSet();
//   }
//
//   String _dismissalKey({
//     required String category,
//     required String entityType,
//     required String entityId,
//   }) {
//     return '$category|$entityType|$entityId';
//   }
//
//   bool _isDismissedKey(
//       Set<String> dismissals, {
//         required String category,
//         required String entityType,
//         required String entityId,
//       }) {
//     return dismissals.contains(
//       _dismissalKey(
//         category: category,
//         entityType: entityType,
//         entityId: entityId,
//       ),
//     );
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
//   String _text(dynamic value) => (value ?? '').toString().trim();
//
//   int _badgeCountFor(String keyName) {
//     switch (keyName) {
//       case 'notifications':
//         return _notificationsBadgeCount;
//       case 'follow_up':
//         return _followUpBadgeCount;
//       default:
//         return 0;
//     }
//   }
//
//   List<_CrmNavItem> get _items {
//     final items = <_CrmNavItem>[
//       _CrmNavItem(
//         keyName: 'home',
//         label: 'Home',
//         icon: Icons.dashboard_outlined,
//         badgeCount: _badgeCountFor('home'),
//         builder: () => HomeDashboardScreen(
//           profile: widget.profile,
//           onLogout: widget.onLogout,
//           showOwnHeader: false,
//         ),
//       ),
//       _CrmNavItem(
//         keyName: 'notifications',
//         label: 'Notifications',
//         icon: Icons.notifications_active_outlined,
//         badgeCount: _badgeCountFor('notifications'),
//         builder: () => NotificationsScreen(
//           profile: widget.profile,
//           onLogout: widget.onLogout,
//           showOwnHeader: false,
//         ),
//       ),
//       _CrmNavItem(
//         keyName: 'leads',
//         label: 'Leads',
//         icon: Icons.people_alt_outlined,
//         badgeCount: _badgeCountFor('leads'),
//         builder: () => LeadsScreen(
//           profile: widget.profile,
//           onLogout: widget.onLogout,
//         ),
//       ),
//       _CrmNavItem(
//         keyName: 'follow_up',
//         label: 'Follow Up',
//         icon: Icons.reply_all_rounded,
//         badgeCount: _badgeCountFor('follow_up'),
//         builder: () => FollowUpScreen(
//           profile: widget.profile,
//           onLogout: widget.onLogout,
//           showOwnHeader: false,
//         ),
//       ),
//       _CrmNavItem(
//         keyName: 'products',
//         label: 'Products',
//         icon: Icons.inventory_2_outlined,
//         badgeCount: _badgeCountFor('products'),
//         builder: () => PriceListScreen(
//           profile: widget.profile,
//           onLogout: widget.onLogout,
//         ),
//       ),
//     ];
//
//     if (_isAdmin) {
//       items.add(
//         _CrmNavItem(
//           keyName: 'statistics',
//           label: 'Statistics',
//           icon: Icons.bar_chart_rounded,
//           badgeCount: _badgeCountFor('statistics'),
//           builder: () => StatisticsScreen(
//             profile: widget.profile,
//             onLogout: widget.onLogout,
//             showOwnHeader: false,
//           ),
//         ),
//       );
//
//       if (_canAssignLeads) {
//         items.add(
//           _CrmNavItem(
//             keyName: 'shared_leads',
//             label: 'Shared Leads',
//             icon: Icons.share_outlined,
//             badgeCount: _badgeCountFor('shared_leads'),
//             builder: () => SharedLeadsScreen(
//               profile: widget.profile,
//               onLogout: widget.onLogout,
//               showOwnHeader: false,
//             ),
//           ),
//         );
//       }
//
//       items.addAll([
//         _CrmNavItem(
//           keyName: 'agent_performance',
//           label: 'Agent Performance',
//           icon: Icons.groups_2_outlined,
//           badgeCount: _badgeCountFor('agent_performance'),
//           builder: () => AgentPerformanceScreen(
//             profile: widget.profile,
//             onLogout: widget.onLogout,
//             showOwnHeader: false,
//           ),
//         ),
//         _CrmNavItem(
//           keyName: 'user_roles',
//           label: 'User Roles',
//           icon: Icons.admin_panel_settings_outlined,
//           badgeCount: _badgeCountFor('user_roles'),
//           builder: () => UserRoleManagementScreen(
//             currentUserId: (widget.profile['id'] ?? '').toString(),
//           ),
//         ),
//       ]);
//     }
//
//     if (_isAccountant) {
//       items.add(
//         _CrmNavItem(
//           keyName: 'accounting_tools',
//           label: 'Accounting',
//           icon: Icons.receipt_long_outlined,
//           badgeCount: _badgeCountFor('accounting_tools'),
//           builder: () => const _PlaceholderModule(
//             title: 'Accounting',
//             subtitle:
//             'Accountant role is active. Add quotation/accounting tools here next.',
//             icon: Icons.receipt_long_outlined,
//           ),
//         ),
//       );
//     }
//
//     if (_isViewer) {
//       return items
//           .where(
//             (item) =>
//         item.keyName == 'home' ||
//             item.keyName == 'leads' ||
//             item.keyName == 'follow_up',
//       )
//           .toList();
//     }
//
//     return items;
//   }
//
//   void _selectIndex(int index) {
//     if (index < 0 || index >= _items.length) return;
//     setState(() {
//       _selectedIndex = index;
//     });
//     Navigator.of(context).maybePop();
//   }
//
//   Future<void> _deleteMyAccount() async {
//     final confirmed = await _showDeleteAccountDialog();
//     if (confirmed != true) return;
//
//     try {
//       await _supabase.functions.invoke('delete-account');
//       await _supabase.auth.signOut();
//
//       if (!mounted) return;
//       await widget.onLogout();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to delete account: $e')),
//       );
//     }
//   }
//
//   Future<bool?> _showDeleteAccountDialog() {
//     return showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text('Delete My Account'),
//           content: const Text(
//             'This will permanently delete your login account. '
//                 'You will lose access immediately. This action cannot be undone.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(false),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () => Navigator.of(dialogContext).pop(true),
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWide = MediaQuery.of(context).size.width >= 1024;
//     final items = _items;
//
//     final mobileNavItems = items.take(5).toList();
//     final mobileSelectedIndex =
//     _selectedIndex < mobileNavItems.length ? _selectedIndex : 0;
//
//     if (_selectedIndex >= items.length) {
//       _selectedIndex = 0;
//     }
//
//     final currentItem = items[_selectedIndex];
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       drawer: isWide
//           ? null
//           : _CrmDrawer(
//         items: items,
//         selectedIndex: _selectedIndex,
//         onSelect: _selectIndex,
//         profile: widget.profile,
//         onLogout: widget.onLogout,
//       ),
//       body: SafeArea(
//         child: isWide
//             ? Row(
//           children: [
//             _CrmSidebar(
//               items: items,
//               selectedIndex: _selectedIndex,
//               onSelect: _selectIndex,
//               profile: widget.profile,
//               onLogout: widget.onLogout,
//             ),
//             const VerticalDivider(
//               width: 1,
//               thickness: 1,
//               color: Color(0xFF3A2F0B),
//             ),
//             Expanded(
//               child: Column(
//                 children: [
//                   _CrmTopBar(
//                     title: currentItem.label,
//                     profile: widget.profile,
//                     onLogout: widget.onLogout,
//                     onDeleteAccount: _deleteMyAccount,
//                   ),
//                   const Divider(
//                     height: 1,
//                     thickness: 1,
//                     color: Color(0xFF3A2F0B),
//                   ),
//                   Expanded(
//                     child: KeyedSubtree(
//                       key: ValueKey(currentItem.keyName),
//                       child: currentItem.builder(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         )
//             : Column(
//           children: [
//             _CrmMobileTopBar(
//               title: currentItem.label,
//               profile: widget.profile,
//               onLogout: widget.onLogout,
//               onDeleteAccount: _deleteMyAccount,
//             ),
//             const Divider(
//               height: 1,
//               thickness: 1,
//               color: Color(0xFF3A2F0B),
//             ),
//             Expanded(
//               child: KeyedSubtree(
//                 key: ValueKey(currentItem.keyName),
//                 child: currentItem.builder(),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: isWide
//           ? null
//           : NavigationBar(
//         selectedIndex: mobileSelectedIndex,
//         onDestinationSelected: _selectIndex,
//         destinations: mobileNavItems.map((item) {
//           return NavigationDestination(
//             icon: _NavIconWithBadge(
//               icon: item.icon,
//               badgeCount: item.badgeCount,
//               selected: false,
//             ),
//             selectedIcon: _NavIconWithBadge(
//               icon: item.icon,
//               badgeCount: item.badgeCount,
//               selected: true,
//             ),
//             label: item.label,
//           );
//         }).toList(),
//       ),
//     );
//   }
// }
//
// class _CrmNavItem {
//   final String keyName;
//   final String label;
//   final IconData icon;
//   final int badgeCount;
//   final Widget Function() builder;
//
//   const _CrmNavItem({
//     required this.keyName,
//     required this.label,
//     required this.icon,
//     required this.badgeCount,
//     required this.builder,
//   });
// }
//
// class _NavIconWithBadge extends StatelessWidget {
//   final IconData icon;
//   final int badgeCount;
//   final bool selected;
//
//   const _NavIconWithBadge({
//     required this.icon,
//     required this.badgeCount,
//     required this.selected,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final text = badgeCount > 99 ? '99+' : badgeCount.toString();
//
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Icon(
//           icon,
//           color: selected ? AppConstants.primaryColor : null,
//         ),
//         if (badgeCount > 0)
//           Positioned(
//             right: -10,
//             top: -8,
//             child: Container(
//               constraints: const BoxConstraints(
//                 minWidth: 18,
//                 minHeight: 18,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFB00020),
//                 borderRadius: BorderRadius.circular(999),
//                 border: Border.all(
//                   color: const Color(0xFF111111),
//                   width: 1.2,
//                 ),
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 text,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w900,
//                   height: 1,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
//
// class _CrmSidebar extends StatelessWidget {
//   final List<_CrmNavItem> items;
//   final int selectedIndex;
//   final ValueChanged<int> onSelect;
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//
//   const _CrmSidebar({
//     required this.items,
//     required this.selectedIndex,
//     required this.onSelect,
//     required this.profile,
//     required this.onLogout,
//   });
//
//   String _displayName() {
//     final fullName = (profile['full_name'] ?? '').toString().trim();
//     final email = (profile['email'] ?? '').toString().trim();
//     return fullName.isNotEmpty ? fullName : email;
//   }
//
//   String _role() {
//     return (profile['role'] ?? '').toString().trim().toUpperCase();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 280,
//       color: const Color(0xFF111111),
//       child: Column(
//         children: [
//           Container(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: 200,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Image.asset(
//                           'assets/icons/logo.png',
//                           height: 40,
//                         ),
//                         const Text(
//                           'Flower Center CRM',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w900,
//                             color: AppConstants.primaryColor,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     _displayName(),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _role(),
//                     style: const TextStyle(
//                       color: AppConstants.primaryColor,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 final item = items[index];
//                 final selected = index == selectedIndex;
//
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(16),
//                       onTap: () => onSelect(index),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 14,
//                         ),
//                         decoration: BoxDecoration(
//                           color: selected
//                               ? const Color(0xFF2B220B)
//                               : const Color(0xFF141414),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: selected
//                                 ? AppConstants.primaryColor
//                                 : const Color(0xFF3A2F0B),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             _NavIconWithBadge(
//                               icon: item.icon,
//                               badgeCount: item.badgeCount,
//                               selected: selected,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 item.label,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w700,
//                                   color: selected
//                                       ? AppConstants.primaryColor
//                                       : null,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const Divider(height: 1, thickness: 1, color: Color(0xFF3A2F0B)),
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: onLogout,
//                 icon: const Icon(Icons.logout_rounded),
//                 label: const Text('Logout'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CrmDrawer extends StatelessWidget {
//   final List<_CrmNavItem> items;
//   final int selectedIndex;
//   final ValueChanged<int> onSelect;
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//
//   const _CrmDrawer({
//     required this.items,
//     required this.selectedIndex,
//     required this.onSelect,
//     required this.profile,
//     required this.onLogout,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final fullName = (profile['full_name'] ?? '').toString().trim();
//     final email = (profile['email'] ?? '').toString().trim();
//     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
//
//     return Drawer(
//       backgroundColor: const Color(0xFF111111),
//       child: SafeArea(
//         child: Column(
//           children: [
//             ListTile(
//               title: const Text(
//                 'Flower Center CRM',
//                 style: TextStyle(
//                   color: AppConstants.primaryColor,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               subtitle: Text(
//                 fullName.isNotEmpty ? '$fullName • $role' : '$email • $role',
//               ),
//             ),
//             const Divider(color: Color(0xFF3A2F0B)),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final item = items[index];
//                   return ListTile(
//                     selected: index == selectedIndex,
//                     leading: _NavIconWithBadge(
//                       icon: item.icon,
//                       badgeCount: item.badgeCount,
//                       selected: index == selectedIndex,
//                     ),
//                     title: Text(item.label),
//                     onTap: () => onSelect(index),
//                   );
//                 },
//               ),
//             ),
//             const Divider(color: Color(0xFF3A2F0B)),
//             ListTile(
//               leading: const Icon(Icons.logout_rounded),
//               title: const Text('Logout'),
//               onTap: () async {
//                 Navigator.of(context).pop();
//                 await onLogout();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _CrmTopBar extends StatelessWidget {
//   final String title;
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final Future<void> Function() onDeleteAccount;
//
//   const _CrmTopBar({
//     required this.title,
//     required this.profile,
//     required this.onLogout,
//     required this.onDeleteAccount,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final fullName = (profile['full_name'] ?? '').toString().trim();
//     final email = (profile['email'] ?? '').toString().trim();
//
//     return Container(
//       height: 72,
//       color: const Color(0xFF111111),
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ),
//           ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 260),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Flexible(
//                   child: Text(
//                     fullName.isNotEmpty ? fullName : email,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 PopupMenuButton<String>(
//                   onSelected: (value) async {
//                     if (value == 'delete_account') {
//                       await onDeleteAccount();
//                     } else if (value == 'logout') {
//                       await onLogout();
//                     }
//                   },
//                   itemBuilder: (_) => const [
//                     PopupMenuItem<String>(
//                       value: 'delete_account',
//                       child: Text('Delete My Account'),
//                     ),
//                     PopupMenuItem<String>(
//                       value: 'logout',
//                       child: Text('Logout'),
//                     ),
//                   ],
//                   icon: const Icon(Icons.account_circle_outlined),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CrmMobileTopBar extends StatelessWidget {
//   final String title;
//   final Map<String, dynamic> profile;
//   final Future<void> Function() onLogout;
//   final Future<void> Function() onDeleteAccount;
//
//   const _CrmMobileTopBar({
//     required this.title,
//     required this.profile,
//     required this.onLogout,
//     required this.onDeleteAccount,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final fullName = (profile['full_name'] ?? '').toString().trim();
//     final email = (profile['email'] ?? '').toString().trim();
//
//     return Container(
//       color: const Color(0xFF111111),
//       height: 64,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Row(
//         children: [
//           Builder(
//             builder: (context) {
//               return IconButton(
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//                 icon: const Icon(Icons.menu_rounded),
//               );
//             },
//           ),
//           Expanded(
//             child: Text(
//               title,
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ),
//           PopupMenuButton<String>(
//             onSelected: (value) async {
//               if (value == 'delete_account') {
//                 await onDeleteAccount();
//               } else if (value == 'logout') {
//                 await onLogout();
//               }
//             },
//             itemBuilder: (_) => [
//               PopupMenuItem<String>(
//                 enabled: false,
//                 value: 'user_label',
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       fullName.isNotEmpty ? fullName : email,
//                       style: const TextStyle(fontWeight: FontWeight.w700),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       email,
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuDivider(),
//               const PopupMenuItem<String>(
//                 value: 'delete_account',
//                 child: Text('Delete My Account'),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'logout',
//                 child: Text('Logout'),
//               ),
//             ],
//             icon: const Icon(Icons.account_circle_outlined),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _DashboardPlaceholder extends StatelessWidget {
//   final Map<String, dynamic> profile;
//
//   const _DashboardPlaceholder({
//     required this.profile,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final role = (profile['role'] ?? '').toString().trim().toUpperCase();
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Wrap(
//             spacing: 14,
//             runSpacing: 14,
//             children: const [
//               _StatCard(
//                 title: 'Total Leads',
//                 value: '—',
//                 icon: Icons.people_outline_rounded,
//               ),
//               _StatCard(
//                 title: 'Important Leads',
//                 value: '—',
//                 icon: Icons.star_outline_rounded,
//               ),
//               _StatCard(
//                 title: 'Follow-ups',
//                 value: '—',
//                 icon: Icons.reply_all_rounded,
//               ),
//             ],
//           ),
//           const SizedBox(height: 18),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: const Color(0xFF141414),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: const Color(0xFF3A2F0B)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Dashboard placeholder',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'Logged in as $role. The CRM shell is now ready. Next modules to build are Important Leads, Follow Up, Shared Leads, and Statistics.',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _StatCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//
//   const _StatCard({
//     required this.title,
//     required this.value,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 240,
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
//               child: Icon(icon, color: AppConstants.primaryColor),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     value,
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(title),
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
// class _PlaceholderModule extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//
//   const _PlaceholderModule({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           constraints: const BoxConstraints(maxWidth: 620),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: const Color(0xFF141414),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFF3A2F0B)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 44, color: AppConstants.primaryColor),
//               const SizedBox(height: 14),
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w900,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 subtitle,
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';

import 'package:FlowerCenterCrm/shell/crm/shared_leads_screen.dart';
import 'package:FlowerCenterCrm/shell/crm/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../price_list_screen.dart';
import '../../user_role_management_screen.dart';
import 'agent_performance_screen.dart';
import 'follow_up_screen.dart';
import 'home_dashboard_screen.dart';
import 'leads_screen.dart';
import 'notifications_screen.dart';

class CrmShellScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;

  const CrmShellScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  State<CrmShellScreen> createState() => _CrmShellScreenState();
}

class _CrmShellScreenState extends State<CrmShellScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _selectedIndex = 0;

  RealtimeChannel? _badgeChannel;
  Timer? _badgeRefreshDebounce;

  int _notificationsBadgeCount = 0;
  int _followUpBadgeCount = 0;

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  bool get _isViewer => _role == 'viewer';
  bool get _isAccountant => _role == 'accountant';

  String get _currentUserId =>
      (widget.profile['id'] ?? '').toString().trim();

  bool get _canAssignLeads =>
      _isAdmin && widget.profile['can_assign_leads'] == true;

  @override
  void initState() {
    super.initState();
    _setupBadgeRealtime();
    _refreshBadgeCounts();
  }

  @override
  void dispose() {
    _badgeRefreshDebounce?.cancel();

    final channel = _badgeChannel;
    _badgeChannel = null;
    if (channel != null) {
      unawaited(_supabase.removeChannel(channel));
    }

    super.dispose();
  }

  void _setupBadgeRealtime() {
    final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;

    _badgeChannel = _supabase
        .channel('crm-shell-badges-$channelKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'follow_ups',
      callback: (_) => _scheduleBadgeRefresh(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'activity_logs',
      callback: (_) => _scheduleBadgeRefresh(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notification_dismissals',
      callback: (_) => _scheduleBadgeRefresh(),
    )
        .subscribe();
  }

  void _scheduleBadgeRefresh() {
    _badgeRefreshDebounce?.cancel();
    _badgeRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _refreshBadgeCounts();
    });
  }

  Future<void> _refreshBadgeCounts() async {
    try {
      final results = await Future.wait<int>([
        _loadNotificationsBadgeCount(),
        _loadFollowUpBadgeCount(),
      ]);

      if (!mounted) return;

      setState(() {
        _notificationsBadgeCount = results[0];
        _followUpBadgeCount = results[1];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationsBadgeCount = 0;
        _followUpBadgeCount = 0;
      });
    }
  }

  Future<int> _loadNotificationsBadgeCount() async {
    if (!_isAdmin && !_isSales) {
      return 0;
    }

    final dismissals = await _loadDismissalKeys();

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startTomorrow = startToday.add(const Duration(days: 1));
    final startDayAfterTomorrow = startToday.add(const Duration(days: 2));

    dynamic overdueQuery = _supabase
        .from('follow_ups')
        .select('id, assigned_to, due_at, status')
        .eq('status', 'pending')
        .lt('due_at', startToday.toUtc().toIso8601String());

    dynamic todayQuery = _supabase
        .from('follow_ups')
        .select('id, assigned_to, due_at, status')
        .eq('status', 'pending')
        .gte('due_at', startToday.toUtc().toIso8601String())
        .lt('due_at', startTomorrow.toUtc().toIso8601String());

    dynamic tomorrowQuery = _supabase
        .from('follow_ups')
        .select('id, assigned_to, due_at, status')
        .eq('status', 'pending')
        .gte('due_at', startTomorrow.toUtc().toIso8601String())
        .lt('due_at', startDayAfterTomorrow.toUtc().toIso8601String());

    if (_isSales && _currentUserId.isNotEmpty) {
      overdueQuery = overdueQuery.eq('assigned_to', _currentUserId);
      todayQuery = todayQuery.eq('assigned_to', _currentUserId);
      tomorrowQuery = tomorrowQuery.eq('assigned_to', _currentUserId);
    }

    final overdueResponse = await overdueQuery;
    final todayResponse = await todayQuery;
    final tomorrowResponse = await tomorrowQuery;

    final assignmentLogsResponse = await _supabase
        .from('activity_logs')
        .select('id, actor_id, action_type, meta')
        .eq('action_type', 'assign_lead')
        .order('created_at', ascending: false)
        .limit(30);

    final overdue = (overdueResponse as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(
          (item) => !_isDismissedKey(
        dismissals,
        category: 'overdue_followups',
        entityType: 'follow_up',
        entityId: _text(item['id']),
      ),
    )
        .length;

    final dueToday = (todayResponse as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(
          (item) => !_isDismissedKey(
        dismissals,
        category: 'due_today_followups',
        entityType: 'follow_up',
        entityId: _text(item['id']),
      ),
    )
        .length;

    final dueTomorrow = (tomorrowResponse as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(
          (item) => !_isDismissedKey(
        dismissals,
        category: 'due_tomorrow_followups',
        entityType: 'follow_up',
        entityId: _text(item['id']),
      ),
    )
        .length;

    final assignmentLogs = (assignmentLogsResponse as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((item) {
      if (_isAdmin) {
        final actorId = _text(item['actor_id']);
        return actorId != _currentUserId &&
            !_isDismissedKey(
              dismissals,
              category: 'assignment_logs',
              entityType: 'activity_log',
              entityId: _text(item['id']),
            );
      }

      if (!_isSales || _currentUserId.isEmpty) return false;

      final meta = _payloadMap(item['meta']);
      final oldOwnerId = _text(meta['old_owner_id']);
      final newOwnerId = _text(meta['new_owner_id']);

      final matchesSalesRelevance =
          oldOwnerId == _currentUserId || newOwnerId == _currentUserId;

      return matchesSalesRelevance &&
          !_isDismissedKey(
            dismissals,
            category: 'assignment_logs',
            entityType: 'activity_log',
            entityId: _text(item['id']),
          );
    }).length;

    return overdue + dueToday + dueTomorrow + assignmentLogs;
  }

  Future<int> _loadFollowUpBadgeCount() async {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startTomorrow = startToday.add(const Duration(days: 1));

    dynamic query = _supabase
        .from('follow_ups')
        .select('id')
        .eq('status', 'pending')
        .lt('due_at', startTomorrow.toUtc().toIso8601String());

    if (_isSales && _currentUserId.isNotEmpty) {
      query = query.eq('assigned_to', _currentUserId);
    }

    final response = await query;
    return (response as List).length;
  }

  Future<Set<String>> _loadDismissalKeys() async {
    if (_currentUserId.isEmpty) return <String>{};

    final response = await _supabase
        .from('notification_dismissals')
        .select('category, entity_type, entity_id')
        .eq('user_id', _currentUserId);

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map(
          (row) => _dismissalKey(
        category: _text(row['category']),
        entityType: _text(row['entity_type']),
        entityId: _text(row['entity_id']),
      ),
    )
        .toSet();
  }

  String _dismissalKey({
    required String category,
    required String entityType,
    required String entityId,
  }) {
    return '$category|$entityType|$entityId';
  }

  bool _isDismissedKey(
      Set<String> dismissals, {
        required String category,
        required String entityType,
        required String entityId,
      }) {
    return dismissals.contains(
      _dismissalKey(
        category: category,
        entityType: entityType,
        entityId: entityId,
      ),
    );
  }

  Map<String, dynamic> _payloadMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  int _badgeCountFor(String keyName) {
    switch (keyName) {
      case 'notifications':
        return _notificationsBadgeCount;
      case 'follow_up':
        return _followUpBadgeCount;
      default:
        return 0;
    }
  }

  List<_CrmNavItem> get _items {
    final items = <_CrmNavItem>[
      _CrmNavItem(
        keyName: 'home',
        label: 'Home',
        icon: Icons.dashboard_outlined,
        badgeCount: _badgeCountFor('home'),
        builder: () => HomeDashboardScreen(
          profile: widget.profile,
          onLogout: widget.onLogout,
          showOwnHeader: false,
        ),
      ),
      _CrmNavItem(
        keyName: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_active_outlined,
        badgeCount: _badgeCountFor('notifications'),
        builder: () => NotificationsScreen(
          profile: widget.profile,
          onLogout: widget.onLogout,
          showOwnHeader: false,
        ),
      ),
      _CrmNavItem(
        keyName: 'leads',
        label: 'Leads',
        icon: Icons.people_alt_outlined,
        badgeCount: _badgeCountFor('leads'),
        builder: () => LeadsScreen(
          profile: widget.profile,
          onLogout: widget.onLogout,
        ),
      ),
      _CrmNavItem(
        keyName: 'follow_up',
        label: 'Follow Up',
        icon: Icons.reply_all_rounded,
        badgeCount: _badgeCountFor('follow_up'),
        builder: () => FollowUpScreen(
          profile: widget.profile,
          onLogout: widget.onLogout,
          showOwnHeader: false,
        ),
      ),
      _CrmNavItem(
        keyName: 'products',
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        badgeCount: _badgeCountFor('products'),
        builder: () => PriceListScreen(
          profile: widget.profile,
          onLogout: widget.onLogout,
        ),
      ),
    ];

    if (_isAdmin) {
      items.add(
        _CrmNavItem(
          keyName: 'statistics',
          label: 'Statistics',
          icon: Icons.bar_chart_rounded,
          badgeCount: _badgeCountFor('statistics'),
          builder: () => StatisticsScreen(
            profile: widget.profile,
            onLogout: widget.onLogout,
            showOwnHeader: false,
          ),
        ),
      );

      if (_canAssignLeads) {
        items.add(
          _CrmNavItem(
            keyName: 'shared_leads',
            label: 'Shared Leads',
            icon: Icons.share_outlined,
            badgeCount: _badgeCountFor('shared_leads'),
            builder: () => SharedLeadsScreen(
              profile: widget.profile,
              onLogout: widget.onLogout,
              showOwnHeader: false,
            ),
          ),
        );
      }

      items.addAll([
        _CrmNavItem(
          keyName: 'agent_performance',
          label: 'Agent Performance',
          icon: Icons.groups_2_outlined,
          badgeCount: _badgeCountFor('agent_performance'),
          builder: () => AgentPerformanceScreen(
            profile: widget.profile,
            onLogout: widget.onLogout,
            showOwnHeader: false,
          ),
        ),
        _CrmNavItem(
          keyName: 'user_roles',
          label: 'User Roles',
          icon: Icons.admin_panel_settings_outlined,
          badgeCount: _badgeCountFor('user_roles'),
          builder: () => UserRoleManagementScreen(
            currentUserId: (widget.profile['id'] ?? '').toString(),
          ),
        ),
      ]);
    }

    if (_isAccountant) {
      items.add(
        _CrmNavItem(
          keyName: 'accounting_tools',
          label: 'Accounting',
          icon: Icons.receipt_long_outlined,
          badgeCount: _badgeCountFor('accounting_tools'),
          builder: () => const _PlaceholderModule(
            title: 'Accounting',
            subtitle:
            'Accountant role is active. Add quotation/accounting tools here next.',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      );
    }

    if (_isViewer) {
      return items
          .where(
            (item) =>
        item.keyName == 'home' ||
            item.keyName == 'leads' ||
            item.keyName == 'follow_up',
      )
          .toList();
    }

    return items;
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).maybePop();
  }

  Future<void> _deleteMyAccount() async {
    final confirmed = await _showDeleteAccountDialog();
    if (confirmed != true) return;

    try {
      await _supabase.functions.invoke('delete-account');
      await _supabase.auth.signOut();

      if (!mounted) return;
      await widget.onLogout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  Future<bool?> _showDeleteAccountDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete My Account'),
          content: const Text(
            'This will permanently delete your login account. '
                'You will lose access immediately. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final items = _items;

    final mobileNavItems = items.take(5).toList();
    final mobileSelectedIndex =
    _selectedIndex < mobileNavItems.length ? _selectedIndex : 0;

    if (_selectedIndex >= items.length) {
      _selectedIndex = 0;
    }

    final currentItem = items[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: isWide
          ? null
          : _CrmDrawer(
        items: items,
        selectedIndex: _selectedIndex,
        onSelect: _selectIndex,
        profile: widget.profile,
        onLogout: widget.onLogout,
        onDeleteAccount: _deleteMyAccount,
      ),
      body: SafeArea(
        child: isWide
            ? Row(
          children: [
            _CrmSidebar(
              items: items,
              selectedIndex: _selectedIndex,
              onSelect: _selectIndex,
              profile: widget.profile,
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFF2A220A),
            ),
            Expanded(
              child: Column(
                children: [
                  _CrmTopBar(
                    title: currentItem.label,
                    profile: widget.profile,
                    onLogout: widget.onLogout,
                    onDeleteAccount: _deleteMyAccount,
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF2A220A),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(currentItem.keyName),
                      child: currentItem.builder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            _CrmMobileTopBar(
              title: currentItem.label,
              profile: widget.profile,
              onLogout: widget.onLogout,
              onDeleteAccount: _deleteMyAccount,
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF2A220A),
            ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey(currentItem.keyName),
                child: currentItem.builder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
        selectedIndex: mobileSelectedIndex,
        onDestinationSelected: _selectIndex,
        destinations: mobileNavItems.map((item) {
          return NavigationDestination(
            icon: _NavIconWithBadge(
              icon: item.icon,
              badgeCount: item.badgeCount,
              selected: false,
            ),
            selectedIcon: _NavIconWithBadge(
              icon: item.icon,
              badgeCount: item.badgeCount,
              selected: true,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _CrmNavItem {
  final String keyName;
  final String label;
  final IconData icon;
  final int badgeCount;
  final Widget Function() builder;

  const _CrmNavItem({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.badgeCount,
    required this.builder,
  });
}

class _NavIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final bool selected;

  const _NavIconWithBadge({
    required this.icon,
    required this.badgeCount,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final text = badgeCount > 99 ? '99+' : badgeCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: selected ? AppConstants.primaryColor : null,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB00020),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF111111),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CrmSidebar extends StatelessWidget {
  final List<_CrmNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Map<String, dynamic> profile;

  const _CrmSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.profile,
  });

  String _displayName() {
    final fullName = (profile['full_name'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();
    return fullName.isNotEmpty ? fullName : email;
  }

  String _role() {
    return (profile['role'] ?? '').toString().trim().toUpperCase();
  }

  bool _isPrimaryKey(String key) {
    return key == 'home' ||
        key == 'notifications' ||
        key == 'leads' ||
        key == 'follow_up' ||
        key == 'products';
  }

  @override
  Widget build(BuildContext context) {
    final primaryEntries = <MapEntry<int, _CrmNavItem>>[];
    final secondaryEntries = <MapEntry<int, _CrmNavItem>>[];

    for (var i = 0; i < items.length; i++) {
      final entry = MapEntry(i, items[i]);
      if (_isPrimaryKey(items[i].keyName)) {
        primaryEntries.add(entry);
      } else {
        secondaryEntries.add(entry);
      }
    }

    return Container(
      width: 252,
      color: const Color(0xFF101010),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/logo.png',
                  height: 34,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Flower Center CRM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2A220A)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _role(),
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF2A220A)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              children: [
                if (primaryEntries.isNotEmpty) ...[
                  const _SidebarSectionLabel(label: 'Main'),
                  const SizedBox(height: 6),
                  ...primaryEntries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SidebarNavTile(
                        item: entry.value,
                        selected: entry.key == selectedIndex,
                        onTap: () => onSelect(entry.key),
                      ),
                    ),
                  ),
                ],
                if (secondaryEntries.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SidebarSectionLabel(label: 'More'),
                  const SizedBox(height: 6),
                  ...secondaryEntries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SidebarNavTile(
                        item: entry.value,
                        selected: entry.key == selectedIndex,
                        onTap: () => onSelect(entry.key),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;

  const _SidebarSectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final _CrmNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
    selected ? AppConstants.primaryColor : Colors.white.withOpacity(0.82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF231C09) : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppConstants.primaryColor
                  : const Color(0xFF241E0C),
            ),
          ),
          child: Row(
            children: [
              _NavIconWithBadge(
                icon: item.icon,
                badgeCount: item.badgeCount,
                selected: selected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: foreground,
                    fontSize: 13.5,
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

class _CrmDrawer extends StatelessWidget {
  final List<_CrmNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;

  const _CrmDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.profile,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = (profile['full_name'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();
    final role = (profile['role'] ?? '').toString().trim().toUpperCase();

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Flower Center CRM',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                fullName.isNotEmpty ? '$fullName • $role' : '$email • $role',
              ),
            ),
            const Divider(color: Color(0xFF2A220A)),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    selected: index == selectedIndex,
                    leading: _NavIconWithBadge(
                      icon: item.icon,
                      badgeCount: item.badgeCount,
                      selected: index == selectedIndex,
                    ),
                    title: Text(item.label),
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF2A220A)),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: const Text('Delete My Account'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(onDeleteAccount);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CrmTopBar extends StatelessWidget {
  final String title;
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;

  const _CrmTopBar({
    required this.title,
    required this.profile,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = (profile['full_name'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();
    final displayName = fullName.isNotEmpty ? fullName : email;

    return Container(
      height: 64,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete_account') {
                      await onDeleteAccount();
                    } else if (value == 'logout') {
                      await onLogout();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete_account',
                      child: Text('Delete My Account'),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Logout'),
                    ),
                  ],
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrmMobileTopBar extends StatelessWidget {
  final String title;
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;

  const _CrmMobileTopBar({
    required this.title,
    required this.profile,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = (profile['full_name'] ?? '').toString().trim();
    final email = (profile['email'] ?? '').toString().trim();

    return Container(
      color: const Color(0xFF111111),
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_account') {
                await onDeleteAccount();
              } else if (value == 'logout') {
                await onLogout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                value: 'user_label',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : email,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete_account',
                child: Text('Delete My Account'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _DashboardPlaceholder({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final role = (profile['role'] ?? '').toString().trim().toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _StatCard(
                title: 'Total Leads',
                value: '—',
                icon: Icons.people_outline_rounded,
              ),
              _StatCard(
                title: 'Important Leads',
                value: '—',
                icon: Icons.star_outline_rounded,
              ),
              _StatCard(
                title: 'Follow-ups',
                value: '—',
                icon: Icons.reply_all_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A220A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard placeholder',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Logged in as $role. The CRM shell is now ready. Next modules to build are Important Leads, Follow Up, Shared Leads, and Statistics.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2A220A)),
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
              child: Icon(icon, color: AppConstants.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderModule extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlaceholderModule({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A220A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppConstants.primaryColor),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}