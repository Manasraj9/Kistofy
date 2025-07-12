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

  /*──────── text controllers ────────*/
  final nameC      = TextEditingController();
  final descC      = TextEditingController();
  final skuC       = TextEditingController();
  final unitC      = TextEditingController();
  final basePriceC = TextEditingController();
  final costPriceC = TextEditingController();
  final discountC  = TextEditingController();
  final quantityC  = TextEditingController();
  final locationC  = TextEditingController();

  /*──────── dropdown data ───────────*/
  final _categories = ['General', 'Electronics', 'Grocery', 'Clothing'];
  final _gstRates   = [0, 5, 12, 18, 28];

  String?  category;
  int      gstRate = 18;
  bool     gstIncluded = true; // always true in this inclusive model
  DateTime? expiryDate;

  double finalPrice = 0;   // GST‑inclusive rounded price
  double gstAmount  = 0;   // extracted GST component

  /*──────── calculation helpers ────*/
  void _recalcPrice() {
    double base = double.tryParse(basePriceC.text) ?? 0;
    double gst  = gstRate.toDouble();

    double priceWithGst = base + (base * gst / 100);
    double rounded      = (priceWithGst / 10).round() * 10;

    setState(() {
      finalPrice = rounded;
      gstAmount  = rounded - base;
    });
  }

  /*──────── submit to Supabase ─────*/
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final qty = int.tryParse(quantityC.text) ?? 0;
    final reorder = (qty * 0.1).floor();

    final data = {
      'user_id'        : userId,
      'name'           : nameC.text.trim(),
      'description'    : descC.text.trim(),
      'category'       : category ?? 'General',
      'sku'            : skuC.text.trim(),
      'unit'           : unitC.text.trim(),

      // Pricing  ► store GST‑inclusive rounded price in `price`
      'price'          : finalPrice,                  // ✅  matches table
      'cost_price'     : double.tryParse(costPriceC.text) ?? 0,
      'discount_percent': double.tryParse(discountC.text) ?? 0,
      'gst_rate'       : gstRate,
      'gst_included'   : true,                        // column exists

      // Inventory
      'quantity'       : qty,
      'location'       : locationC.text.trim(),

      // Misc
      'expiry_date'    : expiryDate?.toIso8601String(),
      'created_at'     : DateTime.now().toIso8601String(),
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

  /*──────── build UI ───────────────*/
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

            _section('Pricing (GST will be added & rounded to ₹10)'),
            _input(basePriceC, 'Selling Price (before GST)',
                keyboard: TextInputType.number, onChanged: (_) => _recalcPrice()),
            _input(costPriceC, 'Cost Price',
                keyboard: TextInputType.number),
            _input(discountC, 'Discount (%)',
                keyboard: TextInputType.number),

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
                _recalcPrice();
              },
            ),
            const SizedBox(height: 8),
            /* Display calculated, rounded price */
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  'Final Price (incl. GST): ₹${finalPrice.toStringAsFixed(2)}',
                ),
              ),
            ),

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

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Product'),
            )
          ]),
        ),
      ),
    );
  }

  /*──────── helpers ───────────────*/
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
