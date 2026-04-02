// // // lib/services/push_sender_service.dart
// // import 'package:flutter/foundation.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // class PushSenderService {
// //   PushSenderService(this._supabase);
// //
// //   final SupabaseClient _supabase;
// //
// //   Future<void> sendToUser({
// //     required String userId,
// //     required String title,
// //     required String body,
// //     Map<String, String>? data,
// //   }) async {
// //     if (userId.trim().isEmpty) return;
// //
// //     final response = await _supabase
// //         .from('user_push_tokens')
// //         .select('fcm_token')
// //         .eq('user_id', userId)
// //         .eq('is_active', true);
// //
// //     final rows = (response as List)
// //         .map((e) => Map<String, dynamic>.from(e as Map))
// //         .toList();
// //
// //     for (final row in rows) {
// //       final token = (row['fcm_token'] ?? '').toString().trim();
// //       if (token.isEmpty) continue;
// //
// //       try {
// //         await _supabase.functions.invoke(
// //           'send-push',
// //           body: {
// //             'token': token,
// //             'title': title,
// //             'body': body,
// //             'data': data ?? <String, String>{},
// //           },
// //         );
// //       } catch (_) {
// //         debugPrint('SEND PUSH FAILED FOR TOKEN: $token');      }
// //     }
// //   }
// // }
//
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
//         .select('fcm_token, created_at, device_platform, is_active')
//         .eq('user_id', userId)
//         .eq('is_active', true)
//         .order('created_at', ascending: false);
//
//     final rows = (response as List)
//         .map((e) => Map<String, dynamic>.from(e as Map))
//         .toList();
//
//     debugPrint('PUSH TOKENS FOUND: ${rows.length} for user $userId');
//
//     for (final row in rows) {
//       final token = (row['fcm_token'] ?? '').toString().trim();
//       if (token.isEmpty) continue;
//
//       try {
//         final result = await _supabase.functions.invoke(
//           'send-push',
//           body: {
//             'token': token,
//             'title': title,
//             'body': body,
//             'data': data ?? <String, String>{},
//           },
//         );
//
//         debugPrint('SEND PUSH SUCCESS FOR TOKEN: $token');
//         debugPrint('SEND PUSH RESULT: ${result.data}');
//       } catch (e, st) {
//         debugPrint('SEND PUSH FAILED FOR TOKEN: $token');
//         debugPrint('SEND PUSH ERROR: $e');
//         debugPrint('SEND PUSH STACK: $st');
//       }
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
        .select('id, fcm_token, created_at, device_platform, is_active')
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final rows = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    debugPrint('PUSH TOKENS FOUND: ${rows.length} for user $userId');

    for (final row in rows) {
      final tokenId = row['id'];
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

        final errorText = e.toString().toUpperCase();

        final shouldDeactivate =
            errorText.contains('SENDER_ID_MISMATCH') ||
                errorText.contains('UNREGISTERED') ||
                errorText.contains('REGISTRATION_TOKEN_NOT_REGISTERED') ||
                errorText.contains('INVALID_ARGUMENT');

        if (shouldDeactivate) {
          await _deactivateToken(
            tokenId: tokenId,
            token: token,
          );
        }
      }
    }
  }

  Future<void> _deactivateToken({
    required dynamic tokenId,
    required String token,
  }) async {
    try {
      if (tokenId != null) {
        await _supabase
            .from('user_push_tokens')
            .update({
          'is_active': false,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        })
            .eq('id', tokenId);

        debugPrint('DEACTIVATED STALE TOKEN BY ID: $tokenId');
        return;
      }

      await _supabase
          .from('user_push_tokens')
          .update({
        'is_active': false,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('fcm_token', token);

      debugPrint('DEACTIVATED STALE TOKEN BY VALUE: $token');
    } catch (deactivateError, deactivateStack) {
      debugPrint('FAILED TO DEACTIVATE TOKEN: $token');
      debugPrint('DEACTIVATE ERROR: $deactivateError');
      debugPrint('DEACTIVATE STACK: $deactivateStack');
    }
  }
}