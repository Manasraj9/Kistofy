import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kistofy/widgets/curved_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  String? _sellerName, _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    final data = await Supabase.instance.client
        .from('seller_profiles')
        .select('shop_name, avatar_url')
        .eq('id', _user!.id)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() {
        _sellerName = data['shop_name'];
        _avatarUrl  = data['avatar_url'];
      });
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  /*────────────────── UI ──────────────────*/
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning 👋',
                    style:
                    TextStyle(fontSize: 14, color: Colors.grey[600])),
                if (_sellerName != null && _sellerName!.isNotEmpty)
                  Text(_sellerName!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
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
            /* Balance card */
            _balanceCard(brand),
            const SizedBox(height: 20),
            /* Stats */
            _statsCard(brand),
            const SizedBox(height: 20),
            /* Quick buttons */
            Text('Quick Access',
                style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quick(Icons.inventory_2_outlined, 'Products', '/products'),
                _quick(Icons.receipt_long, 'Invoices', '/create-invoice'),
                _quick(Icons.person_outline, 'Profile', '/seller-profile'),
              ],
            ),
          ],
        ),
      ),

      /* Curved Nav Bar fixed to screen bottom */
      bottomNavigationBar: const AnimatedCurvedNavBar(),
    );
  }

  /*──────── helper widgets ────────*/
  Widget _balanceCard(Color brand) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('₹2,480',
                style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
          child: const Text('Add Funds'),
        ),
      ],
    ),
  );

  Widget _statsCard(Color brand) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        _stat('Inventory Used', '47 / 100 Products', 0.47, brand),
        const SizedBox(height: 12),
        _stat('Invoices Generated', '8 / 20 this month', 0.4, brand),
        const SizedBox(height: 12),
        _stat('Customers', '15 / 100 limit', 0.15, brand),
      ],
    ),
  );

  Widget _stat(String t, String sub, double v, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: v, color: c, backgroundColor: c.withOpacity(.2)),
      const SizedBox(height: 4),
      Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

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

        Text(lbl, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
