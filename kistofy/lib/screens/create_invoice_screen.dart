import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kistofy/widgets/curved_navbar.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final supabase = Supabase.instance.client;

  final _newCustNameC = TextEditingController();
  final _newCustMobileC = TextEditingController();

  List<Map<String, dynamic>> _selected = [];
  Map<String, dynamic>? selectedCustomer;

  bool _custLoading = false, _prodLoading = false, _saving = false;
  List<Map<String, dynamic>> _custResults = [], _prodResults = [];
  String custSearch = '', prodSearch = '';

  @override
  void dispose() {
    _newCustNameC.dispose();
    _newCustMobileC.dispose();
    super.dispose();
  }

  String selectedPaymentMethod = 'Cash';

  final List<String> paymentMethods = [
    'Cash',
    'Card',
    'UPI',
    'Bank Transfer',
    'Pending'
  ];


  Future<void> _searchCustomers(String term) async {
    setState(() {
      custSearch = term;
      _custLoading = true;
    });
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('customers')
        .select()
        .eq('seller_id', uid)
        .or('name.ilike.%$term%,mobile.ilike.%$term%')
        .limit(10);
    setState(() {
      _custResults = List<Map<String, dynamic>>.from(data);
      _custLoading = false;
    });
  }

  Future<void> _searchProducts(String term) async {
    setState(() {
      prodSearch = term;
      _prodLoading = true;
    });
    final uid = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('products')
        .select()
        .eq('user_id', uid)
        .ilike('name', '%$term%')
        .limit(10);
    setState(() {
      _prodResults = List<Map<String, dynamic>>.from(data);
      _prodLoading = false;
    });
  }

  void _addProduct(Map<String, dynamic> p) {
    final idx = _selected.indexWhere((i) => i['id'] == p['id']);
    if (idx >= 0) {
      if (_selected[idx]['qty'] < _selected[idx]['stock']) {
        _selected[idx]['qty']++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot exceed stock (${p['quantity']})')));
      }
    } else {
      _selected.add({
        'id': p['id'],
        'name': p['name'],
        'price': p['price'],
        'gst_rate': p['gst_rate'],
        'qty': 1,
        'discount': 0.0,
        'stock': p['quantity'],
      });
    }
    setState(() {});
  }

  double get subtotal => _selected.fold(0.0, (s, i) {
    final base = i['price'] * i['qty'];
    return s + (base - base * (i['discount'] / 100));
  });

  Future<void> _addCustomer() async {
    final name = _newCustNameC.text.trim();
    final mobile = _newCustMobileC.text.trim();
    if (name.isEmpty || mobile.isEmpty) return;
    final newCust = await supabase.from('customers').insert({
      'seller_id': supabase.auth.currentUser!.id,
      'name': name,
      'mobile': mobile
    }).select().single();
    setState(() => selectedCustomer = newCust as Map<String, dynamic>);
    _newCustNameC.clear();
    _newCustMobileC.clear();
    Navigator.pop(context);
  }

  void _previewInvoice() {
    if (selectedCustomer == null || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select customer and add products')));
      return;
    }
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Invoice Preview'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${selectedCustomer!['name']}'),
                  Divider(),
                  ..._selected.map((i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${i['name']} × ${i['qty']}'),
                    subtitle: Text(
                        '₹${(i['price'] * i['qty']).toStringAsFixed(2)} (incl. GST)'),
                    trailing: Text('Disc ${i['discount']}%'),
                  )),
                  Divider(),
                  Text('Total: ₹${subtotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
              ElevatedButton(
                  onPressed: _saving ? null : () {
                    Navigator.pop(context);
                    _generateInvoice();
                  },
                  child: _saving
                      ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text('Confirm & Save')),
            ],
          );
        });
  }

  Future<void> _generateInvoice() async {
    setState(() => _saving = true);
    try {
      final uid = supabase.auth.currentUser!.id;

      final invoice = await supabase.from('invoices').insert({
        'user_id': uid,
        'customer_id': selectedCustomer!['id'],
        'customer_name': selectedCustomer!['name'],
        'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch}',
        'total_amount': subtotal,
        'payment_method': selectedPaymentMethod,
        'public_view_id': Uuid().v4(),
      }).select().single();

      for (final i in _selected) {
        final base = i['price'] * i['qty'];
        final discAmount = base * (i['discount'] / 100);
        final afterDiscount = base - discAmount;

        await supabase.from('invoice_items').insert({
          'invoice_id': invoice['id'],
          'product_id': i['id'],
          'product_name': i['name'],
          'price': i['price'],
          'quantity': i['qty'],
          'subtotal': afterDiscount,
        });

        final newStock = (i['stock'] as int) - i['qty'];
        await supabase.from('products').update({'quantity': newStock}).eq('id', i['id']);
      }

      if (!mounted) return;

      final publicId = invoice['public_view_id'];
      final link = 'https://heartfelt-treacle-9c2feb.netlify.app/?id=$publicId';

      // Show QR code dialog
      _showQrDialog(link);

      setState(() {
        _selected.clear();
        selectedCustomer = null;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }
  void _showQrDialog(String link) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invoice QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 10),
            Text(
              'Show this QR to the customer to view the invoice.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            SelectableText(
              link,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Invoice')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search customers…'),
            onChanged: _searchCustomers,
          ),
          if (_custLoading)
            Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Searching...')),
          if (!_custLoading && _custResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _custResults.length,
                itemBuilder: (_, i) {
                  final c = _custResults[i];
                  return ListTile(
                    title: Text('${c['name']} - ${c['mobile']}'),
                    onTap: () {
                      setState(() {
                        selectedCustomer = c;
                        _custResults.clear();
                        custSearch = c['name'];
                      });
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          if (selectedCustomer != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'Selected: ${selectedCustomer!['name']} (${selectedCustomer!['mobile']})',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          TextButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Add New Customer'),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                              controller: _newCustNameC,
                              decoration: InputDecoration(labelText: 'Name')),
                          TextField(
                              controller: _newCustMobileC,
                              decoration:
                              InputDecoration(labelText: 'Mobile')),
                        ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel')),
                      ElevatedButton(
                          onPressed: _addCustomer, child: Text('Add')),
                    ],
                  )),
              icon: Icon(Icons.person_add),
              label: Text('Add New Customer')),

          SizedBox(height: 20),
          Text('Select Products',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Search products…'),
            onChanged: _searchProducts,
          ),
          if (_prodLoading)
            Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Searching...')),
          if (!_prodLoading && _prodResults.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _prodResults.length,
                itemBuilder: (_, i) {
                  final p = _prodResults[i];
                  return ListTile(
                    title: Text(p['name']),
                    trailing: Icon(Icons.add),
                    onTap: () {
                      _addProduct(p);
                      setState(() {
                        _prodResults.clear();
                        prodSearch = p['name'];
                      });
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),

          SizedBox(height: 20),
          Text('Selected Items:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ..._selected.map((i) {
            return ListTile(
              title: Text(i['name']),
              subtitle:
              Row(
                children: [
                  Text('Qty: '),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (i['qty'] > 1) {
                        setState(() => i['qty']--);
                      }
                    },
                  ),
                  Text('${i['qty']}'),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () => _addProduct(i),
                  ),
                ],
              ),

            );
          }).toList(),

          Divider(),
          Text('Total: ₹${subtotal.toStringAsFixed(2)}'),

          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(),
            ),
            items: paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value!;
              });
            },
          ),


          SizedBox(height: 20),
          ElevatedButton(
              onPressed: _saving ? null :  _generateInvoice, child: Text('Generate Invoice')),
        ]),
      ),
      bottomNavigationBar: AnimatedCurvedNavBar(selectedIndex: 2),
    );
  }
}

