import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late Map<String, dynamic> product;

  final _formKey = GlobalKey<FormState>();

  final nameC = TextEditingController();
  final descC = TextEditingController();
  final skuC = TextEditingController();
  final unitC = TextEditingController();
  final basePriceC = TextEditingController();
  final costPriceC = TextEditingController();
  final discountC = TextEditingController();
  final quantityC = TextEditingController();
  final locationC = TextEditingController();

  final _categories = ['General', 'Electronics', 'Grocery', 'Clothing','Stationery'];
  final _gstRates = [0, 5, 12, 18, 28];

  String? category;
  int gstRate = 18;
  bool gstIncluded = true;
  DateTime? expiryDate;

  double finalPrice = 0;
  double gstAmount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    // Populate fields
    nameC.text = product['name'] ?? '';
    descC.text = product['description'] ?? '';
    skuC.text = product['sku'] ?? '';
    unitC.text = product['unit'] ?? '';
    basePriceC.text = product['price'].toString();
    costPriceC.text = product['cost_price']?.toString() ?? '';
    discountC.text = product['discount_percent']?.toString() ?? '';
    quantityC.text = product['quantity'].toString();
    locationC.text = product['location'] ?? '';
    category = product['category'];
    gstRate = (product['gst_rate'] as num?)?.toInt() ?? 18;
    expiryDate = product['expiry_date'] != null
        ? DateTime.tryParse(product['expiry_date'])
        : null;

    _recalcPrice();
  }

  void _recalcPrice() {
    double base = double.tryParse(basePriceC.text) ?? 0;
    double gst = gstRate.toDouble();
    double priceWithGst = base + (base * gst / 100);
    double rounded = (priceWithGst / 10).round() * 10;

    setState(() {
      finalPrice = rounded;
      gstAmount = rounded - base;
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final name = nameC.text.trim();
    final desc = descC.text.trim();
    final price = finalPrice;
    final cost = double.tryParse(costPriceC.text) ?? 0;
    final disc = double.tryParse(discountC.text) ?? 0;
    final qty = int.tryParse(quantityC.text) ?? 0;
    final sku = skuC.text.trim();
    final unit = unitC.text.trim();
    final loc = locationC.text.trim();

    await Supabase.instance.client.from('products').update({
      'user_id': userId,
      'name': name,
      'description': desc,
      'price': price,
      'cost_price': cost,
      'discount_percent': disc,
      'gst_rate': gstRate,
      'gst_included': true,
      'quantity': qty,
      'sku': sku,
      'unit': unit,
      'category': category,
      'location': loc,
      'expiry_date': expiryDate?.toIso8601String(),
    }).eq('id', product['id']);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameC.dispose();
    descC.dispose();
    skuC.dispose();
    unitC.dispose();
    basePriceC.dispose();
    costPriceC.dispose();
    discountC.dispose();
    quantityC.dispose();
    locationC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: nameC, decoration: const InputDecoration(labelText: 'Product Name')),
            TextFormField(controller: descC, decoration: const InputDecoration(labelText: 'Description')),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Category'),
              value: category,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => category = val),
            ),
            TextFormField(controller: skuC, decoration: const InputDecoration(labelText: 'SKU')),
            TextFormField(controller: unitC, decoration: const InputDecoration(labelText: 'Unit')),
            TextFormField(
              controller: basePriceC,
              decoration: const InputDecoration(labelText: 'Selling Price (before GST)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalcPrice(),
            ),
            TextFormField(
              controller: costPriceC,
              decoration: const InputDecoration(labelText: 'Cost Price'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: discountC,
              decoration: const InputDecoration(labelText: 'Discount %'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'GST Rate'),
              value: gstRate,
              items: _gstRates.map((rate) => DropdownMenuItem(value: rate, child: Text("$rate%"))).toList(),
              onChanged: (val) {
                gstRate = val!;
                _recalcPrice();
              },
            ),
            TextFormField(
              controller: quantityC,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalcPrice(),
            ),
            TextFormField(controller: locationC, decoration: const InputDecoration(labelText: 'Location')),
            ListTile(
              title: Text(expiryDate == null
                  ? 'Select Expiry Date'
                  : DateFormat.yMMMd().format(expiryDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expiryDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => expiryDate = picked);
                }
              },
            ),
            const SizedBox(height: 20),
            Text("Final Price (incl. GST): ₹${finalPrice.toStringAsFixed(2)}"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _updateProduct,
              child: const Text('Update Product'),
            )
          ]),
        ),
      ),
    );
  }
}
