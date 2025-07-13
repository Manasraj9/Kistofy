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

  final _categories = ['General', 'Electronics', 'Grocery', 'Clothing', 'Stationery'];
  final _gstRates = [0, 5, 12, 18, 28];

  String? category;
  int gstRate = 18;
  bool gstIncluded = true;
  DateTime? expiryDate;

  double finalPrice = 0;
  double gstAmount = 0;
  double profit = 0;
  bool showLossWarning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

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
    /*──────── parse inputs ───────*/
    final double priceInput = double.tryParse(basePriceC.text) ?? 0;
    final double cost       = double.tryParse(costPriceC.text)  ?? 0;
    final double discPct    = double.tryParse(discountC.text)   ?? 0;
    final double rate       = gstRate.toDouble();

    /*──────── GST & base price ───*/
    double base, gst;
    if (gstIncluded) {
      base = priceInput / (1 + rate / 100);   // reverse GST
      gst  = priceInput - base;
    } else {
      base = priceInput;                      // price excludes GST
      gst  = base * rate / 100;               // exact GST – NO rounding
    }

    /*──────── discount & profit ──*/
    final double discountAmt = base * discPct / 100;
    final double netSell     = base - discountAmt;      // price investor keeps
    final double profitCalc  = netSell - cost;          // true profit

    /*──────── update state ───────*/
    setState(() {
      gstAmount       = gst;                        // exact GST value
      finalPrice      = gstIncluded ? priceInput    // inclusive mode
          : base + gst;   // exclusive mode (exact sum)
      profit          = profitCalc;
      showLossWarning = (cost + gst) > (base);      // warn if loss risk
    });
  }


  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = {
      'user_id': userId,
      'name': nameC.text.trim(),
      'description': descC.text.trim(),
      'price': finalPrice,
      'cost_price': double.tryParse(costPriceC.text),
      'discount_percent': double.tryParse(discountC.text),
      'gst_rate': gstRate,
      'gst_included': gstIncluded,
      'quantity': int.tryParse(quantityC.text),
      'sku': skuC.text.trim(),
      'unit': unitC.text.trim(),
      'category': category,
      'location': locationC.text.trim(),
      'expiry_date': expiryDate?.toIso8601String(),
    };

    await Supabase.instance.client.from('products').update(data).eq('id', product['id']);
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
            _input(nameC, 'Product Name', required: true),
            _input(descC, 'Description'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: category,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => category = val),
            ),
            _input(skuC, 'SKU'),
            _input(unitC, 'Unit'),

            Row(
              children: [
                Expanded(
                  child: _input(basePriceC, gstIncluded
                      ? 'Final Price (inclusive GST)' : 'Selling Price (excl. GST)',
                      keyboard: TextInputType.number,
                      onChanged: (_) => _recalcPrice(),
                      required: true),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: gstIncluded,
                  onChanged: (val) {
                    setState(() => gstIncluded = val);
                    _recalcPrice();
                  },
                ),
                const Text('GST Included'),
              ],
            ),

            _input(costPriceC, 'Cost Price (₹)', keyboard: TextInputType.number, onChanged: (_) => _recalcPrice()),
            _input(discountC, 'Discount (%)', keyboard: TextInputType.number, onChanged: (_) => _recalcPrice()),

            DropdownButtonFormField<int>(
              value: gstRate,
              items: _gstRates.map((rate) => DropdownMenuItem(value: rate, child: Text("$rate%"))).toList(),
              onChanged: (val) {
                gstRate = val!;
                _recalcPrice();
              },
              decoration: const InputDecoration(labelText: 'GST Rate'),
            ),

            const SizedBox(height: 10),
            if (showLossWarning)
              const Text(
                '⚠️ Warning: You may face loss (Cost + GST > Price)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),

            const SizedBox(height: 10),
            Text('GST Amount: ₹${gstAmount.toStringAsFixed(2)}'),
            Text('Final Price (incl. GST): ₹${finalPrice.toStringAsFixed(2)}'),
            Text(
              'Estimated Profit: ₹${profit.toStringAsFixed(2)}',
              style: TextStyle(
                color: profit < 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            _input(quantityC, 'Quantity', keyboard: TextInputType.number),
            _input(locationC, 'Location'),

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
                if (picked != null) setState(() => expiryDate = picked);
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProduct,
              child: const Text('Update Product'),
            )
          ]),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {TextInputType keyboard = TextInputType.text,
        bool required = false,
        void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }
}
