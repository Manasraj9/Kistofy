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
    _checkSellerProfile();
  }

  Future<void> _checkSellerProfile() async {
    final userId = user?.id;
    if (userId == null) return;

    final profile = await Supabase.instance.client
        .from('seller_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      // Redirect to profile setup if not found
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/seller-profile');
      });
    }
  }

  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kistofy Dashboard'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, ${user?.email ?? "User"}!',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // You can navigate to product dashboard next
                },
                child: const Text('Go to Product Dashboard'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/seller-profile');
                },
                child: const Text('Update Seller Profile'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/products');
                },
                child: const Text('Go to Product Dashboard'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-invoice');
                },
                child: const Text('Go to create Invoice form'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
