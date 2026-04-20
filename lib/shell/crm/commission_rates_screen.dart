import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/commission_service.dart';
import '../../services/price_tier_service.dart';

class CommissionRatesScreen extends StatefulWidget {
  const CommissionRatesScreen({super.key});

  @override
  State<CommissionRatesScreen> createState() => _CommissionRatesScreenState();
}

class _CommissionRatesScreenState extends State<CommissionRatesScreen> {
  final _supabase = Supabase.instance.client;

  static const _tiers = [
    ('price_ee', 'EE'),
    ('price_aa', 'AA'),
    ('price_a', 'A'),
    ('price_rr', 'RR'),
    ('price_r', 'R'),
    ('price_art', 'ART'),
  ];

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _salespeople = [];

  // profileId → { priceKey → TextEditingController }
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Set<String> _saving = {};

  late TextEditingController _artMultiplierCtrl;
  bool _savingMultiplier = false;

  @override
  void initState() {
    super.initState();
    _artMultiplierCtrl = TextEditingController(
      text: PriceTierService().artMultiplier.toStringAsFixed(2),
    );
    _load();
  }

  @override
  void dispose() {
    _artMultiplierCtrl.dispose();
    for (final map in _controllers.values) {
      for (final ctrl in map.values) ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final usersRaw = await _supabase
          .from('profiles')
          .select('id, full_name, role')
          .inFilter('role', ['admin', 'sales'])
          .order('full_name');

      final users = (usersRaw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final ratesRaw = await _supabase
          .from('commission_rates')
          .select('profile_id, price_key, rate');

      final ratesMap = <String, Map<String, double>>{};
      for (final row in ratesRaw as List) {
        final pid = row['profile_id']?.toString() ?? '';
        final key = row['price_key']?.toString() ?? '';
        final rate = double.tryParse(row['rate']?.toString() ?? '0') ?? 0;
        ratesMap.putIfAbsent(pid, () => {})[key] = rate;
      }

      // Build controllers
      for (final user in users) {
        final pid = user['id']?.toString() ?? '';
        final userRates = ratesMap[pid] ?? {};
        _controllers[pid] = {
          for (final tier in _tiers)
            tier.$1: TextEditingController(
              text: (userRates[tier.$1] ?? 0).toStringAsFixed(2),
            ),
        };
      }

      setState(() {
        _salespeople = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveRates(String profileId) async {
    setState(() => _saving.add(profileId));
    try {
      final ctrls = _controllers[profileId] ?? {};
      for (final tier in _tiers) {
        final key = tier.$1;
        final rate = double.tryParse(ctrls[key]?.text.trim() ?? '0') ?? 0;
        await CommissionService().setRate(_supabase, profileId, key, rate);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission rates saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(profileId));
    }
  }

  Future<void> _saveMultiplier() async {
    final val = double.tryParse(_artMultiplierCtrl.text.trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid multiplier (e.g. 1.30)')),
      );
      return;
    }
    setState(() => _savingMultiplier = true);
    try {
      await PriceTierService().saveArtMultiplier(_supabase, val);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ART multiplier saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingMultiplier = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Commission Rates',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white70),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildArtMultiplierCard(),
                    const SizedBox(height: 20),
                    ..._salespeople.map(_buildUserCard),
                  ],
                ),
    );
  }

  Widget _buildArtMultiplierCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ART Price Multiplier',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 4),
          const Text('ART = R × multiplier (e.g. 1.30 = 30% above R)',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: _rateField(
                  controller: _artMultiplierCtrl,
                  suffix: '×',
                ),
              ),
              const SizedBox(width: 12),
              _savingMultiplier
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _saveMultiplier,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final pid = user['id']?.toString() ?? '';
    final name = (user['full_name'] ?? 'Unknown').toString();
    final role = (user['role'] ?? '').toString();
    final ctrls = _controllers[pid] ?? {};
    final isSaving = _saving.contains(pid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(role,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: () => _saveRates(pid),
                        child: const Text('Save'),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _tiers.map((tier) {
                final key = tier.$1;
                final label = tier.$2;
                return SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _rateField(controller: ctrls[key]),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateField({
    TextEditingController? controller,
    String suffix = '%',
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        suffixText: suffix,
        suffixStyle:
            const TextStyle(color: Colors.white38, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFCCAA44)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: child,
    );
  }
}
