import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String searchQuery = '';
  String filterOption = 'All';
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        products = [];
        isLoading = false;
      });
      return;
    }

    final response = await Supabase.instance.client
        .from('products')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      products = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> deleteProduct(String id) async {
    await Supabase.instance.client.from('products').delete().eq('id', id);
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredProducts = products.where((product) {
      final nameMatch = product['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final quantity = product['quantity'] ?? 0;

      if (filterOption == 'Low Stock') {
        return nameMatch && quantity <= 10;
      }

      return nameMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => filterOption = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Low Stock', child: Text('Low Quantity')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-product').then((_) => fetchProducts());
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No matching products'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(
                      product['name'] ?? 'Unnamed Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${product['price']}                     Qty: ${product['quantity']}', style: TextStyle( fontWeight: FontWeight.w400),),
                        if (product['sku'] != null)
                          Text('SKU: ${product['sku']}',
                              style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                    trailing: Wrap(

                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/edit-product',
                              arguments: product,
                            ).then((_) => fetchProducts());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: Text(
                                    'Are you sure you want to delete "${product['name']}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm ?? false) {
                              await deleteProduct(product['id']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
