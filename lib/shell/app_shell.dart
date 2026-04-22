import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/supabase_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../login_screen.dart';
import '../services/push_notification_service.dart';
import '../services/whatsapp_listener_service.dart';
import 'crm/crm_shell_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _pushInitialized = false;
  bool _listenerInitialized = false;

  // Debounce: tracks last time each phone was processed
  // WhatsApp fires multiple events per message — 3s gap prevents duplicates
  final Map<String, DateTime> _lastProcessed = {};
  final Set<String> _processingPhones = {};

  StreamSubscription? _whatsappSub;

  @override
  void initState() {
    super.initState();
    _initWhatsAppListener();
  }

  @override
  void dispose() {
    _whatsappSub?.cancel();
    WhatsAppListenerService.stopListening();
    super.dispose();
  }

  Future<void> _initWhatsAppListener() async {
    if (_listenerInitialized) return;
    if (!(Platform.isAndroid)) return;
    _listenerInitialized = true;

    final granted = await WhatsAppListenerService.isPermissionGranted();
    if (!granted) {
      // Ask for permission after a short delay so the UI is ready
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    _startListening();
  }

  void _startListening() {
    WhatsAppListenerService.startListening();
    _whatsappSub = WhatsAppListenerService.onLeadDetected.listen((lead) {
      if (!mounted) return;
      _autoSaveLead(lead);
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text(
              // 'WhatsApp Leads Capture',
              'CRM Admin Permission',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Allow notification ',
          // 'Allow notification access so the app can automatically '
          // 'create leads when customers message you on WhatsApp.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await WhatsAppListenerService.requestPermission();
              // Check again after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              final granted =
                  await WhatsAppListenerService.isPermissionGranted();
              if (granted && mounted) _startListening();
            },
            child: const Text('Allow Access'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSaveLead(WhatsAppLead lead) async {
    // Debounce: skip if same number was processed within the last 3 seconds
    final last = _lastProcessed[lead.phone];
    if (last != null && DateTime.now().difference(last).inSeconds < 3) return;
    if (_processingPhones.contains(lead.phone)) return;
    _lastProcessed[lead.phone] = DateTime.now();
    _processingPhones.add(lead.phone);

    try {
      final supabase = Supabase.instance.client;

      // Check if already exists
      final existing = await supabase
          .from('leads')
          .select('id, notes')
          .or('phone.eq.${lead.phone},phone2.eq.${lead.phone}')
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        // Append message to notes
        if (lead.message.isNotEmpty) {
          final timestamp = DateTime.now()
              .toIso8601String()
              .substring(0, 16)
              .replaceAll('T', ' ');
          final appendNote = '\n[$timestamp] WhatsApp: ${lead.message}';
          final oldNotes = (existing['notes'] as String?) ?? '';
          await supabase.from('leads').update({
            'notes': oldNotes + appendNote,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);
        }
        return;
      }

      // Create new lead
      final notes = lead.message.isNotEmpty
          ? '[WhatsApp] ${lead.message}'
          : '[WhatsApp] New contact';

      final userId = supabase.auth.currentUser?.id;

      await supabase.from('leads').insert({
        'phone': lead.phone,
        'status': 'new',
        'lead_type': 'individual',
        'source': 'whatsapp',
        'notes': notes,
        'is_important': false,
        'requires_follow_up': false,
        'is_completed': false,
        'owner_id': userId,
        'created_by': userId,
      });
    } catch (e) {
      debugPrint('WhatsApp auto-lead error: $e');
    } finally {
      _processingPhones.remove(lead.phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) {
        final hasSession =
            ref.read(supabaseClientProvider).auth.currentUser != null;
        if (hasSession) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(profileProvider);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          });
        }
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(child: CircularProgressIndicator()),
        );
      },
      data: (profile) {
        if (!_pushInitialized) {
          _pushInitialized = true;
          final client = ref.read(supabaseClientProvider);
          PushNotificationService(client).initialize(userId: profile.id);
        }
        return const CrmShellScreen();
      },
    );
  }
}

