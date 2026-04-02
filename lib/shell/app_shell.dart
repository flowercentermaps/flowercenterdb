// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../main.dart';
// import '../price_list_screen.dart';
// import '../login_screen.dart';
// import 'crm/crm_shell_screen.dart';
// import 'crm/leads_screen.dart';
//
// class AppShell extends StatefulWidget {
//   const AppShell({super.key});
//
//   @override
//   State<AppShell> createState() => _AppShellState();
// }
//
// class _AppShellState extends State<AppShell> {
//   bool _isLoading = true;
//   String? _error;
//   Map<String, dynamic>? _profile;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }
//
//   Future<void> _loadProfile() async {
//     try {
//       final user = supabase.auth.currentUser;
//
//       if (user == null) {
//         if (!mounted) return;
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//               (_) => false,
//         );
//         return;
//       }
//
//       final data = await supabase
//           .from('profiles')
//           .select()
//           .eq('id', user.id)
//           .single();
//
//       final profile = Map<String, dynamic>.from(data);
//
//       if (profile['is_active'] != true) {
//         await supabase.auth.signOut();
//         if (!mounted) return;
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//               (_) => false,
//         );
//         return;
//       }
//
//       setState(() {
//         _profile = profile;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _logout() async {
//     await supabase.auth.signOut();
//
//     if (!mounted) return;
//
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//           (_) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0A0A0A),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0A0A0A),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Text(
//               _error!,
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//       );
//     }
//
//     return CrmShellScreen(
//       profile: _profile!,
//       onLogout: _logout,
//     );
//     // return LeadsScreen(
//     //   profile: _profile!,
//     //   onLogout: _logout,
//     // );
//     // return PriceListScreen(
//     //   profile: _profile!,
//     //   onLogout: _logout,
//     // );
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login_screen.dart';
import '../main.dart';
import '../services/push_notification_service.dart';
import 'crm/crm_shell_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PushNotificationService _pushNotificationService =
  PushNotificationService(supabase);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = Map<String, dynamic>.from(data);

      if (profile['is_active'] != true) {
        await supabase.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
        return;
      }

      await _pushNotificationService.initialize(
        userId: user.id,
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
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

  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return CrmShellScreen(
      profile: _profile!,
      onLogout: _logout,
    );
  }
}