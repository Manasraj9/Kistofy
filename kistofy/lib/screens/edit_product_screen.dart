import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late Map<String, dynamic> product;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();

  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _nameController.text = product['name'];
    _priceController.text = product['price'].toString();
    _qtyController.text = product['quantity'].toString();
    _categoryController.text = product['category'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _unitController.text = product['unit'] ?? '';
  }

  Future<void> _updateProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = int.tryParse(_qtyController.text) ?? 0;
    final category = _categoryController.text.trim();
    final sku = _skuController.text.trim();
    final unit = _unitController.text.trim();

    if (name.isEmpty || price <= 0 || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill valid product details')),
      );
      return;
    }

    setState(() => _loading = true);

    await Supabase.instance.client.from('products').update({
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'sku': sku,
      'unit': unit,
    }).eq('id', product['id']);

    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: _skuController, decoration: const InputDecoration(labelText: 'SKU')),
            TextField(controller: _unitController, decoration: const InputDecoration(labelText: 'Unit')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _updateProduct,
              child: _loading ? const CircularProgressIndicator() : const Text('Update Product'),
            )
          ],
        ),
      ),
    );
  }
}
