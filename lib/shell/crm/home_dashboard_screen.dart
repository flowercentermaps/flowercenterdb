
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../login_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final bool showOwnHeader;
  final String? customTitle;

  const HomeDashboardScreen({
    super.key,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserProfile get _profile =>
      ref.read(profileProvider).value ??
      const UserProfile(id: '', email: '', name: '', role: '', isActive: false);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _leadStats;
  Map<String, dynamic>? _followUpStats;

  String get _role => _profile.role.trim().toLowerCase();

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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              title: widget.customTitle ?? 'home_title'.tr(),
              showOwnHeader: widget.showOwnHeader,
              profileName: _displayName(),
              role: _role,
              onRefresh: _loadDashboard,
              onLogout: _logout,
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
        title: 'home_error'.tr(),
        message: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
            label:  Text('btn_retry'.tr()),
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
      _KpiData('home_total_leads'.tr(), totalLeads, Icons.people_outline_rounded),
      _KpiData('home_won_leads'.tr(), wonLeads, Icons.emoji_events_outlined),
      _KpiData(
        'home_pending_followups'.tr(),
        pendingFollowUps,
        Icons.schedule_rounded,
      ),
      _KpiData(
        'home_overdue_followups'.tr(),
        overdueFollowUps,
        Icons.warning_amber_rounded,
      ),
    ];

    final pipelineSnapshot = <_SummaryLine>[
      _SummaryLine('status_new'.tr(), newLeads),
      _SummaryLine('status_contacted'.tr(), contactedLeads),
      _SummaryLine('status_qualified'.tr(), qualifiedLeads),
      _SummaryLine('status_won'.tr(), wonLeads),
      _SummaryLine('status_lost'.tr(), lostLeads),
      _SummaryLine('status_important'.tr(), importantLeads),
    ];

    final followUpSnapshot = <_SummaryLine>[
      _SummaryLine('status_pending'.tr(), pendingFollowUps),
      _SummaryLine('status_overdue'.tr(), overdueFollowUps),
      _SummaryLine('status_done'.tr(), doneFollowUps),
      _SummaryLine('status_missed'.tr(), missedFollowUps),
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
                  title: 'home_quick_actions'.tr(),
                  subtitle: 'home_quick_actions_subtitle'.tr(),
                  child: const _QuickActionsPanel(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Panel(
                  title: 'home_attention'.tr(),
                  subtitle: 'home_attention_subtitle'.tr(),
                  child: const _AttentionPanel(),
                ),
              ),
            ],
          )
              : Column(
            children: [
              _Panel(
                title: 'home_quick_actions'.tr(),
                subtitle: 'home_quick_actions_subtitle'.tr(),
                child: const _QuickActionsPanel(),
              ),
              const SizedBox(height: 14),
              _Panel(
                title: 'home_attention'.tr(),
                subtitle: 'home_attention_subtitle'.tr(),
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
                  title: 'home_pipeline'.tr(),
                  items: pipelineSnapshot,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryPanel(
                  title: 'home_followup_snapshot'.tr(),
                  items: followUpSnapshot,
                ),
              ),
            ],
          )
              : Column(
            children: [
              _SummaryPanel(
                title: 'home_pipeline'.tr(),
                items: pipelineSnapshot,
              ),
              const SizedBox(height: 14),
              _SummaryPanel(
                title: 'home_followup_snapshot'.tr(),
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
                  label:  Text('btn_refresh'.tr()),
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
                    itemBuilder: (_) =>  [
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('btn_logout'.tr()),
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
              'home_subtitle'.tr(),
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
          itemBuilder: (_) =>  [
            PopupMenuItem<String>(
              value: 'logout',
              child: Text('btn_logout'.tr()),
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
          label: 'btn_new_lead'.tr(),
        ),
        _action(
          icon: Icons.people_alt_outlined,
          label: 'btn_open_leads'.tr(),
        ),
        _action(
          icon: Icons.reply_all_rounded,
          label: 'btn_open_follow_up'.tr(),
        ),
        _action(
          icon: Icons.share_outlined,
          label: 'btn_assignments'.tr(),
        ),
      ],
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel();

  @override
  Widget build(BuildContext context) {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine('home_attention_1'.tr()),
        SizedBox(height: 8),
        _InfoLine('home_attention_2'.tr()),
        SizedBox(height: 8),
        _InfoLine('home_attention_3'.tr()),
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