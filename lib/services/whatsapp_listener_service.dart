// whatsapp_listener_service.dart
// Listens to WhatsApp/WhatsApp Business notifications on Android.
// When an unknown number sends a message, emits a WhatsAppLead event
// so the UI can prompt the agent to add it as a lead.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

class WhatsAppLead {
  final String phone;
  final String message;
  final DateTime receivedAt;

  WhatsAppLead({
    required this.phone,
    required this.message,
    required this.receivedAt,
  });
}

class WhatsAppListenerService {
  static const _whatsappPackages = {
    'com.whatsapp',
    'com.whatsapp.w4b',
  };

  // Phone number pattern: optional +, then digits/spaces/dashes
  static final _phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,20}$');

  static final _controller = StreamController<WhatsAppLead>.broadcast();
  static Stream<WhatsAppLead> get onLeadDetected => _controller.stream;

  static StreamSubscription? _subscription;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Returns true if notification access is granted.
  static Future<bool> isPermissionGranted() async {
    if (!_supported) return false;
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// Opens Android Settings so the user can grant notification access.
  static Future<void> requestPermission() async {
    if (!_supported) return;
    try {
      await NotificationListenerService.requestPermission();
    } catch (_) {}
  }

  /// Start listening. Call once after permission is granted.
  static void startListening() {
    if (!_supported) return;
    _subscription?.cancel();
    _subscription =
        NotificationListenerService.notificationsStream.listen(_onNotification);
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _onNotification(ServiceNotificationEvent event) {
    // Only WhatsApp packages
    if (!_whatsappPackages.contains(event.packageName)) return;

    final title = (event.title ?? '').trim();
    final content = (event.content ?? '').trim();

    // Skip summary/group notifications
    if (title.toLowerCase().contains('message') ||
        title.toLowerCase().contains('chat') ||
        content.isEmpty) {
      return;
    }

    // Check if title looks like a phone number (unknown contact)
    final phone = _parsePhone(title);
    if (phone == null) { return; }

    _controller.add(WhatsAppLead(
      phone: phone,
      message: content,
      receivedAt: DateTime.now(),
    ));
  }

  /// Returns normalised phone string if [raw] looks like a phone number,
  /// otherwise null.
  static String? _parsePhone(String raw) {
    if (!_phoneRegex.hasMatch(raw)) return null;

    final digits = raw.replaceAll(RegExp(r'[\s\-()]+'), '');
    final digitOnly = digits.replaceAll('+', '');
    if (digitOnly.length < 7 || digitOnly.length > 15) return null;
    if (RegExp(r'[^\d]').hasMatch(digitOnly)) return null;

    return digits.startsWith('+') ? digits : '+$digitOnly';
  }
}
