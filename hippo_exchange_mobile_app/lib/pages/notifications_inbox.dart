// File: lib/screens/notifications_inbox.dart
// Simple inbox UI to list notifications and show an unread badge.
// Place a bell icon in your AppBar to navigate to this screen.

import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final all = await NotificationService.instance.getAll();
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    await _refresh();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await NotificationService.instance.clearAll();
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
        centerTitle: false,
        title: RichText(
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Notifications',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF93b9e1).withOpacity(0.2),
            height: 1.0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: _items.any((n) => !n.read) ? _markAllRead : null,
            icon: const Icon(
              Icons.done_all,
              color: Color(0xFF93b9e1),
            ),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _items.isNotEmpty ? _clearAll : null,
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFF93b9e1),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF93b9e1),
              ),
            )
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF93b9e1),
                  onRefresh: _refresh,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        return Dismissible(
                          key: ValueKey(n.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) async {
                            await NotificationService.instance.deleteById(n.id);
                            await _refresh();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: n.read ? Colors.grey[50] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: n.read 
                                    ? Colors.grey[300]! 
                                    : const Color(0xFF93b9e1).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Icon(
                                Icons.notifications,
                                color: const Color(0xFF93b9e1), // Blue bell
                                size: 28,
                              ),
                              title: Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  n.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                _formatTime(n.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () async {
                                await NotificationService.instance
                                    .deleteById(n.id); // simple behavior on tap
                                await _refresh();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final isToday = t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month}/${t.day}/${t.year % 100}';
    }
}
