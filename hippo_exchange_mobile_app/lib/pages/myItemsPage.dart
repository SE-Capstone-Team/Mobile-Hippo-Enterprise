import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:hippo_exchange_mobile_app/pages/addItems.dart';
import 'package:hippo_exchange_mobile_app/pages/viewItem.dart';

// NEW: notifications imports
import 'package:hippo_exchange_mobile_app/pages/notifications_inbox.dart';
import 'package:hippo_exchange_mobile_app/services/notification_service.dart';

class LendingPage extends StatefulWidget {
  const LendingPage({super.key});
  @override
  State<LendingPage> createState() => _LendingPageState();
}

class _LendingPageState extends State<LendingPage> {
  late final FirebaseFirestore db;

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'inventory-db',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
        centerTitle: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hippo ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'Exchange: ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93B9E1),
                ),
              ),
              const TextSpan(
                text: 'My Items',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(.5),
          child: Container(
            color: const Color(0xFF93B9E1).withOpacity(0.2),
            height: 1.0,
          ),
        ),

        // NEW: Notification Bell with unread badge
        actions: [
          FutureBuilder<int>(
            future: NotificationService.instance.getUnreadCount(),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsInboxPage(),
                        ),
                      );
                      if (mounted) setState(() {}); // refresh badge on return
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AuthService().streamMyLentItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No items yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final itemName = data['name'] ?? 'unnamed Item';
              final isLent = data['isLent'] == true;
              final itemDesc = data['desc'] ?? '';

              // Get borrower information if available
              String? borrowerInfo;
              if (isLent && data['borrowerDisplayName'] != null) {
                borrowerInfo = data['borrowerDisplayName'];
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewItemPage(
                        itemId: d.id,
                        itemData: data,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF93B9E1).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Circular image placeholder
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF93B9E1).withOpacity(0.8),
                                const Color(0xFF1a6ec7).withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFF93B9E1),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Expanded content area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item name
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 6),

                              // Description
                              if (itemDesc.isNotEmpty) ...[
                                Text(
                                  itemDesc,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Status and borrower info
                              Row(
                                children: [
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLent
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isLent
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isLent ? 'Currently lent' : 'Available',
                                      style: TextStyle(
                                        color: isLent
                                            ? Colors.red[700]
                                            : Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // Borrower info if available
                                  if (borrowerInfo != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                            Colors.blue.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Lent to: $borrowerInfo',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Status icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLent
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLent
                                ? Icons.assignment_return
                                : Icons.check_circle,
                            color: isLent
                                ? Colors.red[600]
                                : Colors.green[600],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        },
        backgroundColor: Color(0xFF1a6ec7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
