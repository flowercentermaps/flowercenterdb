// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'quotation_details_screen.dart';
//
// class QuotationListScreen extends StatefulWidget {
//   const QuotationListScreen({super.key});
//
//   @override
//   State<QuotationListScreen> createState() => _QuotationListScreenState();
// }
//
// class _QuotationListScreenState extends State<QuotationListScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _quotations = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadQuotations();
//   }
//
//   Future<void> _loadQuotations() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final response = await _supabase
//           .from('quotations')
//           .select()
//           .order('created_at', ascending: false);
//
//       if (!mounted) return;
//
//       setState(() {
//         _quotations = (response as List)
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   double _toDouble(dynamic value) {
//     if (value == null) return 0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _formatMoney(dynamic value) {
//     final number = _toDouble(value);
//     if (number == number.roundToDouble()) return number.toInt().toString();
//     return number.toStringAsFixed(2);
//   }
//
//   String _text(dynamic value) {
//     return (value ?? '').toString().trim();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       appBar: AppBar(
//         title: const Text('Quotations'),
//         backgroundColor: const Color(0xFF111111),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Text(
//             _error!,
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _loadQuotations,
//         child: ListView.separated(
//           padding: const EdgeInsets.all(16),
//           itemCount: _quotations.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 12),
//           itemBuilder: (context, index) {
//             final quote = _quotations[index];
//             final id = quote['id'];
//
//             return InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => QuotationDetailsScreen(
//                       quotationId: id,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF141414),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: const Color(0xFF3A2F0B)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _text(quote['quote_no']).isEmpty
//                           ? 'No Quote Number'
//                           : _text(quote['quote_no']),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w900,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     if (_text(quote['customer_name']).isNotEmpty)
//                       Text('Customer: ${_text(quote['customer_name'])}'),
//                     if (_text(quote['company_name']).isNotEmpty)
//                       Text('Company: ${_text(quote['company_name'])}'),
//                     if (_text(quote['quote_date']).isNotEmpty)
//                       Text('Date: ${_text(quote['quote_date'])}'),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Net Total: ${_formatMoney(quote['net_total'])} AED',
//                       style: const TextStyle(
//                         color: AppConstants.primaryColor,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'quotation_details_screen.dart';
//
// class QuotationListScreen extends StatefulWidget {
//   final bool isAdmin;
//   final String currentUserId;
//
//   const QuotationListScreen({
//     super.key,
//     required this.isAdmin,
//     required this.currentUserId,
//   });
//
//   @override
//   State<QuotationListScreen> createState() => _QuotationListScreenState();
// }
//
// class _QuotationListScreenState extends State<QuotationListScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _quotations = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadQuotations();
//   }
//
//   Future<void> _loadQuotations() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final response = widget.isAdmin
//           ? await _supabase
//           .from('quotations')
//           .select()
//           .order('created_at', ascending: false)
//           : await _supabase
//           .from('quotations')
//           .select()
//           .eq('created_by', widget.currentUserId)
//           .order('created_at', ascending: false);
//
//       if (!mounted) return;
//
//       setState(() {
//         _quotations = (response as List)
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   double _toDouble(dynamic value) {
//     if (value == null) return 0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _formatMoney(dynamic value) {
//     final number = _toDouble(value);
//     if (number == number.roundToDouble()) return number.toInt().toString();
//     return number.toStringAsFixed(2);
//   }
//
//   String _text(dynamic value) {
//     return (value ?? '').toString().trim();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       appBar: AppBar(
//         title: Text(widget.isAdmin ? 'All Quotations' : 'My Quotations'),
//         backgroundColor: const Color(0xFF111111),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Text(
//             _error!,
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : _quotations.isEmpty
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Text(
//             widget.isAdmin
//                 ? 'No quotations found.'
//                 : 'You do not have any quotations yet.',
//             textAlign: TextAlign.center,
//           ),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _loadQuotations,
//         child: ListView.separated(
//           padding: const EdgeInsets.all(16),
//           itemCount: _quotations.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 12),
//           itemBuilder: (context, index) {
//             final quote = _quotations[index];
//             final id = quote['id'];
//
//             return InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => QuotationDetailsScreen(
//                       quotationId: id,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF141414),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: const Color(0xFF3A2F0B),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _text(quote['quote_no']),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w900,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('Customer: ${_text(quote['customer_name'])}'),
//                     Text('Company: ${_text(quote['company_name'])}'),
//                     Text('Salesperson: ${_text(quote['salesperson_name'])}'),
//                     Text('Status: ${_text(quote['status'])}'),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Net Total: ${_formatMoney(quote['net_total'])} AED',
//                       style: const TextStyle(
//                         color: AppConstants.primaryColor,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'quotation_details_screen.dart';
//
// class QuotationListScreen extends StatefulWidget {
//   final bool isAdmin;
//   final String currentUserId;
//
//   const QuotationListScreen({
//     super.key,
//     required this.isAdmin,
//     required this.currentUserId,
//   });
//
//   @override
//   State<QuotationListScreen> createState() => _QuotationListScreenState();
// }
//
// class _QuotationListScreenState extends State<QuotationListScreen> {
//   final SupabaseClient _supabase = Supabase.instance.client;
//
//   final TextEditingController _searchController = TextEditingController();
//
//   bool _isLoading = true;
//   String? _error;
//
//   List<Map<String, dynamic>> _quotations = [];
//   List<Map<String, dynamic>> _profiles = [];
//
//   String _searchQuery = '';
//   String? _selectedStatus;
//   String? _selectedUserId;
//   DateTime? _fromDate;
//   DateTime? _toDate;
//
//   static const List<String> _statuses = [
//     'draft',
//     'sent',
//     'approved',
//     'cancelled',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() {
//       if (!mounted) return;
//       setState(() {
//         _searchQuery = _searchController.text.trim();
//       });
//       _loadQuotations();
//     });
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     await Future.wait([
//       _loadProfiles(),
//       _loadQuotations(),
//     ]);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadProfiles() async {
//     if (!widget.isAdmin) return;
//
//     try {
//       final response = await _supabase
//           .from('profiles')
//           .select('id, full_name, email, role')
//           .order('full_name', ascending: true);
//
//       if (!mounted) return;
//
//       setState(() {
//         _profiles = (response as List)
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//       });
//     } catch (_) {}
//   }
//
//   Future<void> _loadQuotations() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       dynamic query = _supabase.from('quotations').select();
//
//       if (!widget.isAdmin) {
//         query = query.eq('created_by', widget.currentUserId);
//       } else if (_selectedUserId != null && _selectedUserId!.isNotEmpty) {
//         query = query.eq('created_by', _selectedUserId!);
//       }
//
//       if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
//         query = query.eq('status', _selectedStatus!);
//       }
//
//       if (_fromDate != null) {
//         query = query.gte(
//           'quote_date',
//           _dateOnly(_fromDate!).toIso8601String().split('T').first,
//         );
//       }
//
//       if (_toDate != null) {
//         query = query.lte(
//           'quote_date',
//           _dateOnly(_toDate!).toIso8601String().split('T').first,
//         );
//       }
//
//       final response = await query.order('created_at', ascending: false);
//
//       var rows = (response as List)
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList();
//
//       final search = _searchQuery.toLowerCase();
//       if (search.isNotEmpty) {
//         rows = rows.where((quote) {
//           final haystack = [
//             _text(quote['quote_no']),
//             _text(quote['customer_name']),
//             _text(quote['company_name']),
//             _text(quote['customer_phone']),
//             _text(quote['salesperson_name']),
//             _text(quote['salesperson_contact']),
//             _text(quote['status']),
//           ].join(' ').toLowerCase();
//
//           return haystack.contains(search);
//         }).toList();
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _quotations = rows;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   DateTime _dateOnly(DateTime date) {
//     return DateTime(date.year, date.month, date.day);
//   }
//
//   Future<void> _pickFromDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _fromDate ?? now,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(now.year + 5),
//     );
//
//     if (picked == null) return;
//
//     setState(() {
//       _fromDate = picked;
//     });
//
//     await _loadQuotations();
//   }
//
//   Future<void> _pickToDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _toDate ?? now,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(now.year + 5),
//     );
//
//     if (picked == null) return;
//
//     setState(() {
//       _toDate = picked;
//     });
//
//     await _loadQuotations();
//   }
//
//   void _clearFilters() {
//     _searchController.clear();
//     setState(() {
//       _searchQuery = '';
//       _selectedStatus = null;
//       _selectedUserId = null;
//       _fromDate = null;
//       _toDate = null;
//     });
//     _loadQuotations();
//   }
//
//   double _toDouble(dynamic value) {
//     if (value == null) return 0;
//     if (value is num) return value.toDouble();
//     return double.tryParse(value.toString().trim()) ?? 0;
//   }
//
//   String _formatMoney(dynamic value) {
//     final number = _toDouble(value);
//     if (number == number.roundToDouble()) return number.toInt().toString();
//     return number.toStringAsFixed(2);
//   }
//
//   String _text(dynamic value) {
//     return (value ?? '').toString().trim();
//   }
//
//   String _formatDate(dynamic value) {
//     final raw = _text(value);
//     if (raw.isEmpty) return '';
//     final parsed = DateTime.tryParse(raw);
//     if (parsed == null) return raw;
//     final day = parsed.day.toString().padLeft(2, '0');
//     final month = parsed.month.toString().padLeft(2, '0');
//     final year = parsed.year.toString();
//     return '$day/$month/$year';
//   }
//
//   String _userLabel(Map<String, dynamic> user) {
//     final fullName = _text(user['full_name']);
//     final email = _text(user['email']);
//
//     if (fullName.isNotEmpty && email.isNotEmpty) {
//       return '$fullName ($email)';
//     }
//     if (fullName.isNotEmpty) return fullName;
//     if (email.isNotEmpty) return email;
//     return _text(user['id']);
//   }
//
//   Widget _buildFilters() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//       decoration: const BoxDecoration(
//         color: Color(0xFF111111),
//         border: Border(
//           bottom: BorderSide(color: Color(0xFF3A2F0B)),
//         ),
//       ),
//       child: Column(
//         children: [
//           TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search by quote no, customer, company, phone, salesperson...',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: _searchQuery.isEmpty
//                   ? null
//                   : IconButton(
//                 onPressed: () {
//                   _searchController.clear();
//                 },
//                 icon: const Icon(Icons.close),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: DropdownButtonFormField<String?>(
//                   value: _selectedStatus,
//                   decoration: const InputDecoration(
//                     labelText: 'Status',
//                   ),
//                   items: [
//                     const DropdownMenuItem<String?>(
//                       value: null,
//                       child: Text('All statuses'),
//                     ),
//                     ..._statuses.map(
//                           (status) => DropdownMenuItem<String?>(
//                         value: status,
//                         child: Text(status),
//                       ),
//                     ),
//                   ],
//                   onChanged: (value) async {
//                     setState(() {
//                       _selectedStatus = value;
//                     });
//                     await _loadQuotations();
//                   },
//                 ),
//               ),
//               const SizedBox(width: 12),
//               if (widget.isAdmin)
//                 Expanded(
//                   child: DropdownButtonFormField<String?>(
//                     value: _selectedUserId,
//                     decoration: const InputDecoration(
//                       labelText: 'User',
//                     ),
//                     items: [
//                       const DropdownMenuItem<String?>(
//                         value: null,
//                         child: Text('All users'),
//                       ),
//                       ..._profiles.map(
//                             (user) => DropdownMenuItem<String?>(
//                           value: _text(user['id']),
//                           child: Text(
//                             _userLabel(user),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ),
//                     ],
//                     onChanged: (value) async {
//                       setState(() {
//                         _selectedUserId = value;
//                       });
//                       await _loadQuotations();
//                     },
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: _pickFromDate,
//                   icon: const Icon(Icons.date_range_outlined),
//                   label: Text(
//                     _fromDate == null
//                         ? 'From date'
//                         : 'From: ${_formatDate(_fromDate!.toIso8601String())}',
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: _pickToDate,
//                   icon: const Icon(Icons.event_outlined),
//                   label: Text(
//                     _toDate == null
//                         ? 'To date'
//                         : 'To: ${_formatDate(_toDate!.toIso8601String())}',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Text(
//                 '${_quotations.length} quotation(s)',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const Spacer(),
//               TextButton.icon(
//                 onPressed: _clearFilters,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Clear filters'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0A0A),
//       appBar: AppBar(
//         title: Text(widget.isAdmin ? 'All Quotations' : 'My Quotations'),
//         backgroundColor: const Color(0xFF111111),
//       ),
//       body: Column(
//         children: [
//           _buildFilters(),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _error != null
//                 ? Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Text(
//                   _error!,
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             )
//                 : _quotations.isEmpty
//                 ? Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Text(
//                   widget.isAdmin
//                       ? 'No quotations found.'
//                       : 'You do not have any quotations yet.',
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             )
//                 : RefreshIndicator(
//               onRefresh: _loadQuotations,
//               child: ListView.separated(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: _quotations.length,
//                 separatorBuilder: (_, __) =>
//                 const SizedBox(height: 12),
//                 itemBuilder: (context, index) {
//                   final quote = _quotations[index];
//                   final id = quote['id'];
//
//                   return InkWell(
//                     borderRadius: BorderRadius.circular(20),
//                     onTap: () {
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (_) => QuotationDetailsScreen(
//                             quotationId: id,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF141414),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: const Color(0xFF3A2F0B),
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _text(quote['quote_no']),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w900,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Date: ${_formatDate(quote['quote_date'])}',
//                           ),
//                           Text(
//                             'Customer: ${_text(quote['customer_name'])}',
//                           ),
//                           Text(
//                             'Company: ${_text(quote['company_name'])}',
//                           ),
//                           Text(
//                             'Salesperson: ${_text(quote['salesperson_name'])}',
//                           ),
//                           Text(
//                             'Status: ${_text(quote['status'])}',
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Net Total: ${_formatMoney(quote['net_total'])} AED',
//                             style: const TextStyle(
//                               color: AppConstants.primaryColor,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'quotation_details_screen.dart';

class QuotationListScreen extends StatefulWidget {
  final String role;
  final String currentUserId;

  const QuotationListScreen({
    super.key,
    required this.role,
    required this.currentUserId,
  });

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  bool get _canViewAllQuotations => widget.role == 'accountant' || widget.role =='admin';
  bool get _canViewOwnQuotations => widget.role == 'sales' || widget.role =='admin';
  bool get _canAccessQuotations => _canViewAllQuotations || _canViewOwnQuotations;

  List<Map<String, dynamic>> _allQuotations = [];
  List<Map<String, dynamic>> _filteredQuotations = [];
  List<Map<String, dynamic>> _profiles = [];

  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedUserId;
  DateTime? _fromDate;
  DateTime? _toDate;

  static const List<String> _statuses = [
    'draft',
    'sent',
    'approved',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
        _applyFilters();
      });
    });

    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_canViewAllQuotations) {
        await _loadProfiles();
      }
      await _loadQuotations();

      if (!mounted) return;
      setState(() {
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

  Future<void> _loadProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, role, is_active')
          .order('full_name', ascending: true);

      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _profiles = rows;
      });

      debugPrint('Loaded profiles count: ${rows.length}');
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
      rethrow;
    }
  }

  Future<void> _loadQuotations() async {
    if (!_canAccessQuotations) {
      throw Exception('You do not have permission to view quotations.');
    }

    try {
      dynamic query = _supabase.from('quotations').select();

      if (_canViewOwnQuotations) {
        query = query.eq('created_by', widget.currentUserId);
      }

      final response = await query.order('created_at', ascending: false);

      final rows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _allQuotations = rows;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Failed to load quotations: $e');
      rethrow;
    }
  }
  void _applyFilters() {
    var rows = List<Map<String, dynamic>>.from(_allQuotations);

    if (widget.role =="admin" &&
        _selectedUserId != null &&
        _selectedUserId!.trim().isNotEmpty) {
      rows = rows
          .where((q) => _text(q['created_by']) == _selectedUserId!.trim())
          .toList();
    }

    if (_selectedStatus != null && _selectedStatus!.trim().isNotEmpty) {
      rows = rows
          .where((q) => _text(q['status']).toLowerCase() ==
          _selectedStatus!.trim().toLowerCase())
          .toList();
    }

    if (_fromDate != null) {
      final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      rows = rows.where((q) {
        final parsed = DateTime.tryParse(_text(q['quote_date']));
        if (parsed == null) return false;
        final onlyDate = DateTime(parsed.year, parsed.month, parsed.day);
        return !onlyDate.isBefore(from);
      }).toList();
    }

    if (_toDate != null) {
      final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
      rows = rows.where((q) {
        final parsed = DateTime.tryParse(_text(q['quote_date']));
        if (parsed == null) return false;
        final onlyDate = DateTime(parsed.year, parsed.month, parsed.day);
        return !onlyDate.isAfter(to);
      }).toList();
    }

    final search = _searchQuery.toLowerCase();
    if (search.isNotEmpty) {
      rows = rows.where((q) {
        final haystack = [
          _text(q['quote_no']),
          _text(q['customer_name']),
          _text(q['company_name']),
          _text(q['customer_trn']),
          _text(q['customer_phone']),
          _text(q['salesperson_name']),
          _text(q['salesperson_contact']),
          _text(q['salesperson_phone']),
          _text(q['status']),
          _formatMoney(q['net_total']),
        ].join(' ').toLowerCase();

        return haystack.contains(search);
      }).toList();
    }

    _filteredQuotations = rows;
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _fromDate = picked;
      _applyFilters();
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _toDate = picked;
      _applyFilters();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedUserId = null;
      _fromDate = null;
      _toDate = null;
      _applyFilters();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0;
  }

  String _formatMoney(dynamic value) {
    final number = _toDouble(value);
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  String _text(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _formatDate(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String _userLabel(Map<String, dynamic> user) {
    final fullName = _text(user['full_name']);
    final email = _text(user['email']);

    if (fullName.isNotEmpty && email.isNotEmpty) {
      return '$fullName ($email)';
    }
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return _text(user['id']);
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3A2F0B)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          final statusField = DropdownButtonFormField<String?>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'All statuses',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ..._statuses.map(
                    (status) => DropdownMenuItem<String?>(
                  value: status,
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
                _applyFilters();
              });
            },
          );

          final userField = DropdownButtonFormField<String?>(
            value: _selectedUserId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'User',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'All users',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ..._profiles.map(
                    (user) => DropdownMenuItem<String?>(
                  value: _text(user['id']),
                  child: Text(
                    _userLabel(user),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedUserId = value;
                _applyFilters();
              });
            },
          );

          final fromButton = SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromDate,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _fromDate == null
                    ? 'From date'
                    : 'From: ${_formatDate(_fromDate!.toIso8601String())}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );

          final toButton = SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickToDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _toDate == null
                    ? 'To date'
                    : 'To: ${_formatDate(_toDate!.toIso8601String())}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );

          return Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                  'Search by quote no, customer, company, phone, salesperson...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (isNarrow) ...[
                statusField,
                const SizedBox(height: 12),
                if (widget.role =="admin") ...[
                  userField,
                  const SizedBox(height: 12),
                ],
                fromButton,
                const SizedBox(height: 12),
                toButton,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: statusField),
                    if (widget.role =="admin") ...[
                      const SizedBox(width: 12),
                      Expanded(child: userField),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: fromButton),
                    const SizedBox(width: 12),
                    Expanded(child: toButton),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filteredQuotations.length} quotation(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.role =="admin" ? 'All Quotations' : 'My Quotations'),
        backgroundColor: const Color(0xFF111111),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : _filteredQuotations.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.role =="admin"
                      ? 'No quotations found.'
                      : 'You do not have any quotations yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadQuotations,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredQuotations.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quote = _filteredQuotations[index];
                  final id = quote['id'];
                  // Read the brand from the quotation row itself — reliable regardless
                  // of which screen navigated here.
                  final isHamasat = quote['is_hamasat'] == true;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuotationDetailsScreen(
                            isHamasat: isHamasat,
                            quotationId: id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isHamasat
                              ? const Color(0xFF3D2E52)
                              : const Color(0xFF3A2F0B),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(quote['quote_no']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${_formatDate(quote['quote_date'])}',
                          ),
                          Text(
                            'Customer: ${_text(quote['customer_name'])}',
                          ),
                          Text(
                            'Company: ${_text(quote['company_name'])}',
                          ),
                          Text(
                            'Salesperson: ${_text(quote['salesperson_name'])}',
                          ),
                          Text(
                            'Status: ${_text(quote['status'])}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Net Total: ${_formatMoney(quote['net_total'])} AED',
                            style: TextStyle(
                              color: isHamasat
                                  ? const Color(0xFF9B77BA)
                                  : AppConstants.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}