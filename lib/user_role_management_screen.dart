import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRoleManagementScreen extends StatefulWidget {
  final String currentUserId;

  const UserRoleManagementScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<UserRoleManagementScreen> createState() =>
      _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingAll = false;
  String? _error;

  List<Map<String, dynamic>> _users = [];
  final Map<String, String> _selectedRoles = {};
  final Set<String> _savingUserIds = {};
  String _searchQuery = '';

  static const List<String> _allowedRoles = [
    'admin',
    'sales',
    'viewer',
    'accountant',
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
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, role, is_active')
          .order('full_name', ascending: true);

      final users = (response as List)
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

      if (!mounted) return;
      setState(() {
        _users = users;
        _selectedRoles
          ..clear()
          ..addAll(selectedRoles);
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

  Future<void> _saveUserRole(Map<String, dynamic> user) async {
    final profileId = (user['id'] ?? '').toString();
    if (profileId.isEmpty || _savingUserIds.contains(profileId)) return;

    final newRole = _selectedRoles[profileId];
    final currentRole = (user['role'] ?? '').toString().trim();

    if (newRole == null || newRole == currentRole) return;

    // Prevent self-demotion unless you explicitly want it.
    if (profileId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('roles_cannot_change_own')),
        ),
      );
      return;
    }

    setState(() {
      _savingUserIds.add(profileId);
    });

    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', profileId);

      final index = _users.indexWhere((u) => (u['id'] ?? '').toString() == profileId);
      if (index != -1) {
        _users[index]['role'] = newRole;
      }

      if (!mounted) return;
      setState(() {
        _savingUserIds.remove(profileId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_updated', namedArgs: {'role': newRole}))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingUserIds.remove(profileId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('roles_update_failed', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _saveAllChangedRoles() async {
    if (_isSavingAll) return;

    final changedUsers = _filteredUsers.where(_hasRoleChanged).toList();
    if (changedUsers.isEmpty) return;

    setState(() {
      _isSavingAll = true;
    });

    try {
      for (final user in changedUsers) {
        final profileId = (user['id'] ?? '').toString();
        if (profileId == widget.currentUserId) {
          continue;
        }

        final newRole = _selectedRoles[profileId];
        if (newRole == null) continue;

        await _supabase
            .from('profiles')
            .update({'role': newRole})
            .eq('id', profileId);

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
      if (mounted) {
        setState(() {
          _isSavingAll = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('roles_title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isSavingAll ? null : _saveAllChangedRoles,
                  icon: _isSavingAll
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSavingAll ? 'Saving...' : tr('btn_save_all')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._filteredUsers.map((user) {
              final profileId = (user['id'] ?? '').toString();
              final isActive = user['is_active'] == true;
              final currentRole = (user['role'] ?? 'sales').toString().trim();
              final selectedRole = _selectedRoles[profileId] ?? currentRole;
              final changed = currentRole != selectedRole;
              final isSelf = profileId == widget.currentUserId;
              final isSaving = _savingUserIds.contains(profileId);

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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userDisplayName(user),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (user['email'] ?? '').toString(),
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr('roles_current', namedArgs: {'role': currentRole.toUpperCase()}),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF1F3A1F)
                                : const Color(0xFF3A1F1F),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive ? tr('roles_active') : tr('roles_inactive'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: tr('roles_new_role'),
                      ),
                      items: _allowedRoles
                          .map(
                            (role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.toUpperCase()),
                        ),
                      )
                          .toList(),
                      onChanged: isSelf
                          ? null
                          : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedRoles[profileId] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (isSelf)
                          Expanded(
                            child: Text(
                              tr('roles_own_role'),
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (changed)
                          Expanded(
                            child: Text(
                              tr('roles_pending', namedArgs: {'from': currentRole.toUpperCase(), 'to': selectedRole.toUpperCase()}),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              tr('roles_no_changes'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: (!changed || isSelf || isSaving)
                              ? null
                              : () => _saveUserRole(user),
                          icon: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save_outlined),
                          label: Text(isSaving ? 'Saving...' : tr('btn_save')),
                        ),
                      ],
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