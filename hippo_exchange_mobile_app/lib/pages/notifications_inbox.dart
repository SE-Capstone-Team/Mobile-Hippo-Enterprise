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
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: _items.any((n) => !n.read) ? _markAllRead : null,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _items.isNotEmpty ? _clearAll : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        background: Container(color: Colors.redAccent),
                        onDismissed: (_) async {
                          await NotificationService.instance.deleteById(n.id);
                          await _refresh();
                        },
                        child: ListTile(
                          leading: Icon(
                            n.read ? Icons.notifications_none : Icons.notifications_active,
                            color: n.read ? null : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatTime(n.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () async {
                            await NotificationService.instance
                                .deleteById(n.id); // simple behavior on tap
                            await _refresh();
                          },
                        ),
                      );
                    },
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
