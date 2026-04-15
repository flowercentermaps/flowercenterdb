import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/supabase_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../login_screen.dart';
import '../services/push_notification_service.dart';
import 'crm/crm_shell_screen.dart';

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
        final hasSession = ref.read(supabaseClientProvider).auth.currentUser != null;
        if (hasSession) {
          // Auth session exists but profile fetch failed (e.g. stale cache after
          // re-login) — invalidate so it retries with the new user's session.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(profileProvider);
          });
        } else {
          // No session at all — kick back to login.
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
        // Init push notifications once per session
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
