// import 'dart:io';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class PushNotificationService {
//   PushNotificationService(this._supabase);
//
//   final SupabaseClient _supabase;
//
//   FirebaseMessaging get _messaging => FirebaseMessaging.instance;
//
//   Future<void> initialize({
//     required String userId,
//   }) async {
//     if (userId.trim().isEmpty) return;
//
//     await _requestPermission();
//     await _saveCurrentToken(userId: userId);
//
//     _messaging.onTokenRefresh.listen((token) async {
//       await _upsertToken(
//         userId: userId,
//         token: token,
//       );
//     });
//   }
//
//   Future<void> _requestPermission() async {
//     await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );
//   }
//
//   Future<void> _saveCurrentToken({
//     required String userId,
//   }) async {
//     final token = await _messaging.getToken();
//     if (token == null || token.trim().isEmpty) return;
//
//     await _upsertToken(
//       userId: userId,
//       token: token,
//     );
//   }
//
//   Future<void> _upsertToken({
//     required String userId,
//     required String token,
//   }) async {
//     final platform = kIsWeb
//         ? 'web'
//         : Platform.isAndroid
//         ? 'android'
//         : Platform.isIOS
//         ? 'ios'
//         : Platform.operatingSystem;
//
//     await _supabase.from('user_push_tokens').upsert(
//       {
//         'user_id': userId,
//         'fcm_token': token,
//         'device_platform': platform,
//         'is_active': true,
//         'last_seen_at': DateTime.now().toUtc().toIso8601String(),
//       },
//       onConflict: 'fcm_token',
//     );
//   }
// }


import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  PushNotificationService(this._supabase);

  final SupabaseClient _supabase;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get _supportsFcm =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) return;
    if (!_supportsFcm) return;

    await _requestPermission();
    await _saveCurrentToken(userId: userId);

    _messaging.onTokenRefresh.listen((token) async {
      await _upsertToken(
        userId: userId,
        token: token,
      );
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _saveCurrentToken({
    required String userId,
  }) async {
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _upsertToken(
      userId: userId,
      token: token,
    );
  }

  Future<void> _upsertToken({
    required String userId,
    required String token,
  }) async {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : Platform.operatingSystem;

    await _supabase.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'device_platform': platform,
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'fcm_token',
    );
  }
}
