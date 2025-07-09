import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();

  bool _loading = false;

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = int.tryParse(_qtyController.text) ?? 0;
    final category = _categoryController.text.trim();
    final sku = _skuController.text.trim();
    final unit = _unitController.text.trim();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (name.isEmpty || price <= 0 || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill valid product details')),
      );
      return;
    }

    setState(() => _loading = true);

    await Supabase.instance.client.from('products').insert({
      'user_id': userId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'sku': sku,
      'unit': unit,
    });

    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: _skuController, decoration: const InputDecoration(labelText: 'SKU')),
            TextField(controller: _unitController, decoration: const InputDecoration(labelText: 'Unit (e.g., pcs, kg)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _addProduct,
              child: _loading ? const CircularProgressIndicator() : const Text('Save Product'),
            )
          ],
        ),
      ),
    );
  }
}
