import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart' show launchUrlString;

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
        .select('id, created_at, total_amount, customer_name, invoice_number, public_view_id, user_id')
        .eq('user_id', _user!.id)
        .order('created_at', ascending: false);


    setState(() {
      _bills = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }


  Future<void> _launchInvoiceViewer(String publicId) async {
    final url = 'https://heartfelt-treacle-9c2feb.netlify.app/?id=$publicId';

    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Launch failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open invoice')),
      );
    }
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
          final publicViewId = (bill['public_view_id'] ?? '').toString().trim();
          final utcDateTime = DateTime.parse(bill['created_at']);
          final localDateTime = utcDateTime.toLocal();
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(localDateTime);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('#${bill['invoice_number'] ?? bill['id']}'),
              subtitle: Text(
                  '${bill['customer_name'] ?? 'No customer'}\n$formattedDate'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${bill['total_amount']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    onPressed: () {
                      final publicId = bill['public_view_id']?.toString() ?? '';

                      if (publicId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Public view link not available for this bill')),
                        );
                        return;
                      }

                      _launchInvoiceViewer(publicId);
                    },

                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
