import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    final response = await Supabase.instance.client
        .from('invoices')
        .select('id, created_at, total_amount, customer_name, invoice_number')
        .eq('user_id', _user!.id)
        .order('created_at', ascending: false);

    setState(() {
      _bills = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bills'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
          ? const Center(child: Text('No bills found.'))
          : ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('Invoice #${bill['invoice_number'] ?? bill['id']}'),
              subtitle: Text(
                  '${bill['customer_name'] ?? 'No customer'}\n${bill['created_at']}'),
              trailing: Text('₹${bill['total_amount']}'),
              onTap: () {
                // You can navigate to a detailed bill view here if needed
              },
            ),
          );
        },
      ),
    );
  }
}
