import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

class UserRoleManagementScreen extends ConsumerStatefulWidget {
  const UserRoleManagementScreen({super.key});

  @override
  ConsumerState<UserRoleManagementScreen> createState() =>
      _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends ConsumerState<UserRoleManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId =>
      ref.read(profileProvider).value?.id ?? '';

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingAll = false;
  String? _error;

  List<Map<String, dynamic>> _users = [];
  final Map<String, String> _selectedRoles = {};
  final Set<String> _savingUserIds = {};
  String _searchQuery = '';

  // Global price settings
  bool _globalBlockAll = false;
  Set<String> _globalBlockedKeys = {};

  // Per-user price settings
  final Map<String, bool> _userBlockAll = {};        // profileId → blockAll
  final Map<String, Set<String>> _userBlockedKeys = {}; // profileId → blocked keys

  static const List<String> _allowedRoles = [
    'admin',
    'sales',
    'viewer',
    'accountant',
  ];

  static const List<Map<String, String>> _priceKeys = [
    {'key': 'price_ee',  'label': 'EE'},
    {'key': 'price_aa',  'label': 'AA'},
    {'key': 'price_a',   'label': 'A'},
    {'key': 'price_rr',  'label': 'RR'},
    {'key': 'price_r',   'label': 'R'},
    {'key': 'price_art', 'label': 'Special'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('profiles')
            .select('id, email, full_name, role, is_active')
            .order('full_name', ascending: true),
        _supabase
            .from('price_permission_settings')
            .select('block_all_prices')
            .eq('id', 1)
            .maybeSingle(),
        _supabase
            .from('global_blocked_price_keys')
            .select('price_key'),
        _supabase
            .from('profile_price_access')
            .select('profile_id, block_all_prices'),
        _supabase
            .from('profile_blocked_price_keys')
            .select('profile_id, price_key'),
      ]);

      final users = (results[0] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final selectedRoles = <String, String>{};
      for (final user in users) {
        final id = (user['id'] ?? '').toString();
        final role = (user['role'] ?? 'sales').toString().trim();
        if (id.isNotEmpty) {
          selectedRoles[id] = _allowedRoles.contains(role) ? role : 'sales';
        }
      }

      // Global block all
      final globalSettings = results[1] as Map<String, dynamic>?;
      final globalBlockAll = globalSettings?['block_all_prices'] == true;

      // Global blocked keys
      final globalBlockedKeys = (results[2] as List)
          .map((e) => (e as Map)['price_key'].toString())
          .toSet();

      // Per-user block all
      final userBlockAll = <String, bool>{};
      for (final row in (results[3] as List)) {
        final data = Map<String, dynamic>.from(row as Map);
        final id = (data['profile_id'] ?? '').toString();
        if (id.isNotEmpty) {
          userBlockAll[id] = data['block_all_prices'] == true;
        }
      }

      // Per-user blocked keys
      final userBlockedKeys = <String, Set<String>>{};
      for (final row in (results[4] as List)) {
        final data = Map<String, dynamic>.from(row as Map);
        final id = (data['profile_id'] ?? '').toString();
        final key = (data['price_key'] ?? '').toString();
        if (id.isNotEmpty && key.isNotEmpty) {
          userBlockedKeys.putIfAbsent(id, () => {}).add(key);
        }
      }

      if (!mounted) return;
      setState(() {
        _users = users;
        _selectedRoles..clear()..addAll(selectedRoles);
        _globalBlockAll = globalBlockAll;
        _globalBlockedKeys = globalBlockedKeys;
        _userBlockAll..clear()..addAll(userBlockAll);
        _userBlockedKeys..clear()..addAll(userBlockedKeys);
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

  String _userDisplayName(Map<String, dynamic> user) {
    final fullName = (user['full_name'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return tr('roles_unknown_user');
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final name = _userDisplayName(user).toLowerCase();
      final email = (user['email'] ?? '').toString().trim().toLowerCase();
      final role = (user['role'] ?? '').toString().trim().toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          role.contains(_searchQuery);
    }).toList();
  }

  bool _hasRoleChanged(Map<String, dynamic> user) {
    final id = (user['id'] ?? '').toString();
    final currentRole = (user['role'] ?? '').toString().trim();
    final selectedRole = _selectedRoles[id] ?? currentRole;
    return currentRole != selectedRole;
  }

  // ── Role saving ───────────────────────────────────────────────

  Future<void> _saveUserRole(Map<String, dynamic> user) async {
    final profileId = (user['id'] ?? '').toString();
    if (profileId.isEmpty || _savingUserIds.contains(profileId)) return;
    final newRole = _selectedRoles[profileId];
    final currentRole = (user['role'] ?? '').toString().trim();
    if (newRole == null || newRole == currentRole) return;
    if (profileId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_cannot_change_own'))),
      );
      return;
    }
    setState(() => _savingUserIds.add(profileId));
    try {
      await _supabase.from('profiles').update({'role': newRole}).eq('id', profileId);
      final index = _users.indexWhere((u) => (u['id'] ?? '').toString() == profileId);
      if (index != -1) _users[index]['role'] = newRole;
      if (!mounted) return;
      setState(() => _savingUserIds.remove(profileId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_updated', namedArgs: {'role': newRole}))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingUserIds.remove(profileId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_update_failed', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _saveAllChangedRoles() async {
    if (_isSavingAll) return;
    final changedUsers = _filteredUsers.where(_hasRoleChanged).toList();
    if (changedUsers.isEmpty) return;
    setState(() => _isSavingAll = true);
    try {
      for (final user in changedUsers) {
        final profileId = (user['id'] ?? '').toString();
        if (profileId == _currentUserId) continue;
        final newRole = _selectedRoles[profileId];
        if (newRole == null) continue;
        await _supabase.from('profiles').update({'role': newRole}).eq('id', profileId);
        user['role'] = newRole;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_saved', namedArgs: {'n': changedUsers.length.toString()}))),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_save_failed', namedArgs: {'error': e.toString()}))),
      );
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  // ── Global price permission helpers ───────────────────────────

  Future<void> _toggleGlobalBlockAll(bool value) async {
    setState(() => _globalBlockAll = value);
    try {
      await _supabase
          .from('price_permission_settings')
          .update({'block_all_prices': value})
          .eq('id', 1);
    } catch (e) {
      setState(() => _globalBlockAll = !value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _toggleGlobalPriceKey(String key) async {
    final wasBlocked = _globalBlockedKeys.contains(key);
    setState(() {
      if (wasBlocked) _globalBlockedKeys.remove(key);
      else _globalBlockedKeys.add(key);
    });
    try {
      if (wasBlocked) {
        await _supabase
            .from('global_blocked_price_keys')
            .delete()
            .eq('price_key', key);
      } else {
        await _supabase
            .from('global_blocked_price_keys')
            .insert({'price_key': key, 'created_by': _currentUserId});
      }
    } catch (e) {
      setState(() {
        if (wasBlocked) _globalBlockedKeys.add(key);
        else _globalBlockedKeys.remove(key);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  // ── Per-user price permission helpers ─────────────────────────

  Future<void> _toggleUserBlockAll(String profileId, bool value) async {
    setState(() => _userBlockAll[profileId] = value);
    try {
      await _supabase.from('profile_price_access').upsert(
        {
          'profile_id': profileId,
          'block_all_prices': value,
          'updated_by': _currentUserId,
        },
        onConflict: 'profile_id',
      );
    } catch (e) {
      setState(() => _userBlockAll[profileId] = !value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _toggleUserPriceKey(String profileId, String key) async {
    final blocked = _userBlockedKeys[profileId]?.contains(key) ?? false;
    setState(() {
      _userBlockedKeys.putIfAbsent(profileId, () => {});
      if (blocked) _userBlockedKeys[profileId]!.remove(key);
      else _userBlockedKeys[profileId]!.add(key);
    });
    try {
      if (blocked) {
        await _supabase
            .from('profile_blocked_price_keys')
            .delete()
            .eq('profile_id', profileId)
            .eq('price_key', key);
      } else {
        await _supabase
            .from('profile_blocked_price_keys')
            .insert({'profile_id': profileId, 'price_key': key, 'created_by': _currentUserId});
      }
    } catch (e) {
      setState(() {
        if (blocked) _userBlockedKeys[profileId]!.add(key);
        else _userBlockedKeys[profileId]!.remove(key);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update price permission: $e')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('roles_title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Global Price Settings ──────────────────
                      _GlobalPriceSettingsCard(
                        globalBlockAll: _globalBlockAll,
                        globalBlockedKeys: _globalBlockedKeys,
                        priceKeys: _priceKeys,
                        onToggleBlockAll: _toggleGlobalBlockAll,
                        onTogglePriceKey: _toggleGlobalPriceKey,
                      ),
                      const SizedBox(height: 20),

                      // ── Search + Save All ──────────────────────
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: tr('roles_search_label'),
                          hintText: tr('roles_search_hint'),
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('roles_count', namedArgs: {'n': _filteredUsers.length.toString()}),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isSavingAll ? null : _saveAllChangedRoles,
                            icon: _isSavingAll
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: Text(_isSavingAll ? 'Saving...' : tr('btn_save_all')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── User cards ─────────────────────────────
                      ..._filteredUsers.map((user) {
                        final profileId = (user['id'] ?? '').toString();
                        final isActive = user['is_active'] == true;
                        final currentRole = (user['role'] ?? 'sales').toString().trim();
                        final selectedRole = _selectedRoles[profileId] ?? currentRole;
                        final changed = currentRole != selectedRole;
                        final isSelf = profileId == _currentUserId;
                        final isSaving = _savingUserIds.contains(profileId);
                        final blockAll = _userBlockAll[profileId] ?? false;
                        final blockedKeys = _userBlockedKeys[profileId] ?? {};

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF3A2F0B)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + active badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userDisplayName(user),
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (user['email'] ?? '').toString(),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          tr('roles_current', namedArgs: {'role': currentRole.toUpperCase()}),
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF1F3A1F) : const Color(0xFF3A1F1F),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isActive ? tr('roles_active') : tr('roles_inactive'),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Role dropdown
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: InputDecoration(labelText: tr('roles_new_role')),
                                items: _allowedRoles
                                    .map((role) => DropdownMenuItem<String>(
                                          value: role,
                                          child: Text(role.toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: isSelf
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => _selectedRoles[profileId] = value);
                                      },
                              ),
                              const SizedBox(height: 12),

                              // Save role row
                              Row(
                                children: [
                                  if (isSelf)
                                    Expanded(
                                      child: Text(
                                        tr('roles_own_role'),
                                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  else if (changed)
                                    Expanded(
                                      child: Text(
                                        tr('roles_pending', namedArgs: {
                                          'from': currentRole.toUpperCase(),
                                          'to': selectedRole.toUpperCase(),
                                        }),
                                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: Text(
                                        tr('roles_no_changes'),
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: (!changed || isSelf || isSaving) ? null : () => _saveUserRole(user),
                                    icon: isSaving
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.save_outlined),
                                    label: Text(isSaving ? 'Saving...' : tr('btn_save')),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFF2A2A2A), height: 1),
                              const SizedBox(height: 12),

                              // Price Access section
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Price Access',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                  if (!isSelf) ...[
                                    Text(
                                      'Block all',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Switch(
                                      value: blockAll,
                                      onChanged: (val) => _toggleUserBlockAll(profileId, val),
                                      activeColor: Colors.redAccent,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (blockAll)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'All prices hidden for this user',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _priceKeys.map((pk) {
                                    final key = pk['key']!;
                                    final label = pk['label']!;
                                    final isBlocked = blockedKeys.contains(key) || _globalBlockedKeys.contains(key);
                                    final isGloballyBlocked = _globalBlockedKeys.contains(key);
                                    final allowed = !isBlocked;
                                    return FilterChip(
                                      label: Text(
                                        label,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      selected: allowed,
                                      onSelected: (isSelf || isGloballyBlocked)
                                          ? null
                                          : (_) => _toggleUserPriceKey(profileId, key),
                                      selectedColor: const Color(0xFFC8A850).withOpacity(0.18),
                                      backgroundColor: Colors.white.withOpacity(0.04),
                                      side: BorderSide(
                                        color: isGloballyBlocked
                                            ? Colors.red.withOpacity(0.4)
                                            : allowed
                                                ? const Color(0xFFC8A850)
                                                : Colors.white.withOpacity(0.12),
                                      ),
                                      checkmarkColor: const Color(0xFFC8A850),
                                      tooltip: isGloballyBlocked ? 'Blocked globally' : null,
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

// ── Global Price Settings Card ─────────────────────────────────────────────────

class _GlobalPriceSettingsCard extends StatelessWidget {
  final bool globalBlockAll;
  final Set<String> globalBlockedKeys;
  final List<Map<String, String>> priceKeys;
  final ValueChanged<bool> onToggleBlockAll;
  final ValueChanged<String> onTogglePriceKey;

  const _GlobalPriceSettingsCard({
    required this.globalBlockAll,
    required this.globalBlockedKeys,
    required this.priceKeys,
    required this.onToggleBlockAll,
    required this.onTogglePriceKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5A4010)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded, size: 18, color: Color(0xFFC8A850)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Global Price Settings',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFFC8A850),
                  ),
                ),
              ),
              Text(
                'Block all prices',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(width: 6),
              Switch(
                value: globalBlockAll,
                onChanged: onToggleBlockAll,
                activeColor: Colors.redAccent,
              ),
            ],
          ),
          if (globalBlockAll)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'All prices hidden for everyone',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 12),
            Text(
              'Hide specific prices for everyone:',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: priceKeys.map((pk) {
                final key = pk['key']!;
                final label = pk['label']!;
                final isBlocked = globalBlockedKeys.contains(key);
                return FilterChip(
                  label: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  selected: !isBlocked,
                  onSelected: (_) => onTogglePriceKey(key),
                  selectedColor: const Color(0xFFC8A850).withOpacity(0.18),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  side: BorderSide(
                    color: isBlocked
                        ? Colors.red.withOpacity(0.4)
                        : const Color(0xFFC8A850),
                  ),
                  checkmarkColor: const Color(0xFFC8A850),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
