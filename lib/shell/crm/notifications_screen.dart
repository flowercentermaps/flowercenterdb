
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;
  final bool showOwnHeader;
  final String? customTitle;

  const NotificationsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.showOwnHeader = true,
    this.customTitle,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeRefreshDebounce;

  String _userLabelFromLogMetaOrId({
    required Map<String, dynamic> log,
    required String idKey,
    required String nameKey,
  }) {
    final meta = _payloadMap(log['meta']);
    final metaName = _text(meta[nameKey]);
    if (metaName.isNotEmpty) return metaName;

    return _userLabel(_text(meta[idKey]));
  }
  List<Map<String, dynamic>> _dismissals = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _overdueFollowUps = [];
  List<Map<String, dynamic>> _dueTodayFollowUps = [];
  List<Map<String, dynamic>> _dueTomorrowFollowUps = [];
  List<Map<String, dynamic>> _assignmentLogs = [];

  Map<String, Map<String, dynamic>> _leadMap = {};
  Map<String, Map<String, dynamic>> _profileMap = {};

  String get _role =>
      (widget.profile['role'] ?? '').toString().trim().toLowerCase();

  bool get _isAdmin => _role == 'admin';
  bool get _isSales => _role == 'sales';
  String get _currentUserId =>
      (widget.profile['id'] ?? '').toString().trim();

// notifications_screen.dart
// REPLACE initState with this, and ADD dispose + helpers right under it:
// notifications_screen.dart
// REPLACE initState + ADD dispose + REPLACE _setupRealtime/_scheduleRealtimeRefresh
// If you still have _scheduleRealtimeRefresh in the file, remove it completely.

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _loadAlerts();
  }

  @override
  void dispose() {
    final channel = _realtimeChannel;
    _realtimeChannel = null;
    if (channel != null) {
      unawaited(_supabase.removeChannel(channel));
    }
    super.dispose();
  }

  void _setupRealtime() {
    final channelKey = _currentUserId.isEmpty ? 'guest' : _currentUserId;

    _realtimeChannel = _supabase
        .channel('crm-notifications-live-$channelKey')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'follow_ups',
      callback: _handleFollowUpRealtime,
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'activity_logs',
      callback: _handleActivityLogRealtime,
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notification_dismissals',
      callback: _handleDismissalRealtime,
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'leads',
      callback: _handleLeadRealtime,
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: _handleProfileRealtime,
    )
        .subscribe();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadAlerts();
    });
  }

  bool _isDismissed({
    required String category,
    required String entityType,
    required String entityId,
  }) {
    return _dismissals.any(
          (row) =>
      _text(row['category']) == category &&
          _text(row['entity_type']) == entityType &&
          _text(row['entity_id']) == entityId,
    );
  }
// notifications_screen.dart
// REPLACE _dismissOne with this local-update version:

  Future<void> _dismissOne({
    required String category,
    required String entityType,
    required String entityId,
  }) async {
    if (_currentUserId.isEmpty || entityId.trim().isEmpty) return;

    final insertedRow = <String, dynamic>{
      'id': 'local-$category-$entityType-$entityId',
      'user_id': _currentUserId,
      'category': category,
      'entity_type': entityType,
      'entity_id': entityId,
    };

    setState(() {
      _dismissals.add(insertedRow);

      if (entityType == 'follow_up') {
        _removeFollowUpFromAllSections(entityId);
      } else if (entityType == 'activity_log' && category == 'assignment_logs') {
        _removeAssignmentLogLocally(entityId);
      }
    });

    try {
      await _supabase.from('notification_dismissals').upsert({
        'user_id': _currentUserId,
        'category': category,
        'entity_type': entityType,
        'entity_id': entityId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification dismissed.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dismissals.removeWhere(
              (row) =>
          _text(row['user_id']) == _currentUserId &&
              _text(row['category']) == category &&
              _text(row['entity_type']) == entityType &&
              _text(row['entity_id']) == entityId,
        );
      });

      await _loadAlerts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to dismiss notification: $e')),
      );
    }
  }

  // notifications_screen.dart
// REPLACE _clearSection with this local-update version:

  Future<void> _clearSection({
    required String category,
    required List<String> entityIds,
    required String entityType,
  }) async {
    if (_currentUserId.isEmpty || entityIds.isEmpty) return;

    final cleanIds = entityIds.where((id) => id.trim().isNotEmpty).toList();
    if (cleanIds.isEmpty) return;

    final localRows = cleanIds
        .map(
          (id) => <String, dynamic>{
        'id': 'local-$category-$entityType-$id',
        'user_id': _currentUserId,
        'category': category,
        'entity_type': entityType,
        'entity_id': id,
      },
    )
        .toList();

    setState(() {
      _dismissals.addAll(localRows);

      if (entityType == 'follow_up') {
        for (final id in cleanIds) {
          _removeFollowUpFromAllSections(id);
        }
      } else if (entityType == 'activity_log' && category == 'assignment_logs') {
        for (final id in cleanIds) {
          _removeAssignmentLogLocally(id);
        }
      }
    });

    try {
      await _supabase.from('notification_dismissals').upsert(
        cleanIds
            .map(
              (id) => {
            'user_id': _currentUserId,
            'category': category,
            'entity_type': entityType,
            'entity_id': id,
          },
        )
            .toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section cleared.')),
      );
    } catch (e) {
      if (!mounted) return;

      await _loadAlerts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear section: $e')),
      );
    }
  }
  // Future<void> _dismissOne({
  //   required String category,
  //   required String entityType,
  //   required String entityId,
  // }) async {
  //   if (_currentUserId.isEmpty || entityId.trim().isEmpty) return;
  //
  //   try {
  //     await _supabase.from('notification_dismissals').upsert({
  //       'user_id': _currentUserId,
  //       'category': category,
  //       'entity_type': entityType,
  //       'entity_id': entityId,
  //     });
  //
  //     await _loadAlerts();
  //
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Notification dismissed.')),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to dismiss notification: $e')),
  //     );
  //   }
  // }

  // Future<void> _clearSection({
  //   required String category,
  //   required List<String> entityIds,
  //   required String entityType,
  // }) async {
  //   if (_currentUserId.isEmpty || entityIds.isEmpty) return;
  //
  //   try {
  //     final rows = entityIds
  //         .where((id) => id.trim().isNotEmpty)
  //         .map((id) => {
  //       'user_id': _currentUserId,
  //       'category': category,
  //       'entity_type': entityType,
  //       'entity_id': id,
  //     })
  //         .toList();
  //
  //     if (rows.isEmpty) return;
  //
  //     await _supabase.from('notification_dismissals').upsert(rows);
  //
  //     await _loadAlerts();
  //
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Section cleared.')),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to clear section: $e')),
  //     );
  //   }
  // }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> dismissals = [];
      if (_currentUserId.isNotEmpty) {
        final dismissalsResponse = await _supabase
            .from('notification_dismissals')
            .select()
            .eq('user_id', _currentUserId);

        dismissals = (dismissalsResponse as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      _dismissals = dismissals;

      final now = DateTime.now();
      final startToday = DateTime(now.year, now.month, now.day);
      final startTomorrow = startToday.add(const Duration(days: 1));
      final startDayAfterTomorrow = startToday.add(const Duration(days: 2));

      dynamic overdueQuery = _supabase
          .from('follow_ups')
          .select()
          .eq('status', 'pending')
          .lt('due_at', startToday.toUtc().toIso8601String());

      dynamic todayQuery = _supabase
          .from('follow_ups')
          .select()
          .eq('status', 'pending')
          .gte('due_at', startToday.toUtc().toIso8601String())
          .lt('due_at', startTomorrow.toUtc().toIso8601String());

      dynamic tomorrowQuery = _supabase
          .from('follow_ups')
          .select()
          .eq('status', 'pending')
          .gte('due_at', startTomorrow.toUtc().toIso8601String())
          .lt('due_at', startDayAfterTomorrow.toUtc().toIso8601String());

      dynamic assignmentLogsQuery = _supabase
          .from('activity_logs')
          .select()
          .eq('action_type', 'assign_lead')
          .order('created_at', ascending: false)
          .limit(30);

      // if (_isSales && _currentUserId.isNotEmpty) {
      //   overdueQuery = overdueQuery.eq('assigned_to', _currentUserId);
      //   todayQuery = todayQuery.eq('assigned_to', _currentUserId);
      //   tomorrowQuery = tomorrowQuery.eq('assigned_to', _currentUserId);
      //   assignmentLogsQuery = assignmentLogsQuery.or(
      //     'actor_id.eq.$_currentUserId',
      //   );
      // }
      if (_isSales && _currentUserId.isNotEmpty) {
        overdueQuery = overdueQuery.eq('assigned_to', _currentUserId);
        todayQuery = todayQuery.eq('assigned_to', _currentUserId);
        tomorrowQuery = tomorrowQuery.eq('assigned_to', _currentUserId);
      }
      final overdueResponse =
      await overdueQuery.order('due_at', ascending: true);
      final todayResponse = await todayQuery.order('due_at', ascending: true);
      final tomorrowResponse =
      await tomorrowQuery.order('due_at', ascending: true);
      final assignmentLogsResponse = await assignmentLogsQuery;
      debugPrint('assignmentLogsResponse: $assignmentLogsResponse');

      final overdueRaw = (overdueResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final dueTodayRaw = (todayResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final dueTomorrowRaw = (tomorrowResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final assignmentLogsRaw = (assignmentLogsResponse as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final overdue = overdueRaw.where((item) {
        return !_isDismissed(
          category: 'overdue_followups',
          entityType: 'follow_up',
          entityId: _text(item['id']),
        );
      }).toList();

      final dueToday = dueTodayRaw.where((item) {
        return !_isDismissed(
          category: 'due_today_followups',
          entityType: 'follow_up',
          entityId: _text(item['id']),
        );
      }).toList();

      final dueTomorrow = dueTomorrowRaw.where((item) {
        return !_isDismissed(
          category: 'due_tomorrow_followups',
          entityType: 'follow_up',
          entityId: _text(item['id']),
        );
      }).toList();

      List<Map<String, dynamic>> assignmentLogs;

      if (_isAdmin || _role == 'viewer' || _role == 'accountant') {
        assignmentLogs = assignmentLogsRaw.where((item) {
          return _matchesAssignmentVisibility(item) &&
              !_isDismissed(
                category: 'assignment_logs',
                entityType: 'activity_log',
                entityId: _text(item['id']),
              );
        }).toList();
      } else if (_isSales) {
        final latestByLead = <String, Map<String, dynamic>>{};

        for (final item in assignmentLogsRaw) {
          final leadId = _text(item['lead_id']);
          if (leadId.isEmpty) continue;

          if (!latestByLead.containsKey(leadId)) {
            latestByLead[leadId] = item;
          }
        }

        assignmentLogs = latestByLead.values.where((item) {
          return _matchesAssignmentVisibility(item) &&
              !_isDismissed(
                category: 'assignment_logs',
                entityType: 'activity_log',
                entityId: _text(item['id']),
              );
        }).toList()
          ..sort((a, b) {
            final aAt = _parseDateTime(a['created_at']);
            final bAt = _parseDateTime(b['created_at']);

            if (aAt == null && bAt == null) return 0;
            if (aAt == null) return 1;
            if (bAt == null) return -1;
            return bAt.compareTo(aAt);
          });
      } else {
        assignmentLogs = <Map<String, dynamic>>[];
      }
      // final assignmentLogs = assignmentLogsRaw.where((item) {
      //   return !_isDismissed(
      //     category: 'assignment_logs',
      //     entityType: 'activity_log',
      //     entityId: _text(item['id']),
      //   );
      // }).toList();
      // final assignmentLogs = assignmentLogsRaw.where((item) {
      //   final meta = item['meta'];
      //   final actorId = _text(item['actor_id']);
      //   final oldOwnerId =
      //   meta is Map ? _text(meta['old_owner_id']) : '';
      //   final newOwnerId =
      //   meta is Map ? _text(meta['new_owner_id']) : '';
      //
      //   // final matchesSalesRelevance = !_isSales ||
      //   //     _currentUserId.isEmpty ||
      //   //     actorId == _currentUserId ||
      //   //     oldOwnerId == _currentUserId ||
      //   //     newOwnerId == _currentUserId;
      //   final matchesSalesRelevance =
      //       _isAdmin ||
      //           _role == 'viewer' ||
      //           _role == 'accountant' ||
      //           !_isSales ||
      //           _currentUserId.isEmpty ||
      //           actorId == _currentUserId ||
      //           oldOwnerId == _currentUserId ||
      //           newOwnerId == _currentUserId;
      //   return matchesSalesRelevance &&
      //       !_isDismissed(
      //         category: 'assignment_logs',
      //         entityType: 'activity_log',
      //         entityId: _text(item['id']),
      //       );
      // }).toList();
      final leadIds = <String>{
        ...overdue.map((e) => _text(e['lead_id'])),
        ...dueToday.map((e) => _text(e['lead_id'])),
        ...dueTomorrow.map((e) => _text(e['lead_id'])),
        ...assignmentLogs.map((e) => _text(e['lead_id'])),
      }..removeWhere((e) => e.isEmpty);

      final actorIds = <String>{
        ...assignmentLogs.map((e) => _text(e['actor_id'])),
      }..removeWhere((e) => e.isEmpty);

      final ownerIdsFromLogs = assignmentLogs
          .map((e) => e['meta'])
          .whereType<Map>()
          .expand<String>((meta) {
        final oldOwner = _text(meta['old_owner_id']);
        final newOwner = _text(meta['new_owner_id']);
        return [oldOwner, newOwner];
      }).where((e) => e.isNotEmpty).toSet();

      final profileIds = <String>{...actorIds, ...ownerIdsFromLogs};

      Map<String, Map<String, dynamic>> leadMap = {};
      Map<String, Map<String, dynamic>> profileMap = {};

      if (leadIds.isNotEmpty) {
        final leadsResponse = await _supabase
            .from('leads')
            .select('id, name, phone, email, company_name, owner_id, status')
            .inFilter('id', leadIds.toList());

        for (final row in leadsResponse as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = _text(map['id']);
          if (id.isNotEmpty) {
            leadMap[id] = map;
            final ownerId = _text(map['owner_id']);
            if (ownerId.isNotEmpty) {
              profileIds.add(ownerId);
            }
          }
        }
        debugPrint('assignmentLogsRaw count: ${assignmentLogsRaw.length}');
        debugPrint('assignmentLogs filtered count: ${assignmentLogs.length}');
      }

      if (profileIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, full_name, email, role')
            .inFilter('id', profileIds.toList());

        for (final row in profilesResponse as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final id = _text(map['id']);
          if (id.isNotEmpty) {
            profileMap[id] = map;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _dismissals = dismissals;
        _overdueFollowUps = overdue;
        _dueTodayFollowUps = dueToday;
        _dueTomorrowFollowUps = dueTomorrow;
        _assignmentLogs = assignmentLogs;
        _leadMap = leadMap;
        _profileMap = profileMap;
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
  // notifications_screen.dart
// ADD all these helpers inside _NotificationsScreenState
// Put them below _loadAlerts() or below _clearSection()

  Map<String, dynamic> _payloadMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map(
            (key, val) => MapEntry(key.toString(), val),
      );
    }
    return <String, dynamic>{};
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfTomorrow() => _startOfToday().add(const Duration(days: 1));

  DateTime _startOfDayAfterTomorrow() =>
      _startOfToday().add(const Duration(days: 2));

  bool _matchesFollowUpVisibility(Map<String, dynamic> row) {
    if (_isAdmin) return true;
    if (_isSales) {
      return _text(row['assigned_to']) == _currentUserId;
    }
    return false;
  }

  String? _followUpCategoryFor(Map<String, dynamic> row) {
    if (_text(row['status']).toLowerCase() != 'pending') return null;
    if (!_matchesFollowUpVisibility(row)) return null;

    final dueAt = _parseDateTime(row['due_at']);
    if (dueAt == null) return null;

    final startToday = _startOfToday();
    final startTomorrow = _startOfTomorrow();
    final startDayAfterTomorrow = _startOfDayAfterTomorrow();

    if (dueAt.isBefore(startToday)) return 'overdue_followups';
    if (!dueAt.isBefore(startToday) && dueAt.isBefore(startTomorrow)) {
      return 'due_today_followups';
    }
    if (!dueAt.isBefore(startTomorrow) && dueAt.isBefore(startDayAfterTomorrow)) {
      return 'due_tomorrow_followups';
    }
    return null;
  }
  //
  // bool _matchesAssignmentVisibility(Map<String, dynamic> row) {
  //   if (_text(row['action_type']) != 'assign_lead') return false;
  //   if (_isAdmin) return true;
  //   if (!_isSales || _currentUserId.isEmpty) return false;
  //
  //   final meta = _payloadMap(row['meta']);
  //   final actorId = _text(row['actor_id']);
  //   final oldOwnerId = _text(meta['old_owner_id']);
  //   final newOwnerId = _text(meta['new_owner_id']);
  //
  //   return actorId == _currentUserId ||
  //       oldOwnerId == _currentUserId ||
  //       newOwnerId == _currentUserId;
  // }
  bool _matchesAssignmentVisibility(Map<String, dynamic> row) {
    if (_text(row['action_type']) != 'assign_lead') return false;

    final meta = _payloadMap(row['meta']);
    final actorId = _text(row['actor_id']);
    final oldOwnerId = _text(meta['old_owner_id']);
    final newOwnerId = _text(meta['new_owner_id']);

    if (_isAdmin) {
      return actorId.isNotEmpty && actorId != _currentUserId;
    }

    if (_role == 'viewer' || _role == 'accountant') {
      return true;
    }

    if (!_isSales || _currentUserId.isEmpty) return false;

    return oldOwnerId == _currentUserId || newOwnerId == _currentUserId;
  }

  void _removeFollowUpFromAllSections(String id) {
    _overdueFollowUps.removeWhere((e) => _text(e['id']) == id);
    _dueTodayFollowUps.removeWhere((e) => _text(e['id']) == id);
    _dueTomorrowFollowUps.removeWhere((e) => _text(e['id']) == id);
  }

  void _upsertFollowUpInSection(
      List<Map<String, dynamic>> list,
      Map<String, dynamic> item,
      ) {
    final id = _text(item['id']);
    final index = list.indexWhere((e) => _text(e['id']) == id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
  }

  void _sortFollowUpSection(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final aDue = _parseDateTime(a['due_at']);
      final bDue = _parseDateTime(b['due_at']);

      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });
  }

  void _applyFollowUpLocally(Map<String, dynamic> row) {
    final id = _text(row['id']);
    if (id.isEmpty) return;

    _removeFollowUpFromAllSections(id);

    final category = _followUpCategoryFor(row);
    if (category == null) return;

    if (_isDismissed(
      category: category,
      entityType: 'follow_up',
      entityId: id,
    )) {
      return;
    }

    switch (category) {
      case 'overdue_followups':
        _upsertFollowUpInSection(_overdueFollowUps, row);
        _sortFollowUpSection(_overdueFollowUps);
        break;
      case 'due_today_followups':
        _upsertFollowUpInSection(_dueTodayFollowUps, row);
        _sortFollowUpSection(_dueTodayFollowUps);
        break;
      case 'due_tomorrow_followups':
        _upsertFollowUpInSection(_dueTomorrowFollowUps, row);
        _sortFollowUpSection(_dueTomorrowFollowUps);
        break;
    }
  }

  void _removeAssignmentLogLocally(String id) {
    _assignmentLogs.removeWhere((e) => _text(e['id']) == id);
  }
  void _removeAssignmentLogsForLeadLocally(String leadId) {
    if (leadId.trim().isEmpty) return;
    _assignmentLogs.removeWhere((e) => _text(e['lead_id']) == leadId);
  }

  void _upsertAssignmentLogLocally(Map<String, dynamic> row) {
    final id = _text(row['id']);
    final leadId = _text(row['lead_id']);
    if (id.isEmpty || leadId.isEmpty) return;

    if (_isAdmin || _role == 'viewer' || _role == 'accountant') {
      _removeAssignmentLogLocally(id);

      if (!_matchesAssignmentVisibility(row)) return;

      if (_isDismissed(
        category: 'assignment_logs',
        entityType: 'activity_log',
        entityId: id,
      )) {
        return;
      }

      _assignmentLogs.insert(0, row);
      _assignmentLogs.sort((a, b) {
        final aAt = _parseDateTime(a['created_at']);
        final bAt = _parseDateTime(b['created_at']);

        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });

      if (_assignmentLogs.length > 30) {
        _assignmentLogs = _assignmentLogs.take(30).toList();
      }
      return;
    }

    if (_isSales) {
      _removeAssignmentLogsForLeadLocally(leadId);

      if (!_matchesAssignmentVisibility(row)) return;

      if (_isDismissed(
        category: 'assignment_logs',
        entityType: 'activity_log',
        entityId: id,
      )) {
        return;
      }

      _assignmentLogs.insert(0, row);
      _assignmentLogs.sort((a, b) {
        final aAt = _parseDateTime(a['created_at']);
        final bAt = _parseDateTime(b['created_at']);

        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
    }
  }  // void _upsertAssignmentLogLocally(Map<String, dynamic> row) {
  //   final id = _text(row['id']);
  //   if (id.isEmpty) return;
  //
  //   _removeAssignmentLogLocally(id);
  //
  //   if (!_matchesAssignmentVisibility(row)) return;
  //
  //   if (_isDismissed(
  //     category: 'assignment_logs',
  //     entityType: 'activity_log',
  //     entityId: id,
  //   )) {
  //     return;
  //   }
  //
  //   _assignmentLogs.insert(0, row);
  //   _assignmentLogs.sort((a, b) {
  //     final aAt = _parseDateTime(a['created_at']);
  //     final bAt = _parseDateTime(b['created_at']);
  //
  //     if (aAt == null && bAt == null) return 0;
  //     if (aAt == null) return 1;
  //     if (bAt == null) return -1;
  //     return bAt.compareTo(aAt);
  //   });
  //
  //   if (_assignmentLogs.length > 30) {
  //     _assignmentLogs = _assignmentLogs.take(30).toList();
  //   }
  // }

  Future<void> _ensureLeadLoaded(String leadId) async {
    if (leadId.isEmpty || _leadMap.containsKey(leadId)) return;

    try {
      final response = await _supabase
          .from('leads')
          .select('id, name, phone, email, company_name, owner_id, status')
          .eq('id', leadId)
          .maybeSingle();

      if (response == null || !mounted) return;

      final map = Map<String, dynamic>.from(response as Map);
      final id = _text(map['id']);
      if (id.isEmpty) return;

      setState(() {
        _leadMap[id] = map;
      });

      final ownerId = _text(map['owner_id']);
      if (ownerId.isNotEmpty) {
        unawaited(_ensureProfileLoaded(ownerId));
      }
    } catch (_) {}
  }

  Future<void> _ensureProfileLoaded(String profileId) async {
    if (profileId.isEmpty || _profileMap.containsKey(profileId)) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('id', profileId)
          .maybeSingle();

      if (response == null || !mounted) return;

      final map = Map<String, dynamic>.from(response as Map);
      final id = _text(map['id']);
      if (id.isEmpty) return;

      setState(() {
        _profileMap[id] = map;
      });
    } catch (_) {}
  }

  Future<void> _ensureAssignmentSupportData(Map<String, dynamic> row) async {
    final leadId = _text(row['lead_id']);
    if (leadId.isNotEmpty) {
      await _ensureLeadLoaded(leadId);
    }

    final actorId = _text(row['actor_id']);
    if (actorId.isNotEmpty) {
      await _ensureProfileLoaded(actorId);
    }

    final meta = _payloadMap(row['meta']);
    final oldOwnerId = _text(meta['old_owner_id']);
    final newOwnerId = _text(meta['new_owner_id']);

    if (oldOwnerId.isNotEmpty) {
      await _ensureProfileLoaded(oldOwnerId);
    }
    if (newOwnerId.isNotEmpty) {
      await _ensureProfileLoaded(newOwnerId);
    }
  }

  Future<void> _handleFollowUpRealtime(dynamic payload) async {
    final eventType = payload.eventType.toString().toUpperCase();
    final newRow = _payloadMap(payload.newRecord);
    final oldRow = _payloadMap(payload.oldRecord);

    final targetLeadId = _text(newRow['lead_id']).isNotEmpty
        ? _text(newRow['lead_id'])
        : _text(oldRow['lead_id']);
    final assigneeId = _text(newRow['assigned_to']).isNotEmpty
        ? _text(newRow['assigned_to'])
        : _text(oldRow['assigned_to']);

    if (targetLeadId.isNotEmpty) {
      await _ensureLeadLoaded(targetLeadId);
    }
    if (assigneeId.isNotEmpty) {
      await _ensureProfileLoaded(assigneeId);
    }

    if (!mounted) return;

    setState(() {
      // if (eventType == 'DELETE') {
      //   _removeFollowUpFromAllSections(_text(oldRow['id']));
      //   return;
      // }
      if (eventType == 'DELETE') {
        final deletedLeadId = _text(oldRow['lead_id']);
        if (_isSales && deletedLeadId.isNotEmpty) {
          _removeAssignmentLogsForLeadLocally(deletedLeadId);
        } else {
          _removeAssignmentLogLocally(_text(oldRow['id']));
        }
        return;
      }
      if (newRow.isEmpty) return;
      _applyFollowUpLocally(newRow);
    });
  }

  Future<void> _handleActivityLogRealtime(dynamic payload) async {
    final eventType = payload.eventType.toString().toUpperCase();
    final newRow = _payloadMap(payload.newRecord);
    final oldRow = _payloadMap(payload.oldRecord);

    final workingRow = newRow.isNotEmpty ? newRow : oldRow;
    if (_text(workingRow['action_type']) != 'assign_lead') return;

    await _ensureAssignmentSupportData(workingRow);

    if (!mounted) return;

    setState(() {
      if (eventType == 'DELETE') {
        _removeAssignmentLogLocally(_text(oldRow['id']));
        return;
      }

      if (newRow.isEmpty) return;
      _upsertAssignmentLogLocally(newRow);
    });
  }

  void _handleDismissalRealtime(dynamic payload) {
    final eventType = payload.eventType.toString().toUpperCase();
    final newRow = _payloadMap(payload.newRecord);
    final oldRow = _payloadMap(payload.oldRecord);
    final row = newRow.isNotEmpty ? newRow : oldRow;

    if (_text(row['user_id']) != _currentUserId) return;

    if (!mounted) return;

    setState(() {
      if (eventType == 'DELETE') {
        final dismissalId = _text(oldRow['id']);
        _dismissals.removeWhere((e) => _text(e['id']) == dismissalId);
        return;
      }

      final dismissalId = _text(row['id']);
      final existingIndex =
      _dismissals.indexWhere((e) => _text(e['id']) == dismissalId);

      if (existingIndex >= 0) {
        _dismissals[existingIndex] = row;
      } else {
        _dismissals.add(row);
      }

      final category = _text(row['category']);
      final entityType = _text(row['entity_type']);
      final entityId = _text(row['entity_id']);

      if (entityType == 'follow_up') {
        _removeFollowUpFromAllSections(entityId);
      } else if (entityType == 'activity_log' && category == 'assignment_logs') {
        _removeAssignmentLogLocally(entityId);
      }
    });
  }

  void _handleLeadRealtime(dynamic payload) {
    final eventType = payload.eventType.toString().toUpperCase();
    final newRow = _payloadMap(payload.newRecord);
    final oldRow = _payloadMap(payload.oldRecord);

    if (!mounted) return;

    setState(() {
      if (eventType == 'DELETE') {
        _leadMap.remove(_text(oldRow['id']));
        return;
      }

      final id = _text(newRow['id']);
      if (id.isEmpty) return;
      _leadMap[id] = newRow;
    });

    final ownerId = _text(newRow['owner_id']);
    if (ownerId.isNotEmpty) {
      unawaited(_ensureProfileLoaded(ownerId));
    }
  }

  void _handleProfileRealtime(dynamic payload) {
    final eventType = payload.eventType.toString().toUpperCase();
    final newRow = _payloadMap(payload.newRecord);
    final oldRow = _payloadMap(payload.oldRecord);

    if (!mounted) return;

    setState(() {
      if (eventType == 'DELETE') {
        _profileMap.remove(_text(oldRow['id']));
        return;
      }

      final id = _text(newRow['id']);
      if (id.isEmpty) return;
      _profileMap[id] = newRow;
    });
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _displayName() {
    final fullName = _text(widget.profile['full_name']);
    final email = _text(widget.profile['email']);
    return fullName.isNotEmpty ? fullName : email;
  }

  String _leadLabel(String leadId) {
    final lead = _leadMap[leadId];
    if (lead == null) return leadId;
    final name = _text(lead['name']);
    final company = _text(lead['company_name']);
    final phone = _text(lead['phone']);
    if (name.isNotEmpty) return name;
    if (company.isNotEmpty) return company;
    if (phone.isNotEmpty) return phone;
    return leadId;
  }

  String _userLabel(String? userId) {
    final id = _text(userId);
    if (id.isEmpty) return 'Unassigned';
    final profile = _profileMap[id];
    if (profile == null) return id;
    final name = _text(profile['full_name']);
    final email = _text(profile['email']);
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return id;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '—';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(
              title: widget.customTitle ?? 'Notifications',
              showOwnHeader: widget.showOwnHeader,
              profileName: _displayName(),
              role: _role,
              onRefresh: _loadAlerts,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _NotificationsErrorCard(
        title: 'Failed to load alerts',
        message: _error!,
        onRetry: _loadAlerts,
      );
    }

    final hasAnything = _overdueFollowUps.isNotEmpty ||
        _dueTodayFollowUps.isNotEmpty ||
        _dueTomorrowFollowUps.isNotEmpty ||
        _assignmentLogs.isNotEmpty;

    if (!hasAnything) {
      return const _NotificationsEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
        children: [
          _AlertSection(
            title: 'Overdue Follow-ups',
            icon: Icons.warning_amber_rounded,
            trailing: TextButton(
              onPressed: _overdueFollowUps.isEmpty
                  ? null
                  : () => _clearSection(
                category: 'overdue_followups',
                entityType: 'follow_up',
                entityIds:
                _overdueFollowUps.map((e) => _text(e['id'])).toList(),
              ),
              child: const Text('Clear All'),
            ),
            child: _overdueFollowUps.isEmpty
                ? const _SectionEmptyText('No overdue follow-ups.')
                : Column(
              children: _overdueFollowUps
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FollowUpAlertCard(
                    leadLabel: _leadLabel(_text(item['lead_id'])),
                    dueAt: _formatDateTime(
                      _parseDateTime(item['due_at']),
                    ),
                    notes: _text(item['notes']),
                    assignee: _userLabel(_text(item['assigned_to'])),
                    tone: _AlertTone.overdue,
                    onDismiss: () => _dismissOne(
                      category: 'overdue_followups',
                      entityType: 'follow_up',
                      entityId: _text(item['id']),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _AlertSection(
            title: 'Due Today',
            icon: Icons.today_outlined,
            trailing: TextButton(
              onPressed: _dueTodayFollowUps.isEmpty
                  ? null
                  : () => _clearSection(
                category: 'due_today_followups',
                entityType: 'follow_up',
                entityIds:
                _dueTodayFollowUps.map((e) => _text(e['id'])).toList(),
              ),
              child: const Text('Clear All'),
            ),
            child: _dueTodayFollowUps.isEmpty
                ? const _SectionEmptyText('No follow-ups due today.')
                : Column(
              children: _dueTodayFollowUps
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FollowUpAlertCard(
                    leadLabel: _leadLabel(_text(item['lead_id'])),
                    dueAt: _formatDateTime(
                      _parseDateTime(item['due_at']),
                    ),
                    notes: _text(item['notes']),
                    assignee: _userLabel(_text(item['assigned_to'])),
                    tone: _AlertTone.today,
                    onDismiss: () => _dismissOne(
                      category: 'due_today_followups',
                      entityType: 'follow_up',
                      entityId: _text(item['id']),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _AlertSection(
            title: 'Due Tomorrow',
            icon: Icons.event_outlined,
            trailing: TextButton(
              onPressed: _dueTomorrowFollowUps.isEmpty
                  ? null
                  : () => _clearSection(
                category: 'due_tomorrow_followups',
                entityType: 'follow_up',
                entityIds: _dueTomorrowFollowUps
                    .map((e) => _text(e['id']))
                    .toList(),
              ),
              child: const Text('Clear All'),
            ),
            child: _dueTomorrowFollowUps.isEmpty
                ? const _SectionEmptyText('No follow-ups due tomorrow.')
                : Column(
              children: _dueTomorrowFollowUps
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FollowUpAlertCard(
                    leadLabel: _leadLabel(_text(item['lead_id'])),
                    dueAt: _formatDateTime(
                      _parseDateTime(item['due_at']),
                    ),
                    notes: _text(item['notes']),
                    assignee: _userLabel(_text(item['assigned_to'])),
                    tone: _AlertTone.tomorrow,
                    onDismiss: () => _dismissOne(
                      category: 'due_tomorrow_followups',
                      entityType: 'follow_up',
                      entityId: _text(item['id']),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _AlertSection(
            title: 'Recent Assignments / Reassignments',
            icon: Icons.share_outlined,
            trailing: TextButton(
              onPressed: _assignmentLogs.isEmpty
                  ? null
                  : () => _clearSection(
                category: 'assignment_logs',
                entityType: 'activity_log',
                entityIds:
                _assignmentLogs.map((e) => _text(e['id'])).toList(),
              ),
              child: const Text('Clear All'),
            ),
            child: _assignmentLogs.isEmpty
                ? const _SectionEmptyText('No recent assignment activity.')
                : Column(
              children: _assignmentLogs
                  .map(
                    (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AssignmentAlertCard(
                    leadLabel: _leadLabel(_text(log['lead_id'])),
                    actorLabel: _userLabelFromLogMetaOrId(
                      log: log,
                      idKey: 'actor_id',
                      nameKey: 'actor_name',
                    ),
                    oldOwnerLabel: _userLabelFromLogMetaOrId(
                      log: log,
                      idKey: 'old_owner_id',
                      nameKey: 'old_owner_name',
                    ),
                    newOwnerLabel: _userLabelFromLogMetaOrId(
                      log: log,
                      idKey: 'new_owner_id',
                      nameKey: 'new_owner_name',
                    ),
                    // actorLabel: _userLabel(_text(log['actor_id'])),
                    // oldOwnerLabel: _userLabel(
                    //   (log['meta'] is Map)
                    //       ? _text((log['meta'] as Map)['old_owner_id'])
                    //       : '',
                    // ),
                    // newOwnerLabel: _userLabel(
                    //   (log['meta'] is Map)
                    //       ? _text((log['meta'] as Map)['new_owner_id'])
                    //       : '',
                    // ),
                    createdAt: _formatDateTime(
                      _parseDateTime(log['created_at']),
                    ),
                    onDismiss: () => _dismissOne(
                      category: 'assignment_logs',
                      entityType: 'activity_log',
                      entityId: _text(log['id']),
                    ),
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
}

class _NotificationsHeader extends StatelessWidget {
  final String title;
  final bool showOwnHeader;
  final String profileName;
  final String role;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const _NotificationsHeader({
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
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF111111),
                  ),
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
                  _NotificationsProfileMenu(
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
                  'In-app alerts for follow-up urgency and recent assignment activity.',
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

class _NotificationsProfileMenu extends StatelessWidget {
  final String profileName;
  final String role;
  final Future<void> Function() onLogout;

  const _NotificationsProfileMenu({
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

class _AlertSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _AlertSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
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
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

enum _AlertTone { overdue, today, tomorrow }

class _FollowUpAlertCard extends StatelessWidget {
  final String leadLabel;
  final String dueAt;
  final String notes;
  final String assignee;
  final _AlertTone tone;
  final VoidCallback? onDismiss;

  const _FollowUpAlertCard({
    required this.leadLabel,
    required this.dueAt,
    required this.notes,
    required this.assignee,
    required this.tone,
    this.onDismiss,
  });

  Color get _toneColor {
    switch (tone) {
      case _AlertTone.overdue:
        return const Color(0xFFB00020);
      case _AlertTone.today:
        return const Color(0xFFFF8F00);
      case _AlertTone.tomorrow:
        return const Color(0xFF1976D2);
    }
  }

  String get _toneLabel {
    switch (tone) {
      case _AlertTone.overdue:
        return 'OVERDUE';
      case _AlertTone.today:
        return 'DUE TODAY';
      case _AlertTone.tomorrow:
        return 'DUE TOMORROW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _toneColor.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      leadLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _toneColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                        border:
                        Border.all(color: _toneColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        _toneLabel,
                        style: TextStyle(
                          color: _toneColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Due: $dueAt'),
          const SizedBox(height: 4),
          Text('Assigned to: $assignee'),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentAlertCard extends StatelessWidget {
  final String leadLabel;
  final String actorLabel;
  final String oldOwnerLabel;
  final String newOwnerLabel;
  final String createdAt;
  final VoidCallback? onDismiss;

  const _AssignmentAlertCard({
    required this.leadLabel,
    required this.actorLabel,
    required this.oldOwnerLabel,
    required this.newOwnerLabel,
    required this.createdAt,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final becameUnassigned = newOwnerLabel == 'Unassigned';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A2F0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leadLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Changed by: $actorLabel'),
          const SizedBox(height: 4),
          Text('From: $oldOwnerLabel'),
          const SizedBox(height: 4),
          Text('To: $newOwnerLabel'),
          const SizedBox(height: 4),
          Text('At: $createdAt'),
          if (becameUnassigned) ...[
            const SizedBox(height: 8),
            const Text(
              'This lead is currently unassigned.',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionEmptyText extends StatelessWidget {
  final String text;

  const _SectionEmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: Color(0xFFD4AF37),
              ),
              SizedBox(height: 12),
              Text(
                'No alerts right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Overdue items, upcoming follow-ups, and assignment changes will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const _NotificationsErrorCard({
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
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