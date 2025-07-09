import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '10');
  final TextEditingController _gstController = TextEditingController(text: '18');

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final userId = supabase.auth.currentUser?.id;
    final res = await supabase
        .from('products')
        .select()
        .eq('user_id', userId as Object);
    setState(() {
      _products = List<Map<String, dynamic>>.from(res);
    });
  }

  void _addProduct(Map<String, dynamic> product) {
    final existing = _selectedItems.indexWhere((item) => item['id'] == product['id']);
    if (existing >= 0) {
      _selectedItems[existing]['quantity']++;
    } else {
      _selectedItems.add({...product, 'quantity': 1});
    }
    setState(() {});
  }

  double get subtotal => _selectedItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

  Future<void> _generateInvoice() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final gstPercent = double.tryParse(_gstController.text) ?? 0;
    final discountAmount = subtotal * (discountPercent / 100);
    final afterDiscount = subtotal - discountAmount;
    final gstAmount = afterDiscount * (gstPercent / 100);
    final finalAmount = afterDiscount + gstAmount;

    final customerRes = await supabase.from('customers').insert({
      'user_id': user.id,
      'name': _customerNameController.text,
      'mobile': _customerMobileController.text,
    }).select().single();

    final invoice = await supabase.from('invoices').insert({
      'user_id': user.id,
      'customer_id': customerRes['id'],
      'customer_name': _customerNameController.text,
      'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch}',
      'total_amount': subtotal,
      'discount': discountPercent,
      'gst_percent': gstPercent,
      'gst_amount': gstAmount,
      'final_amount': finalAmount,
      'public_view_id': const Uuid().v4(),
    }).select().single();

    for (var item in _selectedItems) {
      await supabase.from('invoice_items').insert({
        'invoice_id': invoice['id'],
        'product_id': item['id'],
        'product_name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'subtotal': item['price'] * item['quantity'],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Info', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _customerNameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _customerMobileController, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 20),
            const Text('Products', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _products.map((p) => ActionChip(
                label: Text(p['name']),
                onPressed: () => _addProduct(p),
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Selected Items:'),
            ..._selectedItems.map((item) => ListTile(
              title: Text('${item['name']} × ${item['quantity']}'),
              trailing: Text('₹${item['price'] * item['quantity']}'),
            )),
            const SizedBox(height: 20),
            TextField(controller: _discountController, decoration: const InputDecoration(labelText: 'Discount %')),
            TextField(controller: _gstController, decoration: const InputDecoration(labelText: 'GST %')),
            const Divider(),
            Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
            Text('Discount: ₹${(subtotal * (double.tryParse(_discountController.text) ?? 0) / 100).toStringAsFixed(2)}'),
            Text('GST: ₹${(((subtotal - subtotal * (double.tryParse(_discountController.text) ?? 0) / 100)) * (double.tryParse(_gstController.text) ?? 0) / 100).toStringAsFixed(2)}'),
            Text('Total: ₹${((subtotal - subtotal * (double.tryParse(_discountController.text) ?? 0) / 100) * (1 + (double.tryParse(_gstController.text) ?? 0) / 100)).toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateInvoice,
              child: const Text('Generate Invoice'),
            )
          ],
        ),
      ),
    );
  }
}
