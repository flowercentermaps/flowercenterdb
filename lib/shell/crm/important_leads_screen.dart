import 'package:flutter/material.dart';
import 'leads_screen.dart';

class ImportantLeadsScreen extends StatelessWidget {
  final Map<String, dynamic> profile;
  final Future<void> Function() onLogout;

  const ImportantLeadsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LeadsScreen(
      profile: profile,
      onLogout: onLogout,
      initialImportantOnly: true,
      customTitle: 'Important Leads',
      showOwnHeader: false,
    );
  }
}