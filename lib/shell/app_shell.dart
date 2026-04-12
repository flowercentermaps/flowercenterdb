import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../services/push_notification_service.dart';
import 'crm/crm_shell_screen.dart';
import '../login_screen.dart';
import '../core/network/supabase_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _pushInitialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        // Profile load failed — kick back to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        });
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(child: CircularProgressIndicator()),
        );
      },
      data: (profile) {
        // Init push notifications once per session
        if (!_pushInitialized) {
          _pushInitialized = true;
          final client = ref.read(supabaseClientProvider);
          PushNotificationService(client).initialize(userId: profile.id);
        }

        return const CrmShellScreen(profile: ,);
      },
    );
  }
}
