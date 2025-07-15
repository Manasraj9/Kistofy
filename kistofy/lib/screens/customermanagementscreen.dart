import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kistofy/widgets/curved_navbar.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> customers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => isLoading = true);

    final userId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('customers')
        .select()
        .eq('seller_id', userId as Object)
        .order('created_at', ascending: false);

    setState(() {
      customers = response;
      isLoading = false;
    });
  }

  Future<void> _addOrEditCustomer({Map<String, dynamic>? customer}) async {
    final nameController = TextEditingController(text: customer?['name']);
    final mobileController = TextEditingController(text: customer?['mobile']);

    final isEditing = customer != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final mobile = mobileController.text.trim();
              final userId = supabase.auth.currentUser?.id;

              if (name.isEmpty || mobile.isEmpty) return;

              if (isEditing) {
                await supabase.from('customers').update({
                  'name': name,
                  'mobile': mobile,
                }).eq('id', customer['id']);
              } else {
                await supabase.from('customers').insert({
                  'name': name,
                  'mobile': mobile,
                  'seller_id': userId,
                  'created_at': DateTime.now().toIso8601String(),
                });
              }

              Navigator.pop(context);
              _loadCustomers();
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('customers').delete().eq('id', id);
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? const Center(child: Text('No customers found.'))
          : ListView.builder(
        itemCount: customers.length,
        itemBuilder: (_, index) {
          final customer = customers[index];

          return ListTile(
            title: Text(customer['name']),
            subtitle: Text(customer['mobile']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addOrEditCustomer(customer: customer),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCustomer(customer['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCustomer(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AnimatedCurvedNavBar(selectedIndex: 1),
    );
  }
}
