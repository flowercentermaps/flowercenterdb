import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocNumberService {
  static final DocNumberService _instance = DocNumberService._();
  factory DocNumberService() => _instance;
  DocNumberService._();

  static const int _batchSize = 5;

  final Map<String, String> _userNameCache = {};

  Future<String> nextQuoteNumber(SupabaseClient supabase, String userId) async {
    return _next(supabase, userId, 'QT');
  }

  Future<String> nextInvoiceNumber(SupabaseClient supabase, String userId) async {
    return _next(supabase, userId, 'INV');
  }

  Future<String> _next(SupabaseClient supabase, String userId, String type) async {
    final initials = await _getInitials(supabase, userId);
    final dateStr = _dateStr();
    final prefs = await SharedPreferences.getInstance();
    final key = 'doc_numbers_${userId}_${type}_$dateStr';

    List<String> batch = prefs.getStringList(key) ?? [];

    if (batch.isEmpty) {
      batch = await _allocate(supabase, userId, type, dateStr, initials);
      await prefs.setStringList(key, batch);
    }

    final number = batch.removeAt(0);
    await prefs.setStringList(key, batch);
    return number;
  }

  Future<List<String>> _allocate(
    SupabaseClient supabase,
    String userId,
    String type,
    String dateStr,
    String initials,
  ) async {
    final start = await supabase.rpc('allocate_doc_numbers', params: {
      'p_user_id': userId,
      'p_doc_type': type,
      'p_date_str': dateStr,
      'p_batch_size': _batchSize,
    }) as int;

    return List.generate(
      _batchSize,
      (i) => '$type-$dateStr-$initials-${(start + i).toString().padLeft(3, '0')}',
    );
  }

  Future<String> _getInitials(SupabaseClient supabase, String userId) async {
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;

    try {
      final row = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      final name = (row['full_name'] ?? '').toString().trim();
      final initials = _initialsFromName(name);
      _userNameCache[userId] = initials;
      return initials;
    } catch (_) {
      return 'XX';
    }
  }

  String _initialsFromName(String name) {
    if (name.isEmpty) return 'XX';
    final first = name.split(RegExp(r'\s+')).first;
    return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _dateStr() {
    final now = DateTime.now();
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
