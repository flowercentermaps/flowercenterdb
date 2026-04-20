import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _SalesReport {
  final double totalSales;
  final double netSales;
  final int totalOrders;
  final double totalRefunds;

  const _SalesReport({
    required this.totalSales,
    required this.netSales,
    required this.totalOrders,
    required this.totalRefunds,
  });

  factory _SalesReport.fromJson(Map<String, dynamic> j) => _SalesReport(
        totalSales: double.tryParse(j['total_sales']?.toString() ?? '0') ?? 0,
        netSales: double.tryParse(j['net_sales']?.toString() ?? '0') ?? 0,
        totalOrders: int.tryParse(j['total_orders']?.toString() ?? '0') ?? 0,
        totalRefunds:
            double.tryParse(j['total_refunds']?.toString() ?? '0') ?? 0,
      );
}

class _OrderTotal {
  final String slug;
  final String name;
  final int total;

  const _OrderTotal({
    required this.slug,
    required this.name,
    required this.total,
  });

  factory _OrderTotal.fromJson(Map<String, dynamic> j) => _OrderTotal(
        slug: j['slug']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        total: int.tryParse(j['total']?.toString() ?? '0') ?? 0,
      );
}

class _Order {
  final int id;
  final String number;
  final String status;
  final double total;
  final String customerName;
  final DateTime? dateCreated;

  const _Order({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.customerName,
    required this.dateCreated,
  });

  factory _Order.fromJson(Map<String, dynamic> j) {
    final billing = j['billing'] as Map<String, dynamic>? ?? {};
    final first = billing['first_name']?.toString() ?? '';
    final last = billing['last_name']?.toString() ?? '';
    final name = '$first $last'.trim();

    DateTime? date;
    final raw = j['date_created']?.toString();
    if (raw != null && raw.isNotEmpty) date = DateTime.tryParse(raw);

    return _Order(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      number: j['number']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      total: double.tryParse(j['total']?.toString() ?? '0') ?? 0,
      customerName: name.isEmpty ? 'Guest' : name,
      dateCreated: date,
    );
  }
}

class _TopSeller {
  final String name;
  final int productId;
  final int quantity;

  const _TopSeller({
    required this.name,
    required this.productId,
    required this.quantity,
  });

  factory _TopSeller.fromJson(Map<String, dynamic> j) => _TopSeller(
        name: j['name']?.toString() ?? '',
        productId: int.tryParse(j['product_id']?.toString() ?? '0') ?? 0,
        quantity: int.tryParse(j['quantity']?.toString() ?? '0') ?? 0,
      );
}

class _StockProduct {
  final int id;
  final String name;
  final String sku;
  final int? stockQuantity;

  const _StockProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.stockQuantity,
  });

  factory _StockProduct.fromJson(Map<String, dynamic> j) => _StockProduct(
        id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        name: j['name']?.toString() ?? '',
        sku: j['sku']?.toString() ?? '',
        stockQuantity: j['stock_quantity'] != null
            ? int.tryParse(j['stock_quantity'].toString())
            : null,
      );
}

class _CustomerStat {
  final String slug;
  final String name;
  final int total;

  const _CustomerStat(
      {required this.slug, required this.name, required this.total});

  factory _CustomerStat.fromJson(Map<String, dynamic> j) => _CustomerStat(
        slug: j['slug']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        total: int.tryParse(j['total']?.toString() ?? '0') ?? 0,
      );
}

class _Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final double totalSpent;
  final int ordersCount;

  const _Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.totalSpent,
    required this.ordersCount,
  });

  String get displayName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? email : n;
  }

  factory _Customer.fromJson(Map<String, dynamic> j) => _Customer(
        id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        firstName: j['first_name']?.toString() ?? '',
        lastName: j['last_name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        totalSpent:
            double.tryParse(j['total_spent']?.toString() ?? '0') ?? 0,
        ordersCount:
            int.tryParse(j['orders_count']?.toString() ?? '0') ?? 0,
      );
}

class _OnSaleProduct {
  final int id;
  final String name;
  final String sku;
  final double regularPrice;
  final double salePrice;

  const _OnSaleProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.regularPrice,
    required this.salePrice,
  });

  double get discountPct =>
      regularPrice > 0 ? (regularPrice - salePrice) / regularPrice * 100 : 0;

  factory _OnSaleProduct.fromJson(Map<String, dynamic> j) => _OnSaleProduct(
        id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
        name: j['name']?.toString() ?? '',
        sku: j['sku']?.toString() ?? '',
        regularPrice:
            double.tryParse(j['regular_price']?.toString() ?? '0') ?? 0,
        salePrice: double.tryParse(j['sale_price']?.toString() ?? '0') ?? 0,
      );
}

class _Coupon {
  final int id;
  final String code;
  final String discountType;
  final double amount;
  final int usageCount;
  final DateTime? dateExpires;

  const _Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.amount,
    required this.usageCount,
    required this.dateExpires,
  });

  String get discountLabel => discountType == 'percent'
      ? '${amount.toStringAsFixed(0)}% off'
      : 'AED ${amount.toStringAsFixed(0)} off';

  bool get isExpired =>
      dateExpires != null && dateExpires!.isBefore(DateTime.now());

  factory _Coupon.fromJson(Map<String, dynamic> j) {
    DateTime? exp;
    final raw = j['date_expires']?.toString();
    if (raw != null && raw.isNotEmpty) exp = DateTime.tryParse(raw);
    return _Coupon(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      code: j['code']?.toString() ?? '',
      discountType: j['discount_type']?.toString() ?? '',
      amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
      usageCount: int.tryParse(j['usage_count']?.toString() ?? '0') ?? 0,
      dateExpires: exp,
    );
  }
}

class _Review {
  final int id;
  final String reviewer;
  final int rating;
  final String review; // plain text (HTML stripped)
  final int productId;

  const _Review({
    required this.id,
    required this.reviewer,
    required this.rating,
    required this.review,
    required this.productId,
  });

  factory _Review.fromJson(Map<String, dynamic> j) {
    // Strip basic HTML tags from the review body
    final raw = j['review']?.toString() ?? '';
    final plain = raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();

    return _Review(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      reviewer: j['reviewer']?.toString() ?? 'Anonymous',
      rating: int.tryParse(j['rating']?.toString() ?? '0') ?? 0,
      review: plain,
      productId: int.tryParse(j['product_id']?.toString() ?? '0') ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class WooCommerceScreen extends StatefulWidget {
  const WooCommerceScreen({super.key});

  @override
  State<WooCommerceScreen> createState() => _WooCommerceScreenState();
}

class _WooCommerceScreenState extends State<WooCommerceScreen>
    with SingleTickerProviderStateMixin {
  // ---- WooCommerce credentials --------------------------------------------
  static const String _baseUrl = 'https://flowercenter.ae';
  static const String _consumerKey =
      'ck_76997a7a3b037b87034366bdb2a331914b0e7806';
  static const String _consumerSecret =
      'cs_b30e90a7753254c3fee57e9b78009e43f974cd7f';

  // ---- Tabs ---------------------------------------------------------------
  late final TabController _tabController;
  static const _tabCount = 7;

  // ---- Period filter ------------------------------------------------------
  static const _periods = ['day', 'week', 'month', 'year', 'all'];
  static const _periodLabels = ['Today', 'Week', 'Month', 'Year', 'All Time'];
  int _periodIndex = 4; // default: all time
  String get _period => _periods[_periodIndex];

  // ---- Loading state ------------------------------------------------------
  bool _loading = true;
  bool _loadingPeriod = false;

  // ---- Per-section error strings (null = ok) ------------------------------
  String? _errorRevenue;
  String? _errorOrderTotals;
  String? _errorRecentOrders;
  String? _errorTopSellers;
  String? _errorOutOfStock;
  String? _errorLowStock;
  String? _errorCustomers;
  String? _errorOnSale;
  String? _errorCoupons;
  String? _errorRefunds;
  String? _errorReviews;

  // ---- Data ---------------------------------------------------------------
  _SalesReport? _salesReport;

  List<_OrderTotal> _orderTotals = [];
  List<_Order> _recentOrders = [];
  List<_TopSeller> _topSellers = [];
  List<_StockProduct> _outOfStock = [];
  List<_StockProduct> _lowStock = [];
  List<_CustomerStat> _customerStats = [];
  List<_Customer> _topCustomers = [];
  List<_OnSaleProduct> _onSale = [];
  List<_Coupon> _coupons = [];
  List<_Order> _refunds = [];
  List<_Review> _reviews = [];

  // ---- Auth helpers -------------------------------------------------------
  static String get _authHeader {
    final encoded =
        base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return 'Basic $encoded';
  }

  Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'Content-Type': 'application/json',
      };

  Uri _uri(String endpoint) =>
      Uri.parse('$_baseUrl/wp-json/wc/v3/$endpoint');

  // ---- Fetch helpers ------------------------------------------------------

  Future<dynamic> _getJson(String endpoint) async {
    final response = await http.get(_uri(endpoint), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
    return jsonDecode(response.body);
  }

  Future<_SalesReport> _fetchSalesReport(String period) async {
    final after = _afterDateForPeriod(period == 'all' ? 'all' : period);
    final afterParam = after != null ? '&after=${Uri.encodeComponent(after)}' : '';
    final data = await _getJson(
        'orders?status=completed&per_page=100&orderby=date&order=desc'
        '$afterParam&_fields=id,total,total_refunds');
    if (data is! List) throw Exception('Unexpected format for orders');
    double total = 0;
    double refunds = 0;
    for (final o in data) {
      total += double.tryParse(o['total']?.toString() ?? '0') ?? 0;
      refunds += double.tryParse(o['total_refunds']?.toString() ?? '0') ?? 0;
    }
    return _SalesReport(
      totalSales: total,
      netSales: total + refunds,
      totalOrders: data.length,
      totalRefunds: refunds.abs(),
    );
  }

  // Returns null for 'all' (no date filtering)
  String? _afterDateForPeriod(String period) {
    final now = DateTime.now();
    late DateTime from;
    switch (period) {
      case 'all':
        return null;
      case 'day':
        from = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        from = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(from.year, from.month, from.day);
        break;
      case 'year':
        from = DateTime(now.year, 1, 1);
        break;
      case 'month':
      default:
        from = DateTime(now.year, now.month, 1);
    }
    return from.toIso8601String();
  }

  Future<List<_OrderTotal>> _fetchOrderTotals() async {
    final data = await _getJson('reports/orders/totals');
    if (data is List) {
      return data
          .map((e) => _OrderTotal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for order totals');
  }

  Future<List<_Order>> _fetchRecentOrders([String? period]) async {
    final after = _afterDateForPeriod(period ?? _period);
    final afterParam = after != null ? '&after=${Uri.encodeComponent(after)}' : '';
    final data = await _getJson(
        'orders?per_page=50&orderby=date&order=desc'
        '$afterParam'
        '&_fields=id,number,status,total,billing,date_created');
    if (data is List) {
      return data
          .map((e) => _Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for orders');
  }

  Future<List<_TopSeller>> _fetchTopSellers([String? period]) async {
    final after = _afterDateForPeriod(period ?? _period);
    final afterParam = after != null ? '&after=${Uri.encodeComponent(after)}' : '';
    // Fetch completed orders with line items and aggregate client-side
    final data = await _getJson(
        'orders?status=completed&per_page=100&orderby=date&order=desc'
        '$afterParam'
        '&_fields=id,line_items');
    if (data is! List) throw Exception('Unexpected format for orders');

    final Map<int, _TopSeller> totals = {};
    for (final order in data) {
      final lineItems = order['line_items'] as List? ?? [];
      for (final item in lineItems) {
        final productId = int.tryParse(item['product_id']?.toString() ?? '0') ?? 0;
        final name = item['name']?.toString() ?? '';
        final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
        if (productId == 0) continue;
        if (totals.containsKey(productId)) {
          totals[productId] = _TopSeller(
            name: totals[productId]!.name,
            productId: productId,
            quantity: totals[productId]!.quantity + qty,
          );
        } else {
          totals[productId] = _TopSeller(name: name, productId: productId, quantity: qty);
        }
      }
    }
    final sorted = totals.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    return sorted.take(10).toList();
  }

  Future<List<_StockProduct>> _fetchOutOfStock() async {
    final data = await _getJson(
        'products?stock_status=outofstock&per_page=30'
        '&_fields=id,name,sku,stock_quantity');
    if (data is List) {
      return data
          .map((e) => _StockProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for out-of-stock');
  }

  Future<List<_StockProduct>> _fetchLowStock() async {
    final data = await _getJson(
        'products?low_in_stock=true&per_page=30'
        '&_fields=id,name,sku,stock_quantity');
    if (data is List) {
      return data
          .map((e) => _StockProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for low stock');
  }

  Future<List<_CustomerStat>> _fetchCustomerStats() async {
    final data = await _getJson(
        'orders?status=any&per_page=100&_fields=id,status,billing');
    if (data is! List) throw Exception('Unexpected format for orders');
    final payingEmails = <String>{};
    final allEmails = <String>{};
    for (final o in data) {
      final email = (o['billing']?['email'] ?? '').toString().trim().toLowerCase();
      if (email.isEmpty) continue;
      allEmails.add(email);
      final status = o['status']?.toString() ?? '';
      if (status == 'completed') payingEmails.add(email);
    }
    return [
      _CustomerStat(slug: 'paying_customers', name: 'Paying customers', total: payingEmails.length),
      _CustomerStat(slug: 'customers', name: 'Total customers', total: allEmails.length),
    ];
  }

  Future<List<_Customer>> _fetchTopCustomers() async {
    final data = await _getJson(
        'customers?orderby=total_spent&order=desc&per_page=15'
        '&_fields=id,first_name,last_name,email,total_spent,orders_count');
    if (data is List) {
      return data
          .map((e) => _Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for customers');
  }

  Future<List<_OnSaleProduct>> _fetchOnSale() async {
    final data = await _getJson(
        'products?on_sale=true&per_page=50'
        '&_fields=id,name,sku,regular_price,sale_price');
    if (data is List) {
      return data
          .map((e) => _OnSaleProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for on-sale products');
  }

  Future<List<_Coupon>> _fetchCoupons() async {
    final data = await _getJson(
        'coupons?per_page=50'
        '&_fields=id,code,discount_type,amount,usage_count,date_expires');
    if (data is List) {
      return data
          .map((e) => _Coupon.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for coupons');
  }

  Future<List<_Order>> _fetchRefunds() async {
    // Fetch with status=any and filter client-side — some WooCommerce setups
    // don't return results for status=refunded directly.
    final data = await _getJson(
        'orders?status=any&per_page=100&orderby=date&order=desc'
        '&_fields=id,number,status,total,billing,date_created');
    if (data is List) {
      return data
          .map((e) => _Order.fromJson(e as Map<String, dynamic>))
          .where((o) => o.status == 'refunded')
          .toList();
    }
    throw Exception('Unexpected format for refunded orders');
  }

  Future<List<_Review>> _fetchReviews() async {
    final data = await _getJson(
        'products/reviews?per_page=15&status=approved'
        '&_fields=id,reviewer,rating,review,product_id');
    if (data is List) {
      return data
          .map((e) => _Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Unexpected format for reviews');
  }

  // ---- Load all -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorRevenue = _errorOrderTotals = _errorRecentOrders =
          _errorTopSellers = _errorOutOfStock = _errorLowStock =
              _errorCustomers = _errorOnSale = _errorCoupons =
                  _errorRefunds = _errorReviews = null;
    });

    await Future.wait([
      // Revenue for selected period
      _fetchSalesReport(_period).then((v) {
        if (mounted) setState(() => _salesReport = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorRevenue = e.toString());
      }),
      // Order totals
      _fetchOrderTotals().then((v) {
        if (mounted) setState(() => _orderTotals = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorOrderTotals = e.toString());
      }),
      // Recent orders
      _fetchRecentOrders().then((v) {
        if (mounted) setState(() => _recentOrders = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorRecentOrders = e.toString());
      }),
      // Top sellers
      _fetchTopSellers().then((v) {
        if (mounted) setState(() => _topSellers = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorTopSellers = e.toString());
      }),
      // Out of stock
      _fetchOutOfStock().then((v) {
        if (mounted) setState(() => _outOfStock = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorOutOfStock = e.toString());
      }),
      // Low stock
      _fetchLowStock().then((v) {
        if (mounted) setState(() => _lowStock = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorLowStock = e.toString());
      }),
      // Customers
      _fetchCustomerStats().then((v) {
        if (mounted) setState(() => _customerStats = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorCustomers = e.toString());
      }),
      _fetchTopCustomers().then((v) {
        if (mounted) setState(() => _topCustomers = v);
      }).catchError((e) {
        if (mounted && _errorCustomers == null) {
          setState(() => _errorCustomers = e.toString());
        }
      }),
      // On sale
      _fetchOnSale().then((v) {
        if (mounted) setState(() => _onSale = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorOnSale = e.toString());
      }),
      // Coupons
      _fetchCoupons().then((v) {
        if (mounted) setState(() => _coupons = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorCoupons = e.toString());
      }),
      // Refunds
      _fetchRefunds().then((v) {
        if (mounted) setState(() => _refunds = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorRefunds = e.toString());
      }),
      // Reviews
      _fetchReviews().then((v) {
        if (mounted) setState(() => _reviews = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorReviews = e.toString());
      }),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reloadPeriodData() async {
    if (!mounted) return;
    setState(() {
      _loadingPeriod = true;
      _errorRevenue = null;
      _errorRecentOrders = null;
      _errorTopSellers = null;
    });
    await Future.wait([
      _fetchSalesReport(_period).then((v) {
        if (mounted) setState(() => _salesReport = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorRevenue = e.toString());
      }),
      _fetchRecentOrders().then((v) {
        if (mounted) setState(() => _recentOrders = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorRecentOrders = e.toString());
      }),
      _fetchTopSellers().then((v) {
        if (mounted) setState(() => _topSellers = v);
      }).catchError((e) {
        if (mounted) setState(() => _errorTopSellers = e.toString());
      }),
    ]);
    if (mounted) setState(() => _loadingPeriod = false);
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          'Website Stats',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          if (_loadingPeriod)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: AppConstants.primaryColor, strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppConstants.primaryColor),
            )
          : Column(
              children: [
                // ── Period filter ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildPeriodSelector(),
                ),
                const SizedBox(height: 10),
                // ── Revenue KPI ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _buildRevenueSection(),
                ),
                const SizedBox(height: 14),
                // ── Order status chips ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _buildOrderStatusSection(),
                ),
                const SizedBox(height: 12),
                // ── On Sale compact strip ──
                if (_onSale.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _buildOnSaleStrip(),
                  ),
                if (_onSale.isNotEmpty) const SizedBox(height: 10),
                // ── Coupons compact strip ──
                if (_coupons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _buildCouponsStrip(),
                  ),
                if (_coupons.isNotEmpty) const SizedBox(height: 8),
                // ── Scrollable Tab bar ──
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppConstants.primaryColor,
                  unselectedLabelColor: Colors.white38,
                  indicatorColor: AppConstants.primaryColor,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  tabs: const [
                    Tab(text: 'Recent Orders'),
                    Tab(text: 'Top Sellers'),
                    Tab(text: 'Out of Stock'),
                    Tab(text: 'Low Stock'),
                    Tab(text: 'Customers'),
                    Tab(text: 'Refunds'),
                    Tab(text: 'Reviews'),
                  ],
                ),
                // ── Tab content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentOrdersTab(),
                      _buildTopSellersTab(),
                      _buildOutOfStockTab(),
                      _buildLowStockTab(),
                      _buildCustomersTab(),
                      _buildRefundsTab(),
                      _buildReviewsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // =========================================================================
  // Period selector
  // =========================================================================

  Widget _buildPeriodSelector() {
    return Row(
      children: List.generate(_periods.length, (i) {
        final selected = i == _periodIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (_periodIndex == i) return;
              setState(() => _periodIndex = i);
              _reloadPeriodData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppConstants.primaryColor
                    : const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppConstants.primaryColor
                      : const Color(0xFF2A220A),
                ),
              ),
              child: Text(
                _periodLabels[i],
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white60,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // =========================================================================
  // Section 1 – Revenue KPI card
  // =========================================================================

  Widget _buildRevenueSection() {
    if (_errorRevenue != null && _salesReport == null) {
      return _errorCard('Revenue data unavailable', _errorRevenue!);
    }
    final icons = [Icons.today, Icons.date_range, Icons.calendar_month, Icons.calendar_today, Icons.all_inclusive];
    return _kpiCard(
      label: _periodLabels[_periodIndex],
      value: _salesReport?.netSales,
      sub: '${_salesReport?.totalOrders ?? 0} orders',
      icon: icons[_periodIndex],
    );
  }

  Widget _kpiCard({
    required String label,
    required double? value,
    required String sub,
    required IconData icon,
  }) {
    final formatted =
        value != null ? 'AED ${NumberFormat('#,##0').format(value)}' : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 18),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 11, letterSpacing: 0.7)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatted,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // =========================================================================
  // Section 2 – Order status chips
  // =========================================================================

  static const _statusConfig = {
    'pending': (Icons.hourglass_empty, Color(0xFFFFB300)),
    'processing': (Icons.autorenew, Color(0xFF1E88E5)),
    'completed': (Icons.check_circle_outline, Color(0xFF43A047)),
    'cancelled': (Icons.cancel_outlined, Color(0xFFE53935)),
    'refunded': (Icons.undo, Color(0xFF8E24AA)),
    'on-hold': (Icons.pause_circle_outline, Color(0xFFFF7043)),
  };

  Widget _buildOrderStatusSection() {
    if (_errorOrderTotals != null && _orderTotals.isEmpty) {
      return _errorCard('Order status unavailable', _errorOrderTotals!);
    }
    final Map<String, int> counts = {
      for (final ot in _orderTotals) ot.slug: ot.total
    };
    const slugOrder = [
      'pending',
      'processing',
      'completed',
      'cancelled',
      'on-hold',
      'refunded'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Orders by Status'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: slugOrder.map((slug) {
              final count = counts[slug] ?? 0;
              final cfg = _statusConfig[slug];
              final icon = cfg?.$1 ?? Icons.circle;
              final color = cfg?.$2 ?? Colors.grey;
              final label = slug[0].toUpperCase() +
                  slug.substring(1).replaceAll('-', ' ');
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _statusCard(
                    icon: icon, color: color, count: count, label: label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10, letterSpacing: 0.4),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // =========================================================================
  // Tab 1 – Recent Orders
  // =========================================================================

  Widget _buildRecentOrdersTab() {
    if (_errorRecentOrders != null && _recentOrders.isEmpty) {
      return _centeredError('Could not load recent orders', _errorRecentOrders!);
    }
    if (_recentOrders.isEmpty) return _centeredEmpty('No recent orders found.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _recentOrders.length,
      itemBuilder: (_, i) => _buildOrderRow(_recentOrders[i]),
    );
  }

  Widget _buildOrderRow(_Order order) {
    final cfg = _statusConfig[order.status];
    final statusColor = cfg?.$2 ?? Colors.grey;
    final dateFmt = order.dateCreated != null
        ? DateFormat('dd/MM/yy').format(order.dateCreated!)
        : '—';
    final totalFmt = 'AED ${NumberFormat('#,##0.00').format(order.total)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.number}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(order.customerName,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              order.status[0].toUpperCase() + order.status.substring(1),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalFmt,
                  style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(dateFmt,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Tab 2 – Top Sellers
  // =========================================================================

  Widget _buildTopSellersTab() {
    if (_errorTopSellers != null && _topSellers.isEmpty) {
      return _centeredError('Could not load top sellers', _errorTopSellers!);
    }
    if (_topSellers.isEmpty) {
      return _centeredEmpty('No sales data available for ${_periodLabels[_periodIndex].toLowerCase()}.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _topSellers.length,
      itemBuilder: (_, i) => _buildTopSellerRow(i + 1, _topSellers[i]),
    );
  }

  Widget _buildTopSellerRow(int rank, _TopSeller seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.4)),
            ),
            child: Text('$rank',
                style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(seller.name,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('${seller.quantity} sold',
              style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // =========================================================================
  // Tab 3 – Out of Stock
  // =========================================================================

  Widget _buildOutOfStockTab() {
    if (_errorOutOfStock != null && _outOfStock.isEmpty) {
      return _centeredError('Could not load stock data', _errorOutOfStock!);
    }
    if (_outOfStock.isEmpty) {
      return _allGoodMessage('All products in stock');
    }
    return Column(
      children: [
        _listCountBanner(_outOfStock.length, 'products out of stock',
            const Color(0xFFE53935)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: _outOfStock.length,
            itemBuilder: (_, i) =>
                _buildStockRow(_outOfStock[i], isOut: true),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Tab 4 – Low Stock
  // =========================================================================

  Widget _buildLowStockTab() {
    if (_errorLowStock != null && _lowStock.isEmpty) {
      return _centeredError('Could not load low stock data', _errorLowStock!);
    }
    if (_lowStock.isEmpty) {
      return _allGoodMessage('No low stock products');
    }
    return Column(
      children: [
        _listCountBanner(
            _lowStock.length, 'products running low', const Color(0xFFFF7043)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: _lowStock.length,
            itemBuilder: (_, i) =>
                _buildStockRow(_lowStock[i], isOut: false),
          ),
        ),
      ],
    );
  }

  Widget _buildStockRow(_StockProduct p, {required bool isOut}) {
    final color =
        isOut ? const Color(0xFFE53935) : const Color(0xFFFF7043);
    final qty = p.stockQuantity;
    final qtyText = isOut ? 'Out of stock' : (qty != null ? 'Qty: $qty' : '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                if (p.sku.isNotEmpty)
                  Text('SKU: ${p.sku}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(qtyText,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // =========================================================================
  // Tab 5 – Customers
  // =========================================================================

  Widget _buildCustomersTab() {
    if (_errorCustomers != null &&
        _customerStats.isEmpty &&
        _topCustomers.isEmpty) {
      return _centeredError('Could not load customers', _errorCustomers!);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Stats row
        if (_customerStats.isNotEmpty) ...[
          _sectionTitle('Customer Overview'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _customerStats.map((s) {
                IconData icon;
                Color color;
                switch (s.slug) {
                  case 'paying_customer':
                  case 'paying_customers':
                    icon = Icons.monetization_on_outlined;
                    color = const Color(0xFF43A047);
                    break;
                  case 'customers':
                    icon = Icons.people_outline;
                    color = const Color(0xFF1E88E5);
                    break;
                  default:
                    icon = Icons.person_outline;
                    color = Colors.white60;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _statChip(
                      label: s.name, value: '${s.total}', icon: icon,
                      color: color),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Top spenders list
        if (_topCustomers.isNotEmpty) ...[
          _sectionTitle('Top Spenders'),
          const SizedBox(height: 10),
          ..._topCustomers
              .asMap()
              .entries
              .map((e) => _buildCustomerRow(e.key + 1, e.value)),
        ],
      ],
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(int rank, _Customer c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.35)),
            ),
            child: Text('$rank',
                style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text('${c.ordersCount} orders',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('AED ${NumberFormat('#,##0').format(c.totalSpent)}',
              style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }


  // =========================================================================
  // Tab 6 – Refunds
  // =========================================================================

  Widget _buildRefundsTab() {
    if (_errorRefunds != null && _refunds.isEmpty) {
      return _centeredError('Could not load refunds', _errorRefunds!);
    }
    if (_refunds.isEmpty) {
      return _allGoodMessage('No refunded orders');
    }

    // Total refunded amount
    final totalRefunded = _refunds.fold(0.0, (s, o) => s + o.total);

    return Column(
      children: [
        // Summary banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF5A1A5A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.undo,
                        color: Color(0xFF8E24AA), size: 18),
                    const SizedBox(width: 8),
                    Text('${_refunds.length} refunded orders',
                        style: const TextStyle(
                            color: Color(0xFF8E24AA),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
                Text(
                    'Total: AED ${NumberFormat('#,##0.00').format(totalRefunded)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: _refunds.length,
            itemBuilder: (_, i) => _buildOrderRow(_refunds[i]),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Tab 7 – Reviews
  // =========================================================================

  Widget _buildReviewsTab() {
    if (_errorReviews != null && _reviews.isEmpty) {
      return _centeredError('Could not load reviews', _errorReviews!);
    }
    if (_reviews.isEmpty) return _centeredEmpty('No reviews found.');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _reviews.length,
      itemBuilder: (_, i) => _buildReviewRow(_reviews[i]),
    );
  }

  Widget _buildReviewRow(_Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A220A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 16,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                child: Text(
                  r.reviewer.isNotEmpty ? r.reviewer[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.reviewer,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              // Star rating
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < r.rating ? Icons.star : Icons.star_outline,
                    color: i < r.rating
                        ? const Color(0xFFFFB300)
                        : Colors.white24,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (r.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.review.length > 200
                  ? '${r.review.substring(0, 200)}…'
                  : r.review,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // Compact inline strips (On Sale + Coupons)
  // =========================================================================

  Widget _buildOnSaleStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                color: AppConstants.primaryColor, size: 13),
            const SizedBox(width: 5),
            _sectionTitle('On Sale'),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_onSale.length}',
                style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _onSale.map((p) {
              final pct = p.discountPct;
              final pctLabel =
                  pct > 0 ? '${pct.toStringAsFixed(0)}% off' : 'sale';
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A220A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(pctLabel,
                          style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        p.name,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponsStrip() {
    final active = _coupons.where((c) => !c.isExpired).toList();
    final expired = _coupons.where((c) => c.isExpired).toList();
    final sorted = [...active, ...expired];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.confirmation_num_outlined,
                color: Color(0xFF81C784), size: 13),
            const SizedBox(width: 5),
            _sectionTitle('Coupons'),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${active.length} active',
                style: const TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sorted.map((c) {
              final color =
                  c.isExpired ? Colors.white30 : const Color(0xFF81C784);
              final borderColor = c.isExpired
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF1A3A1A);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.code.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.discountLabel} · ${c.usageCount} uses',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Common helpers
  // =========================================================================

  Widget _listCountBanner(int count, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color, size: 16),
            const SizedBox(width: 8),
            Text('$count $label',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _allGoodMessage(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF43A047), size: 42),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: Color(0xFF43A047),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          color: Colors.white60,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600),
    );
  }

  Widget _errorCard(String title, String detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5A1A1A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredError(String title, String detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _errorCard(title, detail),
        ),
      );

  Widget _centeredEmpty(String message) => Center(
        child: Text(message,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      );
}
