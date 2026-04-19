import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// The Node.js sync server must be running on this machine at port 3030.
// Start it with: cd sync && node server.js
// ─────────────────────────────────────────────────────────────────────────────

class SyncScreen extends StatefulWidget {
  final bool showOwnHeader;
  const SyncScreen({super.key, this.showOwnHeader = true});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  static const _base = 'http://localhost:3030';

  // Status
  bool _syncing = false;
  Map<String, dynamic>? _lastRun;
  List<String> _logs = [];
  String? _statusError;
  Timer? _pollTimer;

  // Schedule
  bool _scheduleEnabled = false;
  int _scheduleHour = 2;
  int _scheduleMinute = 0;
  bool _scheduleSaving = false;

  // SQL Config
  final _serverCtrl   = TextEditingController();
  final _databaseCtrl = TextEditingController();
  final _userCtrl     = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordSet   = false;
  bool _showPassword  = false;
  bool _configSaving  = false;
  bool _configTesting = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadSchedule();
    _loadConfig();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _serverCtrl.dispose();
    _databaseCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadStatus(),
    );
  }

  Future<void> _loadConfig() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/config'))
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _serverCtrl.text   = data['server']   as String? ?? '';
        _databaseCtrl.text = data['database'] as String? ?? '';
        _userCtrl.text     = data['user']     as String? ?? '';
        _passwordSet       = data['passwordSet'] as bool? ?? false;
      });
    } catch (_) {}
  }

  Future<void> _saveConfig() async {
    final server   = _serverCtrl.text.trim();
    final database = _databaseCtrl.text.trim();
    final user     = _userCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (server.isEmpty || database.isEmpty || user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server, Database and User are required.')),
      );
      return;
    }
    setState(() => _configSaving = true);
    try {
      await http.post(
        Uri.parse('$_base/api/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'server': server, 'database': database,
          'user': user, 'password': password,
        }),
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() { _passwordSet = password.isNotEmpty; _testResult = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Config saved ✓'),
          backgroundColor: Color(0xFF22c55e),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _configSaving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() { _configTesting = true; _testResult = null; });
    try {
      final res = await http.post(Uri.parse('$_base/api/test-connection'))
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _testOk     = data['ok'] as bool? ?? false;
        _testResult = _testOk
            ? '✓ Connected — ${data['version'] ?? 'OK'}'
            : '✗ ${data['error'] ?? 'Connection failed'}';
      });
    } catch (e) {
      if (mounted) setState(() { _testOk = false; _testResult = '✗ $e'; });
    } finally {
      if (mounted) setState(() => _configTesting = false);
    }
  }

  Future<void> _loadStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/status'))
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _syncing = data['syncing'] as bool? ?? false;
        _lastRun = data['lastRun'] as Map<String, dynamic>?;
        _logs = List<String>.from(data['logs'] ?? []);
        _statusError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = 'Server offline — start it with: node server.js');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/schedule'))
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final sched = data['schedule'] as Map<String, dynamic>? ?? {};
      setState(() {
        _scheduleEnabled = sched['enabled'] as bool? ?? false;
        _scheduleHour    = sched['hour']    as int?  ?? 2;
        _scheduleMinute  = sched['minute']  as int?  ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _triggerSync() async {
    setState(() { _syncing = true; _logs = []; });
    try {
      await http
          .post(Uri.parse('$_base/api/sync'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reach sync server: $e')),
      );
      setState(() => _syncing = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _scheduleSaving = true);
    try {
      await http
          .post(
            Uri.parse('$_base/api/schedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'enabled': _scheduleEnabled,
              'hour': _scheduleHour,
              'minute': _scheduleMinute,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved ✓'),
          backgroundColor: Color(0xFF22c55e),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save schedule: $e')),
      );
    } finally {
      if (mounted) setState(() => _scheduleSaving = false);
    }
  }

  String _timeAgo(String? isoTime) {
    if (isoTime == null) return 'Never';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _nextRun() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, _scheduleHour, _scheduleMinute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    final label = next.day == now.day ? 'today' : 'tomorrow';
    final h = _scheduleHour.toString().padLeft(2, '0');
    final m = _scheduleMinute.toString().padLeft(2, '0');
    return 'Next run: $label at $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: widget.showOwnHeader
          ? AppBar(
              backgroundColor: const Color(0xFF111111),
              title: const Text('Sync  الخازن ↔ Supabase',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.showOwnHeader)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Sync  الخازن ↔ Supabase',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),

          // ── Server offline banner ──────────────────────────────────────────
          if (_statusError != null)
            _Banner(
              color: const Color(0xFF7f1d1d),
              icon: Icons.wifi_off_rounded,
              message: _statusError!,
            ),

          // ── Status card ───────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusDot(syncing: _syncing, hasRun: _lastRun != null),
                    const SizedBox(width: 8),
                    Text(
                      _syncing
                          ? 'Syncing…'
                          : _lastRun != null
                              ? 'Last sync: ${_timeAgo(_lastRun!['time']?.toString())}'
                              : 'Never synced',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                if (_lastRun != null && !_syncing) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatBox(
                        label: 'Prices Updated',
                        value: '${_lastRun!['priceUpdated'] ?? 0}',
                        color: const Color(0xFF22c55e),
                      ),
                      const SizedBox(width: 8),
                      _StatBox(
                        label: 'Stock Rows',
                        value: '${_lastRun!['stockRows'] ?? 0}',
                        color: const Color(0xFF3b82f6),
                      ),
                      const SizedBox(width: 8),
                      _StatBox(
                        label: 'No Match',
                        value: '${_lastRun!['priceNotFound'] ?? 0}',
                        color: const Color(0xFFf59e0b),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Completed in ${_lastRun!['elapsedSeconds'] ?? '?'}s',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Sync Now button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_syncing || _statusError != null) ? null : _triggerSync,
              icon: _syncing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(_syncing ? 'Syncing…' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22c55e),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF166534),
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // ── Live log ─────────────────────────────────────────────────────
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ..._logs.map((line) => Text(
                        line,
                        style: TextStyle(
                          color: line.contains('[FATAL]') || line.contains('❌')
                              ? const Color(0xFFf87171)
                              : line.contains('✓') || line.contains('complete')
                                  ? const Color(0xFF22c55e)
                                  : const Color(0xFFd1d5db),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── SQL Server config ─────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SQL Server Connection',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Saved to this machine — copy the sync folder to move.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 14),

                _ConfigField(
                  label: 'Server',
                  hint: r'localhost\SQL2008R2  or  192.168.1.5\SQLEXPRESS',
                  controller: _serverCtrl,
                ),
                const SizedBox(height: 10),
                _ConfigField(
                  label: 'Database',
                  hint: 'e.g. KD_FLOWER_CENTER_LLC_2026_SHJ_BR24',
                  controller: _databaseCtrl,
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _ConfigField(
                      label: 'Username',
                      hint: 'sa',
                      controller: _userCtrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ConfigField(
                      label: _passwordSet && _passwordCtrl.text.isEmpty
                          ? 'Password (saved — leave blank to keep)'
                          : 'Password',
                      hint: '••••••',
                      controller: _passwordCtrl,
                      obscure: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18, color: Colors.white38,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                ]),

                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_testOk
                              ? const Color(0xFF22c55e)
                              : const Color(0xFFef4444))
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testOk
                            ? const Color(0xFF22c55e)
                            : const Color(0xFFef4444),
                      ),
                    ),
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testOk
                            ? const Color(0xFF22c55e)
                            : const Color(0xFFf87171),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_configTesting || _statusError != null)
                          ? null
                          : _testConnection,
                      icon: _configTesting
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF22c55e),
                              ))
                          : const Icon(Icons.electrical_services_rounded,
                              size: 16),
                      label: Text(
                          _configTesting ? 'Testing…' : 'Test Connection'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF22c55e),
                        side: const BorderSide(color: Color(0xFF22c55e)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _configSaving ? null : _saveConfig,
                      icon: _configSaving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(_configSaving ? 'Saving…' : 'Save Config'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Schedule section ──────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scheduled Auto-Sync',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),

                // Enable toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enable daily sync',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Switch(
                      value: _scheduleEnabled,
                      onChanged: (v) => setState(() => _scheduleEnabled = v),
                      activeColor: const Color(0xFF22c55e),
                    ),
                  ],
                ),

                if (_scheduleEnabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Hour',
                          value: _scheduleHour,
                          items: List.generate(24, (i) => i),
                          display: (v) => v.toString().padLeft(2, '0'),
                          onChanged: (v) => setState(() => _scheduleHour = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Minute',
                          value: _scheduleMinute,
                          items: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
                          display: (v) => v.toString().padLeft(2, '0'),
                          onChanged: (v) => setState(() => _scheduleMinute = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nextRun(),
                    style: const TextStyle(
                        color: Color(0xFF22c55e), fontSize: 12),
                  ),
                ],

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _scheduleSaving ? null : _saveSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1e3a2f),
                      foregroundColor: const Color(0xFF22c55e),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _scheduleSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF22c55e)),
                          )
                        : const Text('Save Schedule'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  const _Banner({required this.color, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      );
}

class _StatusDot extends StatefulWidget {
  final bool syncing;
  final bool hasRun;
  const _StatusDot({required this.syncing, required this.hasRun});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.syncing
        ? const Color(0xFFf59e0b)
        : widget.hasRun
            ? const Color(0xFF22c55e)
            : Colors.white24;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.syncing
              ? Color.lerp(color, Colors.white, _ctrl.value * 0.5)
              : color,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: const Color(0xFF1a1a1a),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(display(e)),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}

class _ConfigField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;

  const _ConfigField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: const Color(0xFF1a1a1a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3b82f6), width: 1.4),
        ),
      ),
    );
  }
}
