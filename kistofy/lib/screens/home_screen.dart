import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kistofy/widgets/curved_navbar.dart';

enum SalesViewMode { daily, monthly, yearly }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  String? _sellerName, _avatarUrl;
  bool hasUnread = false;

  int totalProducts = 0;
  int totalInvoices = 0;
  int totalCustomers = 0;

  List<FlSpot> dailySales = [];
  List<FlSpot> monthlySales = [];
  List<FlSpot> yearlySales = [];

  SalesViewMode _salesViewMode = SalesViewMode.daily;

  @override
  void initState() {
    super.initState();
    _loadSeller();
    _checkUnreadNotifications();
    _sendLowStockNotifications();
    _loadDashboardData();
  }

  Future<void> _loadSeller() async {
    final data = await Supabase.instance.client
        .from('seller_profiles')
        .select('shop_name, avatar_url')
        .eq('id', _user!.id)
        .maybeSingle();

    if (mounted) {
      if (data == null || data['shop_name'] == null || data['shop_name'].toString().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/seller-profile');
        });
      } else {
        setState(() {
          _sellerName = data['shop_name'];
          _avatarUrl = data['avatar_url'];
        });
      }
    }
  }

  Future<void> _checkUnreadNotifications() async {
    final data = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('seller_id', _user!.id)
        .eq('is_read', false);

    setState(() {
      hasUnread = data.isNotEmpty;
    });
  }

  Future<void> _sendLowStockNotifications() async {
    final products = await Supabase.instance.client
        .from('products')
        .select('id, name, quantity')
        .eq('user_id', _user!.id);

    for (var product in products) {
      final quantity = product['quantity'];
      final productId = product['id'];

      final existing = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('seller_id', _user!.id)
          .eq('product_id', productId)
          .eq('type', 'low_stock')
          .maybeSingle();

      if (quantity != null && quantity < 10) {
        if (existing == null) {
          await Supabase.instance.client.from('notifications').insert({
            'seller_id': _user!.id,
            'title': 'Low Stock Alert',
            'message': 'Product "${product['name']}" is low in stock (${quantity} left).',
            'is_read': false,
            'type': 'low_stock',
            'product_id': productId,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } else {
        if (existing != null) {
          await Supabase.instance.client
              .from('notifications')
              .delete()
              .eq('id', existing['id']);
        }
      }
    }

    _checkUnreadNotifications();
  }

  Future<void> _loadDashboardData() async {
    final userId = _user!.id;

    final products = await Supabase.instance.client
        .from('products')
        .select('id')
        .eq('user_id', userId);

    final invoices = await Supabase.instance.client
        .from('invoices')
        .select('id')
        .eq('user_id', userId);

    final customers = await Supabase.instance.client
        .from('customers')
        .select('id')
        .eq('seller_id', userId);

    final salesData = await Supabase.instance.client
        .rpc('get_sales_summary', params: {'seller_id': userId});

    setState(() {
      totalProducts = products.length;
      totalInvoices = invoices.length;
      totalCustomers = customers.length;

      double todayTotal = (salesData['daily']?[0]?['total'] ?? 0).toDouble();
      dailySales = [FlSpot(0, todayTotal)];

      monthlySales = List<FlSpot>.from((salesData['monthly'] ?? []).map((item) =>
          FlSpot(item['month'].toDouble(), (item['total'] ?? 0).toDouble())));

      yearlySales = List<FlSpot>.from(
          (salesData['yearly'] ?? []).map((item) {
            final yearValue = item['year'];
            if (yearValue == null) {
              return const FlSpot(0, 0);
            }

            return FlSpot(
              yearValue.toDouble(),
              (item['total'] ?? 0).toDouble(),
            );
          })
      );

    });
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF5170FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : const AssetImage('assets/images/user.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning 👋', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  if (_sellerName != null && _sellerName!.isNotEmpty)
                    Text(_sellerName!, style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  _checkUnreadNotifications();
                },
              ),
              if (hasUnread)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black54),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashboardStats(brand),
            const SizedBox(height: 20),
            Text('Sales Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _salesBarChart(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Your Bills'),
              onPressed: () {
                Navigator.pushNamed(context, '/bills');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AnimatedCurvedNavBar(),
    );
  }

  Widget _dashboardStats(Color brand) => Row(
    children: [
      Expanded(child: _dashboardCard('Products', totalProducts, brand, Icons.inventory_2_outlined)),
      Expanded(child: _dashboardCard('Invoices', totalInvoices, Colors.orange, Icons.receipt_long)),
      Expanded(child: _dashboardCard('Customers', totalCustomers, Colors.green, Icons.people_alt)),
    ],
  );

  Widget _dashboardCard(String title, int value, Color color, IconData icon) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    ),


  );

  Widget _salesBarChart() {
    List<FlSpot> spots = [];
    double total = 0;

    switch (_salesViewMode) {
      case SalesViewMode.daily:
        spots = dailySales;
        break;
      case SalesViewMode.monthly:
        spots = monthlySales;
        break;
      case SalesViewMode.yearly:
        spots = yearlySales;
        break;
    }

    if (spots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No sales data available', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ),
      );
    }

    total = spots.fold(0, (sum, item) => sum + item.y);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _salesTab('Daily', SalesViewMode.daily),
            _salesTab('Monthly', SalesViewMode.monthly),
            _salesTab('Yearly', SalesViewMode.yearly),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: spots.map((e) => BarChartGroupData(
                x: e.x.toInt(),
                barRods: [
                  BarChartRodData(
                    toY: e.y,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              )).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      switch (_salesViewMode) {
                        case SalesViewMode.daily:
                          return Text((value.toInt() + 1).toString(), style: const TextStyle(fontSize: 10));
                        case SalesViewMode.monthly:
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          int idx = value.toInt() - 1; // Convert 1-based month to 0-based index
                          return idx >= 0 && idx < months.length
                              ? Text(months[idx], style: const TextStyle(fontSize: 10))
                              : const Text('');

                        case SalesViewMode.yearly:
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));

                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) =>
                        Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Total Sales: ₹${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }




  Widget _salesTab(String label, SalesViewMode mode) {
    final isSelected = _salesViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _salesViewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _quick(IconData i, String lbl, String route) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E8F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(i, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(lbl, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
