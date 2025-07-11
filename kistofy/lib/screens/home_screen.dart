import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  String? _sellerName;
  String? _avatarUrl;

  Future<void> _loadSellerInfo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('seller_profiles')
        .select('shop_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (data != null) {
      setState(() {
        _sellerName = data['shop_name'];
        _avatarUrl = data['avatar_url'];
      });
    }
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF5170FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : const AssetImage('assets/images/user.png') as ImageProvider,
              radius: 20,
            ),

            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Good Morning 👋", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(
                  _sellerName ?? '', // blank if null
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
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

            // 💰 Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Balance", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text("₹2,480", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Add Funds"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 Usage Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _usageItem("Inventory Used", "47 / 100 Products", 0.47, brandColor),
                  const SizedBox(height: 12),
                  _usageItem("Invoices Generated", "8 / 20 this month", 0.4, brandColor),
                  const SizedBox(height: 12),
                  _usageItem("Customers", "15 / 100 limit", 0.15, brandColor),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🎯 Quick Actions
            Text("Quick Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickButton(Icons.inventory_2_outlined, "Products", '/products'),
                _quickButton(Icons.receipt_long, "Invoices", '/create-invoice'),
                _quickButton(Icons.person_outline, "Profile", '/seller-profile'),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: brandColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _usageItem(String label, String usage, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: percent, color: color, backgroundColor: color.withOpacity(0.2)),
        const SizedBox(height: 4),
        Text(usage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _quickButton(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E8F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
