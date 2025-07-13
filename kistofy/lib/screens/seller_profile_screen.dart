import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kistofy/widgets/curved_navbar.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final supabase = Supabase.instance.client;
  final _shop   = TextEditingController();
  final _gst    = TextEditingController();
  final _phone  = TextEditingController();
  final _addr   = TextEditingController();

  bool _loading = true;
  bool _editing = false;
  String? _avatarUrl;
  File?   _pickedImg;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = supabase.auth.currentUser!.id;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await supabase
        .from('seller_profiles')
        .select('shop_name, gst_number, phone, address, avatar_url')
        .eq('id', _uid)
        .maybeSingle();

    if (data != null) {
      _shop.text  = data['shop_name']  ?? '';
      _gst.text   = data['gst_number'] ?? '';
      _phone.text = data['phone']      ?? '';
      _addr.text  = data['address']    ?? '';
      _avatarUrl  = data['avatar_url'];
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    if (!_editing) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedImg = File(file.path));
  }

  Future<String?> _uploadAvatar() async {
    if (_pickedImg == null) return _avatarUrl;
    final name = '$_uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucket = supabase.storage.from('seller-avatars');
    await bucket.upload(name, _pickedImg!, fileOptions: const FileOptions(upsert: true));
    return bucket.getPublicUrl(name);
  }

  Future<void> _save() async {
    final gstOk = _gst.text.isEmpty ||
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
            .hasMatch(_gst.text);
    if (!gstOk) {
      _snack('Invalid GST number');
      return;
    }
    if (_shop.text.isEmpty || _phone.text.isEmpty) {
      _snack('Shop name & phone required');
      return;
    }

    final url = await _uploadAvatar();
    await supabase.from('seller_profiles').upsert({
      'id': _uid,
      'shop_name': _shop.text.trim(),
      'gst_number': _gst.text.trim(),
      'phone': _phone.text.trim(),
      'address': _addr.text.trim(),
      'avatar_url': url,
    });

    _snack('Profile saved');
    setState(() {
      _editing = false;
      _avatarUrl = url;
    });
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true)),
          if (_editing)
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _pickedImg != null
                  ? FileImage(_pickedImg!)
                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null)
              as ImageProvider?,
              child: !_editing && _avatarUrl == null
                  ? const Icon(Icons.person, size: 48)
                  : _editing && _pickedImg == null && _avatarUrl == null
                  ? const Icon(Icons.add_a_photo, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          _field('Shop Name', _shop),
          _field('GST Number', _gst),
          _field('Phone', _phone, input: TextInputType.phone),
          _field('Address', _addr, maxLines: 2),
        ]),
      ),
      bottomNavigationBar: const AnimatedCurvedNavBar(selectedIndex: 4),// 👈 highlight Profile tab
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? input, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _editing
          ? TextField(
        controller: c,
        keyboardType: input,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              c.text.isEmpty ? '-' : c.text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
