import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameC = TextEditingController();
  final descC = TextEditingController();
  final skuC = TextEditingController();
  final unitC = TextEditingController();
  final priceC = TextEditingController(); // Input for final price
  final costPriceC = TextEditingController();
  final discountC = TextEditingController();
  final quantityC = TextEditingController();
  final locationC = TextEditingController();

  final _categories = ['General', 'Electronics', 'Grocery', 'Clothing'];
  final _gstRates = [0, 5, 12, 18, 28];

  String? category;
  int gstRate = 18;
  bool gstIncluded = true;
  DateTime? expiryDate;

  double basePrice = 0;
  double gstAmount = 0;
  double discountAmount = 0;
  double finalPrice = 0;
  double profit = 0;
  bool showLossWarning = false;

  void _recalcPrices() {
    double priceInput = double.tryParse(priceC.text) ?? 0;
    double cost = double.tryParse(costPriceC.text) ?? 0;
    double discount = double.tryParse(discountC.text) ?? 0;

    double base, gst;

    if (gstIncluded) {
      base = priceInput / (1 + gstRate / 100);
      gst = priceInput - base;
    } else {
      base = priceInput;
      gst = base * gstRate / 100;
      priceInput += gst;
    }

    double discountValue = base * (discount / 100);
    double profitCalc = (base - discountValue) - cost;

    setState(() {
      finalPrice = priceInput;
      basePrice = base;
      gstAmount = gst;
      discountAmount = discountValue;
      profit = profitCalc;
      showLossWarning = cost + gst > base;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final qty = int.tryParse(quantityC.text) ?? 0;

    final data = {
      'user_id': userId,
      'name': nameC.text.trim(),
      'description': descC.text.trim(),
      'category': category ?? 'General',
      'sku': skuC.text.trim(),
      'unit': unitC.text.trim(),

      'price': finalPrice,
      'cost_price': double.tryParse(costPriceC.text) ?? 0,
      'discount_percent': double.tryParse(discountC.text) ?? 0,
      'gst_rate': gstRate,
      'gst_included': gstIncluded,

      'quantity': qty,
      'location': locationC.text.trim(),

      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'gst_amount': gstAmount,
    };

    try {
      await Supabase.instance.client.from('products').insert(data);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Product added!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _pickExpiry() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => expiryDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _section('Product Info'),
            _input(nameC, 'Product Name', required: true),
            _input(descC, 'Description', lines: 2),
            DropdownButtonFormField<String>(
              value: category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => category = v),
              validator: (v) => v == null ? 'Select category' : null,
            ),
            const SizedBox(height: 14),
            _input(skuC, 'SKU'),
            _input(unitC, 'Unit'),

            _section('Pricing'),
            SwitchListTile(
              title: const Text('Is Final Price GST Inclusive?'),
              value: gstIncluded,
              onChanged: (v) {
                setState(() => gstIncluded = v);
                _recalcPrices();
              },
            ),
            _input(priceC, 'Final Price (₹)', keyboard: TextInputType.number,
                required: true, onChanged: (_) => _recalcPrices()),
            _input(costPriceC, 'Cost Price',
                keyboard: TextInputType.number, onChanged: (_) => _recalcPrices()),
            _input(discountC, 'Discount (%)',
                keyboard: TextInputType.number, onChanged: (_) => _recalcPrices()),
            DropdownButtonFormField<int>(
              value: gstRate,
              items: _gstRates
                  .map((g) => DropdownMenuItem(value: g, child: Text('$g%')))
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'GST Rate',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                gstRate = v ?? 0;
                _recalcPrices();
              },
            ),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base Price: ₹${basePrice.toStringAsFixed(2)}'),
                  Text('GST Amount: ₹${gstAmount.toStringAsFixed(2)}'),
                  Text('Discount: ₹${discountAmount.toStringAsFixed(2)}'),
                  Text('Final Price: ₹${finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Profit: ₹${profit.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: profit >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold)),
                  if (showLossWarning)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠ You may face loss on this product.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _section('Inventory'),
            _input(quantityC, 'Quantity', keyboard: TextInputType.number),
            _input(locationC, 'Location'),

            _section('Misc'),
            ListTile(
              title: const Text('Expiry Date'),
              subtitle: Text(
                expiryDate != null
                    ? DateFormat('yyyy-MM-dd').format(expiryDate!)
                    : 'Optional',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiry,
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Product'),
            )
          ]),
        ),
      ),
    );
  }

  Widget _section(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );

  Widget _input(TextEditingController c, String label,
      {TextInputType keyboard = TextInputType.text,
        bool required = false,
        int lines = 1,
        void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }
}
