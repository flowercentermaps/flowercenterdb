import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/constants/app_constants.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker>
    with WidgetsBindingObserver {
  bool _checked = false;
  bool _updateRequired = false;
  String _downloadUrl = '';
  String _currentVersion = '';
  String _requiredVersion = '';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVersion();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Re-check when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_updateRequired) {
      _checkVersion();
    }
  }

  /// Listen for real-time changes to app_config in Supabase
  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('app_config_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'app_config',
          callback: (payload) {
            debugPrint('[UpdateChecker] Realtime update received');
            _checkVersion();
          },
        )
        .subscribe();
  }

  /// Compare version strings like "1.0.2" vs "1.0.3"
  /// Returns true if [current] is older than [required]
  bool _isOutdated(String current, String required) {
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final r = required.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = r.length > c.length ? r.length : c.length;
    for (int i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final rv = i < r.length ? r[i] : 0;
      if (cv < rv) return true;
      if (cv > rv) return false;
    }
    return false;
  }

  Future<void> _checkVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;

      final platform = Platform.isAndroid ? 'android' : 'windows';
      debugPrint('[UpdateChecker] platform=$platform currentVersion=$_currentVersion');

      final response = await Supabase.instance.client
          .from('app_config')
          .select('key, value');

      final map = <String, String>{};
      for (final row in response as List) {
        map[row['key'] as String] = row['value'] as String;
      }

      debugPrint('[UpdateChecker] config=$map');

      final minVersion = map['min_version_$platform'] ?? '';
      final downloadUrl = map['download_url_$platform'] ?? '';

      debugPrint('[UpdateChecker] minVersion=$minVersion outdated=${_isOutdated(_currentVersion, minVersion)}');

      if (minVersion.isNotEmpty && _isOutdated(_currentVersion, minVersion)) {
        setState(() {
          _updateRequired = true;
          _requiredVersion = minVersion;
          _downloadUrl = downloadUrl;
        });
      }
    } catch (e) {
      debugPrint('[UpdateChecker] ERROR: $e');
      // If check fails (no internet, table missing), allow app to proceed
    } finally {
      if (mounted) {
        setState(() => _checked = true);
      }
    }
  }

  Future<void> _openDownload() async {
    if (_downloadUrl.isEmpty) return;
    final uri = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryColor,
            ),
          ),
        ),
      );
    }

    if (_updateRequired) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppConstants.primaryColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.system_update_rounded,
                          color: AppConstants.primaryColor,
                          size: 56,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Update Required',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your version ($_currentVersion) is outdated. Please update to version $_requiredVersion to continue.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _openDownload,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text(
                              'Download Update',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
