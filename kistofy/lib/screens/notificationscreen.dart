import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final data = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('seller_id', user!.id)
        .order('created_at', ascending: false);

    setState(() {
      notifications = data;
    });
  }

  Future<void> _markAllAsRead() async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('seller_id', user!.id);

    _fetchNotifications();
  }

  Future<void> _deleteAll() async {
    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('seller_id', user!.id);

    _fetchNotifications();
  }

  Future<void> _markAsRead(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  String _timeAgo(String timeString) {
    final time = DateTime.parse(timeString).toLocal();
    return timeago.format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Buttons under heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _markAllAsRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _deleteAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Delete all', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications yet.'))
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return GestureDetector(
                  onTap: () async {
                    await _markAsRead(n['id']);
                    _fetchNotifications();
                    Navigator.pushNamed(context, '/products');
                  },
                  child: Card(
                    color: n['is_read'] ? Colors.white : const Color(0xFFE8F0FE),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: n['is_read'] ? Colors.grey : Colors.blue),
                      title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['message']),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(n['created_at']),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
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
