// // lib/services/push_sender_service.dart
// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class PushSenderService {
//   PushSenderService(this._supabase);
//
//   final SupabaseClient _supabase;
//
//   Future<void> sendToUser({
//     required String userId,
//     required String title,
//     required String body,
//     Map<String, String>? data,
//   }) async {
//     if (userId.trim().isEmpty) return;
//
//     final response = await _supabase
//         .from('user_push_tokens')
//         .select('fcm_token')
//         .eq('user_id', userId)
//         .eq('is_active', true);
//
//     final rows = (response as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .toList();
//
//     for (final row in rows) {
//       final token = (row['fcm_token'] ?? '').toString().trim();
//       if (token.isEmpty) continue;
//
//       try {
//         await _supabase.functions.invoke(
//           'send-push',
//           body: {
//             'token': token,
//             'title': title,
//             'body': body,
//             'data': data ?? <String, String>{},
//           },
//         );
//       } catch (_) {
//         debugPrint('SEND PUSH FAILED FOR TOKEN: $token');      }
//     }
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushSenderService {
  PushSenderService(this._supabase);

  final SupabaseClient _supabase;

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (userId.trim().isEmpty) return;

    final response = await _supabase
        .from('user_push_tokens')
        .select('fcm_token, created_at, device_platform, is_active')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    debugPrint('PUSH TOKENS FOUND: ${rows.length} for user $userId');

    for (final row in rows) {
      final token = (row['fcm_token'] ?? '').toString().trim();
      if (token.isEmpty) continue;

      try {
        final result = await _supabase.functions.invoke(
          'send-push',
          body: {
            'token': token,
            'title': title,
            'body': body,
            'data': data ?? <String, String>{},
          },
        );

        debugPrint('SEND PUSH SUCCESS FOR TOKEN: $token');
        debugPrint('SEND PUSH RESULT: ${result.data}');
      } catch (e, st) {
        debugPrint('SEND PUSH FAILED FOR TOKEN: $token');
        debugPrint('SEND PUSH ERROR: $e');
        debugPrint('SEND PUSH STACK: $st');
      }
    }
  }
}