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
  final _newCustomerNameController = TextEditingController();
  final _newCustomerMobileController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _selectedItems = [];
  List<Map<String, dynamic>> _customers = [];

  Map<String, dynamic>? selectedCustomer;

  String customerSearch = '';
  String productSearch = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = supabase.auth.currentUser?.id;
    final productsRes = await supabase
        .from('products')
        .select()
        .eq('user_id', userId as Object);

    final customersRes = await supabase
        .from('customers')
        .select()
        .eq('user_id', userId as Object);

    setState(() {
      _products = List<Map<String, dynamic>>.from(productsRes);
      _customers = List<Map<String, dynamic>>.from(customersRes);
    });
  }

  void _addProduct(Map<String, dynamic> product) {
    final existing = _selectedItems.indexWhere((item) => item['id'] == product['id']);
    if (existing >= 0) {
      _selectedItems[existing]['quantity']++;
    } else {
      _selectedItems.add({
        ...product,
        'quantity': 1,
        'discount': 0.0,
        'gst': 0.0,
      });
    }
    setState(() {});
  }

  double get subtotal => _selectedItems.fold(0.0, (sum, item) {
    final price = item['price'] * item['quantity'];
    final discount = price * (item['discount'] / 100);
    return sum + (price - discount);
  });

  double get gstTotal => _selectedItems.fold(0.0, (sum, item) {
    final price = item['price'] * item['quantity'];
    final discount = price * (item['discount'] / 100);
    final afterDiscount = price - discount;
    return sum + (afterDiscount * (item['gst'] / 100));
  });

  Future<void> _addNewCustomer() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final name = _newCustomerNameController.text.trim();
    final mobile = _newCustomerMobileController.text.trim();

    if (name.isEmpty || mobile.isEmpty) return;

    final newCustomer = await supabase.from('customers').insert({
      'user_id': user.id,
      'name': name,
      'mobile': mobile,
    }).select().single();

    setState(() {
      _customers.add(newCustomer);
      selectedCustomer = newCustomer;
      _newCustomerNameController.clear();
      _newCustomerMobileController.clear();
    });

    Navigator.pop(context);
  }

  Future<void> _generateInvoice() async {
    final user = supabase.auth.currentUser;
    if (user == null || selectedCustomer == null) return;

    final finalAmount = subtotal + gstTotal;

    final invoice = await supabase.from('invoices').insert({
      'user_id': user.id,
      'customer_id': selectedCustomer!['id'],
      'customer_name': selectedCustomer!['name'],
      'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch}',
      'total_amount': subtotal,
      'discount': 0,
      'gst_percent': 0,
      'gst_amount': gstTotal,
      'final_amount': finalAmount,
      'public_view_id': const Uuid().v4(),
    }).select().single();

    for (var item in _selectedItems) {
      final price = item['price'] * item['quantity'];
      final discount = price * (item['discount'] / 100);
      final afterDiscount = price - discount;
      final gst = afterDiscount * (item['gst'] / 100);

      await supabase.from('invoice_items').insert({
        'invoice_id': invoice['id'],
        'product_id': item['id'],
        'product_name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'subtotal': afterDiscount + gst,
        'discount': item['discount'],
        'gst_percent': item['gst'],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created!')));
    Navigator.pop(context);
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _newCustomerNameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _newCustomerMobileController, decoration: const InputDecoration(labelText: 'Mobile')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addNewCustomer, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((c) {
      final name = c['name'].toLowerCase();
      return name.contains(customerSearch.toLowerCase());
    }).toList();

    final filteredProducts = _products.where((p) {
      final name = p['name'].toLowerCase();
      return name.contains(productSearch.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers...'),
            onChanged: (val) => setState(() => customerSearch = val),
          ),
          DropdownButtonFormField<String>(
            items: filteredCustomers.map((customer) {
              return DropdownMenuItem<String>(
                value: customer['id'],
                child: Text('${customer['name']} - ${customer['mobile']}'),
              );
            }).toList(),
            onChanged: (value) {
              final customer = _customers.firstWhere((c) => c['id'] == value);
              setState(() => selectedCustomer = customer);
            },
            value: selectedCustomer?['id'],
            hint: const Text('Choose customer'),
          ),

          TextButton.icon(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add New Customer'),
          ),
          const SizedBox(height: 20),
          const Text('Select Products', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products...'),
            onChanged: (val) => setState(() => productSearch = val),
          ),
          Wrap(
            spacing: 8,
            children: filteredProducts.map((p) => ActionChip(
              label: Text(p['name']),
              onPressed: () => _addProduct(p),
            )).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Selected Items:'),
          ..._selectedItems.map((item) => ListTile(
            title: Text('${item['name']} × ${item['quantity']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Discount %'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => item['discount'] = double.tryParse(val) ?? 0),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'GST %'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => item['gst'] = double.tryParse(val) ?? 0),
                ),
              ],
            ),
            trailing: Text('₹${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
          )),
          const Divider(),
          Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
          Text('GST Total: ₹${gstTotal.toStringAsFixed(2)}'),
          Text('Total Amount: ₹${(subtotal + gstTotal).toStringAsFixed(2)}'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _generateInvoice, child: const Text('Generate Invoice')),
        ]),
      ),
    );
  }
}
