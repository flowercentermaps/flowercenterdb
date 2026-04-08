// // // import 'package:flowercenterdb/price_list_screen.dart';
// // // import 'package:flowercenterdb/theme/fc_theme.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // //
// // // Future<void> main() async {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //
// // //   await Supabase.initialize(
// // //     url: 'https://egfntxfseqtoxpnzxsfj.supabase.co',
// // //     anonKey: 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x',
// // //   );
// // //
// // //   runApp(const MyApp());
// // // }
// // //
// // // final supabase = Supabase.instance.client;
// // //
// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       debugShowCheckedModeBanner: false,
// // //       theme: blackGoldTheme,
// // //
// // //       home: const PriceListScreen(),
// // //     );
// // //   }
// // // }
// //
// //
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flowercenterdb/price_list_screen.dart';
// // import 'package:flowercenterdb/theme/fc_theme.dart';
// // import 'package:flutter/material.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// //
// // import 'firebase_options.dart';
// // import 'shell/app_shell.dart';
// // import 'login_screen.dart';
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //
// //   await Firebase.initializeApp(
// //     options: DefaultFirebaseOptions.currentPlatform,
// //   );
// //   await Supabase.initialize(
// //     url: 'https://egfntxfseqtoxpnzxsfj.supabase.co',
// //     anonKey: 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x',
// //   );
// //
// //   runApp(const MyApp());
// // }
// //
// // final supabase = Supabase.instance.client;
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: blackGoldTheme,
// //       home: const AuthGate(),
// //     );
// //   }
// // }
// //
// // class AuthGate extends StatelessWidget {
// //   const AuthGate({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final session = supabase.auth.currentSession;
// //
// //     if (session == null) {
// //       return const LoginScreen();
// //     }
// //
// //     return const AppShell();
// //   }
// // }
//
// import 'package:FlowerCenterCrm/theme/fc_theme.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'firebase_options.dart';
// import 'login_screen.dart';
// import 'shell/app_shell.dart';
// import 'update_checker.dart';
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
// }
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   await Supabase.initialize(
//     url: 'https://egfntxfseqtoxpnzxsfj.supabase.co',
//     anonKey: 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x',
//   );
//
//   runApp(
//     EasyLocalization(
//       supportedLocales: const [Locale('en'), Locale('ar')],
//       path: 'assets/translations',
//       fallbackLocale: const Locale('en'),
//       child: const UpdateChecker(child: MyApp()),
//     ),
//   );
// }
//
// final supabase = Supabase.instance.client;
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: blackGoldTheme,
//       locale: context.locale,
//       supportedLocales: context.supportedLocales,
//       localizationsDelegates: context.localizationsDelegates,
//       home: const AuthGate(),
//     );
//   }
// }
//
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final session = supabase.auth.currentSession;
//
//     if (session == null) {
//       return const LoginScreen();
//     }
//
//     return const AppShell();
//   }
// }


import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'shell/app_shell.dart';
import 'theme/fc_theme.dart';
import 'update_checker.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: 'https://egfntxfseqtoxpnzxsfj.supabase.co',
    anonKey: 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x',
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      useOnlyLangCode: true,
      child: const UpdateChecker(
        child: MyApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: blackGoldTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    }

    return const AppShell();
  }
}